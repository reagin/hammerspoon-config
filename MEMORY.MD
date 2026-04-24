# Project Memory / 项目记忆

## Purpose / 目标

This file is a fast-start memory for stateless sessions.
本文件用于无记忆会话快速恢复项目上下文。

## Architecture Snapshot / 架构快照

- Entry: `init.lua`
- Modules: `modules/eventtap.lua`, `modules/hotkeys.lua`
- Eventtap rules: `eventtap/remaps.lua` auto-loads `eventtap/apps/*.lua`
- Hotkey rules: `hotkeys/bindings.lua` auto-loads `hotkeys/keys/*.lua`
- Logging: `utils/log.lua` provides tagged logger factory

- 入口：`init.lua`
- 模块：`modules/eventtap.lua`、`modules/hotkeys.lua`
- Eventtap 规则：`eventtap/remaps.lua` 自动加载 `eventtap/apps/*.lua`
- Hotkey 规则：`hotkeys/bindings.lua` 自动加载 `hotkeys/keys/*.lua`
- 日志：`utils/log.lua` 提供按标签 logger 工厂

## Runtime Flow / 运行流程

1. `init.lua` assembles runtime config.
2. Modules are loaded and merged with config sections.
3. Modules start when enabled.
4. Startup logs are printed in order: `hotkeys` then `eventtap`.
5. `hs_reload()` stops modules in reverse order, then calls `hs.reload()`.

1. `init.lua` 组装运行时配置。
2. 加载模块并合并对应配置。
3. 启用模块执行 `start()`。
4. 启动日志按 `hotkeys` 再 `eventtap` 输出。
5. `hs_reload()` 逆序停止模块后调用 `hs.reload()`。

## Rule File Contract / 规则文件约定

### Hotkeys (`hotkeys/keys/*.lua`)

- One file = one binding.
- Required fields: `id`, `mods`, `key`, `action`.
- Add/delete file to add/delete behavior.

- 一文件对应一条快捷键。
- 必填字段：`id`、`mods`、`key`、`action`。
- 通过增删文件完成增删行为。

### Eventtap apps (`eventtap/apps/*.lua`)

- One file = one app rule group.
- Typical fields: `id`, `displayName`, optional app-level `target`, `remaps`.
- Each remap needs `trigger.key`; target resolves from remap target or app target.

- 一文件对应一个应用规则组。
- 常用字段：`id`、`displayName`、可选应用级 `target`、`remaps`。
- 每条 remap 需有 `trigger.key`；target 可来自 remap 或 app 级配置。

## Logging Notes / 日志说明

- Project tags: `hotkeys`, `eventtap`, default `config`.
- Console is cleared once on first logger retrieval after reload.
- `modules/hotkeys.lua` sets `hs.hotkey.setLogLevel("error")` to suppress noisy hotkey info logs.

- 项目 logger 标签：`hotkeys`、`eventtap`、默认 `config`。
- 每次重载后首次取 logger 会清空一次控制台。
- `modules/hotkeys.lua` 使用 `hs.hotkey.setLogLevel("error")` 抑制热键扩展噪声日志。

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
