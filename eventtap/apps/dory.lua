return {
    id = "dory",
    displayName = "Dory",

    -- 可选：app 级默认派发策略；单条 remap 可用自己的 dispatch 覆盖。
    -- "immediateTrigger"：trigger keyDown 命中后按住 target，trigger keyUp 或 trigger 修饰键释放时松开。
    -- "afterReleaseTrigger"：吞掉 trigger keyDown/keyUp，等 trigger 修饰键全松开后发送一次 target tap。

    remaps = {
        {
            id = "command-tab-to-dory",
            description = "Command+Tab 转发到 Dory 应用切换器",
            dispatch = "immediateTrigger",
            trigger = {
                mods = { "command" },
                key = "tab"
            },
            target = {
                mods = { "command", "control", "option" },
                key = "tab"
            }
        }
    }
}
