-- One color per Vim mode, shared by every mode indicator (the incline badge
-- and the current line number) so they always agree.

local M = {}

-- Keyed by the first character of vim.fn.mode(). The two control characters
-- are visual-block (Ctrl-V) and select-block (Ctrl-S).
local mode_palette_names = {
  n = "blue",
  i = "green",
  v = "mauve",
  V = "mauve",
  ["\22"] = "mauve",
  s = "mauve",
  S = "mauve",
  ["\19"] = "mauve",
  R = "red",
  c = "peach",
  t = "green",
}

-- Looked up on every call, not at require time, so nothing loads Catppuccin
-- before lazy.nvim has set it up.
function M.palette()
  return require("catppuccin.palettes").get_palette("mocha")
end

function M.color_for_mode()
  local palette = M.palette()
  return palette[mode_palette_names[vim.fn.mode():sub(1, 1)] or "blue"]
end

return M
