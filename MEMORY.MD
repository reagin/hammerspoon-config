# Project Memory / 项目记忆

## Purpose / 目标

This file is a fast-start memory for stateless sessions.
本文件用于无记忆会话快速恢复项目上下文。

## Architecture Snapshot / 架构快照

- Entry: `init.lua`
- Modules: `modules/eventtap.lua`, `modules/hotkeys.lua`, `modules/launched.lua`
- Eventtap rules: `eventtap/remaps.lua` auto-loads `eventtap/apps/*.lua`
- Active eventtap remaps: `eventtap/apps/dory.lua`; `eventtap/apps/example.lua.bak` is a template
- Hotkey rules: `hotkeys/bindings.lua` auto-loads `hotkeys/keys/*.lua`
- Launched scripts: `launched/scripts.lua` auto-loads `launched/scripts/*.lua`
- Active launched scripts: `launched/scripts/limitping.lua`; `launched/scripts/example.lua.bak` is a template
- Logging: `utils/log.lua` provides tagged logger factory
- Modifiers: `utils/modifiers.lua` centralizes modifier-name parsing and Hammerspoon API conversion

- 入口：`init.lua`
- 模块：`modules/eventtap.lua`、`modules/hotkeys.lua`、`modules/launched.lua`
- Eventtap 规则：`eventtap/remaps.lua` 自动加载 `eventtap/apps/*.lua`
- 当前 eventtap 映射：`eventtap/apps/dory.lua`；`eventtap/apps/example.lua.bak` 是模板
- Hotkey 规则：`hotkeys/bindings.lua` 自动加载 `hotkeys/keys/*.lua`
- Launched 脚本：`launched/scripts.lua` 自动加载 `launched/scripts/*.lua`
- 当前 launched 脚本：`launched/scripts/limitping.lua`；`launched/scripts/example.lua.bak` 是模板
- 日志：`utils/log.lua` 提供按标签 logger 工厂
- 修饰键：`utils/modifiers.lua` 统一修饰键名称解析与 Hammerspoon API 转换

## Runtime Flow / 运行流程

1. `init.lua` assembles runtime config.
2. Modules are loaded and merged with config sections.
3. Modules start when enabled.
4. Startup logs are printed in sorted module-name order: `eventtap`, `hotkeys`, `launched`.
5. `hs_reload()` stops modules in reverse order, then calls `hs.reload()`.

1. `init.lua` 组装运行时配置。
2. 加载模块并合并对应配置。
3. 启用模块执行 `start()`。
4. 启动日志按模块名排序输出：`eventtap`、`hotkeys`、`launched`。
5. `hs_reload()` 逆序停止模块后调用 `hs.reload()`。

## Rule File Contract / 规则文件约定

### Hotkeys (`hotkeys/keys/*.lua`)

- One file = one binding.
- Required fields: `id`, `mods`, `key`, `action`.
- `mods` supports `command`, `control`, `option`, `shift` and is converted before binding.
- Actions that emit keystrokes should use `utils.modifiers.normalizeEventtapTargetMods()` when starting from normalized names.
- Add/delete file to add/delete behavior.

- 一文件对应一条快捷键。
- 必填字段：`id`、`mods`、`key`、`action`。
- `mods` 支持 `command`、`control`、`option`、`shift`，绑定前会自动转换。
- action 需要发出模拟按键时，如果从规范名出发，应使用 `utils.modifiers.normalizeEventtapTargetMods()` 转换。
- 通过增删文件完成增删行为。

### Eventtap apps (`eventtap/apps/*.lua`)

- One file = one app rule group.
- Typical fields: `id`, `displayName`, optional app-level `target`, `remaps`.
- Each remap needs `trigger.key` and `trigger.mods`.
- `trigger.mods` supports `command`, `leftCommand`, `rightCommand`, `control`, `leftControl`, `rightControl`, `option`, `leftOption`, `rightOption`, `shift`, `leftShift`, `rightShift`, `fn`; generic names match either physical key.
- Target resolves from remap target or app target; `target.mods` supports `command`, `control`, `option`, `shift`, `fn` and is normalized before forwarding through Hammerspoon event APIs.
- Modifier parsing is shared through `utils/modifiers.lua`.
- Dispatch only starts target forwarding after trigger modifiers and trigger key match; pressing trigger modifiers alone never emits target modifiers.
- Target events are marked as internal synthetic events, ignored by the local watcher, and posted asynchronously with a short inter-event delay so global shortcut listeners see a normal modifier/key sequence after the trigger is swallowed.
- `dispatch = "immediateTrigger"` swallows the trigger keydown, schedules target modifiers/key immediately, keeps them down while the trigger is held, suppresses repeated trigger keydown, then releases target key/modifiers on trigger keyup or trigger modifier release.
- `dispatch = "afterReleaseTrigger"` swallows the trigger keydown/keyup, waits until all trigger modifiers are released, then schedules one complete target tap.

