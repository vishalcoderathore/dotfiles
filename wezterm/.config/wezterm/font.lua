local wezterm = require 'wezterm'

return function(config)
    config.font = wezterm.font_with_fallback {
        { family = 'JetBrainsMono Nerd Font', harfbuzz_features = { 'calt', 'liga' } },
    }
    config.font_size = 10.5
    config.line_height = 1.1
    config.adjust_window_size_when_changing_font_size = false
end
