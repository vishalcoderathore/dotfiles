local wezterm = require 'wezterm'

return function(config)
    config.keys = {
        -- Split top & bottom (horizontal layout)
        {
            key = 'H',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
        },
        -- Split side by side (vertical layout)
        {
            key = 'J',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
        },
        -- Cycle between panes
        {
            key = '>',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.ActivatePaneDirection 'Next',
        },
        {
            key = '<',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.ActivatePaneDirection 'Prev',
        },
        -- Cycle between tabs
        {
            key = 'RightArrow',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.ActivateTabRelative(1),
        },
        {
            key = 'LeftArrow',
            mods = 'CTRL|SHIFT',
            action = wezterm.action.ActivateTabRelative(-1),
        },
    }
end
