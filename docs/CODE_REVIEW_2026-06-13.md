# Squat Counter 代码审查报告

> 审查范围：仓库内全部 18 个 Swift 源文件（约 2400 行实现 + 966 行测试）、构建配置（`project.yml`、`Configs/*.xcconfig`）、权限清单（`Info.plist`、`PrivacyInfo.xcprivacy`、`entitlements`）。
> 审查日期：2026-06-13
> 审查环境说明：本次审查在无 Xcode 的环境下完成，未做实际 `xcodebuild` 编译/真机验证。所有结论基于静态阅读，编译与设备验证需在本地 Xcode 完成。

---

## 一、总体评价

这是一个**架构素质明显高于完成度**的项目。

核心训练逻辑层（`Shared/`）的工程质量相当扎实：全面采用协议抽象 + 依赖注入，状态机清晰，副作用（计时、震动、HealthKit、跨端同步）都被隔离在可替换的边界后面，配套近千行单元测试用纯内存的 fake scheduler/clock 把时间相关逻辑测得很干净。这套结构放在任何团队里都算得上是合格偏上的可维护代码。

但项目存在一个**根本性的功能缺口**，以及若干工程层面的债务。最关键的问题是：**App 的核心卖点——"自动深蹲计数"——目前在产品里完全没有接通真实硬件**。下面按严重程度分级展开。

---

## 二、关键问题（P0 — 阻断核心价值）

### P0-1　自动计数从未接入 CoreMotion，`.live` 模式是死路

这是整份报告里最重要的一条。

`SquatDetectionManager` 设计了一个完整的、可消费 `SquatMotionSample`（含归一化深度、抬腕幅度、站立稳定标志）的状态机，`process(_:)` 方法也实现了 `.live` 模式的识别逻辑。但**全仓库没有任何一行 CoreMotion 代码**（没有 `CMMotionManager`、`CMDeviceMotion`、`CMBatchedSensorManager`），也就是说：

- 没有任何地方真正去**采集**传感器数据并构造 `SquatMotionSample`；
- `process(_:)` 这个 `.live` 模式入口在整个 App 运行路径里**从未被调用**（只有测试在调用它）；
- `WorkoutSessionViewModel` 的 `detectionMode` 默认硬编码为 `.simulation`，`enterTrainingState` 里调用的 `startDetection()` 也只把这个 `.simulation` 模式透传下去；
- Watch 主界面的"主操作"按钮绑定的是 `simulateRepDetection()` → `detectionManager.simulateRep()`，也就是**靠用户手点按钮来"模拟"一次深蹲**。

**结论**：当前形态下，用户做深蹲时手表不会自动计数，必须手动点"模拟识别"或 `+1`。README 里宣称的"深蹲自动计数"在产品层面尚未实现——识别算法写好了，但与硬件之间缺了一座桥（一个 `CoreMotionSquatSampleSource` 之类的采集器，把加速度/姿态数据归一化成 `SquatMotionSample` 再喂给 `process(_:)`）。

**影响**：这是 MVP 验收清单里"训练中可自动计数"这一条目前无法真正勾选的根因。

**修复方向**（对应任务 #3）：
1. 新增一个传感器采集组件（建议在 `SquatCounterWatchExtension` 内，因为 CoreMotion 设备运动在 watchOS 上有平台细节），用 `CMMotionManager`/`CMBatchedSensorManager` 订阅设备运动；
2. 把原始数据归一化成 `SquatMotionSample`（深度估计、抬腕判定、站立稳定判定），这一步是算法核心，需要真机调参；
3. 在训练态把采集器的输出接到 `SquatDetectionManager.process(_:)`；
4. 把 `detectionMode` 默认从 `.simulation` 切到 `.live`（或做成可配置，调试期保留 simulation）；
5. 保留 `+1 / -1` 作为手动纠错，保留 simulation 作为无传感器环境（如模拟器）下的联调通道。

---

## 三、重要问题（P1 — 架构债务 / 健壮性）

### P1-1　`WorkoutSessionViewModel` 职责过载（494 行）

这个 ViewModel 同时扛着：状态机流转、计数与组数管理、倒计时/休息/节奏的 timer 协调、暂停恢复、配置的本地变更、跨端 config 同步与冲突合并（`lastConfigUpdatedAt` / `pendingConfig`）、HealthKit 会话生命周期、训练摘要的组装与发送、以及一堆 health 状态的中文文案。

其中**至少两块可以干净地抽出去**：
- **HealthKit 生命周期协调**（`prepareHealthWorkoutIfNeeded` / `finishHealthWorkout` / `discardHealthWorkout` / 两个 `handleHealth*Result` / `healthMessage`，约 80 行）可以收敛到一个 `WorkoutHealthCoordinator`，ViewModel 只持有它并暴露 `healthStatusMessage`；
- **config 同步与冲突合并**（`observeSyncPayloads` / `handleIncomingSyncPayload` / `applyLocalConfigChange` / `applyPendingConfigIfNeeded` / `pendingConfig` / `lastConfigUpdatedAt`，约 50 行）可以抽成一个 `WorkoutConfigSyncController`。

