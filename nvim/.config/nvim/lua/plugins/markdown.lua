-- Markdown profile: LazyVim's lang.markdown extra, minus Marksman,
-- markdownlint-cli2 and the browser preview plugin.
--
-- render-markdown.nvim, markdown-toc, Prettier formatting and the <leader>um
-- toggle all come from the extra and are kept.

return {
  -- No Marksman language server.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = { enabled = false },
      },
    },
  },

  -- Drop the Markdown linter mapping entirely.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      if opts.linters_by_ft then
        opts.linters_by_ft.markdown = nil
      end
      return opts
    end,
  },

  -- Drop markdownlint-cli2 from Conform's Markdown and MDX formatter lists,
  -- leaving prettier + markdown-toc.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      for _, ft in ipairs({ "markdown", "markdown.mdx" }) do
        if opts.formatters_by_ft and opts.formatters_by_ft[ft] then
          opts.formatters_by_ft[ft] = vim.tbl_filter(function(formatter)
            return formatter ~= "markdownlint-cli2"
          end, opts.formatters_by_ft[ft])
        end
      end
      return opts
    end,
  },

  -- markdown-preview.nvim ships a Socket.IO runtime dependency tree that
  -- carried known high/critical npm advisories when this profile was reviewed.
  -- Disabled so its npm installer never runs.
  {
    "iamcco/markdown-preview.nvim",
    enabled = false,
  },

  -- LazyVim's markdown extra sets `heading.icons = {}`. render-markdown uses
  -- the icon as the *replacement* for the '#' markers (position = 'overlay'),
  -- so with no icon it takes an early return, never creates the overlay mark,
  -- and the raw '## ' stays on screen while reading. Restoring the plugin's
  -- own default icons brings back the glyphs and the concealing together.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
    },
  },
}
