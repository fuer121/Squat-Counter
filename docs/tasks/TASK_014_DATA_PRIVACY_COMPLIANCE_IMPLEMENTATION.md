# Task Contract 014

## 基本信息

- 任务名称：6.9 数据与隐私合规首批实现（基于 `TASK_013` 已冻结边界）
- 任务目标：在 `TASK_013` 已冻结的数据与隐私边界内，补齐 `6.9` 首批实现契约，明确允许修改的代码、配置、隐私清单、测试与文档文件范围，统一 `PrivacyInfo.xcprivacy` / App Privacy / HealthKit / WatchConnectivity / UserDefaults 的实现期边界与最小验证方式，并明确必须由用户手动执行的平台动作
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
  - `docs/tasks/TASK_013_DATA_PRIVACY_COMPLIANCE_BOUNDARY.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/RISKS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/release/RELEASE_CHECKLIST.md`
  - `docs/release/TEST_MATRIX.md`
  - `docs/release/MANUAL_PLATFORM_OPERATIONS.md`
- 输入代码与配置范围：
  - `Shared/Storage/WorkoutConfigStoring.swift`
  - `Shared/Sync/SyncPayload.swift`
  - `Shared/Sync/WatchConnectivitySyncing.swift`
  - `Shared/Models/WorkoutState.swift`
  - `SquatCounteriOS/Features/Home/`
  - `SquatCounterWatchExtension/Features/`
  - `SquatCounterWatchExtension/Support/Info.plist`
  - `SquatCounterWatchExtension/Support/PrivacyInfo.xcprivacy`
  - `SquatCounterWatchExtension/Support/SquatCounterWatchExtension.entitlements`
  - `project.yml`
  - `SquatCounter.xcodeproj/project.pbxproj`
- 预期输出：
  - 正式 `TASK_014` 实现契约文档
  - `6.9` 首批实现目标、文件边界、排除项
  - `PrivacyInfo.xcprivacy` / App Privacy / HealthKit / WatchConnectivity / UserDefaults 的实现期边界
  - 最小验证方式与必须由用户手动执行的平台动作口径

## 执行边界

- 可修改文件范围：
  - 代码（仅限与 `TASK_013` 已冻结数据边界直接相关的最小改动）：
    - `Shared/Storage/WorkoutConfigStoring.swift`
    - `Shared/Sync/SyncPayload.swift`
    - `Shared/Sync/WatchConnectivitySyncing.swift`
    - `Shared/Models/WorkoutState.swift`
    - `SquatCounteriOS/Features/Home/`
    - `SquatCounterWatchExtension/Features/`
  - 配置与隐私清单：
    - `SquatCounterWatchExtension/Support/Info.plist`
    - `SquatCounterWatchExtension/Support/PrivacyInfo.xcprivacy`
    - `SquatCounterWatchExtension/Support/SquatCounterWatchExtension.entitlements`
    - `project.yml`
    - `SquatCounter.xcodeproj/project.pbxproj`
  - 测试：
    - `SquatCounterTests/`
  - 共享文档：
    - `docs/planning/CURRENT_SPRINT.md`
    - 必要时：
    - `docs/planning/PROJECT_WBS.md`
    - `docs/planning/RISKS.md`
    - `docs/planning/DECISIONS.md`
    - `docs/release/RELEASE_CHECKLIST.md`
    - `docs/release/TEST_MATRIX.md`
    - `docs/release/MANUAL_PLATFORM_OPERATIONS.md`
- 不可擅自变更项：
  - 不改写 `TASK_013` 已冻结的数据采集、存储、同步、系统写入口径
  - 不新增账号数据、云同步、后端数据库、历史列表、批量回填
  - 不新增 `iPhone` 侧 `HealthKit` 授权链路
  - 不扩展心率、卡路里、睡眠、体重、位置等额外健康数据类型
  - 不引入统计埋点、分析遥测或未在 `TASK_013` 中声明的网络上报
  - 不创建实现 PR，不自动合并 `main`
- 是否允许自动化执行：`是`（仅限本地构建/测试与文档回写，不含 Apple 平台账号侧动作）
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务是 `6.9` 进入实现前的正式承接文档，先冻结实现文件边界和验证口径，再由总控派发实现写任务

## 继承口径

