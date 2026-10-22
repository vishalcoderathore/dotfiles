-- Neotest, on top of LazyVim's test.core extra.

return {
  -- Neotest opens its output float without a border, and nothing global
  -- (winborder) supplies one, so the box blends into the editor.
  {
    "nvim-neotest/neotest",
    opts = {
      floating = { border = "rounded" },
    },
  },
}
