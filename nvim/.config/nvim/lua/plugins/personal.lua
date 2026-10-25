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
      -- Catppuccin draws split separators in crust, nearly black on base.
      -- surface2 makes the edges between panes (dap-ui boxes included) visible.
      custom_highlights = function(colors)
        return { WinSeparator = { fg = colors.surface2 } }
      end,
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
      -- "auto" loads the theme named after the active colorscheme when one
      -- exists (catppuccin-mocha today) and generates one otherwise.
      opts.options.theme = "auto"
      opts.options.globalstatus = true
      -- Rounded powerline glyphs (Nerd Font). The mode and location
      -- components add the outer caps, so both ends of the bar are rounded.
      opts.options.component_separators = { left = "", right = "" }
      opts.options.section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" }

      opts.sections = {
        lualine_a = { { "mode", separator = { left = "\u{e0b6}" }, right_padding = 2 } },
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
          -- Lines/chars selected in visual mode; empty otherwise.
          "selectioncount",
          -- [current/total] matches while a search is highlighted.
          "searchcount",
          -- Names of the LSP servers attached to this buffer.
          {
            function()
              local names = vim.tbl_map(function(client)
                return client.name
              end, vim.lsp.get_clients({ bufnr = 0 }))
              return "\u{f085} " .. table.concat(names, ", ")
            end,
            cond = function()
              return #vim.lsp.get_clients({ bufnr = 0 }) > 0
            end,
          },
          -- Active Python environment, as set by an activated venv, conda,
          -- or venv-selector (from LazyVim's python extra). A venv named
          -- ".venv" is shown by its project folder instead.
          {
            function()
              local path = vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX
              local name = vim.fn.fnamemodify(path, ":t")
              if name == ".venv" or name == "venv" then
                name = vim.fn.fnamemodify(path, ":h:t")
              end
              return "\u{e73c} " .. name
            end,
            cond = function()
              return vim.bo.filetype == "python" and (vim.env.VIRTUAL_ENV or vim.env.CONDA_PREFIX) ~= nil
            end,
          },
          -- Debugger state ("Running", "Stopped at breakpoint", ...) during a
          -- DAP session. The package.loaded check keeps this from loading
          -- nvim-dap just to draw the statusline.
          {
            function()
              return "\u{f188} " .. require("dap").status()
            end,
            cond = function()
              return package.loaded["dap"] ~= nil and require("dap").status() ~= ""
            end,
          },
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
        lualine_z = { { "location", separator = { right = "\u{e0b4}" }, left_padding = 2 } },
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
