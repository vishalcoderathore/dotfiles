-- Noice UI tweaks layered on top of LazyVim's defaults.

return {
  {
    "folke/noice.nvim",
    opts = function(_, opts)
      -- LazyVim's spec already provides `presets`; the guard keeps this file
      -- working if that ever stops being true.
      opts.presets = opts.presets or {}

      -- Rounded border around LSP hover docs (`K`) and signature help
      -- (`gK`, and `<C-k>` in insert mode) -- both render through Noice's
      -- `hover` view, so one preset covers them. Cosmetic only.
      opts.presets.lsp_doc_border = true

      return opts
    end,
  },
}
