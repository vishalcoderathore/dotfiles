-- ~/.config/nvim/init.lua

-- Set leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load modules
require("keymaps")    -- custom key mappings
require("options")    -- core editor options
require("plugins.lazy")  -- plugin manager setup (e.g., lazy.nvim)
require("plugins.treesitter")  -- Treesitter configuration
require("lsp")        -- LSP, ESLint, Prettier integration
-- require("misc")       -- any miscellaneous settings

-- You can add more modules as you become comfortable
