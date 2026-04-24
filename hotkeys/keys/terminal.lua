return {
    id = "open_terminal",
    mods = { "cmd", "ctrl" },
    key = "t",
    action = function()
        hs.application.launchOrFocus("Terminal")
    end
}
