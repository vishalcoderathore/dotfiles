-- Four-space soft indentation for C# buffers, overriding the two-space default.
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4
vim.opt_local.expandtab = true

-- No format-on-save for C#. Manual LSP formatting stays available.
vim.b.autoformat = false
