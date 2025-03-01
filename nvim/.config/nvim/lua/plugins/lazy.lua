-- ~/.config/nvim/lua/plugins/lazy.lua

-- Bootstrap lazy.nvim if it isn’t already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set up plugins with lazy.nvim
require("lazy").setup({
  -- Treesitter for improved syntax
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  -- LSP support
  "neovim/nvim-lspconfig",

  -- null-ls for ESLint and Prettier integration
  {
    "jose-elias-alvarez/null-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- nvim-tree for file explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional for icons
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- Theme
  require("plugins.theme"),
})
