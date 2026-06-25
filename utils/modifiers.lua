local M = {}

local triggerMaskNames = {
    command = { "command", "deviceLeftCommand", "deviceRightCommand" },
    leftCommand = { "command", "deviceLeftCommand" },
    rightCommand = { "deviceRightCommand" },
    control = { "control", "deviceLeftControl", "deviceRightControl" },
    leftControl = { "control", "deviceLeftControl" },
    rightControl = { "deviceRightControl" },
    option = { "alternate", "deviceLeftAlternate", "deviceRightAlternate" },
    leftOption = { "alternate", "deviceLeftAlternate" },
    rightOption = { "deviceRightAlternate" },
    shift = { "shift", "deviceLeftShift", "deviceRightShift" },
    leftShift = { "shift", "deviceLeftShift" },
    rightShift = { "deviceRightShift" },
    fn = { "secondaryFn" }
}

local eventtapTargetApiNames = {
    command = "cmd",
    control = "ctrl",
    option = "alt",
    shift = "shift",
    fn = "fn"
}

local triggerTargetApiNames = {
    command = "cmd",
    leftCommand = "cmd",
    rightCommand = "cmd",
    control = "ctrl",
    leftControl = "ctrl",
    rightControl = "ctrl",
    option = "alt",
    leftOption = "alt",
    rightOption = "alt",
    shift = "shift",
    leftShift = "shift",
    rightShift = "shift",
    fn = "fn"
}

local targetEventKeyNames = {
    cmd = "cmd",
    ctrl = "ctrl",
    alt = "alt",
    shift = "shift",
    fn = "fn"
}

local hotkeyApiNames = {
    command = "cmd",
    control = "ctrl",
    option = "alt",
    shift = "shift"
}

local function normalizeMods(mods, allowedNames, label)
    if type(mods) ~= "table" then
        error(label .. " must be a table")
    end

    local normalized = {}
    for _, mod in ipairs(mods) do
        local normalizedMod = allowedNames[mod]
        if not normalizedMod then
            error(label .. " contains unsupported modifier '" .. tostring(mod) .. "'")
        end
        if type(normalizedMod) == "table" then
            normalizedMod = mod
        end
        table.insert(normalized, normalizedMod)
    end
    return normalized
end

local function modifierMasks(mod)
    local masks = hs.eventtap.event.rawFlagMasks
    local maskNames = triggerMaskNames[mod]
    local modMasks = {}
    for _, maskName in ipairs(maskNames or {}) do
        local mask = masks[maskName]
        if mask then
            table.insert(modMasks, mask)
        end
    end
    return modMasks
end

function M.normalizeTriggerMods(mods, label)
    return normalizeMods(mods, triggerMaskNames, label)
end

function M.normalizeEventtapTargetMods(mods, label)
    return normalizeMods(mods, eventtapTargetApiNames, label)
end

function M.normalizeHotkeyMods(mods, label)
    return normalizeMods(mods, hotkeyApiNames, label)
end

function M.isTriggerModDown(rawFlags, mod)
    for _, mask in ipairs(modifierMasks(mod)) do
        if (rawFlags & mask) == mask then
            return true
        end
    end
    return false
end

function M.allTriggerModsDown(rawFlags, mods)
    if not mods then
        return false
    end
    for _, mod in ipairs(mods) do
        if not M.isTriggerModDown(rawFlags, mod) then
            return false
        end
    end
    return true
end

function M.anyTriggerModDown(rawFlags, mods)
    for _, mod in ipairs(mods or {}) do
        if M.isTriggerModDown(rawFlags, mod) then
            return true
        end
    end
    return false
end

function M.targetModState(targetMods, triggerMods, useTriggerPhysicalMods)
    local physicalTargetMods = {}
    local physicalTargetModSet = {}
    local syntheticTargetMods = {}
    local seenTargetMods = {}

    if useTriggerPhysicalMods then
        for _, mod in ipairs(triggerMods or {}) do
            local targetMod = triggerTargetApiNames[mod]
            if targetMod then
                physicalTargetModSet[targetMod] = true
            end
        end
    end

    for _, targetMod in ipairs(targetMods or {}) do
        if targetEventKeyNames[targetMod] and not seenTargetMods[targetMod] then
            seenTargetMods[targetMod] = true
            if physicalTargetModSet[targetMod] then
                table.insert(physicalTargetMods, targetMod)
            else
                table.insert(syntheticTargetMods, targetMod)
            end
        end
    end

    return {
        physical = physicalTargetMods,
        synthetic = syntheticTargetMods
    }
end

return M
