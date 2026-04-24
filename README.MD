# Hammerspoon Config / Hammerspoon 配置

Modular Hammerspoon setup for macOS with auto-discovery for `eventtap` remap rules and `hotkeys` bindings.
面向 macOS 的模块化 Hammerspoon 配置，`eventtap` 与 `hotkeys` 规则均支持自动发现。

## Current Architecture / 当前架构

```
~/.hammerspoon/
├── init.lua                    # Entry: assemble config, load/start modules, hs_reload()
├── modules/
│   ├── eventtap.lua            # Keyboard interception + remap forwarding
│   └── hotkeys.lua             # Global hotkey registration lifecycle
├── eventtap/
│   ├── remaps.lua              # Auto-scan eventtap/apps/*.lua -> normalized remaps
│   └── apps/
│       └── example.lua         # Per-app remap definitions
├── hotkeys/
│   ├── bindings.lua            # Auto-scan hotkeys/keys/*.lua -> binding list
│   └── keys/
│       └── ghostty.lua         # Single hotkey definition
├── utils/
│   └── log.lua                 # Tagged logger factory + one-time console clear
└── Spoons/                     # Optional Spoon assets (EmmyLua annotations etc.)
```

## Load Flow / 加载流程

1. `init.lua` builds runtime config (`eventtap.remaps`, `hotkeys.bindings`).
2. Modules in `modules/` are loaded and merged with corresponding config sections.
3. Each module `start()` runs if `enabled ~= false`.
4. Module load logs are printed in fixed order: `hotkeys` -> `eventtap`.
5. `hs_reload()` stops modules in reverse order, then calls `hs.reload()`.

1. `init.lua` 组装运行时配置（`eventtap.remaps`、`hotkeys.bindings`）。
2. 加载 `modules/` 模块并合并对应配置。
3. `enabled ~= false` 的模块执行 `start()`。
4. 模块加载日志按固定顺序输出：`hotkeys` -> `eventtap`。
5. `hs_reload()` 逆序调用 `stop()`，再执行 `hs.reload()`。

## Rule Operations / 规则维护

### Add or remove hotkeys / 新增或删除 hotkey

- Add: create a file under `hotkeys/keys/*.lua` exporting `id`, `mods`, `key`, `action`.
- Remove: delete that file.
- No change needed in `hotkeys/bindings.lua` (auto-scan).
- Reload via `hs_reload()`.

- 新增：在 `hotkeys/keys/*.lua` 新建文件，导出 `id`、`mods`、`key`、`action`。
- 删除：直接删除该文件。
- 无需改 `hotkeys/bindings.lua`（自动扫描）。
- 使用 `hs_reload()` 重载生效。

### Add or remove eventtap remaps / 新增或删除 eventtap remap

- Add: create `eventtap/apps/*.lua` with app-level `id`, `displayName`, `target`, `remaps`.
- Remove: delete that file.
- No change needed in `eventtap/remaps.lua` (auto-scan).
- Reload via `hs_reload()`.

- 新增：在 `eventtap/apps/*.lua` 新建文件，定义应用级 `id`、`displayName`、`target`、`remaps`。
- 删除：直接删除该文件。
- 无需改 `eventtap/remaps.lua`（自动扫描）。
- 使用 `hs_reload()` 重载生效。

## Logging and Debugging / 日志与调试

- Project logs use tagged loggers from `utils/log.lua` (`hotkeys`, `eventtap`, default `config`).
- First logger access clears Hammerspoon console once per reload cycle.
- `modules/hotkeys.lua` sets `hs.hotkey.setLogLevel("error")` to suppress noisy hotkey info logs.
- Hammerspoon internal lines prefixed with `--` are app-native logs, not project logs.

- 项目日志通过 `utils/log.lua` 按 tag 输出（`hotkeys`、`eventtap`、默认 `config`）。
- 每次重载后首次获取 logger 会清空一次控制台。
- `modules/hotkeys.lua` 使用 `hs.hotkey.setLogLevel("error")` 抑制噪声级热键日志。
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
- change rule schema for `eventtap` or `hotkeys` / 修改 `eventtap` 或 `hotkeys` 规则结构

## References / 参考文档

- [Hammerspoon API](https://www.hammerspoon.org/docs/)
- [Hammerspoon Getting Started](https://www.hammerspoon.org/go/)
- [Official SPOONS.md](https://github.com/Hammerspoon/hammerspoon/blob/master/SPOONS.md)
