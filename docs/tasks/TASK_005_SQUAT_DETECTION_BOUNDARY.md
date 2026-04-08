# Task Contract 005

## 基本信息

- 任务名称：6.5 动作识别前置边界冻结 / 实现准备（`SquatDetectionManager`）
- 任务目标：在不进入动作识别实现编码的前提下，冻结 `SquatDetectionManager` 的职责边界、首批实现范围、与 `WorkoutSessionViewModel` / `TimerManager` / `HapticManager` 的接口边界，以及首批测试与真机验证口径，为后续 `6.5` 实现任务提供唯一有效执行口径
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`
- 后续承接：`6.5` 实现阶段由 `docs/tasks/TASK_006_SQUAT_DETECTION_IMPLEMENTATION.md` 承接；本任务只覆盖边界冻结与实现准备

## owner 与协作

- 直接 owner：`开发 Agent`
- 协作方：`总控 Agent`、`产品 Agent`、`测试 Agent`
- 是否需要总控介入：`是`

## 输入与输出

- 输入文档：
  - `AGENTS.md`
  - `docs/agents/AGENT_SYSTEM.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/planning/RISKS.md`
  - `PRD/PRD_V1.md`
- 输入代码范围：
  - `Shared/Models/SquatDetectionEvent.swift`
  - `Shared/Models/SquatMotionState.swift`
  - `Shared/Models/WorkoutState.swift`
  - `Shared/TrainingControl/TimerManager.swift`
  - `Shared/TrainingControl/HapticManager.swift`
  - `SquatCounterTests/WorkoutConfigTests.swift`
- 预期输出：
  - `SquatDetectionManager` 只输出识别事件、不直接改 UI 的正式边界定义
  - “模拟识别模式”是否作为首批联调入口的正式判断
  - 识别状态机、`cooldown`、防误触、可调阈值是否属于 `6.5` 首批实现范围的正式判断
  - 与 `WorkoutSessionViewModel`、`TimerManager`、`HapticManager` 的冻结接口边界
  - 首批测试与真机验证口径
  - 可供总控 checkpoint 使用的共享文档回写结果

## 执行边界

- 可修改文件范围：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - 必要时：
  - `docs/planning/DECISIONS.md`
  - `docs/planning/RISKS.md`
- 不可擅自变更项：
  - 不进入任何动作识别实现编码
  - 不修改 `6.4` 已合入的 `TimerManager`、`HapticManager`、`WorkoutSessionViewModel` 代码
  - 不创建 PR
  - 不扩展到 `iPhone companion`、跨设备同步、`HealthKit`、多动作识别
  - 不新增未在基线文档确认的页面状态或用户可见配置项
  - 不顺手重构无关模块
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务属于边界冻结、实现准备和共享文档回写，影响文件少，不涉及中等以上编码规模；按协作规则先在当前开发执行线程内完成契约与边界确认，再由总控决定后续实现任务的线程与交付方式

## 边界冻结结论

- `SquatDetectionManager` 的唯一职责是采集动作信号并输出 `SquatDetectionEvent`
- `SquatDetectionManager` 不直接读取或修改页面状态，不直接修改 `WorkoutProgress`，不直接触发页面跳转，不直接播放震动
- `SquatDetectionManager` 对外只暴露“训练态开始识别、暂停识别、恢复识别、停止识别”和“输出识别事件”两类语义；具体函数命名留待后续实现任务与现有代码风格对齐，本任务不先行发明细节 API
- `SquatDetectionEvent.repDetected` 是首批必需事件，作为训练计数唯一识别入口
- `SquatDetectionEvent.motionStateChanged` 仅保留为可选调试事件，不作为首批 UI 驱动入口；即使后续接入，也必须由 `WorkoutSessionViewModel` 消费后再决定是否对界面做非关键展示

## 首批实现范围冻结

- 先落“模拟识别模式”作为 `6.5` 首批联调入口：`是`
- 冻结理由：
  - `CURRENT_SPRINT` 已明确“用模拟识别先完成可联调闭环”
  - `PROJECT_WBS` 已将“实现模拟识别模式”列为 `6.5` 的 `P0`
  - 高风险项“动作识别准确率不可控”要求先用最小可验证方案收敛主流程风险
- 模拟识别模式的边界：
  - 仅作为开发 / 联调入口，不作为 `1.0` 面向用户的公开配置项
  - 目标是打通 `WorkoutSessionViewModel` 消费识别事件后的训练主流程，不替代真实识别验收
- 以下能力属于 `6.5` MVP 首批实现范围，但不属于本次前置冻结任务的编码输出：
  - 简化识别状态机：`standing -> descending -> bottom -> ascending -> repCompleted`
  - 单次计数后的 `cooldown`
  - 防误触基线规则：半蹲、抬腕、轻微晃动、小幅下沉不应计数
  - 内部可调阈值结构：最小动作幅度、站立稳定判定、低点阈值、回正阈值、计数冷却时间
- 首批实现顺序冻结为：
  - 第一步：`SquatDetectionManager` 事件接口 + 模拟识别模式 + `WorkoutSessionViewModel` 联调接入
  - 第二步：简化识别状态机 + `cooldown` + 防误触基线 + 内部可调阈值
  - 第三步：真机识别调优与参数回收

## 与现有模块的接口边界冻结

- 与 `WorkoutSessionViewModel`：
  - `WorkoutSessionViewModel` 继续作为训练状态、训练进度和组完成判定的唯一状态源
  - `WorkoutSessionViewModel` 负责决定何时启动、暂停、恢复、停止识别
  - `WorkoutSessionViewModel` 负责消费 `repDetected` 并执行计数、组完成、休息切换、训练完成等业务逻辑
  - 非 `training` 状态下的识别输出必须被停止或忽略，不能越过 ViewModel 直接生效
- 与 `TimerManager`：
  - `TimerManager` 继续只负责 `countdown`、`resting`、`tempo cue`
  - 动作识别的采样节奏、状态机推进和 `cooldown` 不复用 `TimerManager` 语义
  - `SquatDetectionManager` 不直接启动、暂停、恢复、取消训练控制计时
- 与 `HapticManager`：
  - 动作识别模块不直接请求震动
  - 单次计数成功后的反馈仍由 `WorkoutSessionViewModel` 在消费 `repDetected` 后，通过 `HapticManager` 统一触发
  - 震动优先级继续沿用 `6.4` 已冻结规则，不由动作识别模块重定义

## 首批测试与真机验证口径冻结

- 单元测试：
  - 模拟识别模式可稳定输出预期 `SquatDetectionEvent`
  - 简化识别状态机按 `standing -> descending -> bottom -> ascending -> repCompleted` 闭环推进
  - `cooldown` 生效时，同一动作闭环不会重复计数
  - 内部可调阈值具备默认值与边界值校验口径
  - 半蹲、抬腕、轻微晃动、小幅下沉等输入不应触发 `repDetected`
- 集成测试：
  - `WorkoutSessionViewModel` 仅在 `training` 状态消费 `repDetected`
  - `repDetected` 可驱动当前次数、组完成、休息切换、训练完成闭环
  - `paused`、`resting`、`completed`、`idle` 状态下不会继续累计识别结果
  - 动作识别模块不会直接改 UI、不会直接驱动计时器、不会直接触发震动
- 真机验证口径：
  - 正常深蹲节奏下能完成基本计数
  - 半蹲、抬腕查看屏幕、原地晃动尽量不计数
  - 暂停训练、进入休息、结束训练后识别停止
  - `cooldown` 生效时单次动作不重复计数
  - 真机验证结果只作为后续调优依据，不反向扩大 `6.5` 范围到复杂算法

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 如何在高风险识别模块落地前，先用“模拟事件源”建立联调入口
  - 如何冻结“识别只输出事件、ViewModel 统一消费”的模块边界，避免算法直接侵入 UI 与训练状态

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_005` 契约文档
  - 已明确 `SquatDetectionManager` 只输出事件、不直接改 UI 或训练状态
  - 已正式冻结“模拟识别模式”为 `6.5` 首批联调入口
  - 已正式冻结简化识别状态机、`cooldown`、防误触、内部可调阈值属于 `6.5` MVP 首批实现范围
  - 已明确与 `WorkoutSessionViewModel`、`TimerManager`、`HapticManager` 的接口边界
  - 已明确首批测试与真机验证口径
  - 已完成共享文档回写，且未触碰 `6.4` 已合入实现
- 风险与依赖：
  - 动作识别准确率仍是高风险，后续必须通过真机调优收敛
  - 模拟识别模式只能证明主流程联通，不能替代真实识别质量验收
  - `6.4` 训练控制已合入主线，`6.5` 不得反向侵入其职责边界
- 最快验证方式：
  - 检查 `TASK_005`、`CURRENT_SPRINT`、`PROJECT_WBS` 对 `6.5` 的描述是否一致
  - 检查本轮提交是否只修改共享文档、未触碰 `6.4` 代码与 PR 流程

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
