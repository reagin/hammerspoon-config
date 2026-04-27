-- 聚合 hotkeys/keys/*.lua，新增或删除文件即可调整快捷键。

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

local function listKeyModules()
    local modules = {}
    local keyDir = hs.configdir .. "/hotkeys/keys"
    local iterator, dirObject = hs.fs.dir(keyDir)
    if not iterator then
        return modules
    end

    for entry in iterator, dirObject do
        if entry ~= "." and entry ~= ".." then
            local baseName = entry:match("^(.+)%.lua$")
            if baseName then
                if not isKebabLower(baseName) then
                    error("hotkeys.bindings: invalid file name '" .. entry .. "'; expected lower-kebab-case")
                end
                table.insert(modules, {
                    baseName = baseName,
                    moduleName = "hotkeys.keys." .. baseName
                })
            end
        end
    end

    table.sort(modules, function(a, b)
        return a.moduleName < b.moduleName
    end)
    return modules
end

local bindings = {}

for _, moduleMeta in ipairs(listKeyModules()) do
    local binding = require(moduleMeta.moduleName)
    if not isKebabLower(binding.id) then
        error("hotkeys.bindings: invalid id '" .. tostring(binding.id) .. "' in " .. moduleMeta.moduleName)
    end
    if binding.id ~= moduleMeta.baseName then
        error("hotkeys.bindings: id '" .. binding.id .. "' must match file name '" .. moduleMeta.baseName .. "'")
    end
    table.insert(bindings, binding)
end

return bindings
