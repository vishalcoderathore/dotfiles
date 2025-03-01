return {
  "navarasu/onedark.nvim", -- Make sure this line exists in your Lazy.nvim plugin list
  name = "onedark",
  config = function()
    require("onedark").setup {
      style = "cool",
      transparent = false,
      term_colors = true,
      ending_tildes = false,
      cmp_itemkind_reverse = false,

      toggle_style_key = nil,
      toggle_style_list = {"dark", "darker", "cool", "deep", "warm", "warmer", "light"},

      code_style = {
        comments = "italic",
        keywords = "none",
        functions = "none",
        strings = "none",
        variables = "none",
      },

      lualine = {
        transparent = false,
      },

      colors = {},
      highlights = {},

      diagnostics = {
        darker = true,
        undercurl = true,
        background = true,
      },
    }

    -- Load the colorscheme
    require("onedark").load()
  end,
}

