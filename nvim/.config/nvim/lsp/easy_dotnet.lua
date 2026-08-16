-- Roslyn overrides for the easy_dotnet LSP client.
-- Read through vim.lsp.config, which requires Neovim 0.11+.
---@type vim.lsp.Config
return {
  settings = {
    ["csharp|inlay_hints"] = {
      csharp_enable_inlay_hints_for_types = true,
      csharp_enable_inlay_hints_for_lambda_parameter_types = true,
      csharp_enable_inlay_hints_for_implicit_variable_types = true,
      csharp_enable_inlay_hints_for_implicit_object_creation = true,
    },
  },
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        -- Opt in to Neovim's file watcher instead of Roslyn's in-process one.
        -- Depends on the raised fs.inotify limits; see /etc/sysctl.d/.
        dynamicRegistration = true,
      },
    },
  },
}
