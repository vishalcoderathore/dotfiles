-- Python profile: LazyVim's lang.python extra with its default pyright + ruff
-- setup. The only change is dropping two parsers the extra pulls in that this
-- profile has no file types for.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Runs after the extra has appended its own parsers, so this filter is
      -- the final word on the list.
      opts.ensure_installed = vim.tbl_filter(function(parser)
        return parser ~= "ninja" and parser ~= "rst"
      end, opts.ensure_installed or {})
      return opts
    end,
  },
}
