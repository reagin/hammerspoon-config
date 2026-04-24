-- 入口：读 config、合并各模块段、启动；提供 hs_reload()。

local cfg = require("config")
local boot = cfg.bootstrap or {}
local log = require("lib.log")()

local moduleNames = boot.modules or { "eventtap", "hotkeys" }
local state = {}
local loaded = {}

local function merge(mod, name)
    mod.name = name
    mod.cfg = mod.cfg or {}
    local section = cfg[name]
    if section then
        for optionKey, optionValue in pairs(section) do
            mod.cfg[optionKey] = optionValue
        end
    end
end

local function enabled(mod)
    local enabledFlag = mod.cfg.enabled
    if enabledFlag == nil then
        return true
    end
    return enabledFlag == true
end

for _, name in ipairs(moduleNames) do
    local mod = require("modules." .. name)
    merge(mod, name)
    loaded[name] = mod
end

for _, name in ipairs(moduleNames) do
    local mod = loaded[name]
    if enabled(mod) and mod.start then
        mod.start()
        state[name] = "started"
    else
        state[name] = "skipped"
    end
end

do
    local parts = {}
    for _, name in ipairs(moduleNames) do
        table.insert(parts, string.format("%s=%s", name, state[name]))
    end
    log.i("ready | " .. table.concat(parts, " | "))
end

function hs_reload()
    log.i("reload | " .. table.concat(moduleNames, ", "))
    for index = #moduleNames, 1, -1 do
        local moduleName = moduleNames[index]
        local mod = loaded[moduleName]
        if mod and mod.stop then
            mod.stop()
        end
    end
    hs.reload()
end
