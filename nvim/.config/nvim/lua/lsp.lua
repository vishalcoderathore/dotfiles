-- ~/.config/nvim/lua/lsp.lua

-- LSP configuration (using nvim-lspconfig)
local lspconfig = require("lspconfig")

-- Set up tsserver for JavaScript/TypeScript
lspconfig.ts_ls.setup {}

-- Setup null-ls for ESLint and Prettier integration
local null_ls = require("null-ls")

null_ls.setup({
  sources = {
    null_ls.builtins.diagnostics.eslint_d,  -- for ESLint
    null_ls.builtins.code_actions.eslint_d,
    null_ls.builtins.formatting.prettier,     -- for Prettier
  },
})
