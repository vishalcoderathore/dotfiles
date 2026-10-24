-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- dap-ui panels inherit LazyVim's global statuscolumn, which reserves four
-- empty columns for signs and folds they never show.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dapui_no_gutter", { clear = true }),
  pattern = { "dapui_*", "dap-repl" },
  callback = function()
    vim.opt_local.statuscolumn = ""
    vim.opt_local.signcolumn = "no"
  end,
})

-- While relative numbers are on, color the current line number by mode.
-- CursorLineNr is one highlight shared by every window, so it stays untouched.
-- Instead, each window with relative numbers on remaps it, through the
-- window-local winhighlight option, to ModeLineNr, which follows the mode.
-- Other line numbers (LineNr) keep their color.
local mode_colors = require("util.mode_colors")
local linenr_remap = "CursorLineNr:ModeLineNr"

local function paint_mode_linenr()
  vim.api.nvim_set_hl(0, "ModeLineNr", { fg = mode_colors.color_for_mode() })
end

-- Add or drop the remap so it matches the window's own relativenumber value,
-- keeping any winhighlight entries other plugins have set.
local function sync_linenr_remap(win)
  local entries = vim.tbl_filter(function(entry)
    return entry ~= linenr_remap
  end, vim.split(vim.wo[win].winhighlight, ",", { trimempty = true }))
  if vim.wo[win].relativenumber then
    table.insert(entries, linenr_remap)
  end
  local winhighlight = table.concat(entries, ",")
  if winhighlight ~= vim.wo[win].winhighlight then
    -- Local scope only: vim.wo would also set the global value, which every
    -- new window starts from, remap included.
    vim.api.nvim_set_option_value("winhighlight", winhighlight, { win = win, scope = "local" })
  end
end

local function sync_current_window()
  sync_linenr_remap(vim.api.nvim_get_current_win())
end

local mode_linenr_group = vim.api.nvim_create_augroup("mode_cursor_linenr", { clear = true })
-- A colorscheme change clears ModeLineNr along with every other custom group.
vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme" }, {
  group = mode_linenr_group,
  callback = paint_mode_linenr,
})
-- Neovim runs OptionSet in the window whose option changed, even when that is
-- not the focused one (:windo, a plugin setting another window's options).
-- Watching winhighlight too restores the remap after a user or API write
-- replaces it. Autocmds don't nest, so the sync's own write doesn't fire this
-- again, and neither does a write made from inside another plugin's autocmd.
vim.api.nvim_create_autocmd("OptionSet", {
  group = mode_linenr_group,
  pattern = { "relativenumber", "winhighlight" },
  callback = sync_current_window,
})
vim.api.nvim_create_autocmd({ "WinNew", "BufWinEnter" }, {
  group = mode_linenr_group,
  callback = sync_current_window,
})

paint_mode_linenr()
for _, win in ipairs(vim.api.nvim_list_wins()) do
  sync_linenr_remap(win)
end
