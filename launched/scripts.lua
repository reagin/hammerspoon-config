-- 聚合 launched/scripts/*.lua，系统启动后自动执行一次。
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

local function listScriptModules()
    local modules = {}
    local scriptDir = hs.configdir .. "/launched/scripts"
    local iterator, dirObject = hs.fs.dir(scriptDir)
    if not iterator then
        return modules
    end

    for entry in iterator, dirObject do
        if entry ~= "." and entry ~= ".." then
            local baseName = entry:match("^(.+)%.lua$")
            if baseName then
                if not isKebabLower(baseName) then
                    error("launched.scripts: invalid file name '" .. entry .. "'; expected lower-kebab-case")
                end
                table.insert(modules, {
                    baseName = baseName,
                    moduleName = "launched.scripts." .. baseName
                })
            end
        end
    end

    table.sort(modules, function(a, b)
        return a.moduleName < b.moduleName
    end)
    return modules
end

local scripts = {}

for _, moduleMeta in ipairs(listScriptModules()) do
    package.loaded[moduleMeta.moduleName] = nil
    local script = require(moduleMeta.moduleName)
    if not isKebabLower(script.id) then
        error("launched.scripts: invalid id '" .. tostring(script.id) .. "' in " .. moduleMeta.moduleName)
    end
    if script.id ~= moduleMeta.baseName then
        error("launched.scripts: id '" .. script.id .. "' must match file name '" .. moduleMeta.baseName .. "'")
    end
    if type(script.command) ~= "string" or script.command == "" then
        error("launched.scripts: script '" .. script.id .. "' must define a non-empty command string")
    end
    table.insert(scripts, script)
end

return scripts
