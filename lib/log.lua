-- 单一 hs.logger 实例，标签与级别来自 config.bootstrap。

local loggerInstance

return function()
    if loggerInstance then
        return loggerInstance
    end
    local bootstrap = require("config").bootstrap or {}
    loggerInstance = hs.logger.new(bootstrap.logTag or "config", bootstrap.logLevel or "info")
    return loggerInstance
end
