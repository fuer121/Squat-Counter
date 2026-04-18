# Task Contract 010

## 基本信息

- 任务名称：6.7 跨设备同步首批实现（基于 `TASK_009` 已冻结边界）
- 任务目标：在 `TASK_009` 已冻结的首批同步范围、可见承载方式、冲突与重试边界内，完成 `WorkoutConfig` 的 `iPhone -> Watch` 下发、最近一次 `WorkoutSummary` 的 `Watch -> iPhone` 回传，以及与此直接相关的最小测试和真机验证准备，形成可供总控 checkpoint 使用的正式实现契约
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent 1`
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
  - `docs/tasks/TASK_009_CROSS_DEVICE_SYNC_BOUNDARY.md`
- 输入代码范围：
  - `Shared/Sync/SyncPayload.swift`
  - `Shared/Sync/WatchConnectivitySyncing.swift`
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Models/WorkoutState.swift`
  - `Shared/Models/WorkoutProgress.swift`
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionViewModel.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionHomeView.swift`
- 预期输出：
  - `6.7` 首批跨设备同步实现文件范围
  - 配置下发与最近一次训练摘要回传的最小实现闭环
  - 与 `6.7` 直接相关的最小测试与真机验证口径
  - 可供总控 checkpoint 使用的实现边界与排除项

## 执行边界

- 可修改文件范围：
  - 共享层：
    - `Shared/Sync/`
    - `Shared/Models/WorkoutConfig.swift`
    - `Shared/Models/WorkoutState.swift`
    - `Shared/Models/WorkoutProgress.swift`
    - 必要时新增与同步直接相关的共享模型 / 适配器文件，但仅限 `Shared/Sync/` 与 `Shared/Models/`
  - iPhone 侧：
    - `SquatCounteriOS/App/`
    - `SquatCounteriOS/Features/Home/`
    - 仅允许为同步接线、最近一次训练摘要最小承载和状态提示做改动
  - Watch 侧：
    - `SquatCounterWatchExtension/`
    - 仅允许为同步接收默认配置、发送最近一次训练摘要和必要适配点做改动
  - 测试：
    - `SquatCounterTests/`
  - 必要时：
    - `docs/tasks/`
    - `docs/planning/CURRENT_SPRINT.md`
    - `docs/planning/PROJECT_WBS.md`
    - `docs/planning/RISKS.md`
- 不可擅自变更项：
  - 不改写 `TASK_009` 已冻结的首批同步范围、可见承载方式、冲突与重试边界
  - 不新增历史页、结果页、实时训练状态镜像、同步中心或手动重试队列
  - 不让 iPhone 获得训练主状态、训练控制或进行中训练真相
  - 不把 `WatchStateSnapshot` 变成首批用户可见能力
  - 不顺手重构 `6.4` / `6.5` / `6.6` 无关模块
  - 在总控 checkpoint 前不创建实现 PR
- 是否允许自动化执行：`是`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务承接 `TASK_009` 已冻结边界，目标是进入首批同步实现；修改范围集中在共享层、iPhone companion 首页、Watch 训练主流程接线与测试，不需要再拆新 worktree

## 继承口径

- 本任务严格继承 `TASK_009` 已冻结结论：
  - `1.0` 首批同步只包含 `WorkoutConfig` 下发与最近一次 `WorkoutSummary` 回传
  - `WatchStateSnapshot` 继续保留为非首批用户可见预留
  - 若需要结果可见承载，仅允许以 companion 首页中的“最近一次训练摘要”单卡 / 单 section 形式出现
  - 默认参数冲突以 `SyncPayload.updatedAt` 最新值为准，但不改写已启动的 Watch 当前训练会话
  - 重试必须轻量、有限、不可阻塞训练主流程

## 首批实现闭环范围

- 本轮必须落地的同步闭环：
  - iPhone 修改默认参数后，可通过同步链路把最新 `WorkoutConfig` 下发到 Watch 默认配置
  - Watch 完成一次训练后，可回传最近一次 `WorkoutSummary` 到 iPhone
  - iPhone companion 首页在已有信息架构内，最多承接一个“最近一次训练摘要”展示区块
- 本轮最小用户感知：
  - iPhone 端默认参数不再只停留在本地存储，而是可在 Watch 下一次训练前被消费
  - iPhone 端最多看到最近一次训练摘要，不出现历史列表或详情页
  - 同步失败不阻塞 Watch 本地训练闭环

## 共享层 / iPhone / Watch / 测试文件范围说明

- 共享层允许改动：
  - `SyncPayload`：只允许做首批闭环所需的稳定化、编码解码、辅助构造或时间戳使用约束
  - `WatchConnectivitySyncing`：允许从 `NoopSyncCoordinator` 演进为真实同步抽象及其最小实现接线
  - `WorkoutConfig` / `WorkoutState` / `WorkoutProgress`：仅允许为首批同步闭环补最小辅助字段或映射，不得改写既有训练边界
- iPhone 侧允许改动：
  - `PhoneCompanionViewModel`：允许增加同步发送触发、最近一次训练摘要接收与最小状态提示
  - `PhoneCompanionHomeView`：允许增加最近一次训练摘要最小展示区块与“默认参数已同步到下一次训练”的有限提示
  - 不允许新增历史页、结果详情页、实时状态页
- Watch 侧允许改动：
  - 训练设置默认值接收逻辑
  - 训练完成后 `WorkoutSummary` 组装与回传触发
  - 与当前训练会话隔离的默认配置应用逻辑
  - 不允许因此改写训练主状态机核心职责
- 测试允许改动：
  - 共享层同步 payload 与冲突规则测试
  - iPhone 侧最近一次训练摘要接收与展示条件测试
  - Watch 侧配置接收 / 训练结果回传最小行为测试

## 最小验证方式

- 单元 / 模块测试：
  - `SyncPayload` 的 `config / workoutSummary` 编码解码与构造行为正确
  - 同步后的 `WorkoutConfig` 只影响下一次训练默认值，不改写已启动会话
  - `WorkoutSummary` 幂等去重基础成立
  - iPhone 首页最多展示最近一次训练摘要一条，不出现列表
- 构建验证：
  - `xcodebuild build -scheme SquatCounter -destination 'platform=iOS Simulator,name=iPhone 17'`
  - `xcodebuild build -scheme SquatCounter -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm)'`
