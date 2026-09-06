-- SQL support is deliberately parser-only. Database work happens in JetBrains
-- DataGrip, so LazyVim's `lang.sql` extra is not enabled: six of its nine
-- plugins (vim-dadbod, dadbod-ui, dadbod-completion, edgy) exist to be a
-- database client, which would duplicate DataGrip badly.
--
-- What is still wanted is highlighting for SQL that lives in the repo --
-- Alembic migrations, seed files -- and for SQL embedded in SQLAlchemy
-- `text()` calls via after/queries/python/injections.scm, which needs this
-- parser to be present.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- This file sorts last in lua/plugins, so it runs after the parser
      -- filters in python.lua and dotnet.lua. Nothing downstream removes it.
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "sql") then
        table.insert(opts.ensure_installed, "sql")
      end
      return opts
    end,
  },
}
