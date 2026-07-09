# Hammerspoon Config / Hammerspoon 配置

Modular Hammerspoon setup for macOS with auto-discovery for `eventtap` remap rules, `hotkeys` bindings, and one-shot `launched` boot scripts.
面向 macOS 的模块化 Hammerspoon 配置，`eventtap`、`hotkeys` 与系统启动后执行一次的 `launched` 脚本均支持自动发现。

## Current Architecture / 当前架构

```
~/.hammerspoon/
├── init.lua                    # Entry: assemble config, load/start modules, hs_reload()
├── modules/
│   ├── eventtap.lua            # Keyboard interception + remap forwarding
│   ├── hotkeys.lua             # Global hotkey registration lifecycle
│   └── launched.lua            # One-shot boot script runner lifecycle
├── eventtap/
│   ├── remaps.lua              # Auto-scan eventtap/apps/*.lua -> normalized remaps
│   └── apps/
│       └── example.lua.bak     # Template for per-app remap definitions
├── hotkeys/
│   ├── bindings.lua            # Auto-scan hotkeys/keys/*.lua -> binding list
│   └── keys/
│       └── open-ghostty.lua    # Single hotkey definition
├── launched/
│   ├── scripts.lua             # Auto-scan launched/scripts/*.lua -> script list
│   └── scripts/
│       └── example.lua.bak     # Template for launched shell scripts
├── utils/
│   ├── log.lua                 # Tagged logger factory + one-time console clear
│   └── modifiers.lua           # Shared modifier-name parsing and API conversion
└── Spoons/                     # Optional Spoon assets (EmmyLua annotations etc.)
```

## Load Flow / 加载流程

1. `init.lua` builds runtime config (`eventtap.remaps`, `hotkeys.bindings`, `launched.scripts`).
2. Modules in `modules/` are loaded and merged with corresponding config sections.
3. Each module `start()` runs if `enabled ~= false`.
4. Module load logs are printed in sorted module-name order: `eventtap` -> `hotkeys` -> `launched`.
5. `hs_reload()` stops modules in reverse order, then calls `hs.reload()`.

1. `init.lua` 组装运行时配置（`eventtap.remaps`、`hotkeys.bindings`、`launched.scripts`）。
2. 加载 `modules/` 模块并合并对应配置。
3. `enabled ~= false` 的模块执行 `start()`。
4. 模块加载日志按模块名排序输出：`eventtap` -> `hotkeys` -> `launched`。
5. `hs_reload()` 逆序调用 `stop()`，再执行 `hs.reload()`。

## Rule Operations / 规则维护

### Add or remove hotkeys / 新增或删除 hotkey

- Add: create a file under `hotkeys/keys/*.lua` exporting `id`, `mods`, `key`, `action`.
- `mods` uses normalized names (`command`, `control`, `option`, `shift`) and is converted before binding.
- Actions that emit keystrokes should use Hammerspoon eventtap modifier names (`cmd`, `ctrl`, `alt`, `shift`, `fn`); use `utils.modifiers.normalizeEventtapTargetMods()` when starting from normalized names.
- Remove: delete that file.
- No change needed in `hotkeys/bindings.lua` (auto-scan).
- Reload via `hs_reload()`.

- 新增：在 `hotkeys/keys/*.lua` 新建文件，导出 `id`、`mods`、`key`、`action`。
- `mods` 使用规范名（`command`、`control`、`option`、`shift`），绑定前会自动转换。
- 需要发出模拟按键的 action 使用 Hammerspoon eventtap 修饰键名（`cmd`、`ctrl`、`alt`、`shift`、`fn`）；如果从规范名出发，使用 `utils.modifiers.normalizeEventtapTargetMods()` 转换。
- 删除：直接删除该文件。
- 无需改 `hotkeys/bindings.lua`（自动扫描）。
- 使用 `hs_reload()` 重载生效。

### Add or remove eventtap remaps / 新增或删除 eventtap remap