- 真机验证：
  - 必须在真实配对的 iPhone + Apple Watch 上验证：
    - 默认参数从 iPhone 下发到 Watch
    - Watch 完成训练后最近一次训练摘要能回到 iPhone
    - 断连恢复后不阻塞 Watch 本地训练闭环
- 验证声明规则：
  - 仅构建通过或仅模拟器验证，不得声称 `6.7` 跨设备闭环完成

## 本任务明确不吸收的范围

- `WatchStateSnapshot` 用户可见化
- 历史页 / 结果页 / 结果详情页
- iPhone 实时训练状态镜像
- iPhone 训练控制
- 同步中心、手动重试队列、复杂冲突 UI
- 云同步、多设备一致性、跨设备历史累积
- HealthKit、提审素材、权限文案补齐

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_010` 实现契约文档
  - 已明确共享层、iPhone 侧、Watch 侧和测试文件的允许修改范围
  - 已明确 `6.7` 首批实现闭环与最小用户感知
  - 已明确最小验证方式与真机验证要求
  - 已明确排除项，且不改写 `TASK_009` 冻结边界
  - 已完成共享文档回写，且未进入任何实现代码
- 风险与依赖：
  - `WatchConnectivity` 真机可用性、配对状态与时序稳定性仍是实现期主风险
  - 当前 Watch 端尚无正式训练摘要发送链路，后续实现需要谨慎接入训练完成节点
  - 若后续总控要求取消“最近一次训练摘要”可见承载，必须先更新共享文档，再缩减实现范围
- 最快验证方式：
  - 对照 `TASK_009`、`TASK_010`、`CURRENT_SPRINT`、`PROJECT_WBS`、`DECISIONS`、`RISKS`，检查 `6.7` 口径是否一致
  - 检查本轮提交是否只修改共享文档，未进入任何实现代码与 PR 流程

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
