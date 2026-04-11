# Task Contract 009

## 基本信息

- 任务名称：6.7 跨设备同步前置边界冻结 / 实现准备
- 任务目标：在不进入 `6.7` 同步实现编码的前提下，冻结 `1.0` 首批跨设备同步范围、用户可见承载方式、冲突与重试边界、验证口径和实现文件边界，为后续 `6.7` 同步实现任务提供唯一有效执行口径
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent 1`
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
  - `Shared/Sync/SyncPayload.swift`
  - `Shared/Sync/WatchConnectivitySyncing.swift`
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Models/WorkoutState.swift`
  - `Shared/Models/WorkoutProgress.swift`
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionViewModel.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionHomeView.swift`
- 预期输出：
  - `6.7` 首批同步范围的正式冻结结论
  - iPhone / Watch 的用户可见承载方式冻结结论
  - 同步冲突规则、失败与重试边界
  - 最小测试与真机验证口径
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
  - 不进入任何 `6.7` 同步实现代码
  - 不改写 `6.4` / `6.5` / `6.6` 已冻结职责边界和既有实现
  - 不新增历史页、结果页、实时训练控制或实时状态镜像
  - 不在本轮补充 `WatchConnectivity` 具体 transport、签名、权限或真机调试代码
  - 不创建实现 PR
  - 不自动合并 `main`
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务属于同步边界冻结、实现准备和共享文档回写；影响文件少，目标是先统一跨设备同步口径，再由总控决定是否进入后续实现任务

## 首批同步范围冻结

- `1.0` 首批 `6.7` 同步正式冻结为两条链路：
  - `iPhone -> Watch`：同步默认训练参数 `WorkoutConfig`
  - `Watch -> iPhone`：回传最近一次训练摘要 `WorkoutSummary`
- `WatchStateSnapshot` 继续保留在 `SyncPayload` 中，但不纳入 `1.0` 首批用户可见范围：
  - 不进入 iPhone 实时状态镜像
  - 不进入 Watch 侧当前训练会话的反向控制
  - 不作为本轮必须落地的 UI 承载物
- 首批同步明确不吸收以下范围：
  - 历史页 / 训练结果列表
  - iPhone 侧实时训练状态镜像
  - iPhone 侧开始训练、暂停、恢复、结束训练、手动 `+1 / -1`
  - 云同步、多设备一致性、后台长期补偿队列

## 用户可见承载方式冻结

- `WorkoutConfig` 的可见承载方式：
  - iPhone 继续作为默认参数编辑入口
  - Watch 继续作为训练主端和训练参数实际消费端
  - 配置同步的用户感知以“Watch 下一次训练 / 设置默认值已采用最新参数”为准，不新增独立同步中心或复杂同步状态页
- `WorkoutSummary` 的可见承载方式：
  - `1.0` 不新增历史页或独立结果页
  - 若首批回传结果需要用户可见承载，仅允许以 iPhone companion 首页中的“最近一次训练摘要”单卡 / 单 section 形式出现
  - 该承载方式只展示最近一次训练的最小摘要，不扩展为列表、筛选、详情页或成就入口
- `WatchStateSnapshot` 的可见承载方式：
  - `1.0` 明确不做用户可见承载
  - 仅保留为后续版本可能使用的 transport / 抽象预留

## 同步真源与冲突边界冻结

- Watch 继续作为训练主状态、训练进度和训练结果的唯一真源
- iPhone 不拥有进行中训练、休息、暂停、完成等实时业务真相
- `WorkoutConfig` 冲突规则冻结为：
  - 默认参数可在 iPhone 与 Watch 两端被编辑
  - 同步后的默认配置以 `SyncPayload.updatedAt` 最新值为准
  - 若 Watch 已处于一次已启动的训练会话中，收到新的 `WorkoutConfig` 也不能改写当前会话；只影响下一次进入设置页或下一次训练开始前的默认值
- `WorkoutSummary` 冲突规则冻结为：
  - 只能由 Watch 在训练完成后生成并回传
  - iPhone 不允许编辑、补写、拼接或发明训练结果
  - iPhone 对同一条训练摘要必须具备幂等去重能力，至少以 `WorkoutSummary.id` 作为去重依据

## 失败与重试边界冻结

- `1.0` 不提供独立“同步中心”、手动重试列表或用户可控的队列管理界面
- 重试策略冻结为“轻量、有限、不可阻塞训练主流程”：
  - 配置同步失败时，保留最新默认参数作为待同步值；后续连接恢复时只需要保证最新值最终覆盖旧值
  - 训练结果回传失败时，允许在不阻塞 Watch 训练主流程的前提下做有限补发；但不能因此拉高为完整历史补偿系统
  - 同步失败不能阻塞 Watch 本地训练闭环，也不能把 iPhone 页面降级为错误态主流程
- 当前阶段不冻结具体 transport API、队列长度、后台唤醒策略或系统级重试次数；这些实现细节留待后续 `6.7` 实现任务承接

## 测试与真机验证口径冻结

- 单元 / 共享层验证：
  - `SyncPayload` 对 `config / summary / snapshot` 的编码解码保持稳定
  - `WorkoutConfig` 同步冲突遵循“最新 `updatedAt` 生效，但不改写当前训练会话”
  - `WorkoutSummary` 在 iPhone 侧具备幂等去重基础
- 集成验证：
  - iPhone 修改默认参数后，Watch 在下一次进入训练设置 / 训练前可见并应用最新值
  - Watch 完成训练后，iPhone 最多只看到一条最近一次训练摘要承载，不出现历史列表
  - 断连恢复后，同步补发不会把 iPhone 拉成训练主状态，也不会污染 Watch 当前训练会话
- 真机验证口径：
  - 必须在真实配对的 iPhone + Apple Watch 上验证配置下发、训练结果回传和断连恢复
  - 仅模拟器或仅单端构建通过，不足以宣称 `6.7` 完成
- 明确排除项：
  - 实时镜像延迟优化
  - 复杂冲突 UI
  - 多条训练记录浏览与删除
  - 上述内容均不属于 `1.0` 首批 `6.7`

## 实现准备结论

- 后续 `6.7` 实现任务必须至少承接以下共享抽象：
  - `SyncPayload.config`
  - `SyncPayload.workoutSummary`
  - `WatchConnectivitySyncing`
- 后续 `6.7` 实现任务若要消费 `WatchStateSnapshot`，必须先补充新的 Task Contract 和共享文档边界，不得直接在本轮冻结口径上顺手扩展
- `6.6` 已落地的 iPhone companion 页面层边界继续有效：
  - 页面层不直接操作 transport
  - 页面层不直接发明训练主状态
  - 页面层不直接变成历史页 / 结果页 / 实时控制页

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 如何在“页面边界已冻结”后，再单独冻结“同步范围、可见承载方式和冲突规则”，避免跨端职责串扰
  - 如何把“首批可见同步能力”压缩为最小单卡承载，而不是直接扩张为结果页 / 历史系统

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_009` 契约文档
  - 已明确 `6.7` 首批同步范围
  - 已明确配置同步、训练结果回传和 `WatchStateSnapshot` 的用户可见承载方式
  - 已明确冲突与重试边界
  - 已明确测试与真机验证口径
  - 已完成共享文档回写，且未触碰任何 `6.4` / `6.5` / `6.6` 实现代码
- 风险与依赖：
  - `WorkoutSummary` 虽已在共享层定义，但当前 Watch 侧尚未形成正式组装与发送链路；后续实现任务需要补齐
  - `WatchConnectivitySyncing` 当前仍是 `NoopSyncCoordinator`；本轮只能冻结职责和边界，不能证明链路可用
  - 若总控后续判断 `1.0` 不需要“最近一次训练摘要”可见承载，必须先更新共享文档，再调整实现任务范围
- 最快验证方式：
  - 对照 `TASK_009`、`CURRENT_SPRINT`、`PROJECT_WBS`、`DECISIONS`、`RISKS`，检查 `6.7` 口径是否一致
  - 检查本轮提交是否只修改共享文档，未进入任何实现代码与 PR 流程

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
