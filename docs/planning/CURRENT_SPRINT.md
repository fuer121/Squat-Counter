# 当前阶段

## 当前目标

当前项目处于“工程骨架完成，进入核心实现期”阶段。

本轮优先目标：

1. 跑通 Watch 端训练主流程
2. 用模拟识别先完成可联调闭环
3. 明确 iPhone companion 与同步边界
4. 在进入 iPhone Companion 实现前冻结 `6.6` 页面范围与职责边界
5. 前置测试、权限、隐私与发布门禁

## 当前顺序

建议执行顺序：

1. `WorkoutSessionViewModel` 与 Watch 主流程
2. `TimerManager`、`HapticManager`
3. 模拟识别与识别状态机
4. `TASK_007`：iPhone Companion 边界冻结与实现准备
5. `TASK_008`：iPhone Companion 实现契约补齐
6. `6.7`：iPhone 配置同步与训练结果回传
7. HealthKit、隐私、发布基线补齐

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
- 当前直接 owner：`开发 Agent 1`
- 当前线程判断：`codex/task-007-iphone-boundary`
- 当前判断理由：`TASK_007` 与 `TASK_008` 已先后冻结 `6.6` 的页面范围、实现文件边界和验证口径；当前分支已承接首批 iPhone Companion 页面实现，并已形成独立增量 PR，下一步进入评审前门禁检查，不进入 `6.7`
- 当前状态：`TASK_004` 已完成并合入 `main`，`TASK_005` 已完成边界冻结，`TASK_006` 已完成并随 `PR #3` 合入 `main`，`TASK_007` 已完成前置边界冻结并收口，`TASK_008` 已完成首批页面实现；当前已完成 iOS 最小构建与 `build-for-testing` 验证，且 `PR #4` 已创建；完整 `xcodebuild test` 与定向 `test-without-building` 仍在当前环境执行阶段卡住，当前进入评审前检查前的文档状态收口

## 当前交付状态

- 当前分支：`codex/task-007-iphone-boundary`
- 当前提交状态：以当前任务分支 `HEAD` 为准，不再在本文件中固化单个 commit hash
- 当前 PR：`#4`（`6.6 iPhone Companion` 独立增量 PR 已创建，当前等待评审前检查）
- 当前下一步：由总控同时读取 `TASK_007`、`TASK_008`、`CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS` 与 `PR #4` 的状态，完成评审前检查并判断是否进入正式评审

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
