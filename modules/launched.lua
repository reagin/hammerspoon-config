-- 系统启动后执行一次 launched scripts。
local M = {}

local settingsKey = "modules.launched.lastBootId"
local loadLogLines = {}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shellQuote(value)
    return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

local function commandLabel(script)
    local id = script.id or "unnamed_script"
    if script.description and script.description ~= "" then
        return string.format("%s (%s)", id, script.description)
    end
    return id
end

local function currentBootId()
    local stdout, ok = hs.execute("/usr/sbin/sysctl -n kern.boottime", true)
    if not ok then
        return nil, trim(stdout or "unknown error")
    end

    local bootId = tostring(stdout or ""):match("sec%s*=%s*(%d+)")
    if not bootId then
        bootId = trim(tostring(stdout or ""))
    end
    if bootId == "" then
        return nil, "empty boot id"
    end
    return bootId
end

local function runScript(script)
    -- The command already runs in a zsh login shell. Passing true to
    -- hs.execute would wrap it in another interactive login shell and place
    -- the complete command inside unescaped double quotes.
    local command = "/bin/zsh -lc " .. shellQuote(script.command) .. " 2>&1"
    local stdout, ok, _, rc = hs.execute(command, false)
    return ok == true, stdout or "", rc
end

function M.start()
    local scripts = (M.cfg and M.cfg.scripts) or require("launched.scripts")
    if not scripts or #scripts == 0 then
        loadLogLines = { "-- no launched scripts configured" }
        return
    end

    local bootId, bootIdError = currentBootId()
    if not bootId then
        loadLogLines = { "-- launched skipped: cannot determine boot id: " .. tostring(bootIdError) }
        return
    end

    local lastBootId = hs.settings.get(settingsKey)
    if lastBootId == bootId then
        loadLogLines = { string.format("-- launched skipped: already ran for boot %s", bootId) }
        return
    end

    local succeeded = 0
    local failed = 0
    loadLogLines = { string.format("-- launched running: %d script(s), boot %s", #scripts, bootId) }

    for _, script in ipairs(scripts) do
        local ok, output, rc = runScript(script)
        if ok then
            succeeded = succeeded + 1
            table.insert(loadLogLines, string.format("    -- ok: %s", commandLabel(script)))
        else
            failed = failed + 1
            table.insert(loadLogLines, string.format("    -- failed: %s (exit=%s)", commandLabel(script), tostring(rc)))
            local message = trim(output)
            if message ~= "" then
                table.insert(loadLogLines, "       -- " .. message)
            end
        end
    end

    if failed == 0 then
        hs.settings.set(settingsKey, bootId)
    end

    table.insert(loadLogLines, string.format("-- launched finished: %d ok, %d failed", succeeded, failed))
end

function M.stop()
end

function M.getLoadLogLines()
    return loadLogLines
end

return M
