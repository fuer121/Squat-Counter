# Squat Counter 项目执行与跟踪文档

## 1. 文档目的

本文件用于承接 [PRD_V1.md](../../PRD/PRD_V1.md) 的需求定义，作为项目从开发到上架的执行基线。

适用范围：

- `iPhone App + Apple Watch companion App`
- 面向 `App Store` 上架
- 面向后续持续迭代、状态确认和阶段复盘

本文档将持续更新，用于：

- 跟踪工作流和任务完成状态
- 记录关键产品与技术决策
- 明确每阶段交付物与验收标准
- 作为开发、测试、提审和上线后的统一检查基线

---

## 2. 当前项目定义

### 2.1 产品形态

- `iPhone + Watch companion`
- 训练主会话运行在 `Apple Watch`
- `iPhone` 负责配置、引导、帮助、支持和基础设置；训练主流程、训练状态与训练结果真源仍以 `Apple Watch` 为准

### 2.2 首发版本目标

发布一个可上架的 `1.0` 版本，满足以下核心价值：

- 用户可以在 Apple Watch 上完成完整深蹲训练闭环
- 用户可通过 iPhone 完成首次引导、配置默认参数并访问帮助与支持入口
- 应用满足基础隐私、权限、测试和提审要求

### 2.3 首发范围边界

`1.0` 包含：

- Watch 端训练设置、倒计时、自动计数、组间休息、节奏提示、震动反馈
- Watch 端暂停 / 恢复、结束训练、手动 `+1 / -1`
- iPhone 端首次引导、参数配置、帮助与支持入口
- Watch 与 iPhone 的基础数据同步
- App Store 上架所需的权限、隐私、素材和元数据准备

`1.0` 不包含：

- 账号体系
- 云同步
- 社交分享
- 训练历史记录 / 历史页
- 成就系统
- 多动作识别
- AI 动作纠错
- 复杂训练计划

### 2.4 开发工具与环境基线

当前确认的开发工具组合：

- `Codex`
- `Xcode`
- `Figma MCP`
- 真机 `iPhone`
- 真机 `Apple Watch`
- `GitHub`
- `Notion`

当前工具分工：

- `Codex`：需求拆解、任务推进、代码生成、文档维护、评审辅助
- `Xcode`：iOS / watchOS 工程开发、签名、调试、归档、提审前验证
- `Figma MCP`：设计稿读取、界面结构对照、设计到代码协作
- `iPhone + Apple Watch`：真机联调、识别验证、同步验证、权限验证
- `GitHub`：源码管理、分支策略、变更追踪
- `Notion`：项目计划、任务确认、阶段进展和决策同步

工具使用原则：

- 文档基线以仓库内文件为准，避免信息只存在外部平台
- `Notion` 作为项目执行面板和状态跟踪工具，不替代仓库内基线文档
- 所有关键决策先更新仓库文档，再同步到 `Notion`
- 所有 watchOS 训练相关能力必须经过真机验证，不能只依赖模拟器

后续建议补齐的工具与平台：

- `App Store Connect`
- `TestFlight`
- `Xcode Instruments`
- `Xcode Organizer`

---

## 3. 使用规则

### 3.1 状态字段

统一使用以下状态：

- `未开始`
- `进行中`
- `阻塞`
- `已完成`
- `已取消`

### 3.2 更新方式

每次推进后，至少更新以下内容：

1. 对应任务状态
2. 实际完成内容
3. 存在的问题或风险
4. 下一步动作

### 3.3 更新建议

- 小任务完成时，直接更新对应任务状态
- 阶段任务完成时，同时更新“阶段结论”
- 发生范围变更时，同时更新“关键决策记录”

---

## 4. 关键决策记录

| 日期 | 决策项 | 当前结论 | 备注 |
| --- | --- | --- | --- |
| 2026-04-04 | 产品发行形态 | `iPhone + Watch companion` | 已确认 |
| 2026-04-04 | 训练主状态源 | `Apple Watch` | 已确认 |
| 2026-04-04 | 首发版本定位 | `1.0 可上架 MVP` | 已确认 |
| 2026-04-04 | 首发范围 | 不做账号、云同步、社交、AI 纠错 | 已确认 |
| 2026-04-04 | HealthKit 写入策略 | `1.0` 写入 `Health app` 的 workout | 已确认 |
| 2026-04-04 | 首发 KPI | 下载量达到 `100` | 已确认 |
| 2026-04-04 | 首发市场策略 | 中国区、中文、免费 | 已确认 |

---

## 5. 总体工作流

