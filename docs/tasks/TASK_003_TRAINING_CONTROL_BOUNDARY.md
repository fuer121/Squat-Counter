# Task Contract 003

## 基本信息

- 任务名称：6.4 训练控制能力边界冻结（`TimerManager` / `HapticManager`）
- 任务目标：在不进入实现的前提下，先冻结 `TimerManager` 与 `HapticManager` 的职责、触发点、与 `WorkoutSessionViewModel` 的边界，以及首批测试范围，为下一阶段实现提供唯一有效执行口径
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent`
- 协作方：`总控 Agent`、`产品 Agent`、`测试 Agent`、`UI Agent`
- 是否需要总控介入：`是`

## 输入与输出

- 输入文档：
  - `AGENTS.md`
  - `docs/agents/AGENT_SYSTEM.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/planning/RISKS.md`
  - `docs/release/TEST_MATRIX.md`
- 输入代码范围：
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Models/WorkoutProgress.swift`
  - `Shared/Models/WorkoutState.swift`
  - `Shared/Models/PauseContext.swift`
  - `SquatCounterWatchExtension/Features/Home/WatchArchitectureOverviewView.swift`
  - `SquatCounterTests/WorkoutConfigTests.swift`
- 预期输出：
  - `TimerManager` 是否统一覆盖 `countdown` 与 `resting` 的正式判断
  - `HapticManager` 最小职责与首批触发点清单
  - `WorkoutSessionViewModel` 与两个 manager 的冻结边界
  - 倒计时 / 休息 / 暂停 / 结束训练的产品边界、异常路径与关键文案
  - 首批测试范围与排除项
  - 进入实现阶段前的总控 checkpoint 结论

## 执行边界

- 可修改文件范围：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - 下一阶段实现生效后，代码范围先收敛在：
  - `Shared/Models/`
  - `Shared/` 下与训练控制直接相关的代码
  - `SquatCounterWatchExtension/`
  - `SquatCounterTests/`
- 不可擅自变更项：
  - 不进入 `TimerManager` / `HapticManager` 实现编码
  - 不扩展到真实动作识别
  - 不扩展到 `iPhone companion` 新功能
  - 不调整同步链路边界
  - 不进入 `HealthKit` 完整实现
  - 不新增 `WorkoutState` 顶层状态
  - 不顺手重构无关模块
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务属于总控冻结边界与测试口径，不是中等以上实现任务；文件范围集中，且用户未确认切换到子线程或 worktree

## 边界冻结结论

- `TimerManager` 统一覆盖 `countdown` 与 `resting`，并为训练态的节奏提示提供同一套计时能力入口；但同一时刻只允许存在一个激活中的训练控制计时上下文，不并行维护多个倒计时源
- `HapticManager` 的最小职责是：接收训练控制事件并触发对应反馈，不拥有训练状态，不直接修改 `WorkoutProgress`，也不直接驱动页面跳转
- `HapticManager` 首批冻结触发点为：
  - 训练前倒计时关键 tick / 完成
  - 组间休息完成或被提前跳过后进入下一组
  - 单次计数确认
  - 训练态节奏提示
- `WorkoutSessionViewModel` 继续作为训练状态与进度的唯一状态源，负责：
  - 决定何时启动、暂停、恢复、取消、结束计时
  - 消费计时事件并执行 `countdown -> training`、`resting -> training` 等状态流转
  - 决定何时请求震动反馈
- `TimerManager` 只输出时间事件，不直接写入 `WorkoutState`
- `HapticManager` 只执行反馈策略，不直接读取或修改界面状态
- `remainingRestSeconds` 继续只表示 `resting` 剩余时间，不与训练前倒计时复用语义

## 产品侧补充口径

- 倒计时态产品规则：
  - 仅支持 `取消`，不提供 `暂停`、`结束训练`、`+1 / -1`
  - 倒计时取消后直接回 `idle`，不保留任何中间进度或残留反馈
