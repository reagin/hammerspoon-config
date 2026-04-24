-- 按标签缓存 hs.logger 实例。
local loggerByTag = {}
local consoleCleared = false

return function(tag, level)
    if not consoleCleared then
        hs.console.clearConsole()
        consoleCleared = true
    end

    local loggerTag = tag or "config"
    if loggerByTag[loggerTag] then
        return loggerByTag[loggerTag]
    end

    local logger = hs.logger.new(loggerTag, level or "info")
    loggerByTag[loggerTag] = logger
    return logger
end
