-- 聚合 config/apps/*.lua，生成供 eventtap 使用的已解析重映射列表。
-- 新应用：新增 config/apps/<name>.lua，并在下表追加 require。
local apps = {require("config.apps.pieoneer")}

-- keyName：键名字符串，如 "tab"
local function resolveKeyCode(keyName)
    local code = hs.keycodes.map[keyName]
    if not code then
        error("config.remaps: unknown key name '" .. tostring(keyName) .. "'")
    end
    return code
end

local function appendResolved(resolved, app, remap)
    local trigger = remap.trigger
    if not trigger or not trigger.key then
        error("config.remaps: remap missing trigger.key (app=" .. tostring(app.id) .. ")")
    end

    local target = remap.target or app.target
    if not target or not target.mods or not target.key then
        error("config.remaps: remap missing target (app=" .. tostring(app.id) .. ", id=" .. tostring(remap.id) .. ")")
    end

    table.insert(resolved, {
        id = remap.id or (tostring(app.id) .. "_remap"),
        description = remap.description,
        appId = app.id,
        appDisplayName = app.displayName or app.id,
        keyCode = resolveKeyCode(trigger.key),
        modifierPolicy = remap.modifierPolicy or "cmdOnly",
        targetMods = target.mods,
        targetKey = target.key
    })
end

local resolved = {}

for _, app in ipairs(apps) do
    for _, remap in ipairs(app.remaps or {}) do
        appendResolved(resolved, app, remap)
    end
end

return resolved