抽离后 ViewModel 会回到"纯状态机 + 进度"的核心职责，更易读也更易测。

### P1-2　Watch 主视图命名与结构停留在脚手架阶段（323 行）

`WatchArchitectureOverviewView` 这个名字本身就暴露了它还是"架构概览"原型——但它实际上**就是 Watch 端的主训练界面**（`SquatCounterWatchExtensionApp` 直接把它当根视图）。两个问题：

1. **命名误导**：应更名为 `WorkoutRootView` 或 `WatchWorkoutView` 之类能反映其真实职责的名字；
2. **单文件塞了 6 个状态的 UI**：idle/countdown/training/resting/paused/completed 全挤在一个 323 行的文件里。建议按状态拆成独立子视图（`ConfigView`、`CountdownView`、`SessionView`、`RestView`、`CompletedView`），主视图只做 `switch viewModel.state` 的路由。

此外视图里还有些产品文案仍是开发期口径（如"当前先用模拟识别联调主流程"），接通真实计数后需要一并更新。

### P1-3　HealthKit 授权失败被静默吞掉

`WatchWorkoutHealthManager.requestAuthorization` 里，`success == false`（用户拒绝授权）和 `success == true` 走了**完全相同的分支**（都 `continuation.resume(returning: ())`）：

```swift
if success {
    continuation.resume(returning: ())
} else {
    continuation.resume(returning: ())   // ← 与上面没有区别
}
```

虽然后续 `resolveAuthorizationStatus` 会再查一次 `currentAuthorizationStatus()` 来兜底，逻辑上不会出错，但这段代码意图不清、有误导性。建议要么合并成一句，要么真正区分（拒绝时直接返回 denied，省掉一次多余的状态查询）。

### P1-4　训练态退到后台 / 锁屏时计时器会停摆

`TimerManager` 用 `RunLoop.main` + `Timer` 实现，`FoundationTimerScheduler` 把 timer 加到主 RunLoop。watchOS 上手腕放下、息屏或 App 进入后台时，主 RunLoop 的常规 timer 不保证继续触发。`Info.plist` 里虽然声明了 `WKBackgroundModes: workout-processing`，且 HealthKit workout session 确实能拿到后台运行时间，但**当前 timer 实现并没有借助 workout session 的运行时来驱动**——两者是脱节的。

**影响**：组间休息倒计时、固定节奏提示在息屏后可能不准甚至暂停。这在真机上才会暴露，模拟器和单测都发现不了。需要在真机验证，并考虑把节奏/休息计时与 HKWorkoutSession 的运行时对齐。

---

## 四、次要问题（P2 — 细节 / 一致性）

### P2-1　`completeRest()` 与定时器自动结束休息存在重复触发风险（低）
`completeRest()`（用户点"提前开始"）会 `timerManager.cancel()` 后进入训练态；而休息计时自然结束走的是 `handleTimerEvent(.restCompleted)`。两条路径都有 `guard state == .resting` 保护，所以不会双触发——这点测试也覆盖了。属于"目前安全但耦合略紧"，抽离 timer 协调时留意即可。

### P2-2　`detectionMode` 缺少运行时切换入口（中）
即便接通了 CoreMotion，目前也没有从 UI/配置切换 simulation/live 的通道。调试与真机联调会需要它，建议接通计数时一并设计（哪怕只是 Debug build 下的隐藏开关）。

### P2-3　大量面向用户的中文文案散落在代码里（低）
health 状态文案、session hint、各种提示语都硬编码在 View 和 ViewModel 里，没有走 `Localizable.strings`。MVP 阶段可接受，但若有出海或文案统一维护的打算，迟早要收口。

### P2-4　`WorkoutProgress.empty` 的 `currentSet` 从 1 开始（语义提醒，非缺陷）
`.empty` 的 `currentSet = 1` 是有意为之（第一组从 1 开始计数），但 `latestWorkoutSummary` 用 `progress.currentSet` 作为 `totalSets`。在正常完成路径下，完成最后一组时 `currentSet` 恰好等于 `totalSets`，所以结果正确；但这依赖"完成态不再自增 currentSet"这一隐含约定。建议加一行注释说明，避免后人重构时踩坑。

### P2-5　`SquatCounterWatchApp/Resources/README.md` 等占位内容
Watch App target 目录下只有一个 README 占位，`project.yml` 里 `SquatCounterWatchApp` 是个空壳 watchapp2（真正逻辑在 extension）。这是 watchOS 的标准双 target 结构，没问题，仅提示别误删。

