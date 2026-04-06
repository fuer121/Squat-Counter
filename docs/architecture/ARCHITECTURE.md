# Squat Counter 工程架构说明

## 目标

第二阶段聚焦于建立 `iPhone + Watch companion` 的工程骨架，先固定目录结构、共享层、同步边界和本地存储边界，不提前展开完整训练流程实现。

## 工程结构

- `SquatCounteriOS`
  iPhone companion 代码入口
- `SquatCounterWatchApp`
  Watch App 容器资源
- `SquatCounterWatchExtension`
  Watch 训练逻辑和界面入口
- `Shared`
  iOS 和 Watch 共同使用的模型、存储协议、同步协议
- `SquatCounterTests`
  共享层和后续状态机测试

## 当前边界

### 单一训练状态源

- 训练主会话归属 `Apple Watch`
- iPhone 不驱动训练状态，只负责配置、引导、历史和帮助

### 同步原则

- `iPhone -> Watch`：默认训练配置同步
- `Watch -> iPhone`：训练结果摘要同步
- 冲突规则：Watch 始终是训练真源

### 本地持久化

- 当前阶段先使用 `UserDefaults`
- iPhone 和 Watch 各自持久化自己的本地副本
- 后续通过 `WatchConnectivity` 做显式同步

### HealthKit

- `1.0` 目标是写入 `Health app` 的 workout
- 第二阶段只先为工程结构预留能力，不在本阶段实现完整授权和 workout 保存

### 构建环境

- 当前工程已建立 `Debug / Beta / Release` 三套构建配置
- 配置文件位于 `Configs/`，用于集中管理编译开关和后续发版差异
- `Beta` 当前仅作为测试发布通道配置，不单独拆分 bundle identifier

## 当前验证结果

- `xcodegen generate` 已通过
- `xcodebuild ... build` 已通过
- `xcodebuild ... test` 在当前 companion 模拟器链路下耗时异常，后续单列到测试链路排查

## 本阶段完成标准

- 可生成 `iOS + Watch companion` 工程
- 共享模型已落地
- 同步 payload 与存储接口已落地
- iPhone 和 Watch 均有最小可运行入口
- 后续第三阶段可以直接进入训练主流程实现
