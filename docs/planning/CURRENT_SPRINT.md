# 当前阶段

## 当前目标

当前项目处于“工程骨架完成，进入核心实现期”阶段。

本轮优先目标：

1. 跑通 Watch 端训练主流程
2. 完成真实动作计数第一阶段“真实可用闭环”（实时采样 + 一次性校准 + `live` 默认路径）
3. 明确 iPhone companion 与同步边界
4. 在进入 iPhone Companion 实现前冻结 `6.6` 页面范围与职责边界
5. 前置测试、权限、隐私与发布门禁

## 当前顺序

建议执行顺序：

1. `WorkoutSessionViewModel` 与 Watch 主流程
2. `TimerManager`、`HapticManager`
3. 真实传感器采样接线、一次性校准、`live` 正式路径切换
4. `TASK_007`：iPhone Companion 边界冻结与实现准备
5. `TASK_008`：iPhone Companion 实现契约补齐
6. `TASK_009`：跨设备同步边界冻结与实现准备
7. `6.7`：iPhone 配置同步与训练结果回传实现
8. `TASK_011`：HealthKit 与权限边界冻结 / 实现准备
9. HealthKit、隐私、发布基线补齐
10. `TASK_013`：数据与隐私合规边界冻结 / 实现准备
11. `TASK_014`：数据与隐私合规实现契约补齐

## 当前 owner 建议

- 总控 Agent：阶段推进与 checkpoint
- 产品 Agent：规则、文案、验收标准
- 开发 Agent：Watch 主流程
- UI Agent：Watch 与 companion 页面落位
- 测试 Agent：状态机、计时、识别、真机验证基线

## 当前活跃任务

- `TASK_005`：`docs/tasks/TASK_005_SQUAT_DETECTION_BOUNDARY.md`
- `TASK_006`：`docs/tasks/TASK_006_SQUAT_DETECTION_IMPLEMENTATION.md`
- `TASK_007`：`docs/tasks/TASK_007_IPHONE_COMPANION_BOUNDARY.md`
- `TASK_008`：`docs/tasks/TASK_008_IPHONE_COMPANION_IMPLEMENTATION.md`
- `TASK_009`：`docs/tasks/TASK_009_CROSS_DEVICE_SYNC_BOUNDARY.md`
- `TASK_010`：`docs/tasks/TASK_010_CROSS_DEVICE_SYNC_IMPLEMENTATION.md`
- `TASK_011`：`docs/tasks/TASK_011_HEALTHKIT_PERMISSION_BOUNDARY.md`
- `TASK_012`：`docs/tasks/TASK_012_HEALTHKIT_PERMISSION_IMPLEMENTATION.md`
- `TASK_013`：`docs/tasks/TASK_013_DATA_PRIVACY_COMPLIANCE_BOUNDARY.md`
- `TASK_014`：`docs/tasks/TASK_014_DATA_PRIVACY_COMPLIANCE_IMPLEMENTATION.md`
- `TASK_017`：`docs/tasks/TASK_017_REAL_LIVE_DETECTION_VALIDATION_REPAIR.md`
- 当前直接 owner：`开发 Agent`
- 当前线程判断：`codex/task-016-real-live-detection`
- 当前判断理由：用户已在真实 `iPhone 16 + Apple Watch Series 8` 上完成 `TASK_016` 真机验证，结果为不通过；当前先通过 `TASK_017` 收敛失败后的需求口径、修复边界和后续任务拆分，再继续代码修复
- 当前状态：`TASK_004` 已完成并合入 `main`，`TASK_005` 已完成边界冻结，`TASK_006` 已完成并随 `PR #3` 合入 `main`，`TASK_007` 已完成前置边界冻结并收口，`TASK_008` 已完成首批页面实现并随 `PR #4` 合入 `main`，`TASK_009` 已完成 `6.7` 前置边界冻结 / 实现准备，`TASK_010` 已完成 `6.7` 首批实现契约补齐并随 `PR #6` 合入 `main`，`TASK_011` 已完成 `6.8` 边界冻结与实现准备口径，`TASK_012` 已完成 `6.8` 首批实现契约补齐并随 `PR #7` 合入 `main`，`TASK_013` / `TASK_014` 已完成 `6.9` 收口；本轮 `6.5` 的 `TASK_016` 本地实现已完成但真机验证失败，`TASK_017` 已将必须修复项、验收口径修订和后续新增范围拆开

## 当前交付状态

- 当前分支：`codex/task-016-real-live-detection`
- 当前提交状态：以当前任务分支 `HEAD` 为准，不在本文件中固化单个 commit hash
- 当前 PR：`无`（按任务要求本轮不创建 PR）
- 当前下一步：基于 `TASK_017` 派发真机失败修复任务，优先修复正式路径 UI、校准体验 / 采样窗口和真实识别链路；iPhone 端重置校准入口后续单独立项

## 本阶段禁止扩展

- 不引入账号体系
- 不引入云同步
- 不引入多动作识别
- 不引入 AI 动作纠错
- 不引入社交与成就体系

## 本阶段观察与沉淀方向

- 观察重点：总控调度、共享文档同步、文件边界拆分是否稳定
- 沉淀方向：如何在 `vibe coding` 协作下减少群聊式推进、减少文件冲突、减少任务失真
- 扩展角色判断：当前项目暂不启用 `平台 Agent` 与 `数据 Agent`，后续若引入服务端或数据库再启用