1. 产品定义与发行策略
2. 工程与架构设计
3. Watch 端核心训练闭环
4. iPhone companion 能力
5. 跨设备同步
6. HealthKit / 权限 / 合规
7. 数据与隐私交付
8. 测试与质量门禁
9. 发布工程与 TestFlight
10. App Store 上架
11. 上线后运营与版本迭代

---

## 6. WBS 任务拆解

### 6.1 产品定义

#### 模块状态

- 状态：`已完成`
- 阶段目标：明确首发范围、职责边界、数据与权限策略

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 明确 `iPhone + Watch companion` 首发范围 | P0 | 已完成 | `Scope v1` 结论 | 明确 iPhone 做什么、Watch 做什么、`1.0` 不做什么 |
| 明确训练主会话归属 | P0 | 已完成 | 架构结论 | Watch 为训练主状态源 |
| 明确 HealthKit 策略 | P0 | 已完成 | 权限与数据流说明 | `1.0` 写入 workout，并需补齐权限、写入策略和拒权降级说明 |
| 明确首发 KPI | P1 | 已完成 | 指标清单 | 首发 KPI 为下载量达到 `100` |
| 明确首发地区、语言、定价策略 | P1 | 已完成 | 发布策略说明 | 中国区、中文、免费 |

#### 当前待办

- 阶段一已完成，进入阶段二工程与架构设计
- 阶段二优先确认工程目录结构、共享层命名方式和通信模型

---

### 6.2 工程与架构设计

#### 模块状态

- 状态：`已完成`
- 阶段目标：建立可持续迭代的 `iOS + Watch` 工程骨架

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 创建 `iOS App + Watch App + Watch Extension` 工程 | P0 | 已完成 | 可编译工程 | 已生成 `SquatCounter.xcodeproj`，`build` 通过 |
| 建立共享代码层 | P0 | 已完成 | `Shared` 模块或共享 group | 已落地共享模型、同步 payload 和存储接口 |
| 设计通信机制 | P0 | 已完成 | 通信设计说明 | 已通过 `ARCHITECTURE.md` 和 `SyncPayload` / `WatchConnectivitySyncing` 明确边界 |
| 明确本地持久化边界 | P0 | 已完成 | 存储设计说明 | 已确定当前阶段使用 `UserDefaults` 本地存储 |
| 建立环境配置 | P1 | 已完成 | `Debug / Beta / Release` 方案 | 已通过 `Configs/*.xcconfig` 和 `project.yml` 落地三套构建配置 |

#### 当前待办

- 阶段二已完成，下一步进入第三阶段 Watch 训练主流程实现
- 后续补充 companion 结构下的模拟器测试链路排查

---

### 6.3 Watch 端核心训练闭环

#### 模块状态

- 状态：`已完成`
- 阶段目标：不依赖完整算法也能跑通训练主流程

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 实现 `WorkoutConfig`、`WorkoutProgress`、`WorkoutState`、`PauseContext` | P0 | 已完成 | 核心模型代码 | 共享模型已落地，可表达当前训练会话和暂停上下文 |
| 实现 `SquatMotionState`、`SquatDetectionEvent` | P0 | 已完成 | 识别事件模型 | 识别状态与事件模型已落地，可供后续检测模块接入 |
| 实现 `WorkoutSessionViewModel` | P0 | 已完成 | 会话状态管理代码 | 已支持 `idle / countdown / training / resting / paused / completed` 最小状态流转 |
| 实现设置页 | P0 | 已完成 | `WorkoutConfigView` | Watch 端已可设置 reps / sets / rest 并从首页进入主流程 |
| 实现训练页 | P0 | 已完成 | `WorkoutSessionView` | 已展示组数、次数、状态与主控制按钮 |
| 实现休息页 | P0 | 已完成 | `RestView` | 已展示休息态入口与下一组继续控制 |
| 实现完成页 | P0 | 已完成 | `WorkoutCompleteView` | 已展示训练完成结果与返回入口 |
| 实现手动 `+1 / -1` 修正 | P0 | 已完成 | 修正逻辑 | 已限制仅在 `training` 可用，且边界受控 |
| 实现暂停 / 恢复 | P0 | 已完成 | 状态恢复逻辑 | 已通过 `resumeTarget` 回到正确状态 |
| 实现结束训练确认 | P0 | 已完成 | 结束训练交互 | 已确认后丢弃当前进度并回首页 |

#### 当前待办

- `TASK_001` 已完成最小闭环，实现与测试已通过
- 首个草稿 PR 已创建，当前处于评审前检查与文档收口状态
- 评审前检查完成后，再进入 `TimerManager`、训练前倒计时和组间休息真实计时

---

### 6.4 训练控制能力

