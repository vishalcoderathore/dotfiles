-- nvim-lint decides between linting the package and the lone file only once, from
-- Neovim's starting directory. Decide per buffer from the file's own go.mod, so a
-- repo opened at its root still lints whole packages.

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      -- No InsertLeave: golangci-lint only reads the saved file, so linting unsaved
      -- edits would misplace its diagnostics. This applies to every linter.
      events = { "BufWritePost", "BufReadPost" },
      linters = {
        -- nvim-lint calls a linter given as a function on every run.
        golangcilint = function()
          local linter = vim.deepcopy(require("lint.linters.golangcilint"))
          local file = vim.api.nvim_buf_get_name(0)
          local module_root = vim.fs.root(file, "go.mod")
          -- The target is always the last argument: the package, or a file with no module.
          -- nvim-lint leaves args empty when golangci-lint or go can't run; keep its ENOENT.
          if linter.args then
            linter.args[#linter.args] = vim.fn.fnamemodify(file, module_root and ":h" or ":p")
          end
          linter.cwd = module_root or vim.fs.dirname(file)
          return linter
        end,
      },
    },
  },

  -- Delve builds from Neovim's starting directory, so the stock configurations
  -- fail with "cannot find main module" when the module is in a subfolder.
  {
    "leoluz/nvim-dap-go",
    optional = true,
    -- Stay lazy: defaults.lazy = false would otherwise load the DAP stack at startup.
    lazy = true,
    opts = {
      dap_configurations = {
        {
          type = "go",
          name = "Debug Package (module root)",
          request = "launch",
          program = "${fileDirname}",
          -- Stock entries set this too; without it, program output skips the debug console.
          outputMode = "remote",
          dlvCwd = function()
            return vim.fs.root(0, "go.mod")
          end,
        },
      },
    },
  },
}
