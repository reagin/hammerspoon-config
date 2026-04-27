-- 聚合 eventtap/apps/*.lua，生成供 eventtap 使用的已解析重映射列表。
-- 新应用：新增 eventtap/apps/<name>.lua；无需手动修改本文件。

local function isKebabLower(value)
    if type(value) ~= "string" then
        return false
    end
    if value == "" then
        return false
    end
    if value:match("^[a-z-]+$") == nil then
        return false
    end
    if value:sub(1, 1) == "-" or value:sub(-1) == "-" then
        return false
    end
    if value:find("%-%-", 1, false) then
        return false
    end
    return true
end

local function listAppModules()
    local modules = {}
    local appDir = hs.configdir .. "/eventtap/apps"
    local iterator, dirObject = hs.fs.dir(appDir)
    if not iterator then
        return modules
    end

    for entry in iterator, dirObject do
        if entry ~= "." and entry ~= ".." then
            local baseName = entry:match("^(.+)%.lua$")
            if baseName then
                if not isKebabLower(baseName) then
                    error("eventtap.remaps: invalid file name '" .. entry .. "'; expected lower-kebab-case")
                end
                table.insert(modules, {
                    baseName = baseName,
                    moduleName = "eventtap.apps." .. baseName
                })
            end
        end
    end

    table.sort(modules, function(a, b)
        return a.moduleName < b.moduleName
    end)
    return modules
end

local function loadApps()
    local apps = {}
    for _, moduleMeta in ipairs(listAppModules()) do
        local app = require(moduleMeta.moduleName)
        if not isKebabLower(app.id) then
            error("eventtap.remaps: invalid app id '" .. tostring(app.id) .. "' in " .. moduleMeta.moduleName)
        end
        if app.id ~= moduleMeta.baseName then
            error("eventtap.remaps: app id '" .. app.id .. "' must match file name '" .. moduleMeta.baseName .. "'")
        end
        table.insert(apps, app)
    end
    return apps
end

-- keyName：键名字符串，如 "tab"
local function resolveKeyCode(keyName)
    local code = hs.keycodes.map[keyName]
    if not code then
        error("eventtap.remaps: unknown key name '" .. tostring(keyName) .. "'")
    end
    return code
end

local function appendResolved(resolved, app, remap)
    local trigger = remap.trigger
    if not trigger or not trigger.key then
        error("eventtap.remaps: remap missing trigger.key (app=" .. tostring(app.id) .. ")")
    end

    local target = remap.target or app.target
    if not target or not target.mods or not target.key then
        error("eventtap.remaps: remap missing target (app=" .. tostring(app.id) .. ", id=" .. tostring(remap.id) .. ")")
    end

    local remapId = remap.id or (tostring(app.id) .. "-remap")
    if not isKebabLower(remapId) then
        error("eventtap.remaps: invalid remap id '" .. tostring(remapId) .. "' in app '" .. tostring(app.id) .. "'")
    end

    table.insert(resolved, {
        id = remapId,
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

for _, app in ipairs(loadApps()) do
    for _, remap in ipairs(app.remaps or {}) do
        appendResolved(resolved, app, remap)
    end
end

return resolved
