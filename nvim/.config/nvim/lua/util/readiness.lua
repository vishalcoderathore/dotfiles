-- Bottom-right progress bar showing how ready the current file is.
--
-- When a file is opened, this works out what its filetype needs and tracks
-- each piece until it is ready:
--   - plugins lazy-loaded for the filetype (lazy.nvim `ft` specs)
--   - the Treesitter parser
--   - each LSP server that should attach, until it finishes indexing
--   - the conform formatters and nvim-lint linters set for the filetype
--
-- Nothing installs automatically (see lua/lockdown.lua), so anything absent is
-- marked "missing" with the command that installs it. :Readiness lists every
-- item for the current buffer.
--
-- After a buffer is ready, the bar comes back whenever one of its LSP servers
-- reports progress again (re-indexing after a save, for example). This replaces
-- Noice's LSP progress text, which noice.lua turns off.

local M = {}

local api = vim.api

-- How long an expected LSP server may take to attach before it is reported as
-- "didn't start".
local ATTACH_TIMEOUT = 15000
-- Some clients attach without being predicted (rustaceanvim, easy-dotnet), so
-- a buffer is never declared ready sooner than this after it opens.
local SETTLE_MS = 1200
-- How long the final state stays on screen.
local LINGER_OK = 1200
local LINGER_WARN = 5000
-- Servers often attach first and announce indexing a moment later. An attached
-- server only counts as ready once it has been quiet this long.
local QUIET_MS = 1000

local WIDTH = 44
local SPINNER = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

-- LSP clients started by plugins rather than vim.lsp.enable(), keyed by
-- filetype. They cannot be predicted from vim.lsp's configs.
local PLUGIN_CLIENTS = {
  rust = { { plugin = "rustaceanvim", client = "rust-analyzer", cmd = "rust-analyzer" } },
}

---@class readiness.Item
---@field kind "plugin"|"parser"|"lsp"|"formatter"|"linter"
---@field name string
---@field state "pending"|"indexing"|"ready"|"missing"|"skipped"
---@field hint? string   install command or explanation for missing/skipped
---@field client_id? integer
---@field deadline? integer
---@field attached_at? integer
---@field peak? number       highest progress percentage seen
---@field was_busy? boolean

---@class readiness.Buf
---@field ft string
---@field items readiness.Item[]
---@field opened integer
---@field done boolean
---@field done_at? integer

---@type table<integer, readiness.Buf>
local bufs = {}
-- Active progress tokens per LSP client: token -> { title, message, pct }.
---@type table<integer, table<string|integer, {title?:string, message?:string, pct?:number}>>
local progress = {}

local win, buf_display = nil, nil
local ns = api.nvim_create_namespace("readiness")
local timer = nil
local spin = 1
local tick = 0 -- free-running, drives the sweep animation
local render_queued = false

local function now()
  return vim.uv.now()
end

local function is_file_buf(b)
  return api.nvim_buf_is_valid(b) and vim.bo[b].buftype == "" and api.nvim_buf_get_name(b) ~= ""
end

local function norm(name)
  return name:lower():gsub("[-_]", "")
end

local function client_matches(item, client)
  return norm(item.name) == norm(client.name)
end

---------------------------------------------------------------------------
-- Working out what a filetype needs
---------------------------------------------------------------------------

