-- example：与该应用相关的快捷键约定（触发 + 转发目标）。
-- 请在 example 中将「全局快捷键」设为与 target 一致；Hammerspoon 会模拟该组合键。
return {
    id = "example",
    displayName = "example",

    -- 默认转发目标；remaps 项可省略 target 以复用此处
    target = {
        -- hs.eventtap.keyStroke 支持的 mods 名（任选其一或多个组成表，勿需写全）：
        -- "shift" | "control" | "option" | "cmd" | "fn"
        mods = { "alt", "shift" },
        key = "tab"
    },

    remaps = { {
        id = "cmd_tab_to_cmd_tab",
        description = "Cmd+Tab 转发给 example",
        trigger = {
            mods = { "cmd" },
            key = "tab"
        },
        target = {
            mods = { "cmd" },
            key = "tab"
        }
    } }
}
