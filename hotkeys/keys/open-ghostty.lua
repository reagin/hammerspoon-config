local APP_BUNDLE_ID = "com.mitchellh.ghostty"

return {
    id = "open-ghostty",
    mods = { "cmd", "ctrl" },
    key = "t",
    action = function()
        local appPath = hs.application.pathForBundleID(APP_BUNDLE_ID)
        if not appPath or appPath == "" then
            local msg = string.format("open-ghostty: app not found (%s)", APP_BUNDLE_ID)
            hs.printf("%s", msg)
            return
        end

        hs.application.launchOrFocusByBundleID(APP_BUNDLE_ID)
    end
}
