-- Theme, statusline, git signs and the shared Treesitter parser additions.

return {
  -- Colorscheme -------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      term_colors = true,
      styles = {
        comments = { "italic" },
        keywords = {},
        functions = {},
        strings = {},
        variables = {},
      },
      lsp_styles = {
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
    },
  },

  -- Make Catppuccin Mocha the active colorscheme.
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },

  -- Statusline --------------------------------------------------------------
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.theme = "catppuccin-mocha"
      opts.options.globalstatus = true
      opts.options.component_separators = { left = "", right = "" }
      opts.options.section_separators = { left = "", right = "" }

      opts.sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = {
          { "filename", path = 1 },
          {
            function()
              return vim.b.gitsigns_blame_line or ""
            end,
            cond = function()
              return vim.b.gitsigns_blame_line ~= nil
            end,
          },
        },
        lualine_x = {
          "encoding",
          {
            "fileformat",
            symbols = {
              unix = "LF",
              dos = "CRLF",
              mac = "CR",
            },
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      }

      return opts
    end,
  },

  -- Current-line git blame, consumed by the lualine component above ----------
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = false,
        delay = 100,
        ignore_whitespace = true,
      },
      current_line_blame_formatter = "<author> • <author_time:%Y-%m-%d %H:%M>",
    },
  },

  -- Treesitter --------------------------------------------------------------
  -- LazyVim already requests javascript, typescript, tsx, lua, html and xml.
  -- `opts_extend` means this list is appended to theirs, not replacing it.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "css" },
    },
  },
}