#### 模块状态

- 状态：`已完成`
- 阶段目标：让倒计时、休息、节奏和震动具备可复用能力

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 实现 `TimerManager` | P0 | 已完成 | 计时管理代码 | 支持开始倒计时、休息倒计时、节奏提示，且同一时刻只保留一个激活中的训练控制计时上下文 |
| 接入 3 秒训练前倒计时 | P0 | 已完成 | 倒计时逻辑 | 倒计时结束自动进入训练；倒计时态仅允许取消，不开放暂停、结束训练和 `+1 / -1` |
| 接入组间休息倒计时 | P0 | 已完成 | 休息逻辑 | 休息结束自动进入下一组；休息态暂停恢复后继续剩余时间而不重置 |
| 实现“提前开始下一组” | P0 | 已完成 | 快捷控制逻辑 | 可跳过剩余休息时间，且与休息自然结束共用同一条进入下一组语义，不重复触发反馈 |
| 实现 `HapticManager` | P0 | 已完成 | 震动封装 | 支持倒计时、计数、单组完成、进入下一组、训练完成等不同事件反馈 |
| 实现节奏提示与计数震动冲突处理 | P1 | 已完成 | 反馈优先级逻辑 | 遵循 `训练完成` > `单组完成 / 进入下一组` > `单次计数成功` > `节奏提示`，高优先级覆盖低优先级 |

#### 当前待办

- 已完成 `TASK_003` 边界冻结与产品口径回收，确认 `TimerManager`、`HapticManager` 与 `WorkoutSessionViewModel` 的职责边界
- 已补齐 `TASK_004` 实现契约，明确当前 PR #2 由实现阶段 Task Contract 承接
- 已完成训练控制事件模型、`TimerManager`、`HapticManager`、`WorkoutSessionViewModel` 接入与 Watch 端最小震动执行落地
- 已完成相关自动化验证：
  - `SquatCounterTests` 完整成功结果包包含 `16` 个测试，状态为 `succeeded`
  - `WorkoutConfigTests`、`TimerManagerTests`、`HapticManagerTests` 均包含在该次成功结果内
  - `SquatCounterWatchApp` 最小构建已通过
- `PR #2` 已合入 `main`，`6.4` 已完成主线收口
- 下一步等待总控派发下一任务

---

### 6.5 动作识别

#### 模块状态

- 状态：`进行中`
- 阶段目标：完成可替换、可调参的 MVP 识别模块

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 定义 `SquatDetectionManager` 接口 | P0 | 已完成 | 协议与事件流 | 只输出事件，不直接改 UI |
| 实现模拟识别模式 | P0 | 已完成 | 调试模式 | 无真实传感器时可联调整体流程 |
| 实现简化识别状态机 | P1 | 已完成 | MVP 识别逻辑 | 正常深蹲能计数 |
| 增加 cooldown 机制 | P1 | 已完成 | 去重逻辑 | 单动作不会重复计数 |
| 增加内部阈值配置 | P1 | 已完成 | 可调参数结构 | 可进行真机调参 |
| 做真机识别调优 | P1 | 未开始 | 调优记录 | 半蹲、抬腕、晃动尽量不计数 |

#### 当前待办

- 已完成 `TASK_005` 边界冻结，正式确认“识别只输出事件、不直接改 UI / 训练状态 / 震动 / TimerManager”的实现前提
- 已补齐 `TASK_006` 实现契约，使当前分支已发生的 `6.5` 最小实现、测试与构建验证具备合法承接文档
- 已完成 `SquatDetectionManager` 最小实现，支持独立事件流、模拟识别模式、简化识别状态机、`cooldown`、防误触基线与内部可调阈值
- 已完成 `WorkoutSessionViewModel` 对 `repDetected` 的接入，并冻结“识别只输出事件、不直接改 UI / 训练状态 / 震动 / TimerManager”的边界
- 已完成 Watch 端模拟识别联调入口接入，保留手动 `+1 / -1` 作为纠错能力
- 已完成与 `6.5` 直接相关的单测与集成测试验证：`WorkoutSessionViewModelTests` 与 `SquatDetectionManagerTests` 共 `17` 个测试通过
- 已完成 `SquatCounterWatchApp` 的 Watch Simulator 最小构建验证，结果通过
- `PR #3` 已合入 `main`，`6.5` 已完成主线收口
- 下一步等待总控派发下一任务

---

### 6.6 iPhone Companion

#### 模块状态