- 休息态产品规则：
  - `休息自然结束` 与 `提前开始下一组` 共享同一条“进入下一组训练”语义
  - 若用户手动提前开始，不得在稍后再补发一次“休息结束”状态切换或反馈
  - 休息态暂停恢复后继续剩余秒数，不重置为配置中的完整休息时长
- 震动优先级规则：
  - `训练完成` > `单组完成 / 进入下一组` > `单次计数成功` > `节奏提示`
  - 命中更高优先级事件时，低优先级反馈必须被抑制，不做连续叠加
- 暂停与结束训练规则：
  - `paused` 仅允许从 `training` 或 `resting` 进入
  - 暂停态允许结束训练，但确认后必须直接丢弃当前进度并回首页
- 关键文案冻结：
  - 倒计时：`准备开始` / `取消`
  - 训练中：`训练中` / `暂停` / `结束`
  - 暂停中：`已暂停` / `继续训练` 或 `继续休息`
  - 休息中：`本组完成` / `即将开始第 N 组` / `提前开始`
  - 结束确认：`结束本次训练？` / `当前进度将被丢弃` / `结束训练` / `继续训练`
  - 完成页：`训练完成` / `再来一次` / `返回首页`

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 如何在最小状态机落地后，继续通过“控制器下沉”而不是“状态扩张”推进训练闭环
  - 如何先冻结 manager 与 ViewModel 边界，再进入 watchOS 系统能力接入

## 验收与风险

- 验收标准：
  - 已明确 `TimerManager` 统一覆盖 `countdown` 与 `resting`
  - 已明确 `HapticManager` 的最小职责与首批触发点
  - 已明确 `WorkoutSessionViewModel` 仍是唯一训练状态源，manager 不直接改状态
  - 已明确倒计时不可暂停、不可手动修正、仅允许取消返回首页
  - 已明确休息自然结束与提前开始下一组共用同一状态语义与单次反馈
  - 已明确震动冲突遵循高优先级事件覆盖低优先级事件，不做重复叠加
  - 已明确训练页、休息页、暂停态与结束确认的关键文案口径
  - 已明确首批测试至少覆盖倒计时、组间休息、提前开始下一组、暂停恢复、节奏提示与计数反馈优先级
  - 已明确排除真实识别、同步链路、`HealthKit`、companion 新功能和无关重构
- 风险与依赖：
  - companion 同步链路尚未落地，当前任务不得反向侵入同步边界
  - `Health app` 写入仍是中风险事项，本任务不吸收该复杂度
  - 真实动作识别准确率是高风险事项，本任务只保留与未来识别接入兼容的状态边界
  - watchOS 真机震动体验需要后续真机验证，当前仅冻结代码职责，不宣称体验完成
- 最快验证方式：
  - 对照 `PROJECT_WBS` 的 6.4 验收项确认职责与触发点无缺项
  - 对照现有 `WorkoutSessionViewModel` 与测试，确认新增 manager 不改写既有状态主导权

## 首批测试范围冻结

- 单元测试：
  - `TimerManager` 覆盖训练前倒计时、组间休息、暂停 / 恢复、取消 / 跳过
  - `HapticManager` 覆盖事件映射与“计数反馈优先于节奏提示”的冲突处理
  - `HapticManager` 覆盖“训练完成覆盖单组完成与普通计数反馈”的冲突处理
- 集成测试：
  - `WorkoutSessionViewModel` 配合测试替身，覆盖 `startWorkout -> countdown -> training`
  - `WorkoutSessionViewModel` 配合测试替身，覆盖单组完成进入 `resting`，休息结束自动进入下一组
  - `WorkoutSessionViewModel` 配合测试替身，覆盖“提前开始下一组”与休息态暂停 / 恢复
  - `WorkoutSessionViewModel` 配合测试替身，覆盖倒计时态无 `pause` / `+1` / `-1` 入口时的状态约束
- 暂不纳入首批范围：
  - 真实动作识别联调
  - `iPhone <-> Watch` 同步验证
  - `HealthKit` 授权与写入
  - 无关 UI 重构与快照测试

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