- 本任务严格继承 `TASK_013` 已冻结结论：
  - 当前仅承接 `UserDefaults` 训练默认配置存储
  - 当前仅承接 `WatchConnectivity` 的 `WorkoutConfig` / 最近一次 `WorkoutSummary` 最小同步
  - 当前仅承接 Watch 完成训练路径写入单条 `Health app` workout
  - `WatchStateSnapshot` 只保留协议能力，不作为 `1.0` 首批用户可见能力

## 6.9 首批实现目标

- 必须落地的最小实现目标：
  - 让代码、配置与 `PrivacyInfo.xcprivacy` 的声明保持一致，不出现“实现行为与隐私声明”偏差
  - 保持 `UserDefaults` / `WatchConnectivity` / `Health app` 三类数据链路与 `TASK_013` 口径一致
  - 为 App Privacy 平台填报提供与仓库事实一致的最小对照口径（不代做平台填报）
  - 保持帮助与支持中的隐私/支持入口与当前提审口径一致
- 本轮用户可感知结果：
  - 不新增功能面，不改变训练主流程
  - 数据与隐私行为、清单声明和发布检查口径保持一致且可审计

## 实现期边界（PrivacyInfo / App Privacy / HealthKit / WatchConnectivity / UserDefaults）

- `PrivacyInfo.xcprivacy`：
  - 仅声明当前真实收集的数据类别与用途
  - 不为未实现数据类型做前置声明
- App Privacy（App Store Connect）：
  - 仅按仓库当前真实行为填写
  - 平台问卷由用户手动执行并回传结果；未回传前不得声称“已完成填报”
- HealthKit：
  - 维持 `6.8` 已冻结最小 workout 权限与写入边界
  - 不扩展到额外健康数据读写
- WatchConnectivity：
  - 仅同步 `WorkoutConfig` 与最近一次 `WorkoutSummary`
  - 不扩展为实时镜像、历史批量同步或账号数据同步
- UserDefaults：
  - 仅保存训练默认配置
  - 不保存身份类敏感信息与历史训练列表

## 最小验证方式

- 最快相关检查：
  - `xcodebuild build`
  - `xcodebuild build-for-testing`
- 最小自动化验证：
  - 至少 1 条与数据/隐私边界直接相关的定向测试（如 `SyncPayload` 或 `WorkoutConfigStore`）
  - 若完整 `xcodebuild test` / `test-without-building` 卡住，必须记录卡住位置、影响范围与替代结论
- 文档一致性验证：
  - `TASK_013`、`TASK_014`、`CURRENT_SPRINT`、`PROJECT_WBS`、`RISKS`、`DECISIONS`、`RELEASE_CHECKLIST`、`TEST_MATRIX` 的 `6.9` 口径一致

## 必须由用户手动执行的动作

- 以下动作必须由用户在 Apple 平台、图形界面或账号环境中执行：
  - App Store Connect 的 App Privacy 问卷填写与确认
  - Apple Developer 账号侧 capability / 签名 / provisioning 调整（若后续需要）
  - 真实配对设备上的系统权限弹窗路径选择与 `Health app` 写入结果观察
  - 提审后台材料上传与审核问答填写
- 回传要求：
  - 必须按 `docs/release/MANUAL_PLATFORM_OPERATIONS.md` 的模板回传执行环境、步骤结果、异常与结论

## 本轮明确排除项

- 不进入任何 `6.9` 功能实现代码提交
- 不创建实现 PR
- 不自动合并 `main`
- 不扩大任务到账号体系、云端数据、历史系统或额外健康数据类型

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_014` 实现契约文档
  - 已明确 `6.9` 首批实现目标与排除项
  - 已明确允许修改的代码、配置、隐私清单、测试与文档文件范围
  - 已明确 `PrivacyInfo.xcprivacy` / App Privacy / HealthKit / WatchConnectivity / UserDefaults 的实现期边界
  - 已明确最小验证方式与用户手动平台动作
  - 已完成必要状态文档回写，且未进入任何功能实现代码
- 风险与依赖：
  - App Privacy 平台问卷与提审后台动作依赖用户手动执行与回传
  - 若后续实现超出 `TASK_013` 冻结边界，必须先回总控补契约

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`以用户手动平台操作回传为准`