- Add: create `eventtap/apps/*.lua` with app-level `id`, `displayName`, `target`, `remaps`.
- `trigger.mods` is required and uses raw modifier names: `command`, `leftCommand`, `rightCommand`, `control`, `leftControl`, `rightControl`, `option`, `leftOption`, `rightOption`, `shift`, `leftShift`, `rightShift`, `fn`. Generic names such as `option` match either physical key.
- `target.mods` uses normalized names (`command`, `control`, `option`, `shift`, `fn`) and is sent via Hammerspoon event APIs.
- Modifier parsing and Hammerspoon API conversion are shared through `utils/modifiers.lua`.
- Dispatch only starts target forwarding after trigger modifiers and trigger key match; pressing trigger modifiers alone never emits target modifiers.
- Target events are marked as internal synthetic events, ignored by the local watcher, and posted asynchronously with a short inter-event delay so global shortcut listeners see a normal modifier/key sequence after the trigger is swallowed.
- `dispatch = "immediateTrigger"` swallows the trigger keydown, schedules target modifiers/key immediately, keeps them down while the trigger is held, suppresses repeated trigger keydown, then releases target key/modifiers on trigger keyup or trigger modifier release.
- `dispatch = "afterReleaseTrigger"` swallows the trigger keydown/keyup, waits until all trigger modifiers are released, then schedules one complete target tap.
- Remove: delete that file.
- No change needed in `eventtap/remaps.lua` (auto-scan).
- Reload via `hs_reload()`.

- 新增：在 `eventtap/apps/*.lua` 新建文件，定义应用级 `id`、`displayName`、`target`、`remaps`。
- `trigger.mods` 为必填，使用原始修饰键名：`command`、`leftCommand`、`rightCommand`、`control`、`leftControl`、`rightControl`、`option`、`leftOption`、`rightOption`、`shift`、`leftShift`、`rightShift`、`fn`。`option` 这类通用名会同时匹配左右两侧实体键。
- `target.mods` 使用规范名（`command`、`control`、`option`、`shift`、`fn`），并通过 Hammerspoon 事件 API 转发。
- 修饰键解析与 Hammerspoon API 转换由 `utils/modifiers.lua` 统一处理。
- dispatch 只会在触发修饰键和触发键同时命中后才开始转发；单独按下触发修饰键不会发出 target 修饰键。
- target 事件会标记为内部合成事件，本 watcher 再次看到时直接放行，并在吞掉 trigger 后异步、短间隔投递，让全局快捷键监听器看到更正常的修饰键/普通键序列。
- `dispatch = "immediateTrigger"` 会吞掉触发键 keydown，立即调度 target 修饰键/普通键，在 trigger 按住期间保持 target 按下，抑制重复 trigger keydown，并在触发键 keyup 或触发修饰键释放时松开 target。
- `dispatch = "afterReleaseTrigger"` 会吞掉触发键 keydown/keyup，等所有触发修饰键松开后调度一次完整 target tap。
- 删除：直接删除该文件。
- 无需改 `eventtap/remaps.lua`（自动扫描）。
- 使用 `hs_reload()` 重载生效。

### Active eventtap remaps / 当前 eventtap 映射

- `eventtap/apps/dory.lua`: maps `Command+Tab` to a held `Command+Control+Option+Tab` target with `dispatch = "immediateTrigger"`.
- `eventtap/apps/example.lua.bak` is a template and is not auto-loaded.

- `eventtap/apps/dory.lua`：用 `dispatch = "immediateTrigger"` 将 `Command+Tab` 映射为保持按下状态的 `Command+Control+Option+Tab`。
- `eventtap/apps/example.lua.bak` 是模板，不会被自动加载。

### Configured hotkeys / 当前配置的 hotkeys

- `hotkeys/keys/open-ghostty.lua`: binds `Command+Control+T` to open Ghostty.

- `hotkeys/keys/open-ghostty.lua`：绑定 `Command+Control+T` 打开 Ghostty。

### Add or remove launched scripts / 新增或删除 launched 脚本

- Add: create `launched/scripts/*.lua` exporting `id`, optional `description`, and `command`.
- `command` can be a single-line or multi-line Lua string and is executed through `/bin/zsh -lc`.
- `hs.execute(command, true)` is used under the hood so scripts can access the user's shell environment where Hammerspoon can resolve it.
- The module records the current macOS boot ID from `sysctl -n kern.boottime` in `hs.settings`, so scripts run only once per system boot and are skipped on later Hammerspoon reloads.
- If any script fails, the boot ID is not marked complete and the scripts will be retried on the next Hammerspoon load.
- `launched/scripts/limitping.lua` uses `/usr/local/bin/limitping` when available, runs `limitping bg status` before start to clear stale state, starts only the Codex watcher with `limitping bg start codex`, and prints status plus recent logs on failure.
- Remove: delete that file.
- No change needed in `launched/scripts.lua` (auto-scan).
- Reload via `hs_reload()`; scripts will only run if the current boot has not been marked complete.

