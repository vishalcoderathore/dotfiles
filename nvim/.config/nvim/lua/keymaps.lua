-- Set leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic key mappings using the older API:
local opts = { noremap = true, silent = true }
vim.api.nvim_set_keymap("n", "<leader>w", ":w<CR>", opts)  -- Save file
vim.api.nvim_set_keymap("n", "<leader>q", ":q<CR>", opts)  -- Quit Neovim

-- Add a keymap for toggling NvimTree (File Explorer)
vim.api.nvim_set_keymap("n", "<M-1>", ":NvimTreeToggle<CR>", opts)  -- Open/Close File Explorer