- 状态：`已完成`
- 阶段目标：在不侵入 Watch 主流程和 `6.7` 同步实现的前提下，让 iPhone 端承担配置、引导和辅助能力

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 冻结 `TASK_007` companion 边界与页面范围 | P0 | 已完成 | 边界契约 | 已明确 `1.0` 页面范围、职责边界、`6.7` 接口边界、Figma 判断与测试口径 |
| 补齐 `TASK_008` 首批实现契约 | P0 | 已完成 | 实现契约 | 已明确 `6.6` 首批实现页面范围、允许修改文件范围、本地持久化边界、最小验证方式与排除项 |
| 收口 companion 首页与导航结构 | P0 | 已完成 | 首页信息架构 | 首页已承接引导、默认参数、帮助与支持、轻量信息入口，且 `1.0` 不使用 `Tab Bar` |
| 实现首次启动引导页 | P0 | 已完成 | iPhone onboarding | 已解释手表端训练路径、权限预期和“Watch 是训练主端”规则；完成后不重复强展示 |
| 实现参数配置页 | P0 | 已完成 | 配置 UI | 默认参数已支持本地编辑并立即持久化；页面不提供实时训练控制，并继续作为后续 `6.7` 配置同步唯一输入 |
| 实现帮助与支持页 | P1 | 已完成 | 帮助中心 | 已落地 FAQ、支持说明、隐私说明占位和 companion 能做什么 / 不能做什么的页面骨架 |
| 整理基础设置信息入口 | P1 | 已完成 | 轻量信息入口 | 已在帮助与支持内承接版本信息、范围信息与基础说明，不扩展为训练控制面板，也不单独拆出复杂设置页 |
| 实现基础历史页 | P1 | 已取消 | 训练记录列表 | 历史页不纳入 `1.0`，留待后续版本重开范围后再评估 |

#### 当前待办

- 已完成 `TASK_007`，正式冻结 iPhone Companion 在 `1.0` 中只承接引导、默认参数配置、帮助与支持、轻量基础信息
- 已明确“基础设置”不作为首批独立页面，优先并入帮助与支持信息架构
- 已明确历史页不纳入 `1.0`，避免提前吸收训练结果回传与列表展示依赖
- 已明确 `WorkoutConfig` 是 `6.6` 首批 companion 页面唯一必需共享输入；`SyncPayload.config`、`WatchConnectivitySyncing` 由 `6.7` 承接同步 transport
- 已明确 Figma 设计资产不是 `6.6` 首批实现前置阻塞项，但在截图制作与 UI 定稿前需要补齐
- 已完成 companion 首页收口，当前采用单首页导航结构承接首次启动引导、默认参数、帮助与支持与轻量基础信息入口
- 已完成首次启动引导页、默认参数配置页、帮助与支持页与轻量基础信息入口的首批实现
- 已完成 `WorkoutConfig` 本地持久化接线，页面层继续通过 `PhoneCompanionViewModel` 与 `WorkoutConfigStoring` 间接读写，不直接触碰 `Shared/Sync/`
- 已补齐 `6.6` 直接相关的本地持久化测试，并完成 `xcodebuild build` 与 `xcodebuild build-for-testing`
- 已尝试用 `test-without-building` 只运行 `WorkoutConfigTests` 与 `WorkoutConfigStoreTests`；当前现象为模拟器已 `Booted`，但测试命令停在执行前、`xctest` 宿主未启动
- 当前可确认“`6.6` 直接相关测试已成功编译进入产物”，但完整测试执行结果仍需总控判断是否在更稳定环境补跑
- `PR #4` 已合入 `main`，`6.6 iPhone Companion` 已完成主线收口
- 下一步等待总控派发下一任务；若进入 `6.7` 或其他模块，需先补齐对应 Task Contract

---

### 6.7 跨设备同步

#### 模块状态

- 状态：`进行中`
- 阶段目标：建立稳定、可恢复的 iPhone 与 Watch 数据同步链路

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 冻结 `TASK_009` 同步边界与实现准备 | P0 | 已完成 | 边界契约 | 已明确首批同步范围、可见承载方式、冲突与重试边界、验证口径与实现排除项 |
| 补齐 `TASK_010` 首批实现契约 | P0 | 已完成 | 实现契约 | 已明确共享层、iPhone 侧、Watch 侧、测试文件范围，以及最小验证方式与排除项 |
| 定义同步数据模型 | P0 | 已完成 | `SyncPayload` 结构 | 已覆盖默认配置、最近一次训练摘要与 `WatchStateSnapshot` 预留边界 |
| 实现 iPhone -> Watch 配置同步 | P0 | 已完成 | 同步逻辑 | iPhone 保存默认参数后会下发到 Watch；Watch 仅在空闲 / 已完成态应用，训练中只影响下一次默认值 |
| 实现 Watch -> iPhone 训练结果同步 | P0 | 已完成 | 回传逻辑 | 完成训练后 iPhone companion 首页最多可看到最近一次训练摘要，不扩展为历史页 |
| 增加断连重试机制 | P1 | 未开始 | 同步容错逻辑 | 断连后可重试，不破坏训练主流程 |
| 明确冲突规则 | P0 | 已完成 | 同步规则说明 | Watch 始终是训练真源，且进行中会话不被新配置改写 |

