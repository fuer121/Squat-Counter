# Task Contract 007

## 基本信息

- 任务名称：6.6 iPhone Companion 前置边界冻结 / 实现准备
- 任务目标：在不进入 iPhone Companion 功能实现编码的前提下，冻结 `1.0` 中 iPhone Companion 的职责边界、首批页面范围、与 Watch 端 / `6.7` 同步链路的接口边界、Figma 设计资产判断，以及首批测试与真机验证口径，为后续 `6.6` 实现任务提供唯一有效执行口径
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent 1`
- 协作方：`总控 Agent`、`产品 Agent`、`UI Agent`、`测试 Agent`
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
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `Shared/Sync/SyncPayload.swift`
  - `Shared/Sync/WatchConnectivitySyncing.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionViewModel.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionHomeView.swift`
- 预期输出：
  - `1.0` 中 iPhone Companion 的正式职责边界
  - 首批页面范围与“历史页是否进入 `1.0`”的正式判断
  - iPhone Companion 与 Watch 端、`6.7` 同步链路的冻结接口边界
  - “首批页面是否需要先做 Figma 设计资产”的正式判断
  - 首批测试与真机验证口径
  - 可供总控 checkpoint 使用的共享文档回写结果

## 执行边界

- 可修改文件范围：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - 必要时：
  - `docs/planning/RISKS.md`
- 不可擅自变更项：
  - 不进入任何 iPhone Companion 代码实现
  - 不修改 Watch 端既有实现和 `6.5` 已冻结职责边界
  - 不提前实现 `6.7` 同步逻辑，只允许冻结接口与责任边界
  - 不新增未在基线文档确认的 `1.0` 页面、账号、云同步、历史页增强或实时联动能力
  - 不创建 PR
  - 不顺手重构无关模块
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务属于边界冻结、实现准备和共享文档回写，影响文件少，不涉及中等以上编码规模；应先在当前开发执行线程内完成正式契约与共享口径统一，再由总控决定是否进入后续实现任务

## 边界冻结结论

- iPhone Companion 在 `1.0` 中只承担四类职责：
  - 首次启动引导：解释 `iPhone + Watch companion` 形态、Watch 为训练主端、以及使用路径与权限原因
  - 默认训练参数配置：围绕共享模型 `WorkoutConfig` 管理默认 `reps / sets / rest`
  - 帮助与支持：承载 FAQ、支持入口、隐私政策等静态辅助信息
  - 基础设置：只保留 companion 自身的轻量信息项，不扩展为训练过程控制面板
- iPhone Companion 不承担以下职责：
  - 不作为训练主状态源
  - 不展示或控制进行中的 Watch 训练会话
  - 不提供实时计数、暂停 / 恢复、结束训练、手动 `+1 / -1`
  - 不在 `6.6` 中承接训练结果回传、同步重试、冲突解决或实时状态镜像

## 首批页面范围冻结

- `1.0` 首批独立页面冻结为：
  - 首次启动引导页
  - 默认参数配置页
  - 帮助与支持页
- “基础设置”不作为 `1.0` 首批独立页面；若需要展示版本信息、隐私政策或帮助入口，应并入“帮助与支持”信息架构
- “历史页”不纳入 `1.0`
- 冻结理由：
  - `PRD_V1` 已将“训练历史记录”和“iPhone 复杂联动”列为 MVP 暂不覆盖范围
  - 当前阶段优先目标是先完成 Watch 主流程和 iPhone 基础配置闭环，再进入 `6.7` 同步
  - 若在 `6.6` 提前吸收历史页，会与 `PRD` 的 MVP 边界冲突，并扩大 `6.7` 训练结果回传依赖

## 与 Watch 端 / 6.7 的接口边界冻结

- 与 Watch 端：
  - Watch 继续作为训练主状态、训练进度和训练结果的唯一真源
  - iPhone Companion 仅管理“默认配置”的展示与编辑，不直接驱动当前训练会话
  - iPhone 侧页面状态不能越过 Watch 主状态源，单独发明进行中训练、暂停态或完成态的业务真相
- 与 `6.7` 同步链路：
  - `6.6` 只冻结“数据归属与页面消费边界”，不实现传输
  - `WorkoutConfig` 是 `6.6` 首批 companion 页面唯一必需的共享输入模型
  - `SyncPayload.config` 是后续 `iPhone -> Watch` 默认配置同步的正式承接载体
  - `SyncPayload.workoutSummary` 与 `SyncPayload.watchStateSnapshot` 保留给 `6.7` 及其后续能力使用，不进入 `6.6` 首批 UI 范围
  - `WatchConnectivitySyncing` 继续作为同步 transport 抽象，由 `6.7` 承接；`6.6` 页面层不直接拥有重试、冲突处理、时序控制和可用性兜底逻辑

## Figma 设计资产判断

- 正式判断：首批 iPhone Companion 页面不要求“先完成 Figma 设计资产”才可进入 `6.6` 实现
- 冻结理由：
  - 首批页面以信息架构、文案和系统控件为主，复杂视觉和动效不是当前主风险
  - 当前更高优先级是先冻结职责边界、页面范围和同步责任，避免 `6.6 / 6.7` 交叉返工
- 同时明确：
  - 在进入 App Store 截图制作、UI 定稿或需要统一视觉语言前，应由 `UI Agent` 补齐首批 iPhone 页面设计资产
  - Figma 在本轮不是实现前置阻塞项，但会是后续截图与提审素材阶段的重要输入

## 首批测试与真机验证口径冻结

- 单元 / 特性测试：
  - iPhone Companion 对 `WorkoutConfig` 的默认参数编辑必须遵守共享范围约束
  - 默认参数的本地持久化必须在重启后保持一致
  - `6.6` 页面层不得直接修改 `WorkoutState`、`WorkoutProgress` 或其他 Watch 训练真相
  - `1.0` 首批 companion UI 不应暴露历史页、实时训练控制或训练结果列表
- 集成验证：
  - iPhone 端在没有 Watch 连接或 `6.7` 同步尚未实现时，仍可完成引导、默认参数配置、帮助与支持浏览
  - `6.6` 不得声称“配置已实时应用到 Watch”或“训练结果已回传到 iPhone”
  - “帮助与支持”承载的静态入口不应反向引入训练主流程依赖
- 真机验证口径：
  - iPhone 首次启动可顺利完成引导并理解 Watch 主端定位
  - 默认参数编辑后重启 iPhone 仍能保留本地结果
  - 无论 Watch 当前是否在线，iPhone Companion 的引导、配置、帮助与支持页面都可独立访问
  - `1.0` 设备侧不出现历史页入口，不出现进行中训练控制承诺
- 明确排除项：
  - `iPhone -> Watch` 配置同步成功
  - `Watch -> iPhone` 训练结果回传成功
  - 断连重试、冲突规则、最近状态摘要展示
  - 上述内容均留待 `6.7` 任务承接

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 如何在 PRD 与 WBS 出现页面范围冲突时，用 Task Contract 先冻结 `1.0` 页面边界，再进入实现
  - 如何将“页面职责”和“同步 transport 职责”拆开，避免 companion 页面层过早侵入跨设备同步

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_007` 契约文档
  - 已明确 `1.0` 中 iPhone Companion 的职责边界
  - 已正式冻结首批页面范围，并明确历史页不纳入 `1.0`
  - 已明确与 Watch 端、`6.7` 同步链路的接口边界
  - 已明确“Figma 设计资产不是首批实现前置阻塞项”的判断
  - 已明确首批测试与真机验证口径
  - 已完成共享文档回写，且未触碰任何 iPhone / Watch 实现代码
- 风险与依赖：
  - `6.7` 同步链路尚未实现，`6.6` 只能冻结配置输入，不证明跨设备闭环已经可用
  - App Store 截图与最终视觉定稿仍依赖后续 UI 资产补齐
  - 若后续产品确认要在 `1.0` 恢复历史页，必须先更新 `PRD` 与共享文档，再重新派发任务
- 最快验证方式：
  - 对照 `TASK_007`、`CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS`，检查 `6.6/6.7` 描述是否一致
  - 检查本轮提交是否只修改共享文档，未进入实现代码与 PR 流程

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
