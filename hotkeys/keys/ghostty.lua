return {
    id = "open_ghostty",
    mods = { "cmd", "ctrl" },
    key = "t",
    action = function()
        hs.application.launchOrFocus("Ghostty")
    end
}
