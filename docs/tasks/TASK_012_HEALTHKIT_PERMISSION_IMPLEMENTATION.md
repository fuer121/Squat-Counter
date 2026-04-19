# Task Contract 012

## 基本信息

- 任务名称：6.8 HealthKit 与权限首批实现（基于 `TASK_011` 已冻结边界）
- 任务目标：在 `TASK_011` 已冻结的最小权限范围、拒权降级策略、`Workout Session` 生命周期与 `Health app` 写入口径内，补齐 `6.8` 首批实现契约，明确允许修改的 Watch 代码、工程配置、隐私与测试文件范围，以及最小验证与用户手动操作边界，为后续实现提供唯一有效执行口径
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
  - `docs/tasks/TASK_011_HEALTHKIT_PERMISSION_BOUNDARY.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/RISKS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/release/RELEASE_CHECKLIST.md`
  - `docs/release/TEST_MATRIX.md`
  - `docs/release/MANUAL_PLATFORM_OPERATIONS.md`
  - `PRD/PRD_V1.md`
- 输入代码与工程范围：
  - `SquatCounterWatchExtension/`
  - `Shared/Models/WorkoutState.swift`
  - `project.yml`
  - `SquatCounter.xcodeproj/project.pbxproj`
  - `SquatCounterWatchExtension/Support/Info.plist`
- 预期输出：
  - 正式 `TASK_012` 实现契约文档
  - `6.8` 首批实现目标、排除项与授权文件范围
  - `HealthKit capability`、权限文案、`PrivacyInfo.xcprivacy`、`Workout Session`、workout 写入的边界说明
  - 最小验证方式与必须人工执行的平台操作口径

## 执行边界

- 可修改文件范围：
  - Watch 实现：
    - `SquatCounterWatchExtension/`
    - `Shared/Models/WorkoutState.swift`
    - 仅允许为 `HealthKit` 授权、`Workout Session` 生命周期接线、训练完成后 workout 写入与直接相关的状态承载做最小改动
  - 工程与隐私配置：
    - `project.yml`
    - `SquatCounter.xcodeproj/project.pbxproj`
    - `SquatCounterWatchExtension/Support/Info.plist`
    - `PrivacyInfo.xcprivacy`
    - 必要时新增与 Watch `HealthKit` capability 直接相关的 entitlements 文件
  - 测试：
    - `SquatCounterTests/`
  - 共享文档：
    - `docs/planning/CURRENT_SPRINT.md`
    - 必要时：
    - `docs/planning/PROJECT_WBS.md`
    - `docs/planning/RISKS.md`
    - `docs/release/RELEASE_CHECKLIST.md`
    - `docs/release/TEST_MATRIX.md`
    - `docs/release/MANUAL_PLATFORM_OPERATIONS.md`
- 不可擅自变更项：
  - 不改写 `TASK_011` 已冻结的权限范围、拒权降级、`Workout Session` 生命周期与 `Health app` 写入口径
  - 不新增 `iPhone` 侧 `HealthKit` 授权、`Health app` 页面、历史页、结果页或实时状态镜像
  - 不扩展到心率、卡路里、路线、睡眠、体重等额外健康数据读写
  - 不引入云同步、历史补写、删除 / 编辑 workout、复杂冲突 UI
  - 不接受 `Xcode recommended settings` 全量迁移
  - 不提交本地签名环境专属配置，如个人 `DEVELOPMENT_TEAM`
  - 在总控发出新派单前，不创建实现 PR，不自动合并 `main`
- 是否允许自动化执行：`是`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务是 `6.8` 实现前的正式承接文档，核心目的是先冻结实现文件边界、验证方式与人工操作边界，再进入编码

## 继承口径

- 本任务严格继承 `TASK_011` 已冻结结论：
  - `1.0` 首批 `HealthKit` 只覆盖 `Apple Watch` 侧 workout 相关最小权限
  - `HealthKit` 拒权不能阻塞 Watch 本地训练主流程
  - `Workout Session` 只由 Watch 侧持有和驱动
  - 完成路径最多写入一条 workout 到 `Health app`
  - 倒计时取消、未进入训练、拒权与当前定义的中止路径不写入 `Health app`

## 6.8 首批实现目标

- 必须落地的最小闭环：
  - Watch 侧最小 `HealthKit capability` 与授权接线
  - 首次授权与拒权后的非阻塞降级
  - `Workout Session` 与现有训练状态机的最小生命周期接线
  - 已完成训练后写入一条对应的 workout 到 `Health app`
  - 与以上能力直接相关的权限文案、隐私清单、测试与发布文档收口
- 本轮用户可感知结果：
  - 首次进入相关训练链路时，Watch 可按产品口径请求最小必要授权
  - 拒权后训练仍可继续，但不会写入 `Health app`
  - 完成一次训练后，可在系统 `Health app` 中看到对应 workout 记录

## 本轮明确排除项

