# Task Contract 013

## 基本信息

- 任务名称：6.9 数据与隐私合规前置边界冻结 / 实现准备
- 任务目标：在不进入功能实现的前提下，冻结 `1.0` 首批数据与隐私合规边界，明确当前实际数据收集、存储、同步、写入口径，统一 `PrivacyInfo.xcprivacy` / App Privacy / HealthKit / WatchConnectivity / UserDefaults 的合规承接方式，并定义最小发布检查、排除项与必须由用户手动执行的平台动作
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent 2`
- 协作方：`总控 Agent`、`产品 Agent`、`测试 Agent`
- 是否需要总控介入：`是`

## 输入与输出

- 输入文档：
  - `AGENTS.md`
  - `docs/agents/AGENT_SYSTEM.md`
  - `PRD/PRD_V1.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/RISKS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/release/RELEASE_CHECKLIST.md`
  - `docs/release/TEST_MATRIX.md`
  - `docs/release/MANUAL_PLATFORM_OPERATIONS.md`
- 输入代码与配置范围（只读基线）：
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `Shared/Sync/SyncPayload.swift`
  - `Shared/Sync/WatchConnectivitySyncing.swift`
  - `Shared/Models/WorkoutState.swift`
  - `SquatCounterWatchExtension/Support/Info.plist`
  - `SquatCounterWatchExtension/Support/PrivacyInfo.xcprivacy`
  - `SquatCounterWatchExtension/Support/SquatCounterWatchExtension.entitlements`
- 预期输出：
  - 正式 `TASK_013` 契约文档
  - `1.0` 首批数据与隐私合规边界冻结结论
  - 最小发布检查与验证口径
  - 用户必须手动执行的平台动作清单

## 执行边界

- 可修改文件范围：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - 必要时：
  - `docs/planning/RISKS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/release/RELEASE_CHECKLIST.md`
- 不可擅自变更项：
  - 不修改任何业务实现代码
  - 不修改 `TASK_011`、`TASK_012`
  - 不新增或修改权限 capability / 签名 / entitlements
  - 不创建实现 PR
  - 不自动合并 `main`
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`

## 1.0 首批实际数据边界（冻结）

- 当前实际收集 / 生成的数据：
  - 训练配置数据：`repsPerSet`、`totalSets`、`restSeconds`、`countdownSeconds`、`tempoCueEnabled`
  - 训练摘要数据：`completedAt`、`totalSets`、`totalReps`、`durationSeconds`
  - 训练状态快照数据（非首批用户可见）：`WorkoutState` + `WorkoutProgress`
  - HealthKit workout 写入相关元数据：总组数、总次数
- 当前实际本地存储：
  - `UserDefaults` 持久化 `WorkoutConfig`（JSON 编码）
  - 不持久化训练历史列表、不持久化用户身份信息
- 当前实际跨设备同步：
  - `WatchConnectivity` 同步 `WorkoutConfig` 与最近一次 `WorkoutSummary`
  - `WatchStateSnapshot` 保留为协议能力，不作为 `1.0` 首批用户可见功能承诺
- 当前实际系统写入：
  - Watch 在训练完成路径最多写入一条 workout 到 `Health app`
  - 倒计时取消 / 中途结束 / 拒权路径不写入

## 隐私口径冻结（PrivacyInfo / App Privacy / 权限）

- `PrivacyInfo.xcprivacy` 冻结口径：
  - 当前声明为 `NSPrivacyCollectedDataTypeHealthFitness`
  - 用途限定为 `App Functionality`
  - 不声明追踪、不过度声明未实现数据类型
- App Privacy（App Store Connect）冻结口径：
  - 仅按当前真实数据行为填写
  - 不提前勾选未收集、未同步、未写入的数据类型
- HealthKit 口径：
  - 仅 Watch 侧最小 workout 权限与写入
  - iPhone 不单独申请 HealthKit
  - 不扩展到心率、卡路里、睡眠、体重、路线等额外健康数据
- WatchConnectivity 口径：
  - 仅同步训练配置与最近一次训练摘要
  - 不同步账号、联系方式、精细生理数据或历史批量数据
- UserDefaults 口径：
  - 仅保存训练默认配置
  - 不保存身份类敏感数据

## 最小发布检查与验证方式（冻结）

- 最小构建检查：
  - `xcodebuild build`
  - `xcodebuild build-for-testing`
- 最小自动化验证：
  - 至少 1 条定向测试覆盖数据/权限边界关键行为
  - 若完整 `xcodebuild test` / `test-without-building` 卡住，必须记录卡住位置、影响范围与替代结论
- 最小真机/平台验证：
  - HealthKit 首次授权
  - 拒权降级不阻塞训练主流程
  - 完成训练写入 `Health app`
- 发布前文档一致性：
  - `CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS`、`DECISIONS`、`RELEASE_CHECKLIST`、`TEST_MATRIX` 必须和当前事实一致

## 本轮明确排除项

- 账号体系、云端用户数据、后端数据库或 migration
- 历史训练列表、批量历史回填、删除/编辑已写入 workout
- 新增数据采集类型（心率、卡路里、睡眠、位置等）
- 新增 iPhone 端 HealthKit 授权链路
- App Store Connect 提审材料的完整填报执行（仅冻结口径，不代做平台动作）

## 必须由用户手动执行的动作

- Apple 平台 / 图形界面 / 账号环境中必须手动完成：
  - App Store Connect 的 App Privacy 问卷填写与确认
  - 真实配对设备上的 HealthKit 授权路径与写入结果观察
  - Apple Developer 账号侧 capability / 签名 / provisioning 调整（若后续需要）
  - 提审资料上传、截图配置、审核问答填写
- 回传要求：
  - 必须按 `docs/release/MANUAL_PLATFORM_OPERATIONS.md` 的格式回传执行环境、结果、异常与结论

## 风险与依赖

- 若 App Privacy 填报与仓库内口径不一致，会阻塞提审
- 若未来新增数据类型未先补契约，可能导致隐私声明失真
- 真机平台动作不可由 Agent 代做，依赖用户回传质量

## 验收标准

- 已形成 `TASK_013` 正式边界契约
- 已明确 `1.0` 首批数据收集、存储、同步、写入口径
- 已明确 `PrivacyInfo` / App Privacy / HealthKit / WatchConnectivity / UserDefaults 合规边界
- 已明确最小发布检查与验证方式
- 已明确不纳入项与用户手动动作
- 已完成必要共享文档回写，且未进入任何实现代码

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`以用户手动平台操作回传为准`
