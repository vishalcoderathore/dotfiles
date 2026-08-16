-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- TypeScript language server. `vtsls` is currently LazyVim's default; set
-- explicitly so a future upstream default change does not silently switch it.
vim.g.lazyvim_ts_lsp = "vtsls"

-- Let the ESLint language server format on save.
vim.g.lazyvim_eslint_auto_format = true

-- Allow Prettier to format even in projects that ship no Prettier config.
vim.g.lazyvim_prettier_needs_config = false

-- NOTE: vim.g.lazyvim_python_lsp ("pyright") and vim.g.lazyvim_python_ruff
-- ("ruff") are deliberately not set here -- they already match the current
-- upstream defaults of the lang.python extra.

-- Line numbers: absolute plus relative.
vim.opt.number = true
vim.opt.relativenumber = true

-- Two-space soft indentation, spaces instead of tabs.
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

vim.opt.termguicolors = true
vim.opt.wrap = false