#### 当前待办

- 已完成 `TASK_009`，正式冻结 `6.7` 首批同步范围为：
  - `iPhone -> Watch` 默认参数 `WorkoutConfig`
  - `Watch -> iPhone` 最近一次训练摘要 `WorkoutSummary`
- 已完成 `TASK_010`，正式补齐 `6.7` 首批实现契约，明确共享层、iPhone 侧、Watch 侧和测试文件范围，以及最小验证方式与排除项
- 已明确 `WatchStateSnapshot` 虽保留在共享 payload 中，但不纳入 `1.0` 首批用户可见范围，不承接实时状态镜像
- 已明确 `1.0` 的同步可见承载方式：
  - Watch 侧消费最新默认参数，但不新增独立同步中心
  - iPhone 侧若需要结果可见承载，只允许使用 companion 首页中的“最近一次训练摘要”单卡 / 单 section，不扩展为历史页或结果页
- 已冻结冲突规则：
  - Watch 仍是训练主状态与训练结果的唯一真源
  - 默认参数冲突以 `SyncPayload.updatedAt` 最新值为准
  - 正在进行中的 Watch 训练会话不被同步中的新配置改写，只影响下一次训练默认值
  - 训练摘要只能由 Watch 生成，iPhone 侧至少按 `WorkoutSummary.id` 做幂等去重
- 已冻结失败与重试边界：
  - 不提供手动重试队列或同步中心
  - 重试必须轻量且不阻塞 Watch 本地训练主流程
  - 当前阶段不冻结具体 transport API、后台队列和系统级重试细节
- 已完成当前轮最小实现：
  - `WatchConnectivitySyncCoordinator` 已替换 `NoopSyncCoordinator`，统一承接 `SyncPayload` 编解码、`applicationContext` 下发与 `userInfo` 回传
  - iPhone 保存默认参数后会发送 `SyncPayload.config`
  - Watch 侧会持久化收到的默认参数，并在空闲 / 已完成态应用到下一次训练默认值；训练中收到的新配置只入队，不打断当前会话
  - Watch 完成训练后会发送最近一次 `WorkoutSummary`
  - iPhone companion 首页新增“最近一次训练摘要”单 section，并按 `WorkoutSummary.id` 做幂等去重与本地缓存
- 已完成当前轮最小验证：
  - `xcodebuild -scheme SquatCounter -project SquatCounter.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' build` 通过
  - `xcodebuild build-for-testing -scheme SquatCounter -project SquatCounter.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'` 通过
  - `xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/SquatCounter-czzsegtsdrailkgojlgummwegulo/Build/Products/Debug-iphonesimulator/SquatCounter.app` 与 `xcrun simctl launch booted com.fuer.SquatCounter` 通过，当前 app 可在 simulator 正常安装并启动
  - 已新增 `SyncPayload` 编解码、训练中配置排队、完成训练后摘要发送等直接相关单测
  - `xcodebuild test -scheme SquatCounter -project SquatCounter.xcodeproj -destination 'platform=iOS Simulator,id=A54F1E80-0E34-4DD9-BA09-7E002AC5D0BB' -destination-timeout 60 -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -only-testing:SquatCounterTests/SyncPayloadTests/testConfigPayloadRoundTripsThroughJSONEncoding` 已成功通过
  - 用户侧已按真实配对 `iPhone + Apple Watch` 路径完成 1 次 `6.7` 最小闭环验证，当前反馈为配置下发、摘要回传与首页承载均无异常
  - 完整 `xcodebuild test` / `test-without-building` 覆盖面仍未扩跑到更大范围，当前补证口径以“最小构建 + 1 条定向 XCTest + 1 次真机闭环”成立
- `PR #6` 已创建：`https://github.com/fuer121/Squat-Counter/pull/6`
- 当前状态已推进到：`PR #6` 正式评审中
- 下一步完成 `PR #6` 正式评审，并判断是否可合入 `main`；若要把 `WatchStateSnapshot` 变成用户可见能力，必须先补新契约

---

### 6.8 HealthKit 与权限

#### 模块状态

