-- 按 M.cfg.remaps 拦截 keyDown，并将 trigger 按压状态映射到 target。
local M = {}
local modifiers = require("utils.modifiers")

local eventTypes = hs.eventtap.event.types
local eventProperties = hs.eventtap.event.properties

local DISPATCH_IMMEDIATE_TRIGGER = "immediateTrigger"
local DISPATCH_AFTER_RELEASE_TRIGGER = "afterReleaseTrigger"

local tap
local activeTarget
local loadLogLines = {}
local postQueueGeneration = 0
local afterReleaseTriggerRule
local capturedTriggerKeyUpRule
local syntheticEventUserData = math.random(1, 0x7fffffff)
local eventSequenceStepSeconds = hs.timer.seconds("10ms")

local function copyList(items)
    local copied = {}
    for _, item in ipairs(items or {}) do
        table.insert(copied, item)
    end
    return copied
end

local function removeFirst(items, value)
    for index, item in ipairs(items) do
        if item == value then
            table.remove(items, index)
            return
        end
    end
end

local function flagTable(mods)
    local flags = {}
    for _, mod in ipairs(mods or {}) do
        flags[mod] = true
    end
    return flags
end

local function markSyntheticEvent(event)
    return event:setProperty(eventProperties.eventSourceUserData, syntheticEventUserData)
end

local function isSyntheticEvent(event)
    return event:getProperty(eventProperties.eventSourceUserData) == syntheticEventUserData
end

local function newTargetModifierEvent(mod, currentMods, isDown)
    local keyCode = hs.keycodes.map[mod]
    if not keyCode then
        error("eventtap: unknown target modifier key '" .. tostring(mod) .. "'")
    end

    return markSyntheticEvent(hs.eventtap.event.newKeyEvent(keyCode, isDown):setFlags(flagTable(currentMods)))
end

local function newTargetKeyEvent(rule, isDown)
    return markSyntheticEvent(hs.eventtap.event.newKeyEvent(rule.targetKey, isDown):setFlags(flagTable(rule.targetMods)))
end

local function appendTargetModifierEvents(events, rule, isDown, useTriggerPhysicalMods)
    local modState = modifiers.targetModState(rule.targetMods, rule.triggerMods, useTriggerPhysicalMods)
    local currentMods = copyList(modState.physical)

    if isDown then
        for _, targetMod in ipairs(modState.synthetic) do
            table.insert(currentMods, targetMod)
            table.insert(events, newTargetModifierEvent(targetMod, currentMods, true))
        end
        return
    end

    for _, targetMod in ipairs(modState.synthetic) do
        table.insert(currentMods, targetMod)
    end

    for index = #modState.synthetic, 1, -1 do
        local targetMod = modState.synthetic[index]
        removeFirst(currentMods, targetMod)
        table.insert(events, newTargetModifierEvent(targetMod, currentMods, false))
    end
end

local function buildTargetDownEvents(rule, useTriggerPhysicalMods)
    local events = {}
    appendTargetModifierEvents(events, rule, true, useTriggerPhysicalMods)
    table.insert(events, newTargetKeyEvent(rule, true))
    return events
end

local function buildTargetUpEvents(rule, useTriggerPhysicalMods)
    local events = {}
    table.insert(events, newTargetKeyEvent(rule, false))
    appendTargetModifierEvents(events, rule, false, useTriggerPhysicalMods)
    return events
end

local function buildTargetTapEvents(rule, useTriggerPhysicalMods)
    local events = buildTargetDownEvents(rule, useTriggerPhysicalMods)
    for _, event in ipairs(buildTargetUpEvents(rule, useTriggerPhysicalMods)) do
        table.insert(events, event)
    end
    return events
end

local function postEventsNow(events)
    for _, event in ipairs(events or {}) do
        event:post()
    end
end

local function eventPostDelay(index)
    return (index - 1) * eventSequenceStepSeconds
end

local function postEventsSequentially(events)
    if not events or #events == 0 then
        return
    end

    local generation = postQueueGeneration
    for index, event in ipairs(events) do
        hs.timer.doAfter(eventPostDelay(index), function()
            if generation ~= postQueueGeneration then
                return
            end

            event:post()
        end)
    end
end

local function cancelQueuedPosts()
    postQueueGeneration = postQueueGeneration + 1
end

local function refreshSyntheticMarker()
    local nextMarker = math.random(1, 0x7fffffff)
    if nextMarker == syntheticEventUserData then
        nextMarker = math.random(1, 0x7fffffff)
    end
    syntheticEventUserData = nextMarker
end

local function resetSyntheticEventState()
    cancelQueuedPosts()
    refreshSyntheticMarker()
end

local function activateTarget(rule)
    activeTarget = {
        rule = rule
    }
end

local function clearActiveTarget()
    activeTarget = nil
end

local function releaseActiveTarget(useTriggerPhysicalMods)
    if not activeTarget then
        return nil
    end

    local target = activeTarget
    clearActiveTarget()
    return buildTargetUpEvents(target.rule, useTriggerPhysicalMods)
