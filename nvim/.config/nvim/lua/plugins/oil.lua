-- Edit the filesystem as a buffer: one directory per buffer, one entry per
-- line. Rename, move, create and delete by editing lines, then :w applies it.

return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open Parent Directory (Oil)" },
    },
    opts = {
      -- Leave `nvim .` and directory buffers to the snacks explorer; oil only
      -- opens when asked for.
      default_file_explorer = false,
      -- Deleted entries go to the freedesktop trash, not straight to rm.
      delete_to_trash = true,
      -- Oil's floats are borderless by default; match the rounded lazy, mason
      -- and diagnostic windows.
      float = { border = "rounded" },
      confirmation = { border = "rounded" },
      progress = { border = "rounded" },
      ssh = { border = "rounded" },
      keymaps_help = { border = "rounded" },
    },
  },
}