- 一文件对应一个应用规则组。
- 常用字段：`id`、`displayName`、可选应用级 `target`、`remaps`。
- 每条 remap 需有 `trigger.key` 与 `trigger.mods`。
- `trigger.mods` 支持 `command`、`leftCommand`、`rightCommand`、`control`、`leftControl`、`rightControl`、`option`、`leftOption`、`rightOption`、`shift`、`leftShift`、`rightShift`、`fn`；通用名会匹配任一侧实体键。
- target 可来自 remap 或 app 级配置；`target.mods` 支持 `command`、`control`、`option`、`shift`、`fn`，规范化后通过 Hammerspoon 事件 API 转发。
- 修饰键解析由 `utils/modifiers.lua` 统一处理。
- dispatch 只会在触发修饰键和触发键同时命中后才开始转发；单独按下触发修饰键不会发出 target 修饰键。
- target 事件会标记为内部合成事件，本 watcher 再次看到时直接放行，并在吞掉 trigger 后异步、短间隔投递，让全局快捷键监听器看到更正常的修饰键/普通键序列。
- `dispatch = "immediateTrigger"` 会吞掉触发键 keydown，立即调度 target 修饰键/普通键，在 trigger 按住期间保持 target 按下，抑制重复 trigger keydown，并在触发键 keyup 或触发修饰键释放时松开 target。
- `dispatch = "afterReleaseTrigger"` 会吞掉触发键 keydown/keyup，等所有触发修饰键松开后调度一次完整 target tap。

### Launched scripts (`launched/scripts/*.lua`)

- One file = one boot script.
- Required fields: `id`, `command`.
- Optional field: `description`.
- `command` supports single-line or multi-line Lua strings.
- Commands run through `/bin/zsh -lc` with `hs.execute(..., true)` so user shell environment variables are available where Hammerspoon can resolve them.
- The module stores the current macOS boot ID from `sysctl -n kern.boottime` in `hs.settings`.
- Scripts run once per system boot, not once per Hammerspoon reload.
- If any script fails, the boot ID is not marked complete and scripts are retried on the next Hammerspoon load.
- `launched/scripts/limitping.lua` prefers `/usr/local/bin/limitping`, runs `limitping bg status` before start to clear stale state, starts only the Codex watcher, and prints status/log diagnostics on failure.

- 一文件对应一个启动脚本。
- 必填字段：`id`、`command`。
- 可选字段：`description`。
- `command` 支持单行或多行 Lua 字符串。
- 命令通过 `/bin/zsh -lc` 与 `hs.execute(..., true)` 执行，让脚本尽量获得 Hammerspoon 可解析到的用户 shell 环境变量。
- 模块会把 `sysctl -n kern.boottime` 得到的当前 macOS 启动 ID 存入 `hs.settings`。
- 脚本每次系统启动只运行一次，不会每次 Hammerspoon reload 都运行。
- 如果任一脚本失败，本次启动不会标记完成，下次 Hammerspoon 加载时会重试。
- `launched/scripts/limitping.lua` 优先使用 `/usr/local/bin/limitping`，启动前运行 `limitping bg status` 清理陈旧状态，只启动 Codex watcher，并在失败时输出状态和日志诊断。

## Logging Notes / 日志说明

- Project tags: `eventtap`, `hotkeys`, `launched`, default `config`.
- Console is cleared once on first logger retrieval after reload.
- `modules/hotkeys.lua` sets `hs.hotkey.setLogLevel("error")` to suppress noisy hotkey info logs.
- `modules/hotkeys.lua` reports failed `hs.hotkey.bind` registrations in startup logs.

- 项目 logger 标签：`eventtap`、`hotkeys`、`launched`、默认 `config`。
- 每次重载后首次取 logger 会清空一次控制台。
- `modules/hotkeys.lua` 使用 `hs.hotkey.setLogLevel("error")` 抑制热键扩展噪声日志。
- `modules/hotkeys.lua` 会在启动日志中报告失败的 `hs.hotkey.bind` 注册。

## Safe Change Checklist / 安全修改清单

Before editing:
- Confirm target module and rule path.
- Keep lifecycle methods stable (`start/stop`).

After editing:
- Run Lua syntax checks for touched files.
- Verify no new lint errors.
- Reload and validate behavior + logs.

改动前：
- 确认目标模块与规则文件路径。
- 保持生命周期方法稳定（`start/stop`）。

改动后：
- 对修改文件执行 Lua 语法检查。
- 检查无新增 lint 错误。
- 重载并验证功能与日志。

## Documentation Sync Policy / 文档同步策略

When code changes affect architecture, workflow, logging, loading order, or rule schema, update **both** `README.MD` and `MEMORY.MD` in the same task.
当代码改动影响架构、流程、日志、加载顺序或规则结构时，需在同一任务中同步更新 `README.MD` 与 `MEMORY.MD`。
