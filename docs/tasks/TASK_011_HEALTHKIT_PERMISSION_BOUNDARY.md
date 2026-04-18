# Task Contract 011

## 基本信息

- 任务名称：6.8 HealthKit 与权限前置边界冻结 / 实现准备
- 任务目标：在不进入 `6.8` 实现编码、不直接修改 capability / 签名 / 权限配置的前提下，冻结 `1.0` 首批 `HealthKit` 权限范围、拒权降级策略、`Workout Session` 生命周期边界、`Health app` 写入口径与验证方式，为后续 `6.8` 实现任务提供唯一有效执行口径
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
  - `docs/planning/RISKS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/release/RELEASE_CHECKLIST.md`
  - `docs/release/TEST_MATRIX.md`
  - `PRD/PRD_V1.md`
- 输入代码与工程范围：
  - `Shared/Models/WorkoutState.swift`
  - `SquatCounterWatchExtension/Features/Home/WatchArchitectureOverviewView.swift`
  - `SquatCounterWatchExtension/Support/Info.plist`
  - `project.yml`
  - `SquatCounter.xcodeproj/project.pbxproj`
- 预期输出：
  - 正式 `TASK_011` 契约文档
  - `6.8` 首批权限范围、拒权降级、`Workout Session` 生命周期与 `Health app` 写入口径冻结结论
  - 与 `6.8` 相关的共享文档回写结果
  - 可供总控 checkpoint 使用的实现准备说明

## 执行边界

- 可修改文件范围：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - 必要时：
  - `docs/planning/RISKS.md`
  - `docs/planning/DECISIONS.md`
- 不可擅自变更项：
  - 不进入任何 `HealthKit` / 权限实现代码
  - 不直接修改 capability、签名、entitlements、`PrivacyInfo.xcprivacy`、`Info.plist` 权限文案或工程配置
  - 不改写 `6.4` / `6.5` / `6.6` / `6.7` 已合入的功能代码
  - 不把 `HealthKit` 需求扩大为心率、能量、路线、历史补写或云同步系统
  - 不创建实现 PR
  - 不自动合并 `main`
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务属于实现前边界冻结与共享文档回写，目标是先统一 `6.8` 口径，再由总控决定是否进入实现任务

## 当前基线观察

- 现有工程已经为 Watch Extension 链接 `HealthKit.framework`
- Watch Extension 的 `Info.plist` 已声明 `WKBackgroundModes = workout-processing`
- 当前仓库中尚无 `HKHealthStore`、`HKWorkoutSession`、`HKLiveWorkoutBuilder` 或 HealthKit 授权代码
- 当前仓库中尚无 `PrivacyInfo.xcprivacy`、`NSHealth*UsageDescription` 或 HealthKit capability 落地结果
- 当前 Watch 训练主流程仍由 `WorkoutSessionViewModel` 本地状态机驱动，`6.8` 需要在该边界上补系统会话与写入能力，但不能改写 Watch 为训练真源的基本规则

## 权限范围冻结

- `1.0` 首批 `HealthKit` 权限正式冻结为：
  - 仅承接 `Apple Watch` 侧训练主流程所需的最小 `HealthKit` 权限
  - 仅覆盖 `Workout Session` 运行与“已完成训练写入 `Health app`”所必需的 workout 相关权限
- `1.0` 首批明确不纳入以下权限范围：
  - `iPhone` 侧单独申请 `HealthKit`
  - 心率、静息心率、卡路里、睡眠、体重等额外健康数据读写
  - 路线、地理位置、后台历史补写、多 workout 类型扩展
- 实现任务必须遵循“最小权限集”原则：
  - 若某类健康数据不是完成当前深蹲训练闭环与 workout 写入的必要前提，则不得在 `1.0` 首批请求

## 拒权降级策略冻结

- 用户拒绝 `HealthKit` 或设备不支持相关能力时：
  - Watch 本地训练主流程仍可继续运行
  - 计时、识别、组次进度、震动反馈、`6.7` 同步链路均不得因为 `HealthKit` 拒权而被硬阻塞
  - 唯一允许降级的是：
    - 不创建 / 不运行系统 `Workout Session`
    - 不写入 `Health app`
- 拒权后的产品口径冻结为：
  - 给出非阻塞说明，解释“训练仍可继续，但不会写入 `Health app`”
  - 不允许把用户永久锁死在权限页
  - 不允许因为拒权导致崩溃、空白页或主流程不可恢复

## Workout Session 生命周期边界冻结

