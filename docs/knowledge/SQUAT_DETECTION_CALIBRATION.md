# 深蹲自动识别：信号管线与标定指南

> 本文档说明 `.live` 模式下从 CoreMotion 原始数据到「一次深蹲」的完整管线，以及为什么这些常数**必须在真机上用真实深蹲数据标定**才能准确。

## 管线总览

```
CMDeviceMotion
  → CoreMotionSquatSampleProvider   (WatchExtension，唯一依赖 CoreMotion 的胶水层)
  → DeviceMotionSnapshot            (Shared，CoreMotion-free，可测试)
  → SquatMotionSignalProcessor      (Shared，纯数学，可单元测试)
  → SquatMotionSample               (normalizedDepth / wristRaise / isStandingStable)
  → SquatDetectionManager.process   (Shared，状态机：standing→descending→bottom→ascending→repCompleted)
  → SquatDetectionEvent.repDetected
  → WorkoutSessionViewModel         (累计次数、组数、触发震动)
```

设计原则：把**唯一**依赖硬件的部分（`CoreMotionSquatSampleProvider`）压到最薄，其余全部是平台无关、可在任意机器上跑单元测试的纯逻辑。

## 核心信号思路

站立时，手腕处的重力向量指向一个稳定的「基线」方向。下蹲时手臂与躯干倾斜，使重力向量相对基线发生角度偏移。我们用这个**角度偏移**（而不是对加速度做积分）来估计深度——这样可以避免腕上 IMU 积分漂移这一通病。

- `normalizedDepth`：重力相对基线的偏移角，按 `fullDepthAngle` 归一化到 0~1。
- `wristRaiseMagnitude`：估计「抬腕看表」的程度，用于让状态机拒绝看表误触发。
- `isStandingStable`：当前是否处于机械上安静、接近基线的稳定站立。

基线会在稳定站立时缓慢自适应（`baselineAdaptationFactor`），吸收姿态漂移但不追逐下蹲动作。

## 两层可调常数

### 1. 信号层 `SquatSignalProcessingConfig`

| 常数 | 默认 | 含义 | 调大的后果 |
| --- | --- | --- | --- |
| `fullDepthAngle` | 1.05 (~60°) | 映射到 depth=1.0 的偏移角 | 需要蹲得更深才算满深度 |
| `standingAngleTolerance` | 0.17 (~10°) | 视为站立基线的角度容差 | 更不敏感，小幅晃动不计深度 |
| `standingAccelerationTolerance` | 0.12 g | 判定「机械安静」的加速度上限 | 更容易判定为稳定站立 |
| `standingRotationTolerance` | 0.6 rad/s | 判定「机械安静」的角速度上限 | 同上 |
| `depthSmoothingFactor` | 0.35 | depth 的 EMA 平滑系数 | 越大越跟手但越抖 |
| `baselineAdaptationFactor` | 0.05 | 站立时基线自适应速度 | 越大越快漂移，可能吃掉慢速下蹲 |
| `wristRaiseFullAngle` | 1.4 (~80°) | 抬腕满量程角 | 越大越不容易判为看表 |

### 2. 状态机层 `SquatDetectionThresholds`

| 常数 | 默认 | 含义 |
| --- | --- | --- |
| `descendingThreshold` | 0.32 | 从站立进入「下降」的 depth 阈值 |
| `bottomThreshold` | 0.68 | 进入「最低点」的 depth 阈值 |
| `ascendingThreshold` | 0.42 | 从最低点进入「上升」的 depth 阈值 |
| `standingThreshold` | 0.12 | 回到站立、完成一次计数的 depth 阈值 |
| `standingStabilityDuration` | 0.35s | 进入下降前需要的稳定站立时长 |
| `cooldownDuration` | 0.8s | 一次计数后的冷却，防抖动重复计数 |
| `maximumWristRaiseMagnitude` | 0.45 | 超过则判为看表、不计数 |

## 为什么默认值一定要在真机上标定

腕上深蹲计数没有「通用正确常数」，原因：

1. **佩戴位置/松紧**不同，手腕到重力向量的映射就不同。
2. **个人深蹲幅度差异大**：有人蹲到大腿水平，有人半蹲，`fullDepthAngle` 必须贴合真实人群分布。
3. **手臂姿势**：抱胸、垂手、扶物，重力向量轨迹完全不同。
4. **采样率与融合延迟**：50 Hz 下的平滑参数换到别的频率就要重调。

默认常数是**有依据的起点**（基于典型 50–80° 腕部摆动），但上线前必须用真实数据校准。

## 标定流程建议

1. 在真机上加一个临时调试开关，把 `DeviceMotionSnapshot` 与派生的 `normalizedDepth` 记成 CSV。
2. 录制多组真实深蹲（不同人、不同幅度、不同佩戴），同时人工标注真值次数。
3. 离线回放数据，扫描阈值网格，以「漏计 + 误计最小」为目标选常数。
4. 单独验证抗误触发：看表、走路、甩手都不应计数。
5. 把标定后的常数写回 `SquatSignalProcessingConfig` / `SquatDetectionThresholds` 的默认值。

## 当前可验证 / 不可验证边界

- **可单元测试（已覆盖）**：信号处理数学、状态机转换、冷却、看表拒绝、完整管线产出恰好一次计数。见 `SquatMotionSignalProcessorTests.swift` 与既有 `SquatDetectionManagerTests`。
- **必须真机验证**：精度、功耗、`workout-processing` 后台续航、不同人群召回率。这些无法在没有传感器的环境里保证。
