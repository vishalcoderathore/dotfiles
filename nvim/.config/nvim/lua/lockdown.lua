-- Nothing is installed, downloaded or updated behind my back. Every install is
-- a command I run myself: :Lazy install/update, :MasonInstall, :TSInstall,
-- `dotnet tool install`.
--
-- Imported last from config/lazy.lua so these overrides win over LazyVim, its
-- extras and every file in lua/plugins/. The lazy.nvim side of the lockdown
-- (no startup install of missing plugins, no background update checker) lives
-- in config/lazy.lua itself.
--
-- Already installed packages, servers and parsers are untouched and keep
-- working.

return {
  -- LazyVim's mason.nvim config installs its `ensure_installed` list (stylua,
  -- shfmt, plus whatever the extras append) and refreshes the package
  -- registry from the network every time Mason loads. Keep only the setup and
  -- the hook that starts a server right after I install it by hand.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
      return opts
    end,
    config = function(_, opts)
      require("mason").setup(opts)
      require("mason-registry"):on("package:install:success", function()
        vim.defer_fn(function()
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
    end,
  },

  -- LazyVim fills mason-lspconfig's `ensure_installed` with every server in
  -- nvim-lspconfig's `opts.servers` and passes it straight to
  -- `require("mason-lspconfig").setup()`, where plugin opts cannot reach it,
  -- so `setup` is wrapped to empty the list. mason-lspconfig v2 has no
  -- `automatic_installation` option; `automatic_enable` only starts servers
  -- that are already installed, so it stays on.
  {
    "mason-org/mason-lspconfig.nvim",
    config = function()
      local mason_lspconfig = require("mason-lspconfig")
      local setup = mason_lspconfig.setup
      mason_lspconfig.setup = function(opts)
        opts = opts or {}
        opts.ensure_installed = {}
        opts.automatic_installation = false
        return setup(opts)
      end
    end,
  },

  -- The dap.core extra turns on automatic debug adapter installs.
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = {}
      opts.automatic_installation = false
      return opts
    end,
  },

  -- LazyVim downloads and compiles every missing parser in `ensure_installed`
  -- at startup (and installs tree-sitter-cli through Mason to do it). The
  -- lists in lua/plugins/ still record which parsers I want; install them
  -- with :TSInstall.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = {}
      return opts
    end,
  },

  -- easy-dotnet runs `dotnet tool install -g EasyDotnet` on setup unless its
  -- marker file exists, and has no option to turn that off. Writing the
  -- marker first skips the check; install the server yourself with
  -- `dotnet tool install -g EasyDotnet` (:checkhealth easy-dotnet shows it).
  {
    "GustavEikaas/easy-dotnet.nvim",
    optional = true,
    init = function()
      local dir = vim.fs.joinpath(vim.fn.stdpath("data"), "easy-dotnet")
      local marker = vim.fs.joinpath(dir, "easy_dotnet_installed")
      if vim.fn.filereadable(marker) == 0 then
        vim.fn.mkdir(dir, "p")
        vim.fn.writefile({ "installed" }, marker)
      end
    end,
  },
}
