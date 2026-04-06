# Task Contract 004

## 基本信息

- 任务名称：6.4 训练控制能力实现（`TimerManager` / `HapticManager`）
- 任务目标：在 `TASK_003` 已冻结的边界内，完成 `TimerManager`、`HapticManager`、`WorkoutSessionViewModel` 接入、Watch 端最小震动执行与首批测试补齐，形成可评审的 `6.4` 增量实现
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent`
- 协作方：`总控 Agent`、`产品 Agent`、`测试 Agent`
- 是否需要总控介入：`是`

## 输入与输出

- 输入文档：
  - `PRD/PRD_V1.md`
  - `AGENTS.md`
  - `docs/agents/AGENT_SYSTEM.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/planning/RISKS.md`
  - `docs/tasks/TASK_003_TRAINING_CONTROL_BOUNDARY.md`
- 输入代码范围：
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Models/WorkoutProgress.swift`
  - `Shared/Models/WorkoutState.swift`
  - `Shared/Models/PauseContext.swift`
  - `SquatCounterWatchExtension/Features/Home/WatchArchitectureOverviewView.swift`
  - `SquatCounterTests/WorkoutConfigTests.swift`
- 预期输出：
  - `TimerManager` 最小实现
  - `HapticManager` 最小实现
  - `WorkoutSessionViewModel` 对计时与反馈事件的接入
  - Watch 端最小震动执行接线
  - 与训练控制能力直接相关的首批测试
  - 可提交评审的独立增量 PR

## 执行边界

- 可修改文件范围：
  - `Shared/Models/`
  - `Shared/TrainingControl/`
  - `SquatCounterWatchExtension/`
  - `SquatCounterTests/`
  - 必要时：
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/RISKS.md`
- 不可擅自变更项：
  - 不扩展到真实动作识别
  - 不扩展到 `iPhone companion` 新功能
  - 不调整同步链路边界
  - 不进入 `HealthKit` 完整实现
  - 不新增 `WorkoutState` 顶层状态
  - 不顺手重构无关模块
- 是否允许自动化执行：`是`
- 是否需要子线程：`是`
- 是否需要 worktree：`否`
- 使用理由：`TASK_003` 已冻结边界并完成产品口径回收，当前任务是中等规模实现与测试补齐，适合在独立开发 Agent 子线程内推进并回收到独立 PR

## 继承口径

- 本任务严格继承 `TASK_003` 已冻结的职责边界、产品边界、关键文案与测试范围
- `TimerManager` 统一覆盖 `countdown`、`resting` 与训练态节奏提示入口；同一时刻只保留一个激活中的训练控制计时上下文
- `HapticManager` 只负责反馈事件映射与优先级，不直接驱动 `WorkoutSessionViewModel` 状态流转
- `WorkoutSessionViewModel` 继续作为训练状态与进度的唯一状态源

## 验收与风险

- 验收标准：
  - 已完成 `TimerManager` 最小实现并接入倒计时、休息、节奏提示
  - 已完成 `HapticManager` 最小实现并满足冻结的反馈优先级
  - 已完成 `WorkoutSessionViewModel` 与两个 manager 的接入
  - 已完成倒计时、休息、提前开始、暂停恢复、反馈优先级相关测试
  - 已完成相关自动化验证并形成独立 PR
- 风险与依赖：
  - watchOS 真机震动体验仍需后续真机验证，当前 PR 仅完成代码职责与模拟器构建验证
  - 真实动作识别、同步链路、`HealthKit` 不属于本任务吸收范围
- 最快验证方式：
  - 运行 `WorkoutConfigTests`、`TimerManagerTests`、`HapticManagerTests`
  - 运行 `SquatCounterWatchApp` 最小构建检查

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
