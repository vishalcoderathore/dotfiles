-- ~/.config/nvim/lua/plugins/treesitter.lua

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "javascript", "typescript", "tsx", "lua", "html", "css" },
  highlight = { enable = true },
}
