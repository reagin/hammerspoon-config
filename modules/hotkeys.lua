-- 预留：在此绑定 hs.hotkey，并从 M.cfg 读取选项。
local M = {}
local activeHotkeys = {}
local loadLogLines = {}

local function clearHotkeys()
    for _, hotkey in ipairs(activeHotkeys) do
        hotkey:delete()
    end
    activeHotkeys = {}
end

local function joinMods(mods)
    if not mods or #mods == 0 then
        return ""
    end
    return table.concat(mods, "+")
end

local function bindingLabel(binding)
    local id = binding.id or "unnamed_binding"
    local combo = joinMods(binding.mods)
    if combo == "" then
        return string.format("%s (%s)", id, tostring(binding.key))
    end
    return string.format("%s (%s+%s)", id, combo, tostring(binding.key))
end

function M.start()
    clearHotkeys()
    hs.hotkey.setLogLevel("error")

    local bindings = (M.cfg and M.cfg.bindings) or require("hotkeys.bindings")

    local boundCount = 0
    local labels = {}
    local failedLabels = {}
    for _, binding in ipairs(bindings) do
        if binding.mods and binding.key and binding.action then
            local ok, hotkey = pcall(hs.hotkey.bind, binding.hotkeyMods or binding.mods, binding.key, binding.action)
            if ok and hotkey then
                table.insert(activeHotkeys, hotkey)
                boundCount = boundCount + 1
                table.insert(labels, bindingLabel(binding))
            else
                local reason = ok and "hs.hotkey.bind returned nil" or tostring(hotkey)
                table.insert(failedLabels, string.format("%s: %s", bindingLabel(binding), reason))
            end
        end
    end

    loadLogLines = { string.format("-- hotkeys bound: %d", boundCount) }
    for _, label in ipairs(labels) do
        table.insert(loadLogLines, string.format("    -- %s", label))
    end
    if #failedLabels > 0 then
        table.insert(loadLogLines, string.format("-- hotkeys failed: %d", #failedLabels))
        for _, label in ipairs(failedLabels) do
            table.insert(loadLogLines, string.format("    -- %s", label))
        end
    end
end

function M.stop()
    clearHotkeys()
end

function M.getLoadLogLines()
    return loadLogLines
end

return M
