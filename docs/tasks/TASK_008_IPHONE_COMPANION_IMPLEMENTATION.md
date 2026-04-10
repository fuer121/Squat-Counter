# Task Contract 008

## 基本信息

- 任务名称：6.6 iPhone Companion 首批实现（基于 `TASK_007` 已冻结边界）
- 任务目标：在 `TASK_007` 已冻结的职责边界、页面范围和 `6.7` 接口边界内，完成 iPhone Companion 首批页面落地、`WorkoutConfig` 本地持久化接线、最小测试与 iPhone 构建验证，并形成可供总控 checkpoint 使用的实现契约
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent 1`
- 协作方：`总控 Agent`、`产品 Agent`、`UI Agent`、`测试 Agent`
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
  - `docs/tasks/TASK_007_IPHONE_COMPANION_BOUNDARY.md`
- 输入代码范围：
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `SquatCounteriOS/App/SquatCounterApp.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionHomeView.swift`
  - `SquatCounteriOS/Features/Home/PhoneCompanionViewModel.swift`
  - `SquatCounterTests/WorkoutConfigTests.swift`
- 预期输出：
  - iPhone Companion 首页信息架构落地
  - 首次启动引导页落地
  - 默认参数配置页落地
  - 帮助与支持页落地，并承接轻量基础信息入口
  - `WorkoutConfig` 本地持久化与页面层边界实现口径
  - 与 `6.6` 直接相关的最小测试与 iPhone 最小构建验证
  - 可供总控 checkpoint 使用的实现状态与共享文档回写结果

## 执行边界

- 可修改文件范围：
  - `SquatCounteriOS/App/`
  - `SquatCounteriOS/Features/`
  - `Shared/Models/WorkoutConfig.swift`
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `SquatCounterTests/`
  - 必要时：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/RISKS.md`
- 不可擅自变更项：
  - 不改写 `TASK_007` 已冻结的职责边界、页面范围和排除项
  - 不进入 `6.7` 同步实现，不修改 `Shared/Sync/`
  - 不新增历史页、训练结果页、实时训练控制、实时状态镜像
  - 不修改 Watch 端既有实现和 `6.5` / `6.4` 已冻结职责边界
  - 不在页面层直接读写 `UserDefaults`、`SyncPayload` 或 `WatchConnectivitySyncing`
  - 不顺手重构无关模块
  - 在总控 checkpoint 前不创建 PR
- 是否允许自动化执行：`是`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：用户已明确要求继续使用当前分支 `codex/task-007-iphone-boundary`，且本任务实现范围仅聚焦 iPhone Companion 首批页面与本地持久化边界，不需要再切新 worktree 或并行写同批文件

## 继承口径

- 本任务严格继承 `TASK_007` 已冻结的职责边界、首批页面范围、`6.7` 接口边界、Figma 判断与测试口径
- iPhone Companion 在 `1.0` 中继续只承担：
  - 首次启动引导
  - 默认训练参数配置
  - 帮助与支持
  - 轻量基础信息访问
- Watch 继续作为训练主状态、训练进度和训练结果的唯一真源
- `6.7` 的 `SyncPayload.config`、`SyncPayload.workoutSummary`、`WatchConnectivitySyncing` 继续留在后续同步任务承接

## 首批实现页面范围冻结

- `6.6` 首批必须落地的页面 / 入口为：
  - companion 首页
  - 首次启动引导页
  - 默认参数配置页
  - 帮助与支持页
- 轻量基础信息入口作为“帮助与支持页”中的信息 section 落地，不单独拆出复杂设置页，也不要求独立 Feature 模块
- companion 首页必须承担：
  - `iPhone + Watch` 形态说明
  - `Apple Watch` 为训练主端说明
  - 默认参数摘要
  - 通往引导、默认参数、帮助与支持的导航入口
- 默认参数配置页只承接：
  - `repsPerSet`
  - `totalSets`
  - `restSeconds`
  - 本地保存状态提示
- 明确不纳入首批实现：
  - 历史页 / 训练结果页
  - 实时训练控制
  - 实时状态镜像
  - 配置同步成功态

## WorkoutConfig 本地持久化与页面层边界

- `WorkoutConfig` 继续作为 `6.6` 首批 companion 页面唯一必需的共享输入模型
- `UserDefaultsWorkoutConfigStore` 继续作为 `6.6` 阶段默认参数的本地持久化实现
- 页面层边界冻结为：
  - SwiftUI 页面只负责展示、导航和触发用户交互
  - `PhoneCompanionViewModel` 或其在 `SquatCounteriOS/Features/` 内的同域扩展对象负责读取、编辑、校验和保存 `WorkoutConfig`
  - 页面层不直接操作 `UserDefaults`
  - 页面层不直接依赖 `SyncPayload`、`WatchConnectivitySyncing`、`WorkoutState`、`WorkoutProgress`
- 持久化边界冻结为：
  - 默认参数修改后先本地立即持久化
  - 本地保存成功不等于已同步到 Watch
  - 文案不得承诺“已实时应用到 Watch”

## 最小验证方式

- 单元 / 特性测试：
  - `WorkoutConfig` 取值范围约束保持不变
  - iPhone 默认参数编辑后可正确持久化并在重新加载后恢复
  - 页面层不会暴露历史页、实时训练控制或训练结果列表入口
- 构建验证：
  - 运行 `xcodebuild test -scheme SquatCounter -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:SquatCounterTests`
  - 运行 `xcodebuild build -scheme SquatCounter -destination 'platform=iOS Simulator,name=iPhone 17'`
- 验证通过标准：
  - iPhone 首次启动引导可独立访问
  - 默认参数页在无 Watch 连接时仍可用
  - 帮助与支持页可独立访问
  - 不出现实时训练控制或历史页入口

## 本任务明确不吸收的范围

- `6.7` 同步逻辑、断连重试、冲突规则、最近状态摘要
- 历史页 / 训练结果页
- iPhone 侧实时训练控制
- iPhone 侧实时训练状态镜像
- Watch 端代码、`HealthKit`、提审素材和 Figma 设计补齐

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_008` 实现契约文档
  - 已明确 `6.6` 首批实现页面范围与信息架构落点
  - 已明确 iPhone 可修改代码与测试文件范围
  - 已明确 `WorkoutConfig` 本地持久化与页面层边界
  - 已明确最小测试与 iPhone 构建验证方式
  - 已明确 `6.7`、历史页、实时训练控制、实时状态镜像不纳入本任务
  - 已完成共享文档回写，且未进入任何功能实现
- 风险与依赖：
  - 帮助与支持页的正式 FAQ、支持联系方式与隐私政策 URL 仍待补齐，当前不阻塞页面骨架实现，但阻塞提审收口
  - `6.7` 未实现前，iPhone Companion 只能证明本地配置与页面独立可用，不能证明跨设备闭环
  - 若后续产品要恢复历史页或结果页，必须先更新 `PRD` 与共享文档，再重新派发任务
- 最快验证方式：
  - 对照 `TASK_007`、`TASK_008`、`CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS`，检查 `6.6/6.7` 描述是否一致
  - 检查本轮提交是否只修改共享文档，未进入 iPhone / Watch 实现代码

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