---

## 五、做得好的地方（值得保持）

- **协议 + 依赖注入贯彻得很彻底**：`TimerManaging`、`HapticManaging`、`SquatDetectionManaging`、`WorkoutHealthManaging`、`WatchConnectivitySyncing`、`WorkoutConfigStoring` 全是协议，每个都有 Noop/Spy 实现。这是这套代码可测性的根基。
- **时间相关逻辑的可测性设计是范本级的**：`TimerScheduling` 抽象 + 测试里的 `TestTimerScheduler`（虚拟时钟、可 `advance(by:)`）让倒计时、休息、节奏这些本来最难测的东西变得确定可控。
- **跨端同步的冲突处理考虑了时序**：用 `updatedAt` 比较 + 训练中收到 config 先 `pendingConfig` 暂存、回到 idle/completed 再应用，避免了训练中途参数被远端改掉。
- **HealthKit 边界处理得当**：授权被拒/设备不支持都不阻断训练主流程，只更新提示文案。降级策略清晰。
- **震动优先级模型干净**：`playHighestPriority` + 明确的 priority 表，保证"完成训练"震动不会被同时触发的"节奏提示"盖过。
- **输入边界防御到位**：`WorkoutConfig`、`SquatDetectionThresholds`、`SquatMotionSample` 都在 init 里做了 clamp，阈值之间还做了相对约束（descending < bottom、ascending 介于两者之间）。
- **并发标注规范**：`project.yml` 开了 `SWIFT_STRICT_CONCURRENCY: complete`，模型类型普遍标了 `Sendable`，`WatchWorkoutHealthManager` 标了 `@MainActor`。

---

## 六、测试现状

测试覆盖**核心逻辑层非常充分**，共约 966 行，覆盖：

- ✅ 配置默认值与 clamp
- ✅ SyncPayload 编解码往返
- ✅ 配置存储持久化
- ✅ ViewModel 全状态流转（倒计时取消/完成、暂停恢复、组完成、训练完成、跳过休息、自动进下一组、结束训练、手动 +1/-1 边界、倒计时态拒绝操作）
- ✅ 检测事件→计数、检测生命周期跟随训练态、暂停时忽略 repDetected
- ✅ 训练中收到 config 的暂存与延迟应用
- ✅ 完成训练发送摘要 payload
- ✅ HealthKit 生命周期与授权被拒降级
- ✅ SquatDetectionManager 的 simulation/live 识别、半蹲拒绝、抬腕误触发拒绝、阈值 clamp
- ✅ TimerManager 单上下文、暂停恢复保留剩余秒
- ✅ HapticManager 优先级

**测试盲区**（对应任务 #5 补强方向）：
- ❌ **CoreMotion 采集层**——目前不存在，接通后需要为"原始数据→SquatMotionSample 归一化"补测；
- ❌ **`WatchConnectivitySyncCoordinator` 真实收发路径**——只测了 payload 编解码，没测 WCSession 委托回调→通知发布的链路（可对 `WatchConnectivitySessioning` 做 fake 来补）；
- ❌ **PhoneCompanionViewModel** 没有任何测试（onboarding 状态、config 持久化、收到 summary 的去重与持久化都没覆盖）；
- ❌ **后台/息屏下计时行为**——这类只能靠真机或集成测试，单测覆盖不了，需列入手动测试矩阵。

---

## 七、建议的执行顺序

结合你"全选"的四个方向，建议按下面顺序推进，让每一步都为下一步铺路：

1. **接通真实自动计数（任务 #3，P0）**——这是补上核心价值的关键，也是其他工作的前提。先做采集层 + 接线，simulation 作为 fallback 保留。
2. **拆分臃肿视图与 ViewModel（任务 #4，P1-1 / P1-2）**——在计数接通后做，因为接线会动到 `enterTrainingState`/`startDetection` 附近的代码，拆分时正好一并理顺。
3. **补强测试与边界（任务 #5）**——为新增的采集层补测，补 PhoneCompanionViewModel 测试，补 sync 链路测试，并把"后台计时""真机识别准确率"写进手动测试矩阵。
4. **真机验证（贯穿）**——P1-4（后台计时）和 P0（识别调参）都必须在真机上验证，这部分需要你在本地 Xcode 配合。

---

## 八、需要你确认的两个现实约束

1. **编译验证**：本沙箱无 Xcode，我能保证代码逻辑自洽、风格一致、符合现有架构，但**最终编译通过与真机行为需要你在本地 Xcode 验证**。我会在每步改动后说明应如何验证。
2. **算法调参**：CoreMotion 的深度/抬腕归一化阈值是经验值，必须用真实手表数据迭代。我能搭好可调参的框架并给出合理初值，但精度调优依赖你的真机反馈。
