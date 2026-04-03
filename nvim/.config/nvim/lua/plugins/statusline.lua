return {
  "nvim-lualine/lualine.nvim",
  version = false,  -- use latest commit; tagged releases have a vim.tbl_flatten deprecation bug on Neovim 0.11+
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      options = {
        theme = "catppuccin",       -- matches your Catppuccin Mocha colorscheme
        globalstatus = true,        -- single statusline across all splits
        component_separators = { left = "", right = "" },
        section_separators   = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },  -- path=1 shows relative path
        lualine_x = { "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    })
  end,
}
