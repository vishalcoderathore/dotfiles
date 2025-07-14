local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Load partials
require("font")(config)
require("appearance")(config)
require("keys")(config)

-- Works with Linux + compositor
--config.window_background_opacity = 1
--config.text_background_opacity = 1

-- Works with macOS only
--config.macos_window_background_blur = 20


return config