- `Workout Session` 仅由 `Apple Watch` 侧持有和驱动，`iPhone` 不承接任何会话控制权
- `Workout Session` 生命周期只覆盖一次明确开始的 Watch 训练尝试：
  - `idle` / 配置页 / iPhone 引导页不属于 `Workout Session`
  - 倒计时被取消时，不应创建或保留可写入的系统 workout
  - 系统 `Workout Session` 应在 Watch 真正进入训练主链路时开始，不早于倒计时完成后的训练进入点
  - `training`、`resting`、`paused` 仍属于同一训练会话生命周期
  - `completed` 或用户确认结束训练时，应进入会话结束分支
- 生命周期边界同时冻结以下限制：
  - 不新增独立后台会话管理器 UI
  - 不把 `Workout Session` 生命周期扩展到 iPhone
  - 不允许在会话结束后继续补写或修改当前次训练的业务进度真相

## Health app 写入口径冻结

- `1.0` 首批写入口径冻结为：
  - 最多为一次已完成的 Watch 深蹲训练写入一条对应 workout 记录到 `Health app`
  - 写入发生在训练完成路径，而不是开始路径
  - 写入内容以当前训练闭环已有的组数、次数、起止时间等最小摘要为基础，不扩展到复杂指标
- 首批明确不吸收以下范围：
  - 历史补写
  - 删除 / 编辑既有 workout
  - 多条失败重放队列
  - 额外样本写入、心率采集、路线采集、卡路里精算
- 取消 / 中止 / 拒权路径冻结为：
  - 倒计时取消、未进入训练、用户中途结束训练的当前设计默认不写入 `Health app`
  - 若后续产品决定“提前结束也要写入部分 workout”，必须先补新契约，不得直接扩展

## 实现范围准备结论

- 后续 `6.8` 实现任务允许承接的核心范围：
  - Watch 侧 `HealthKit` capability 与最小权限申请
  - Watch 侧 `Workout Session` 生命周期接线
  - 训练完成后的最小 workout 写入
  - 与之直接相关的权限文案、`PrivacyInfo.xcprivacy`、真机验证与发布检查回写
- 后续实现任务的潜在文件范围应优先限制在：
  - `SquatCounterWatchExtension/`
  - `Shared/Models/WorkoutState.swift`
  - 必要时：
  - `project.yml`
  - `SquatCounter.xcodeproj/project.pbxproj`
  - `SquatCounterWatchExtension/Support/Info.plist`
  - `docs/release/RELEASE_CHECKLIST.md`
  - `docs/release/TEST_MATRIX.md`
- 若后续实现需要直接改 capability、签名或提审产物，总控应先判断是否继续由开发 Agent 承接，还是单独启用 / 协调平台侧收口

## 测试与验证口径冻结

- 模拟器验证不足以宣称 `6.8` 完成，`HealthKit` 与 `Workout Session` 必须依赖真实 `Apple Watch`
- 首批验证口径至少包含：
  - `HealthKit` 首次授权通过
  - `HealthKit` 拒权降级可用
  - 训练进行中稳定性
  - 已完成训练可写入 `Health app`
  - 中途结束 / 取消倒计时不会产生错误写入
- 验证入口以 `docs/release/TEST_MATRIX.md` 与 `docs/release/RELEASE_CHECKLIST.md` 为准
- 构建与工程验证口径：
  - capability、签名、文案、`PrivacyInfo.xcprivacy`、真机验证必须在后续实现任务中一起收口
  - 当前边界冻结阶段只负责定义口径，不宣称这些检查已通过

## 风险与依赖

- `HealthKit` 在工程中仅有 framework 与后台模式预留，尚未形成 capability、权限文案、授权代码与 workout 写入链路
- 若实现期把权限请求扩大到额外健康数据，可能直接增加提审复杂度并偏离最小权限原则
- 若实现期把 `HealthKit` 拒权变成训练阻塞，会破坏当前“Watch 本地训练主流程优先”原则
- 真机验证必须依赖真实配对 Apple Watch；仅凭模拟器无法关闭 `6.8`

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 如何在已有 Watch 本地状态机上补系统 `Workout Session`，同时保持“系统能力不是业务真源”
  - 如何先冻结最小权限集与拒权降级，再进入 `HealthKit` 实现，避免权限范围膨胀

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_011` 契约文档
  - 已明确 `6.8` 首批权限范围
  - 已明确拒权降级策略
  - 已明确 `Workout Session` 生命周期边界
  - 已明确 `Health app` 写入口径
  - 已明确验证方式与排除项
  - 已完成共享文档回写，且未进入任何实现代码或 capability / 签名配置修改
- 最快验证方式：
  - 检查本轮提交是否仅修改共享文档
  - 对照 `TASK_011`、`CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS`、`DECISIONS`、`RELEASE_CHECKLIST`、`TEST_MATRIX`，确认 `6.8` 口径一致

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
