-- 按 M.cfg.remaps 拦截 keyDown 并 keyStroke 转发。
local M = {}

local tap

local function matchMods(flags, policy)
    if policy == "cmdOnly" then
        return flags.cmd and not flags.alt and not flags.ctrl and not flags.shift and not flags.fn
    end
    return false
end

function M.start()
    local remaps = M.cfg and M.cfg.remaps
    if not remaps or #remaps == 0 then
        require("utils.log")():e("eventtap: empty cfg.remaps")
        return
    end

    if tap then
        tap:stop()
        tap = nil
    end

    tap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
        local flags = event:getFlags()
        local keyCode = event:getKeyCode()
        for _, rule in ipairs(remaps) do
            if keyCode == rule.keyCode and matchMods(flags, rule.modifierPolicy) then
                hs.eventtap.keyStroke(rule.targetMods, rule.targetKey, 0)
                return true
            end
        end
        return false
    end)

    tap:start()
end

function M.stop()
    if tap then
        tap:stop()
        tap = nil
    end
end

return M