- 状态：`已完成`
- 阶段目标：`PR #7` 已合入 `main`，`6.8` HealthKit / 权限最小实现已完成主线收口

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 冻结 `TASK_011`：HealthKit 与权限边界 | P0 | 已完成 | 边界契约 | 已明确权限范围、拒权降级、`Workout Session` 生命周期、`Health app` 写入口径与验证方式 |
| 配置 `HealthKit capability` | P0 | 已完成 | target capability 配置 | 工程已补 entitlements 与最小 capability 接线，真实配对设备授权与写入验证已完成 |
| 明确权限使用文案 | P0 | 已完成 | usage description 文案 | Watch Extension `Info.plist` 已补齐与 workout 写入一致的最小文案 |
| 实现授权申请流程 | P0 | 已完成 | 权限代码与提示 | 已完成首次授权代码接线，并已完成真实配对设备首次授权验证 |
| 实现 `Workout Session` 生命周期 | P0 | 已完成 | 训练运行控制 | 已接到现有训练状态机，并已完成完成路径手动闭环验证 |
| 明确拒权降级方案 | P0 | 已完成 | 降级处理说明 | 已实现拒权后训练继续、仅跳过 `Health app` 写入 |
| 评估并实现训练写入 Health app | P1 | 已完成 | workout 保存逻辑 | 已完成训练完成路径写入代码，并已完成真实 `Health app` 写入验证 |

#### 当前待办

- 已完成 `TASK_011`，正式冻结 `6.8` 首批边界：
  - 仅承接 Watch 侧最小 `HealthKit` 权限，不在 `1.0` 首批向 iPhone 请求 HealthKit
  - `1.0` 不读取心率、卡路里、体重等额外健康数据
  - `Workout Session` 仅覆盖 Watch 端一次明确开始的训练主链路，不早于倒计时完成后的训练进入点
  - 训练完成路径最多写入一条 workout 到 `Health app`；取消倒计时、中途结束、拒权路径不写入
  - 拒权后 Watch 本地训练主流程仍可继续，不允许把权限拒绝变成训练硬阻塞
- 当前工程现状已确认：
  - Watch Extension 已链接 `HealthKit.framework`
  - Watch Extension 已声明 `workout-processing` 后台模式
  - 已补 `HKHealthStore` / `HKWorkoutSession` 最小接线、Watch 侧权限申请、`PrivacyInfo.xcprivacy`、entitlements 与 workout 写入代码
  - 已完成 `build` 与 `build-for-testing` 最小验证
  - 已完成真实配对 `iPhone + Apple Watch` 上的首次授权、拒权降级与完成训练写入 `Health app` 手动验证
  - 当前环境下完整 `XCTest` / `test-without-building` 在执行阶段仍可能卡住
- `PR #7` 已合入 `main`，`6.8` 最小实现已完成主线收口
- 下一步：等待总控派发下一任务

---

### 6.9 数据与隐私合规

#### 模块状态

- 状态：`已完成`
- 阶段目标：`PR #8` 已合入 `main`，`6.9` 已完成当前免费 `Apple Personal Team` 路径下的主线收口

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 冻结 `TASK_013`：数据与隐私合规边界 | P0 | 已完成 | 边界契约 | 已明确首批数据收集、存储、同步、写入口径与手动平台动作 |
| 补齐 `TASK_014`：数据与隐私合规实现契约 | P0 | 已完成 | 实现契约 | 已明确实现目标、可修改文件范围、最小验证方式与手动平台动作 |
| 执行 `6.9` 最小实现收口 | P0 | 已完成 | 最小实现回写 | 已完成 `PrivacyInfo.xcprivacy` 与 `UserDefaults` 真实行为对齐，并完成发布检查与状态文档回写 |
| 盘点全量采集数据 | P0 | 已完成 | 数据清单 | 已明确 `UserDefaults`、`WatchConnectivity`、`Health app` 写入的最小数据边界 |
| 添加 `PrivacyInfo.xcprivacy` | P0 | 已完成 | manifest 文件 | 文件已落地，并已补齐 `UserDefaults` 必需 API 访问声明，口径与当前实现一致 |
| 完成 App Privacy 配置 | P0 | 未开始 | App Store Connect 问卷 | 与实际采集行为一致，并在用户手动填报后回传结果 |
| 准备隐私政策 URL | P0 | 未开始 | 可访问网页 | 可公开访问，内容完整 |
| 准备支持页面 URL | P0 | 未开始 | 可访问网页 | 提供反馈和支持入口 |
| 盘点第三方 SDK 隐私要求 | P1 | 未开始 | SDK 合规清单 | 所有第三方依赖均已核查 |

#### 当前待办

