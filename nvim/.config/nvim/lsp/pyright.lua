-- Auto-detect a project-local .venv and point pyright at its interpreter.
-- Read through vim.lsp.config, which requires Neovim 0.11+.
---@type vim.lsp.Config
return {
  before_init = function(_, config)
    local venv = (config.root_dir or vim.fn.getcwd()) .. "/.venv/bin/python"
    if vim.uv.fs_stat(venv) then
      config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
        python = { pythonPath = venv },
      })
    end
  end,
}
