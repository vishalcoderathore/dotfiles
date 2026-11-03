-- GraphQL support is deliberately parser-only: highlighting here, formatting from
-- the prettier extra. graphql-language-service-cli stays out because its npm
-- dependency tree carried high-severity advisories when this was reviewed, and
-- it needs a Node `graphql` package that a Go project doesn't have.
--
-- Install the parser by hand (see lua/lockdown.lua): `:TSInstall graphql`.

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "graphql" },
    },
  },
}