- 已形成 `TASK_013`，冻结 `6.9` 首批边界：
  - 当前仅存储训练默认配置（`UserDefaults`），不存储账号身份数据与历史列表
  - 当前仅同步 `WorkoutConfig` 与最近一次 `WorkoutSummary`（`WatchConnectivity`）
  - 当前仅在 Watch 完成训练路径写入一条 workout 到 `Health app`
  - `PrivacyInfo.xcprivacy` 与 HealthKit 使用口径已与当前实现对齐
- 已形成 `TASK_014`，补齐 `6.9` 实现契约：
  - 已明确实现目标、代码/配置/隐私清单/测试/文档文件范围
  - 已明确 `PrivacyInfo.xcprivacy` / App Privacy / HealthKit / WatchConnectivity / UserDefaults 实现期边界
  - 已明确最小验证方式与必须由用户手动执行的平台动作
- 已完成 `6.9` 最小实现收口：
  - `PrivacyInfo.xcprivacy` 已补齐 `UserDefaults` 必需 API 访问声明（`CA92.1`）
  - 已完成与本轮实现直接相关的最小验证与发布检查回写：
    - `plutil -lint SquatCounterWatchExtension/Support/PrivacyInfo.xcprivacy` 通过
    - `xcodebuild build-for-testing -scheme SquatCounter -project SquatCounter.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'` 通过
    - `xcodebuild test -scheme SquatCounter -project SquatCounter.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' -only-testing:SquatCounterTests/WorkoutConfigStoreTests/testStorePersistsConfigAcrossStoreInstances` 通过
- `PR #8` 已合入 `main`，`6.9` 已完成当前免费 `Apple Personal Team` 路径下的主线收口
- App Privacy / TestFlight / 提审后台相关动作保留为后续提审路径事项，不作为本轮下一步
- 下一步等待总控派发下一任务

---

### 6.10 测试与质量门禁

#### 模块状态

- 状态：`未开始`
- 阶段目标：建立从单元测试到真机回归的质量保障链路

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 为 `WorkoutSessionViewModel` 编写单元测试 | P0 | 未开始 | 测试代码 | 覆盖开始、取消、暂停、恢复、组完成、结束训练 |
| 为 `TimerManager` 编写测试 | P0 | 未开始 | 测试代码 | 倒计时和休息计时逻辑可验证 |
| 为识别状态机编写测试 | P1 | 已完成 | 测试代码 | cooldown、闭环状态、阈值逻辑可验证 |
| 建立真机测试矩阵 | P0 | 未开始 | 测试计划 | 覆盖佩戴、节奏、暂停、断连、权限等场景 |
| 建立性能观察项 | P1 | 未开始 | 观察清单 | 至少包含电量、稳定性、发热、同步延迟 |
| 建立发布门禁 checklist | P0 | 未开始 | 提审前检查清单 | 提审前必须逐项完成 |

#### 当前待办

- 优先把状态机测试纳入首批开发范围

---

### 6.11 发布工程与 TestFlight

#### 模块状态

- 状态：`未开始`
- 阶段目标：建立可重复执行的测试发布流程

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 配置 Bundle ID、签名、证书、Provisioning | P0 | 未开始 | 可归档发布工程 | iOS 和 Watch 均可成功 Archive |
| 建立 `Debug / Beta / Release` 构建配置 | P1 | 已完成 | 环境配置方案 | 已落地 `Configs/*.xcconfig` 和三套 build configuration |
| 建立 Beta 发布流程 | P0 | 未开始 | 测试发布说明 | 每次 beta 可稳定发到 TestFlight |
| 组织内部测试 | P0 | 未开始 | 测试反馈记录 | 至少完成一轮团队内部验证 |
| 组织外部 TestFlight 测试 | P1 | 未开始 | 外测反馈记录 | 至少完成一轮真实用户验证 |

#### 当前待办

- 发版前需要先完成签名和 target 配置

---

## 7. 更新日志

| 日期 | 版本 | 更新内容 |
| --- | --- | --- |
| 2026-04-04 | v0.3 | 完成阶段二工程骨架：生成 `iOS + Watch companion` 工程、共享模型、同步 payload、本地存储接口和最小入口页面 |
| 2026-04-04 | v0.4 | 完成 `Debug / Beta / Release` 构建配置，阶段二状态更新为已完成；阶段三共享模型任务同步标记为已完成 |

---

### 6.12 App Store 上架

#### 模块状态

