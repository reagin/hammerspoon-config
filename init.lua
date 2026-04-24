-- 入口：读 config、合并各模块段、启动；提供 hs_reload()。
local cfg = require("config")
local log = require("utils.log")()
local boot = cfg.bootstrap or {}

local state = {}
local loaded = {}
local moduleNames = boot.modules or {"eventtap", "hotkeys"}

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

local function logRemapLoadTree(remapRules)
    if not remapRules or #remapRules == 0 then
        return
    end
    local groups = {}
    local appOrder = {}
    for _, rule in ipairs(remapRules) do
        local appId = rule.appId
        if not groups[appId] then
            groups[appId] = {
                displayName = rule.appDisplayName or appId,
                rules = {}
            }
            table.insert(appOrder, appId)
        end
        table.insert(groups[appId].rules, rule)
    end
    for _, appId in ipairs(appOrder) do
        local group = groups[appId]
        log.i(string.format("-- %s (%s)", appId, group.displayName))
        for _, rule in ipairs(group.rules) do
            local description = rule.description or ""
            log.i(string.format("    -- %s (%s)", rule.id, description))
        end
    end
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
    log.i("initialization complete")
    for _, name in ipairs(moduleNames) do
        log.i(string.format("%s: %s", name, state[name]))
    end
    logRemapLoadTree(cfg.eventtap and cfg.eventtap.remaps)
end

function hs_reload()
    log.i("reloading...")
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