- `iPhone` 侧任何 `HealthKit` 页面、授权流程或状态解释页
- 历史 workout 列表、结果详情页、同步中心
- 心率、能量消耗、路线、VO2 Max、睡眠、体重等额外数据读写
- 中断训练写入部分 workout、批量补写、编辑 / 删除系统 workout
- 把 `HealthKit` 或 `Workout Session` 提升为训练业务真源
- 与 `6.8` 无关的 UI 重构、状态机扩展或签名环境个性化改动

## 页面层与系统层边界

- 页面层边界：
  - Watch 页面只允许承接最小权限说明、拒权后的非阻塞提示与必要状态反馈
  - 不新增独立“权限中心”“健康数据中心”或复杂设置页
- 系统层边界：
  - `HKHealthStore`、`HKWorkoutSession`、workout 写入逻辑必须收敛在 Watch 侧系统能力适配层
  - 现有训练状态、组次、计时和识别结果仍以现有 Watch 本地状态机为业务真相
  - `HealthKit` 只消费训练结果并提供系统写入，不反向定义训练完成条件

## HealthKit capability / 权限文案 / PrivacyInfo 边界

- `HealthKit capability`：
  - 仅允许为 Watch 首批 workout 写入闭环增加最小必需 capability / entitlements
  - 若工程层需要联动 iOS 容器或 target 配置，必须以“满足 Watch capability 生效”为唯一理由，不得顺手引入其他平台能力
- 权限文案：
  - 仅允许声明“用于记录深蹲训练 workout 到 `Health app`”等与当前闭环一致的最小目的
  - 不得提前声明当前并未读写的数据类型或未来能力
- `PrivacyInfo.xcprivacy`：
  - 仅允许登记当前真实使用的数据类别与访问目的
  - 不得为尚未实现的数据采集预留泛化声明

## Workout Session 与 workout 写入边界

- `Workout Session`：
  - 只能在 Watch 真正进入训练链路时启动，不早于倒计时完成后的训练进入点
  - `training`、`resting`、`paused` 共享一次系统 session 生命周期
  - 会话结束点必须与当前训练完成 / 中止边界一致，不能额外创造业务状态
- workout 写入：
  - 最多写入一条“已完成深蹲训练”的最小 workout 记录
  - 写入摘要只允许使用当前业务闭环已具备的起止时间、组数、次数等最小信息
  - 不得在拒权、取消倒计时、未进入训练或当前定义的非完成路径下写入

## 最小验证方式

- 最快相关验证：
  - 定向单元测试：覆盖授权状态映射、拒权降级、`Workout Session` 接线适配或 workout 摘要映射中的至少一条成功用例
  - 最小构建验证：Watch 目标相关 `xcodebuild build` 或 `build-for-testing`
- 扩大验证前提：
  - 若 `XCTest` 或完整 `xcodebuild test` 在当前环境卡住，必须先记录卡住位置、影响范围与替代结论，不得跳过说明
- 真实设备验证：
  - 必须依赖真实配对 `iPhone + Apple Watch`
  - 必须人工完成首次授权、拒权降级与 workout 写入 `Health app` 验证
  - 未完成真实设备闭环，不得宣称 `6.8` 完整交付

## 必须由用户手动执行的动作

- 按 [docs/release/MANUAL_PLATFORM_OPERATIONS.md](/Users/fuer/Desktop/AI%20coding/Project/Squat%20Counter/docs/release/MANUAL_PLATFORM_OPERATIONS.md) 执行：
  - 首次 `HealthKit` 授权
  - 拒权降级验证
  - 真实 `Apple Watch` 训练完成后写入 `Health app` 验证
- 若 capability / 签名 / provisioning 需要 Apple Developer 账号侧操作：
  - 由用户或总控判断是否启用平台 Agent
  - 当前开发 Agent 不默认代做账号侧与证书侧动作
- 人工验证结果必须按 runbook 中的结果回传模板回写总控线程

## 验收与风险

- 验收标准：
  - 已形成正式 `TASK_012` 契约文档
  - 已明确 `6.8` 首批实现目标与排除项
  - 已明确允许修改的 Watch、工程配置、隐私与测试文件范围
  - 已明确 `HealthKit capability`、权限文案、`PrivacyInfo.xcprivacy`、`Workout Session` 与 workout 写入边界
  - 已明确最小验证方式与必须人工执行的平台操作
  - 已完成最小共享文档回写，且未进入任何实现代码
- 风险与依赖：
  - `HealthKit` 真机能力与提审配置仍依赖真实配对设备及 Apple 账号环境
  - 若 capability 配置要求落入本地签名环境专属字段，必须先隔离，不得混入业务交付
  - 若实现期发现 `Workout Session` 接线需要扩大到共享状态结构之外，必须先回总控补边界，不得顺手扩改
- 最快验证方式：
  - 检查本轮提交是否只包含 `TASK_012` 契约与最小状态文档回写
  - 对照 `TASK_011`、`TASK_012`、`CURRENT_SPRINT`，确认 `6.8` 已从“边界冻结”推进到“实现契约已补齐 / 等待实现”

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`以真实配对设备手动验证为准`