- 状态：`未开始`
- 阶段目标：补齐提审所需元数据、截图和审核说明

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 准备 App 名称、副标题、描述、关键词 | P0 | 未开始 | 元数据文案 | 可直接填入 App Store Connect |
| 准备 iPhone 截图 | P0 | 未开始 | 截图素材 | 展示 iPhone companion 核心价值 |
| 准备 Apple Watch 截图 | P0 | 未开始 | 截图素材 | 展示 Watch 训练主流程 |
| 准备 App 图标 | P0 | 未开始 | 图标素材 | 满足提审与展示要求 |
| 编写 `App Review Notes` | P0 | 未开始 | 审核说明 | 清楚解释 companion 结构、权限和使用方式 |
| 配置地区、分级、价格、发布日期 | P1 | 未开始 | 发布配置 | 可完成最终提交 |

#### 当前待办

- 截图素材需要和最终 UI 定稿同步推进

---

### 6.13 上线后运营与迭代

#### 模块状态

- 状态：`未开始`
- 阶段目标：建立首发后的监控与迭代节奏

| 任务 | 优先级 | 状态 | 交付物 | 验收标准 |
| --- | --- | --- | --- | --- |
| 监控崩溃、评分和用户反馈 | P0 | 未开始 | 首发观察面板 | 首发后 48 小时内可识别高风险问题 |
| 建立 `1.0.1` 修复计划 | P0 | 未开始 | 修复 backlog | 对高频 bug 有明确处理节奏 |
| 规划 `1.1` 路线图 | P1 | 未开始 | 版本规划文档 | 明确下一阶段功能方向 |
| 建立需求池与优先级机制 | P1 | 未开始 | backlog 管理方式 | 新需求可持续进入评估流程 |

#### 当前待办

- 首发前先定义上线后 2 周观察项

---

## 7. 当前阶段优先级总览

### P0 先做

1. 确认 `HealthKit` 策略
2. 创建 `iOS + Watch` 工程骨架
3. 建立共享模型和同步模型
4. 跑通 Watch 端训练主流程
5. 先冻结 `6.6` / `6.7` 页面与同步边界
6. 实现 iPhone 端最小 companion：引导页 + 参数配置 + 帮助与支持
7. 接入权限、隐私和基础提审准备

### P1 后做

1. iPhone 历史页 / 训练结果页
2. 识别调参工具
3. 外部 TestFlight
4. 训练写入 Health app
5. 上线后数据与迭代规划

---

## 8. 当前阻塞与风险

| 风险项 | 当前状态 | 影响 | 处理建议 |
| --- | --- | --- | --- |
| `1.0` 写入 Health app 的实现复杂度 | 已确认 | 影响权限、数据流和提审说明 | 在工程初始化阶段同步落地权限和 workout 保存方案 |
| 动作识别准确率不可控 | 高风险 | 影响核心体验 | 先做模拟识别和可调阈值 |
| companion 同步链路未实现 | 中风险 | 影响 iPhone/Watch 职责闭环与配置回传闭环 | 已先通过 `TASK_007` 冻结页面边界与 Watch 真源规则，再进入 `6.7` payload、重试和冲突处理实现 |
| App Store 合规项容易后补遗漏 | 中风险 | 影响提审 | 将隐私和权限纳入开发前期 |

---

## 9. 近期执行清单

### 下一步建议

1. 确认 `HealthKit` 写入策略
2. 创建 `iOS + Watch companion` 工程
3. 建共享模型与状态机
4. 用模拟识别先跑通 Watch 主流程
5. 启动 iPhone 最小 companion 页面开发

### 本轮完成记录

- 已确认产品形态为 `iPhone + Watch companion`
- 已整理完整工作流
- 已落地首版 `WBS` 执行文档
- 已完成阶段一产品定义决策：`HealthKit` 写入、首发 KPI、首发市场策略
- 已完成第二阶段核心骨架：`xcodegen` 工程、共享层、同步骨架、iPhone / Watch 最小入口

---

## 10. 更新日志

| 日期 | 版本 | 更新内容 |
| --- | --- | --- |
| 2026-04-04 | v0.1 | 创建首版项目执行与跟踪文档，补齐从开发到上架的完整工作流与任务拆解 |
| 2026-04-04 | v0.2 | 完成阶段一决策更新：确认 `1.0` 写入 `Health app` workout、首发 KPI 为下载量 100、首发市场为中国区中文免费 |
| 2026-04-04 | v0.3 | 启动并完成第二阶段核心骨架：生成 `iOS + Watch companion` 工程，建立共享模型、同步接口、本地存储边界与最小入口页面 |
| 2026-04-09 | v0.4 | 完成 `TASK_007`：冻结 `6.6 iPhone Companion` 的职责边界、页面范围、`6.7` 接口边界、Figma 判断与测试口径，并将历史页正式排除出 `1.0` |
