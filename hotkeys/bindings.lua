-- 聚合 hotkeys/keys/*.lua，新增或删除文件即可调整快捷键。

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
                table.insert(modules, "hotkeys.keys." .. baseName)
            end
        end
    end

    table.sort(modules)
    return modules
end

local bindings = {}

for _, moduleName in ipairs(listKeyModules()) do
    table.insert(bindings, require(moduleName))
end

return bindings
