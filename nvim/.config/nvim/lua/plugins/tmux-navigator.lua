-- Ctrl+h/j/k/l moves between Neovim splits and tmux panes with the same keys.
-- The tmux half of this lives in tmux/.config/tmux/tmux.conf: tmux checks
-- whether the focused pane is running Neovim and, if so, forwards the key here
-- instead of switching panes itself. Both halves must be installed or the key
-- stops at whichever side is missing.

return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    -- These replace LazyVim's own <C-hjkl> window-navigation maps; the plugin
    -- commands fall back to a plain window move when there is no tmux pane in
    -- that direction, so nothing is lost when running Neovim outside tmux.
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to Left Window" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to Lower Window" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to Upper Window" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to Right Window" },
    },
  },
}
