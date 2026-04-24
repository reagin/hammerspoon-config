-- 按 M.cfg.remaps 拦截 keyDown 并 keyStroke 转发。
local M = {}

local tap
local loadLogLines = {}

local function matchMods(flags, policy)
    if policy == "cmdOnly" then
        return flags.cmd and not flags.alt and not flags.ctrl and not flags.shift and not flags.fn
    end
    return false
end

local function buildRemapLoadLines(remapRules)
    local lines = {}
    if not remapRules or #remapRules == 0 then
        return lines
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
        table.insert(lines, string.format("-- %s (%s)", appId, group.displayName))
        for _, rule in ipairs(group.rules) do
            local description = rule.description or ""
            table.insert(lines, string.format("    -- %s (%s)", rule.id, description))
        end
    end
    return lines
end

function M.start()
    local remaps = (M.cfg and M.cfg.remaps) or require("eventtap.remaps")
    if not remaps or #remaps == 0 then
        if tap then
            tap:stop()
            tap = nil
        end
        loadLogLines = { "-- no remaps configured, skip watcher" }
        return
    end

    if tap then
        tap:stop()
        tap = nil
    end

    loadLogLines = buildRemapLoadLines(remaps)

    tap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local flags = event:getFlags()
        local keyCode = event:getKeyCode()
        for _, rule in ipairs(remaps) do
            if keyCode == rule.keyCode and matchMods(flags, rule.modifierPolicy) then
                hs.eventtap.keyStroke(rule.targetMods, rule.targetKey, 0)
                return true
            end
        end
        return false
    end)

    tap:start()
end

function M.stop()
    if tap then
        tap:stop()
        tap = nil
    end
end

function M.getLoadLogLines()
    return loadLogLines
end

return M
