-- 入口：读 config、合并各模块段、启动；提供 hs_reload()。
hs.loadSpoon("EmmyLua")

local cfg = require("config")
local log = require("utils.log")()

local loaded = {}
local moduleNames = (cfg.bootstrap or {}).modules or { "eventtap", "hotkeys" }

local function merge(mod, name)
    mod.cfg = mod.cfg or {}
    local section = cfg[name]
    if section then
        for optionKey, optionValue in pairs(section) do
            mod.cfg[optionKey] = optionValue
        end
    end
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
    if mod.cfg.enabled ~= false and mod.start then
        mod.start()
    end
end

---@diagnostic disable-next-line: lowercase-global
function hs_reload()
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

-- 打印 remaps 树
logRemapLoadTree(cfg.eventtap and cfg.eventtap.remaps)
