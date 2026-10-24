-- One color per Vim mode, shared by every mode indicator (the incline badge
-- and the current line number) so they always agree.
--
-- Colors come from the active colorscheme's highlight groups rather than a
-- fixed palette, so the indicators follow whatever theme is loaded.

local M = {}

-- Keyed by the first character of vim.fn.mode(). The two control characters
-- are visual-block (Ctrl-V) and select-block (Ctrl-S). Each group's foreground
-- is the mode color; under Catppuccin Mocha these resolve to blue, green,
-- mauve, red and peach.
local mode_groups = {
  n = "Function",
  i = "String",
  v = "Keyword",
  V = "Keyword",
  ["\22"] = "Keyword",
  s = "Keyword",
  S = "Keyword",
  ["\19"] = "Keyword",
  R = "DiagnosticError",
  c = "Constant",
  t = "String",
}

-- Looked up on every call, not cached, so a colorscheme change is picked up.
local function hl_color(group, attr)
  local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
  return value and string.format("#%06x", value)
end

function M.color_for_mode()
  return hl_color(mode_groups[vim.fn.mode():sub(1, 1)] or "Function", "fg")
end

-- The editor background, used as text color on the mode-colored badge.
-- Transparent themes leave Normal without a background, hence the fallback.
function M.background()
  return hl_color("Normal", "bg") or (vim.o.background == "light" and "#ffffff" or "#000000")
end

return M
