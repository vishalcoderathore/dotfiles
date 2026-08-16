-- C#/.NET and Blazor profile built on easy-dotnet.nvim.
--
-- LazyVim's lang.dotnet extra is deliberately NOT enabled: it provisions the
-- overlapping OmniSharp and neotest-vstest stack. EasyDotnet supplies the
-- Roslyn LSP, the test runner and its own bundled netcoredbg instead.

return {
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
      "folke/snacks.nvim",
    },
    config = function()
      require("easy-dotnet").setup()
    end,
  },

  -- Belt-and-braces: dap.core already declares nvim-nio, restated so the
  -- dependency is explicit at this layer too.
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "nvim-neotest/nvim-nio" },
  },

  -- html-lsp supplies vscode-html-language-server for EasyDotnet's Razor/Blazor
  -- bridge. Mason links it into its own bin dir, which is prepended to Neovim's
  -- PATH, so EasyDotnet's auto-detection finds it without a global npm install.
  -- No `html` server is enabled for ordinary .html buffers.
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "html-lsp" } },
  },

  -- C# parser in, F# and JSON5 out. This file is imported after python.lua
  -- alphabetically, but both filters are independent so order does not matter.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "c_sharp") then
        table.insert(opts.ensure_installed, "c_sharp")
      end
      opts.ensure_installed = vim.tbl_filter(function(parser)
        return parser ~= "fsharp" and parser ~= "json5"
      end, opts.ensure_installed)
      return opts
    end,
  },
}
