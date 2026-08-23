-- Floating filename badge marking which split currently has focus.
-- The badge is colored by the current mode, so it doubles as a mode indicator.

return {
  {
    "b0o/incline.nvim",
    event = "BufReadPre",
    config = function()
      local colors = require("catppuccin.palettes").get_palette("mocha")

      -- Keyed by the first character of vim.fn.mode(). The two control
      -- characters are visual-block (Ctrl-V) and select-block (Ctrl-S).
      local mode_colors = {
        n = colors.blue,
        i = colors.green,
        v = colors.mauve,
        V = colors.mauve,
        ["\22"] = colors.mauve,
        s = colors.mauve,
        S = colors.mauve,
        ["\19"] = colors.mauve,
        R = colors.red,
        c = colors.peach,
        t = colors.green,
      }

      -- The badge background is the float's Normal highlight, so repainting
      -- this single group recolors the whole rectangle, padding included.
      local function paint()
        local bg = mode_colors[vim.fn.mode():sub(1, 1)] or colors.blue
        vim.api.nvim_set_hl(0, "InclineNormal", { bg = bg, fg = colors.base })
      end

      vim.api.nvim_create_autocmd({ "ModeChanged", "ColorScheme" }, {
        group = vim.api.nvim_create_augroup("incline_mode_color", { clear = true }),
        callback = paint,
      })

      require("incline").setup({
        window = { margin = { vertical = 0, horizontal = 1 } },
        -- With a single file window there is nothing to disambiguate, so the
        -- badge only earns its place once the tabpage is actually split.
        hide = { only_win = true },
        render = function(props)
          -- Returning nil hides the badge, so every unfocused split shows
          -- nothing and the badge marks the active pane by its presence.
          if not props.focused then
            return nil
          end

          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          if vim.bo[props.buf].modified then
            filename = "[+] " .. filename
          end

          -- The icon inherits the badge foreground rather than its filetype
          -- color, which would collide with the mode background (a blue
          -- TypeScript glyph on a blue normal-mode badge is invisible).
          local icon = require("nvim-web-devicons").get_icon(filename)
          if icon then
            return { { icon }, { " " }, { filename } }
          end
          return { { filename } }
        end,
      })

      paint()
    end,
  },
}
