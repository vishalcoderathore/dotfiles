local wezterm = require 'wezterm'
local theme_dark = require 'theme_dark'
local theme_light = require 'theme_light'

return function(config)
    config.color_schemes = {
        ['Catppuccin Mocha'] = theme_dark,
        ['Catppuccin Latte'] = theme_light,
    }

    local function scheme_for_appearance(appearance)
        if appearance:find 'Dark' then
            return 'Catppuccin Mocha'
        else
            return 'Catppuccin Latte'
        end
    end

    --config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())
    config.color_scheme = 'Catppuccin Mocha'

    config.inactive_pane_hsb = {
        saturation = 1.0,
        brightness = 0.85,
    }

    config.window_padding = {
        left = 2,
        right = 2,
        top = 2,
        bottom = 2,
    }

    config.window_decorations = "RESIZE"
    config.use_fancy_tab_bar = true
    config.enable_tab_bar = true
    config.hide_tab_bar_if_only_one_tab = false
    config.tab_bar_at_bottom = false
    config.enable_scroll_bar = true
    config.prefer_egl = true
    config.max_fps = 120

    -- Cursor
    config.default_cursor_style = "BlinkingBlock"
    config.cursor_blink_rate = 500
    config.cursor_blink_ease_in = "Constant"
    config.cursor_blink_ease_out = "Constant"

    -- Default size
    config.window_close_confirmation = "NeverPrompt"

    -- Make Wezterm fullscreen
    wezterm.on("gui-startup", function(cmd)
        local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
        window:gui_window():maximize()
    end)
end
