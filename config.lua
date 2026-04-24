-- 总配置：bootstrap 为启动项；其余段合并进 modules/*.lua 的 M.cfg。
return {
    bootstrap = {
        modules = {"eventtap", "hotkeys"},
        logTag = "config",
        logLevel = "info"
    },
    eventtap = {
        enabled = true,
        remaps = require("config.remaps")
    },
    hotkeys = {
        enabled = true
    }
}
