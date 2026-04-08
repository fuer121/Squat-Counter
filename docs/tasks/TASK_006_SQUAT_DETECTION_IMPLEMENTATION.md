# Task Contract 006

## 基本信息

- 任务名称：6.5 动作识别实现（基于 `TASK_005` 已冻结边界）
- 任务目标：在 `TASK_005` 已冻结的职责边界内，完成 `SquatDetectionManager` 事件流与管理接口、模拟识别模式、`WorkoutSessionViewModel` 接线、最小识别状态机 / `cooldown` / 防误触基线 / 内部可调阈值、相关测试与 Watch 最小构建验证，并让共享文档能够合法承接当前分支已发生的实现范围
- 优先级：`P0`
- 当前阶段：`阶段 3：可联调`

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
  - `docs/tasks/TASK_005_SQUAT_DETECTION_BOUNDARY.md`
- 输入代码范围：
  - `Shared/Models/SquatDetectionEvent.swift`
  - `Shared/Models/SquatMotionState.swift`
  - `Shared/Models/WorkoutState.swift`
  - `SquatCounterWatchExtension/Features/Home/WatchArchitectureOverviewView.swift`
  - `SquatCounterTests/WorkoutConfigTests.swift`
- 预期输出：
  - `SquatDetectionManager` 最小实现与事件流接线
  - 模拟识别模式作为首批联调入口
  - `WorkoutSessionViewModel` 对 `repDetected` 的接入
  - 简化识别状态机、`cooldown`、防误触基线与内部可调阈值
  - 与 `6.5` 直接相关的最小测试与 Watch 最小构建验证
  - 可供总控 checkpoint 使用的实现状态与共享文档回写结果

## 执行边界

- 可修改文件范围：
  - `Shared/Models/`
  - `SquatCounterWatchExtension/Features/Home/WatchArchitectureOverviewView.swift`
  - `SquatCounterTests/WorkoutConfigTests.swift`
  - 必要时：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/RISKS.md`
- 不可擅自变更项：
  - 不突破 `TASK_005` 已冻结的职责边界
  - `SquatDetectionManager` 不直接改 UI、不直接改 `WorkoutProgress`、不直接触发震动、不直接驱动 `TimerManager`
  - 不扩展到 `iPhone companion`、跨设备同步、`HealthKit`、多动作识别
  - 不修改 `6.4` 已合入模块的职责定义
  - 不新增 `WorkoutState` 顶层状态
  - 不顺手重构无关模块
  - 在总控 checkpoint 前不创建 PR
- 是否允许自动化执行：`是`
- 是否需要子线程：`是`
- 是否需要 worktree：`否`
- 使用理由：`TASK_005` 已完成边界冻结，当前任务属于中等规模实现与测试补齐；当前分支已承接该实现工作，但在进入 PR 准备前需要先通过独立实现契约补齐共享文档与合法承接关系

## 继承口径

- 本任务严格继承 `TASK_005` 已冻结的职责边界、实现顺序、接口边界与测试口径
- `SquatDetectionManager` 继续只作为动作信号采集与事件输出源
- `WorkoutSessionViewModel` 继续作为训练状态、训练进度与反馈触发的唯一业务状态源
- `TimerManager` 继续只负责倒计时、休息与节奏提示
- `HapticManager` 继续只负责反馈执行与优先级处理

## 当前已承接的实现范围

- 已完成动作识别事件流与管理接口定义，包含：
  - `SquatDetectionEvent`
  - `SquatDetectionMode`
  - `SquatDetectionThresholds`
  - `SquatMotionSample`
  - `SquatDetectionManaging`
  - `SquatDetectionManager`
- 已完成“模拟识别模式”作为首批联调入口，并通过显式入口驱动 `repDetected`
- 已完成 `WorkoutSessionViewModel` 对识别生命周期与 `repDetected` 的接入，仅在 `training` 状态消费识别结果
- 已完成最小简化识别状态机、`cooldown`、防误触基线与内部可调阈值
- 已完成 Watch 端模拟识别联调入口接线，并保留手动 `+1 / -1` 作为纠错能力
- 已完成与 `6.5` 直接相关的单元测试、集成测试与 Watch Simulator 最小构建验证

## 本任务明确不吸收的范围

- 真实传感器采样链路接入
- 真机识别调优完成定义
- iPhone companion 配置与同步
- `HealthKit`、训练结果落库或发布工程
- 复杂算法、姿态评分、多动作扩展

## 验收与风险

- 验收标准：
  - 已有实现严格落在 `TASK_005` 已冻结边界内
  - 已完成 `SquatDetectionManager` 最小实现、模拟识别模式与 `WorkoutSessionViewModel` 接线
  - 已完成简化识别状态机、`cooldown`、防误触基线与内部可调阈值
  - 已完成与 `6.5` 直接相关的最小测试
  - 已完成 `SquatCounterWatchApp` 的 Watch Simulator 最小构建验证
  - 已完成共享文档回写，使当前实现状态与契约状态一致
  - 已明确当前阶段不创建 PR，等待总控 checkpoint
- 风险与依赖：
  - 动作识别准确率仍是高风险，当前参数只具备 MVP 基线，不代表真机调优完成
  - 当前验证以模拟识别闭环、单测和 Watch Simulator 构建为主，不能替代真机识别验收
  - Watch 真机构建与设备侧验证仍依赖本地签名与设备环境
- 最快验证方式：
  - 运行 `xcodebuild test -scheme SquatCounter -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SquatCounterTests`
  - 运行 `xcodebuild build -scheme SquatCounterWatchApp -destination 'generic/platform=watchOS Simulator'`
  - 对照 `TASK_005`、`CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS`，确认当前状态与范围一致

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
