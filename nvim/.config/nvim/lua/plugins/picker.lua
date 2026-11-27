return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        -- always show the list for `gr`, including the usage under the cursor
        lsp_references = { auto_confirm = false, include_current = true },
      },
      layout = {
        cycle = true,
        -- wide terminal: side-by-side; narrow: stacked
        preset = function()
          return vim.o.columns >= 120 and "default" or "vertical"
        end,
      },
      layouts = {
        -- copy of the built-in "default" preset
        custom = {
          layout = {
            box = "horizontal",
            width = 0.8,
            min_width = 120,
            height = 0.8,
            {
              box = "vertical",
              border = true,
              title = "{title} {live} {flags}",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
            },
            { win = "preview", title = "{preview}", border = true, width = 0.5 },
          },
        },
      },
    },
  },
}
