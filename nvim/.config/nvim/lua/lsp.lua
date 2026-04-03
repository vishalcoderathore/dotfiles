-- ~/.config/nvim/lua/lsp.lua

-- LSP configuration (Neovim 0.11+ native API)
vim.lsp.config('ts_ls', {})
vim.lsp.enable('ts_ls')

-- Setup none-ls for ESLint and Prettier integration
local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.eslint_d,
    null_ls.builtins.code_actions.eslint_d,
    null_ls.builtins.formatting.prettier,
  },
})
