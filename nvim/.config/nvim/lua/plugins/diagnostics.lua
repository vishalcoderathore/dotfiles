return {
  "neovim/nvim-lspconfig",
  opts = {
    diagnostics = {
      -- The line-diagnostics float (`<leader>cd`, `]d`) falls back to
      -- 'winborder', which is unset, so failing-test messages float borderless.
      float = { border = "rounded" },
    },
  },
}