- 新增：在 `launched/scripts/*.lua` 新建文件，导出 `id`、可选 `description` 与 `command`。
- `command` 可以是单行或多行 Lua 字符串，并通过 `/bin/zsh -lc` 执行。
- 底层使用 `hs.execute(command, true)`，让脚本尽量获得 Hammerspoon 可解析到的用户 shell 环境。
- 模块会把 `sysctl -n kern.boottime` 得到的当前 macOS 启动 ID 记录到 `hs.settings`，因此脚本每次系统启动只运行一次，后续 Hammerspoon reload 会跳过。
- 如果任一脚本失败，本次启动不会标记完成，下次 Hammerspoon 加载时会重试。
- `launched/scripts/limitping.lua` 会优先使用 `/usr/local/bin/limitping`，启动前运行 `limitping bg status` 清理陈旧状态，只用 `limitping bg start codex` 启动 Codex watcher，并在失败时输出 status 与最近日志。
- 删除：直接删除该文件。
- 无需改 `launched/scripts.lua`（自动扫描）。
- 使用 `hs_reload()` 重载；只有当前启动周期尚未标记完成时才会执行脚本。

### Active launched scripts / 当前 launched 脚本

- `launched/scripts/limitping.lua`: starts the Codex `limitping` background watcher once per macOS boot and reports status/log diagnostics when startup fails.
- `launched/scripts/example.lua.bak` is a template and is not auto-loaded.

- `launched/scripts/limitping.lua`：每次 macOS 启动后启动一次 Codex `limitping` 后台 watcher，启动失败时输出状态与日志诊断。
- `launched/scripts/example.lua.bak` 是模板，不会被自动加载。

## Logging and Debugging / 日志与调试

- Project logs use tagged loggers from `utils/log.lua` (`eventtap`, `hotkeys`, `launched`, default `config`).
- First logger access clears Hammerspoon console once per reload cycle.
- `modules/hotkeys.lua` sets `hs.hotkey.setLogLevel("error")` to suppress noisy hotkey info logs.
- `modules/hotkeys.lua` reports failed `hs.hotkey.bind` registrations in startup logs.
- Hammerspoon internal lines prefixed with `--` are app-native logs, not project logs.

- 项目日志通过 `utils/log.lua` 按 tag 输出（`eventtap`、`hotkeys`、`launched`、默认 `config`）。
- 每次重载后首次获取 logger 会清空一次控制台。
- `modules/hotkeys.lua` 使用 `hs.hotkey.setLogLevel("error")` 抑制噪声级热键日志。
- `modules/hotkeys.lua` 会在启动日志中报告失败的 `hs.hotkey.bind` 注册。
- 以 `--` 开头的日志是 Hammerspoon 应用自身输出，并非本项目日志。

## Permissions / 系统权限

Enable Accessibility permission for Hammerspoon in macOS Settings, otherwise keyboard interception will fail.
需在 macOS “隐私与安全性 -> 辅助功能”中为 Hammerspoon 开启权限，否则按键拦截不会生效。

## Maintenance Policy / 文档维护规则

After any code change, the model **must** review and update `README.MD` and `MEMORY.MD` when behavior, structure, or workflows changed.
每次项目代码改动后，模型**必须**检查并更新 `README.MD` 与 `MEMORY.MD`（若架构、行为、流程发生变化）。

Update docs at least when one of the following changes occurs:
发生以下任一变化时，必须同步更新文档：

- add/remove entry files or directories / 新增或删除目录、入口文件
- change module load order, config sources, or logger behavior / 修改模块加载顺序、配置来源或日志行为
- change rule schema for `eventtap`, `hotkeys`, or `launched` / 修改 `eventtap`、`hotkeys` 或 `launched` 规则结构

## References / 参考文档

- [Hammerspoon API](https://www.hammerspoon.org/docs/)
- [Hammerspoon Getting Started](https://www.hammerspoon.org/go/)
- [Official SPOONS.md](https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md)