local function plugin_items(ft)
  local items = {}
  local ok, Config = pcall(require, "lazy.core.config")
  if not ok then
    return items
  end
  local Plugin = require("lazy.core.plugin")
  for name, plugin in pairs(Config.plugins) do
    local fts = Plugin.values(plugin, "ft", true)
    -- A plugin turned off by `cond` never loads, so it is not a requirement.
    if vim.list_contains(fts, ft) and plugin._.cond ~= false then
      if not plugin._.installed then
        -- Not installed (lockdown skips installs on startup); it can't load.
        items[#items + 1] = { kind = "plugin", name = name, state = "missing", hint = ":Lazy install " .. name }
      else
        items[#items + 1] = { kind = "plugin", name = name, state = plugin._.loaded and "ready" or "pending" }
      end
    end
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  return items
end

local function parser_item(ft)
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok, added = pcall(vim.treesitter.language.add, lang)
  if ok and added then
    return { kind = "parser", name = lang, state = "ready" }
  end
  -- Only flag it when nvim-treesitter can actually install one.
  local cfg_ok, cfg = pcall(require, "nvim-treesitter.config")
  if cfg_ok and vim.list_contains(cfg.get_available(), lang) then
    return { kind = "parser", name = lang, state = "missing", hint = ":TSInstall " .. lang }
  end
end

local function mason_package(server)
  local ok, mappings = pcall(require, "mason-lspconfig.mappings")
  if ok then
    return mappings.get_mason_map().lspconfig_to_package[server]
  end
end

-- Install command for a tool, trying each candidate as a Mason package name
-- (nvim-lint calls it "golangcilint", Mason calls it "golangci-lint").
local function install_hint(...)
  local ok, registry = pcall(require, "mason-registry")
  for _, candidate in ipairs({ ... }) do
    if ok and type(candidate) == "string" and registry.has_package(candidate) then
      return ":MasonInstall " .. candidate
    end
  end
  local first = select(1, ...)
  return "install " .. tostring(first)
end

local function cmd_executable(config)
  return type(config.cmd) == "function" or (type(config.cmd) == "table" and vim.fn.executable(config.cmd[1]) == 1)
end

-- Mirrors vim.lsp.enable()'s own decision: a config whose root_dir function
-- never calls on_dir, or that requires a workspace it cannot find, is not
-- expected to start for this buffer.
local function wants_buffer(config, b)
  if type(config.root_dir) == "function" then
    local called = false
    pcall(config.root_dir, b, function()
      called = true
    end)
    return called
  end
  if config.workspace_required and config.root_markers then
    return vim.fs.root(b, config.root_markers) ~= nil
  end
  return true
end

local function lsp_items(ft, b)
  local items, seen = {}, {}
  local function add(item)
    if not seen[item.name] then
      seen[item.name] = true
      items[#items + 1] = item
    end
  end

  local deadline = now() + ATTACH_TIMEOUT

  -- Servers vim.lsp will try to start for this filetype.
  for _, config in ipairs(vim.lsp.get_configs({ enabled = true, filetype = ft })) do
    if not cmd_executable(config) then
      local pkg = mason_package(config.name)
      add({
        kind = "lsp",
        name = config.name,
        state = "missing",
        hint = pkg and (":MasonInstall " .. pkg)
          or ("install " .. tostring(type(config.cmd) == "table" and config.cmd[1] or config.name)),
      })
    elseif wants_buffer(config, b) then
      add({ kind = "lsp", name = config.name, state = "pending", deadline = deadline })
    end
  end

  -- Servers LazyVim is configured for but never enabled. With mason-lspconfig
  -- that means the package is not installed, since only installed servers are
  -- enabled automatically.
  local ok, servers = pcall(function()
    return LazyVim.opts("nvim-lspconfig").servers
  end)
  if ok and type(servers) == "table" then
    for name, sopts in pairs(servers) do
      local enabled = sopts ~= false and not (type(sopts) == "table" and sopts.enabled == false)
      if name ~= "*" and enabled and not seen[name] and not vim.lsp.is_enabled(name) then
        local cfg_ok, config = pcall(function()
          return vim.lsp.config[name]
        end)
        local fts = cfg_ok and config and config.filetypes or {}
        if vim.list_contains(fts, ft) then
          local pkg = mason_package(name)
          add({
            kind = "lsp",
            name = name,
            state = "missing",
            hint = pkg and (":MasonInstall " .. pkg) or "not installed",
          })
        end
      end
    end
  end

  for _, spec in ipairs(PLUGIN_CLIENTS[ft] or {}) do
    local has = pcall(function()
      return assert(require("lazy.core.config").plugins[spec.plugin])
    end)
    if has then
      if vim.fn.executable(spec.cmd) == 1 then
        add({ kind = "lsp", name = spec.client, state = "pending", deadline = deadline })
      else
        add({ kind = "lsp", name = spec.client, state = "missing", hint = "install " .. spec.cmd })
      end
    end
  end

  return items
end

local function formatter_items(b)
  local items = {}
  local ok, conform = pcall(require, "conform")
  if not ok then
    return items
  end
  for _, name in ipairs(conform.list_formatters_for_buffer(b)) do
    local info = conform.get_formatter_info(name, b)
    if info.available then
      items[#items + 1] = { kind = "formatter", name = name, state = "ready" }
    elseif info.error then
      items[#items + 1] = { kind = "formatter", name = name, state = "missing", hint = "unknown formatter" }
    elseif (info.available_msg or ""):match("^Command") then
      -- "Command 'x' not found". A failed condition (markdown-toc without a
      -- TOC marker) or missing project root just means it doesn't apply here.
      items[#items + 1] =
        { kind = "formatter", name = name, state = "missing", hint = install_hint(name, info.command) }
    end
  end
  return items
end

local function linter_items(ft, b)
  local items = {}
  local ok, lint = pcall(require, "lint")
  if not ok then
    return items
  end
  local names = vim.list_extend({}, lint._resolve_linter_by_ft(ft))
  vim.list_extend(names, lint.linters_by_ft["*"] or {})
  local ctx = { filename = api.nvim_buf_get_name(b) }
  ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
  for _, name in ipairs(names) do
    local linter = lint.linters[name]
    if type(linter) == "function" then
      local lok, resolved = pcall(linter)
      linter = lok and resolved or nil
    end
    -- Same filter LazyVim applies before running a linter.
    if type(linter) == "table" and not (linter.condition and not linter.condition(ctx)) then
      local cmd = linter.cmd
      if type(cmd) == "function" then
        local cok, resolved = pcall(cmd)
        cmd = cok and resolved or nil
      end
      if type(cmd) == "string" and vim.fn.executable(cmd) == 1 then
        items[#items + 1] = { kind = "linter", name = name, state = "ready" }
      else
        items[#items + 1] = { kind = "linter", name = name, state = "missing", hint = install_hint(cmd, name) }
      end
    end
  end
  return items
end

---------------------------------------------------------------------------
-- State updates
---------------------------------------------------------------------------

-- Forget progress from clients that have stopped. A server that crashes
-- mid-indexing never sends the "end" for its tokens.
local function prune_progress()
  for id in pairs(progress) do
    local client = vim.lsp.get_client_by_id(id)
    if not client or client:is_stopped() then
      progress[id] = nil
    end
  end
end

local function sync_lsp(b)
  local st = bufs[b]
  if not st then
    return
  end
  local attached = vim.lsp.get_clients({ bufnr = b })

  -- Clients nobody predicted still count once they attach.
  for _, client in ipairs(attached) do
    local known = false
    for _, item in ipairs(st.items) do
      if item.kind == "lsp" and client_matches(item, client) then
        known = true
        break
      end
    end
    if not known then
      st.items[#st.items + 1] = { kind = "lsp", name = client.name, state = "pending" }
    end
  end

  for _, item in ipairs(st.items) do
    if item.kind == "lsp" and item.state ~= "missing" then
      local client
      for _, c in ipairs(attached) do
        if client_matches(item, c) then
          client = c
          break
        end
      end
      if client then
        item.hint = nil -- clear "stopped" once a restarted client reattaches
        if item.client_id ~= client.id then
          item.client_id = client.id
          item.attached_at = now()
        end
        local busy = next(progress[client.id] or {}) ~= nil
        if busy then
          item.attached_at = now() -- restart the quiet period after each burst
          for _, p in pairs(progress[client.id]) do
            item.peak = math.max(item.peak or 0, p.pct or 0)
          end
        elseif item.was_busy then
          item.peak = 100 -- a finished burst keeps the bar full while it settles
        end
        item.was_busy = busy
        item.state = (busy or now() - item.attached_at < QUIET_MS) and "indexing" or "ready"
      elseif item.client_id then
        -- Was attached, now gone: stopped or crashed. A restart that
        -- reattaches takes the branch above again.
        item.client_id = nil
        item.state = "skipped"
        item.hint = "stopped"
      elseif item.state == "pending" and item.deadline and now() > item.deadline then
        item.state = "skipped"
        item.hint = "didn't start, see :checkhealth vim.lsp"
      end
    end
  end
end

local function sync_plugins(b)
  local st = bufs[b]
  if not st then
    return
  end
  local Config = require("lazy.core.config")
  for _, item in ipairs(st.items) do
    if item.kind == "plugin" and item.state == "pending" then
      local plugin = Config.plugins[item.name]
      if plugin and plugin._.loaded then
        item.state = "ready"
      end
    end
  end
end

-- How far an indexing server has got: the highest percentage it has reported.
local function item_pct(item)
  local pct = item.peak or 0
  for _, p in pairs(progress[item.client_id] or {}) do
    pct = math.max(pct, p.pct or 0)
  end
  return pct
end

local function counts(st)
  local resolved, missing, total = 0, 0, #st.items
  for _, item in ipairs(st.items) do
    if item.state == "ready" then
      resolved = resolved + 1
    elseif item.state == "missing" or item.state == "skipped" then
      resolved = resolved + 1
      missing = missing + 1
    elseif item.state == "indexing" then
      -- An attached server is half way; its own percentage fills the rest.
      resolved = resolved + 0.5 + 0.5 * item_pct(item) / 100
    end
  end
  return resolved, missing, total
end

local function settled(st)
  if now() - st.opened < SETTLE_MS then
    return false
  end
  for _, item in ipairs(st.items) do
    if item.state == "pending" or item.state == "indexing" then
      return false
    end
  end
  return true
end

-- Progress currently reported by any client attached to this buffer.
local function active_progress(b)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = b })) do
    for _, p in pairs(progress[client.id] or {}) do
      return client.name, p
    end
  end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local function close()
  if win and api.nvim_win_is_valid(win) then
    api.nvim_win_close(win, true)
  end
  win = nil
end

local function bar(fraction, width)
  local filled = math.floor(fraction * width + 0.5)
  return string.rep("━", filled), string.rep("─", width - filled)
end

-- Colour of a finished or waiting segment, by item state.
local SEGMENT_HL = {
  ready = "ReadinessDone",
  missing = "ReadinessWarn",
  skipped = "ReadinessWarn",
  pending = "ReadinessEmpty",
}

-- One segment per item, in item order (plugins, parser, LSP, formatters,
-- linters), separated by a space. Ready segments are green, missing ones
-- yellow, waiting ones dim; an indexing server's segment fills with its own
-- percentage. Returns the text and highlights as byte offsets into it.
local function segments(items, width)
  local n = #items
  local gap = (width - (n - 1) >= n) and 1 or 0
  local avail = width - gap * (n - 1)
  local base, extra = math.floor(avail / n), avail % n

  local parts, hls, pos = {}, {}, 0
  for i, item in ipairs(items) do
    local cells = base + (i <= extra and 1 or 0)
    if item.state == "indexing" then
      local filled = math.max(1, math.floor(cells * item_pct(item) / 100 + 0.5))
      local fill, rest = string.rep("━", filled), string.rep("─", cells - filled)
      parts[#parts + 1] = fill .. rest
      hls[#hls + 1] = { pos, pos + #fill, "ReadinessFill" }
      hls[#hls + 1] = { pos + #fill, pos + #fill + #rest, "ReadinessEmpty" }
      pos = pos + #fill + #rest
    else
      local char = item.state == "pending" and "─" or "━"
      local text = string.rep(char, cells)
      parts[#parts + 1] = text
      hls[#hls + 1] = { pos, pos + #text, SEGMENT_HL[item.state] }
      pos = pos + #text
    end
    if gap == 1 and i < n then
      parts[#parts + 1] = " "
      pos = pos + 1
    end
  end
  return table.concat(parts), hls
end

local function fit(text, width)
  if vim.fn.strdisplaywidth(text) <= width then
    return text
  end
  return vim.fn.strcharpart(text, 0, width - 1) .. "…"
end

local function current_activity(st)
  for _, item in ipairs(st.items) do
    if item.state == "indexing" then
      for _, p in pairs(progress[item.client_id] or {}) do
        local text = item.name .. " · " .. (p.title or "working")
        if p.message then
          text = text .. " " .. p.message
        end
        return text
      end
      return item.name .. (item.peak and " · finishing" or " · starting")
    end
  end
  for _, item in ipairs(st.items) do
    if item.state == "pending" then
      return (item.kind == "lsp" and "starting " or "loading ") .. item.name
    end
  end
  return "finishing"
end

local function show(lines, highlights)
  if not buf_display or not api.nvim_buf_is_valid(buf_display) then
    buf_display = api.nvim_create_buf(false, true)
    vim.bo[buf_display].bufhidden = "hide"
  end
  api.nvim_buf_set_lines(buf_display, 0, -1, false, lines)
  api.nvim_buf_clear_namespace(buf_display, ns, 0, -1)
  for _, hl in ipairs(highlights) do
    api.nvim_buf_set_extmark(buf_display, ns, hl[1], hl[2], { end_col = hl[3], hl_group = hl[4] })
  end

  -- Bottom-right corner, just above the (global) statusline.
  local statusline = (vim.o.laststatus == 0 or (vim.o.laststatus == 1 and #api.nvim_list_wins() == 1)) and 0 or 1
  local config = {
    relative = "editor",
    anchor = "SE",
    row = vim.o.lines - vim.o.cmdheight - statusline,
    col = vim.o.columns,
    width = WIDTH,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 45,
    noautocmd = true,
  }
  if win and api.nvim_win_is_valid(win) then
    config.noautocmd = nil
    api.nvim_win_set_config(win, config)
  else
    win = api.nvim_open_win(buf_display, false, config)
    vim.wo[win].winhighlight = "NormalFloat:Normal,FloatBorder:ReadinessBorder"
    vim.wo[win].winblend = 0
  end
end

local function render()
  render_queued = false
  local b = api.nvim_get_current_buf()
  local st = bufs[b]
  local width = WIDTH - 2

  prune_progress()
  if st then
    sync_plugins(b)
    sync_lsp(b)
  end

  -- 1. Still getting ready.
  if st and not st.done and #st.items > 0 then
    if settled(st) then
      st.done = true
      st.done_at = now()
    end
  end

  if
    st
    and #st.items > 0
    and (not st.done or now() - st.done_at < (select(2, counts(st)) > 0 and LINGER_WARN or LINGER_OK))
  then
    local resolved, missing, total = counts(st)
    local label = st.ft .. " "
    local count = (" %d/%d"):format(math.floor(resolved), total)
    local bar_width = width - #label - #count
    local track, track_hls = segments(st.items, bar_width)
    local line1 = label .. track .. count

    local line2, hl2
    if not st.done then
      line2 = SPINNER[spin] .. " " .. current_activity(st)
      hl2 = "ReadinessText"
    elseif missing > 0 then
      line2 = ("⚠ %d missing · :Readiness"):format(missing)
      hl2 = "ReadinessWarn"
    else
      line2 = "✓ ready"
      hl2 = "ReadinessDone"
    end
    line2 = fit(line2, width)

    local hls = {
      { 0, 0, #label, "ReadinessLabel" },
      { 0, #line1 - #count, #line1, "ReadinessText" },
      { 1, 0, #line2, hl2 },
    }
    for _, h in ipairs(track_hls) do
      hls[#hls + 1] = { 0, #label + h[1], #label + h[2], h[3] }
    end
    show({ line1, line2 }, hls)
    return
  end

  -- 2. Ready, but an attached server is working again.
  local client_name, p = active_progress(b)
  if client_name and p then
    local label = client_name .. " "
    local pct = p.pct and (" %3d%%"):format(p.pct) or ""
    local bar_width = width - #label - #pct
    local fill, rest
    if p.pct then
      fill, rest = bar(p.pct / 100, bar_width)
    else
      fill, rest = "", string.rep("─", bar_width)
    end
    local line1 = label .. fill .. rest .. pct
    local line2 = fit(SPINNER[spin] .. " " .. (p.title or "working") .. (p.message and (" " .. p.message) or ""), width)
    local hls = {
      { 0, 0, #label, "ReadinessLabel" },
      { 0, #label, #label + #fill, "ReadinessFill" },
      { 0, #label + #fill, #label + #fill + #rest, "ReadinessEmpty" },
      { 0, #line1 - #pct, #line1, "ReadinessText" },
      { 1, 0, #line2, "ReadinessText" },
    }
    if not p.pct then
      -- No percentage: a 3-cell block sweeping along the track.
      local cell = #"─"
      local pos = tick % (bar_width - 2)
      local start = #label + pos * cell
      hls[#hls + 1] = { 0, start, start + 3 * cell, "ReadinessFill" }
    end
    show({ line1, line2 }, hls)
    return
  end

  close()
end

local function queue_render()
  if not render_queued then
    render_queued = true
    vim.schedule(render)
  end
end

-- The spinner and the timeouts need a clock; it only runs while the bar is up.
-- `timer` is the single "is a clock running?" flag. Ticks are scheduled, so
-- several can queue while the main loop is busy and run after their timer was
-- torn down or replaced. Each tick therefore acts only on its own handle and
-- does nothing once that handle is no longer the current timer.
local function ensure_timer()
  if timer then
    return
  end
  local own = vim.uv.new_timer()
  timer = own
  own:start(
    100,
    100,
    vim.schedule_wrap(function()
      if timer ~= own then
        return -- stale tick: its timer was closed or replaced
      end
      spin = spin % #SPINNER + 1
      tick = tick + 1
      render()
      if not win then
        own:stop()
        own:close()
        timer = nil
      end
    end)
  )
end

---------------------------------------------------------------------------
-- Tracking buffers
---------------------------------------------------------------------------

local function track(b)
  if not is_file_buf(b) then
    return
  end
  local ft = vim.bo[b].filetype
  if ft == "" then
    return
  end
  -- Wait a moment so lazy.nvim has handled the FileType and LazyFile events
  -- (that is when nvim-lspconfig, conform and nvim-lint load and when the
  -- servers are enabled).
  vim.defer_fn(function()
    if not api.nvim_buf_is_valid(b) or vim.bo[b].filetype ~= ft then
      return
    end
    local items = plugin_items(ft)
    items[#items + 1] = parser_item(ft)
    vim.list_extend(items, lsp_items(ft, b))
    vim.list_extend(items, formatter_items(b))
    vim.list_extend(items, linter_items(ft, b))
    bufs[b] = { ft = ft, items = items, opened = now(), done = false }
    ensure_timer()
    queue_render()
  end, 50)
end

function M.report()
  local b = api.nvim_get_current_buf()
  local st = bufs[b]
  if not st then
    vim.notify("No readiness data for this buffer", vim.log.levels.INFO, { title = "Readiness" })
    return
  end
  prune_progress()
  sync_plugins(b)
  sync_lsp(b)
  local icons = { ready = "✓", missing = "✗", skipped = "!", pending = "…", indexing = "↻" }
  local lines = {}
  for _, item in ipairs(st.items) do
    local line = ("%s %-9s %s"):format(icons[item.state], item.kind, item.name)
    if item.hint then
      line = line .. "  (" .. item.hint .. ")"
    end
    lines[#lines + 1] = line
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Readiness: " .. st.ft })
end

local function set_highlights()
  local function link(name, target)
    api.nvim_set_hl(0, name, { link = target, default = true })
  end
  link("ReadinessLabel", "Title")
  link("ReadinessFill", "Function")
  link("ReadinessEmpty", "NonText")
  link("ReadinessText", "Comment")
  link("ReadinessDone", "DiagnosticOk")
  link("ReadinessWarn", "DiagnosticWarn")
  link("ReadinessBorder", "FloatBorder")
end

function M.setup()
  local group = api.nvim_create_augroup("readiness", { clear = true })
  set_highlights()

  api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })

  api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(ev)
      track(ev.buf)
    end,
  })

  api.nvim_create_autocmd("User", {
    group = group,
    pattern = "LazyLoad",
    callback = queue_render,
  })

  api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    group = group,
    callback = function()
      ensure_timer()
      queue_render()
    end,
  })

  api.nvim_create_autocmd("LspProgress", {
    group = group,
    callback = function(ev)
      local id, params = ev.data.client_id, ev.data.params
      local value = params.value
      if type(value) ~= "table" then
        return
      end
      progress[id] = progress[id] or {}
      if value.kind == "end" then
        progress[id][params.token] = nil
      else
        -- A "report" for a token we never saw "begin" for still counts.
        local p = progress[id][params.token] or {}
        p.title = value.title or p.title
        p.message = value.message
        p.pct = value.percentage or p.pct
        progress[id][params.token] = p
      end
      ensure_timer()
      queue_render()
    end,
  })

  api.nvim_create_autocmd({ "BufEnter", "VimResized" }, {
    group = group,
    callback = function()
      ensure_timer()
      queue_render()
    end,
  })

  api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(ev)
      bufs[ev.buf] = nil
    end,
  })

  api.nvim_create_user_command("Readiness", M.report, { desc = "List what the current buffer needs and its state" })

  -- Buffers that got their filetype before setup ran.
  for _, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(b) and not bufs[b] then
      track(b)
    end
  end
end

return M
