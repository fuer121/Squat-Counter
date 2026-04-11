# 风险基线

## 当前风险

### 高风险

- 动作识别准确率不可控，影响核心体验

### 中风险

- `1.0` 写入 `Health app` 的实现复杂度较高，影响权限、提审和数据流
- `6.7` 最小同步闭环已完成代码落地，但真实配对设备上的配置下发、结果回传、幂等去重与断连恢复仍未验证；在真机确认前，不能把跨设备闭环视为完全成立
- `TASK_008` 已冻结 `6.6` 的实现文件范围与本地持久化边界；若后续实现阶段绕过 `PhoneCompanionViewModel` / `WorkoutConfigStoring` 直接在页面层操作存储或同步抽象，将导致 `6.6` 与 `6.7` 职责再次串扰
- `TASK_009` 已冻结 `6.7` 首批同步范围与可见承载方式，当前也已完成 `WatchConnectivitySyncing` 最小实现；但轻量重试仍停留在边界约束层，尚未补到更强的 transport 级容错与恢复验证
- App Store 合规项若后置处理，容易阻塞提审
- 帮助与支持页所需的最终 FAQ 内容、支持联系方式和隐私政策正式 URL 尚未冻结；不阻塞 `6.6` 页面骨架实现，但会阻塞提审收口
- watch 震动体验尚未完成真机验证，可能导致震动强度、优先级体感与设计口径存在偏差
- `6.5` 当前仅完成模拟识别联调、单测与 Watch Simulator 构建验证；真实手表上的传感器采样、阈值调优与签名链路尚未验证，可能导致真机表现与当前验证结果存在偏差

### 低风险

- companion / 同步相关 iOS 模拟器测试链路在 `xcodebuild test`、`test-without-building` 执行阶段仍可能卡住；本轮 `6.7` 定向 `xcodebuild test -only-testing:SquatCounterTests/WorkoutConfigTests` 与 `test-without-building -only-testing:SquatCounterTests/SyncPayloadTests -only-testing:SquatCounterTests/WorkoutSessionViewModelTests` 的现象均为 simulator 已 `Booted`，但 XCTest 执行阶段未继续产出结果；`build-for-testing` 与 app 安装启动验证已通过，当前影响完整测试执行确认，不阻塞本轮最小实现代码落地

## 应对原则

- 高风险先做最小可验证方案
- 中风险提前建文档和门禁，避免后补
- 风险状态变化后，必须在 checkpoint 前更新本文件
