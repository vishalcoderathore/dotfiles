-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Bottom-right readiness bar for opened files. Set up here rather than in
-- config/autocmds.lua, which only loads on VeryLazy, after the first file's
-- FileType event has already fired.
require("util.readiness").setup()