end

local function shouldSuppressTriggerKeyUp(rule, eventType, keyCode)
    return rule and eventType == eventTypes.keyUp and keyCode == rule.keyCode
end

local function captureTriggerKeyUp(rule)
    capturedTriggerKeyUpRule = rule
end

local function consumeCapturedTriggerKeyUp(eventType, keyCode)
    if not shouldSuppressTriggerKeyUp(capturedTriggerKeyUpRule, eventType, keyCode) then
        return false
    end

    capturedTriggerKeyUpRule = nil
    return true
end

local function handleActiveTarget(eventType, rawFlags, keyCode)
    if not activeTarget then
        return nil
    end

    local rule = activeTarget.rule
    if eventType == eventTypes.keyDown and keyCode == rule.keyCode then
        return true
    end

    if eventType == eventTypes.keyUp and keyCode == rule.keyCode then
        local events = releaseActiveTarget(true)
        capturedTriggerKeyUpRule = nil
        return true, events
    end

    if eventType == eventTypes.flagsChanged
        and not modifiers.allTriggerModsDown(rawFlags, rule.triggerMods) then
        return false, releaseActiveTarget(false)
    end

    return nil
end

local function handlePendingAfterReleaseTrigger(eventType, rawFlags, keyCode)
    if shouldSuppressTriggerKeyUp(afterReleaseTriggerRule, eventType, keyCode) then
        consumeCapturedTriggerKeyUp(eventType, keyCode)
        return true
    end

    if afterReleaseTriggerRule and eventType == eventTypes.keyDown and keyCode == afterReleaseTriggerRule.keyCode then
        return true
    end

    if afterReleaseTriggerRule
        and eventType == eventTypes.flagsChanged
        and not modifiers.anyTriggerModDown(rawFlags, afterReleaseTriggerRule.triggerMods) then
        local rule = afterReleaseTriggerRule
        afterReleaseTriggerRule = nil
        return false, buildTargetTapEvents(rule, false)
    end

    return nil
end

local function findMatchingRule(remaps, rawFlags, keyCode)
    for _, rule in ipairs(remaps) do
        if keyCode == rule.keyCode and modifiers.allTriggerModsDown(rawFlags, rule.triggerMods) then
            return rule
        end
    end
    return nil
end

local function dispatchMatchedRule(rule)
    local dispatch = rule.dispatch or DISPATCH_IMMEDIATE_TRIGGER

    if dispatch == DISPATCH_AFTER_RELEASE_TRIGGER then
        afterReleaseTriggerRule = rule
        captureTriggerKeyUp(rule)
        return true
    end

    captureTriggerKeyUp(rule)
    activateTarget(rule)
    return true, buildTargetDownEvents(rule, true)
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

local function resetState()
    if activeTarget then
        postEventsNow(releaseActiveTarget(false))
    end
    capturedTriggerKeyUpRule = nil
    afterReleaseTriggerRule = nil
    activeTarget = nil
    resetSyntheticEventState()
end

local function stopTap()
    if tap then
        tap:stop()
        tap = nil
    end
    resetState()
end

local function handleEvent(remaps, event)
    local eventType = event:getType()
    local rawFlags = event:rawFlags()
    local keyCode = event:getKeyCode()

    local activeResult, activeEvents = handleActiveTarget(eventType, rawFlags, keyCode)
    if activeResult ~= nil then
        return activeResult, activeEvents
    end

    local afterReleaseTriggerResult, afterReleaseTriggerEvents = handlePendingAfterReleaseTrigger(eventType, rawFlags, keyCode)
    if afterReleaseTriggerResult ~= nil then
        return afterReleaseTriggerResult, afterReleaseTriggerEvents
    end

    if consumeCapturedTriggerKeyUp(eventType, keyCode) then
        return true
    end

    if eventType ~= eventTypes.keyDown then
        return false
    end

    local rule = findMatchingRule(remaps, rawFlags, keyCode)
    if not rule then
        return false
    end

    return dispatchMatchedRule(rule)
end

function M.start()
    local remaps = (M.cfg and M.cfg.remaps) or require("eventtap.remaps")
    if not remaps or #remaps == 0 then
        stopTap()
        loadLogLines = { "-- no remaps configured, skip watcher" }
        return
    end

    stopTap()
    loadLogLines = buildRemapLoadLines(remaps)

    tap = hs.eventtap.new({
        eventTypes.keyDown,
        eventTypes.keyUp,
        eventTypes.flagsChanged
    }, function(event)
        if isSyntheticEvent(event) then
            return false
        end

        local shouldDeleteEvent, events = handleEvent(remaps, event)
        postEventsSequentially(events)
        return shouldDeleteEvent
    end)

    tap:start()
end

function M.stop()
    stopTap()
end

function M.getLoadLogLines()
    return loadLogLines
end

return M
