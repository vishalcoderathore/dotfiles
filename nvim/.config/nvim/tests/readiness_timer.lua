-- Headless check for the readiness bar's timer race (ticks queued while the
-- main loop is blocked must not crash the bar or kill a newer clock).
-- Run through readiness_timer.sh, which also checks a quit with ticks queued.
-- READINESS_CHECK=quit: block with the bar up, then quit at once.
local api = vim.api
local log = {}
local function say(s)
  table.insert(log, s)
end

local function bar_wins()
  local ns = api.nvim_get_namespaces()["readiness"]
  local out = {}
  for _, w in ipairs(api.nvim_list_wins()) do
    if api.nvim_win_get_config(w).relative ~= "" then
      local b = api.nvim_win_get_buf(w)
      if ns and #api.nvim_buf_get_extmarks(b, ns, 0, -1, { limit = 1 }) > 0 then
        table.insert(out, w)
      end
    end
  end
  return out
end

local function block(ms)
  -- system() blocks the main loop but keeps libuv polling, so timer ticks
  -- fire and queue up as during a heavy startup. A Lua busy-wait would also
  -- stall libuv and never reproduce the race.
  vim.fn.system({ "sleep", tostring(ms / 1000) })
end

local function readiness_errors()
  local msgs = api.nvim_exec2("messages", { output = true }).output
  local errs = {}
  for line in msgs:gmatch("[^\n]+") do
    if line:find("readiness") and (line:find("attempt") or line:find("Error") or line:find("error")) then
      table.insert(errs, line)
    end
  end
  if vim.v.errmsg:find("readiness") then
    table.insert(errs, "v:errmsg: " .. vim.v.errmsg)
  end
  return errs
end

-- Phase helpers --------------------------------------------------------------
local function wait_for(pred, timeout_ms)
  return vim.wait(timeout_ms, pred, 50)
end

-- Repeatedly block the main loop while the bar is up, so ticks queue across
-- the moment the bar closes.
local function hammer_until_closed(max_ms)
  local start = vim.uv.now()
  while #bar_wins() > 0 and vim.uv.now() - start < max_ms do
    block(500)
    vim.wait(30) -- let queued ticks drain back to back
  end
  return #bar_wins() == 0
end

local function finish(ok)
  local errs = readiness_errors()
  for _, e in ipairs(errs) do
    say("ERROR: " .. e)
  end
  ok = ok and #errs == 0
  say(ok and "RESULT: PASS" or "RESULT: FAIL")
  io.stdout:write(table.concat(log, "\n") .. "\n")
  vim.cmd(ok and "qa!" or "cq!")
end

-- Fire an LspProgress from a libuv timer so it lands in the schedule queue
-- between readiness ticks that pile up during the block.
local function progress_mid_block(client_id, kind)
  local t = vim.uv.new_timer()
  t:start(250, 0, vim.schedule_wrap(function()
    t:close()
    api.nvim_exec_autocmds("LspProgress", {
      pattern = kind,
      data = { client_id = client_id, params = { token = "readiness-check", value = { kind = kind, title = "Check" } } },
    })
  end))
  block(500)
end

-- Quit while the bar is up and ticks are still queued. Errors thrown during
-- shutdown can't be seen from here, so the runner checks stderr.
if vim.env.READINESS_CHECK == "quit" then
  vim.schedule(function()
    if not wait_for(function()
      return #bar_wins() > 0
    end, 5000) then
      io.stdout:write("bar opened: false\nRESULT: FAIL\n")
      return vim.cmd("cq!")
    end
    block(500)
    vim.cmd("qa!")
  end)
  return
end

vim.schedule(function()
  -- Scenario 1: blocked main loop while the bar is up and as it closes.
  local opened = wait_for(function()
    return #bar_wins() > 0
  end, 5000)
  say("bar opened: " .. tostring(opened))
  if not opened then
    return finish(false)
  end
  local closed = hammer_until_closed(40000)
  say("bar closed after blocked loop: " .. tostring(closed))
  block(500) -- stale ticks may still be queued right after close
  vim.wait(300)
  if not closed then
    return finish(false)
  end

  -- Scenario 2: an ensure_timer event lands between queued ticks after close;
  -- the new clock must survive, so the bar reopens and closes again by itself.
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
  end
  say("attached clients: " .. (#names > 0 and table.concat(names, ",") or "none"))
  if #clients == 0 then
    return finish(false)
  end
  local id = clients[1].id
  vim.cmd("doautocmd BufEnter")
  progress_mid_block(id, "begin")
  local reopened = wait_for(function()
    return #bar_wins() > 0
  end, 3000)
  say("bar reopened on LSP progress: " .. tostring(reopened))
  hammer_until_closed(1500) -- keep queuing ticks while progress shows
  progress_mid_block(id, "end")
  local reclosed = hammer_until_closed(20000)
  vim.wait(300)
  say("bar closed again by itself: " .. tostring(reclosed))
  finish(reopened and reclosed)
end)
