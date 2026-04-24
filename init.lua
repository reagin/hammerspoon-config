-- 入口：装配模块配置、启动模块；提供 hs_reload()。
hs.loadSpoon("EmmyLua")

-- 初始化日志
local log = require("utils.log")()

-- 加载模块配置
local loaded = {}
local config = {
    eventtap = {
        enabled = true,
        remaps = require("eventtap.remaps")
    },
    hotkeys = {
        enabled = true,
        bindings = require("hotkeys.bindings")
    }
}


local function listModuleNames()
    local names = {}
    for name, _ in pairs(config) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

local function merge(mod, name)
    mod.cfg = mod.cfg or {}
    local section = config[name]
    if section then
        for optionKey, optionValue in pairs(section) do
            mod.cfg[optionKey] = optionValue
        end
    end
end

local function printModuleLoadLogs()
    local logOrder = { "hotkeys", "eventtap" }
    for _, moduleName in ipairs(logOrder) do
        local mod = loaded[moduleName]
        if mod and mod.getLoadLogLines then
            local lines = mod.getLoadLogLines() or {}
            local moduleLog = require("utils.log")(moduleName)
            for _, line in ipairs(lines) do
                moduleLog.i(line)
            end
        end
    end
end

for _, name in ipairs(listModuleNames()) do
    local mod = require("modules." .. name)
    merge(mod, name)
    loaded[name] = mod
end

for _, name in ipairs(listModuleNames()) do
    local mod = loaded[name]
    if mod.cfg.enabled ~= false and mod.start then
        mod.start()
    end
end

-- 打印模块加载日志
printModuleLoadLogs()

---@diagnostic disable-next-line: lowercase-global
function hs_reload()
    local moduleNames = listModuleNames()
    log.i("reloading | " .. table.concat(moduleNames, ", "))
    for index = #moduleNames, 1, -1 do
        local moduleName = moduleNames[index]
        local mod = loaded[moduleName]
        if mod and mod.stop then
            mod.stop()
        end
    end
    hs.reload()
end
