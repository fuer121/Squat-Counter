# 发布检查清单

## 构建与签名

- [ ] Bundle ID 已确认
- [ ] 签名、证书、Provisioning 可用于 Archive
- [ ] `Debug / Beta / Release` 构建配置可用

## 权限与隐私

- [x] HealthKit capability 已配置
- [x] 权限文案与真实用途一致
- [x] 拒权降级策略已确认
- [x] `PrivacyInfo.xcprivacy` 已补齐
- [ ] App Privacy 信息与实际行为一致

### 6.9 当前确认

- 已冻结 `TASK_013`：数据与隐私合规首批边界
- 已补齐 `TASK_014`：数据与隐私合规实现契约
- 已确认当前数据口径：`UserDefaults` 训练配置、`WatchConnectivity` 最小同步、Watch 完成路径写入 `Health app`
- 已按当前真实行为收口 `PrivacyInfo.xcprivacy`：`HealthFitness` 数据用途 + `UserDefaults` 必需 API 访问声明（`CA92.1`）
- 与本轮实现直接相关的最小验证已通过：`plutil -lint`、`build-for-testing`、`WorkoutConfigStoreTests` 定向测试
- App Privacy 问卷与提审后台动作仍需用户在 Apple 平台手动执行并回传

## 质量门禁

- [ ] 核心状态机测试通过
- [ ] 计时逻辑测试通过
- [ ] 识别逻辑测试通过
- [ ] 真机验证矩阵已执行
- [ ] 已知风险已记录

### 6.8 当前确认

- 已完成真实配对 `iPhone + Apple Watch` 上的 `HealthKit` 首次授权验证
- 已完成真实配对设备上的拒权降级验证，确认训练主流程不被阻塞
- 已完成真实配对设备上的完成训练写入 `Health app` 验证
- `build` 与 `build-for-testing` 已通过；完整 `XCTest` 执行阶段在当前环境仍可能卡住

## 部署检查

- [ ] 部署步骤已确认
- [ ] 环境差异已确认
- [ ] smoke check 已定义
- [ ] 回滚入口已确认

## 数据变更检查

- [ ] migration 已准备
- [ ] 回滚方案已准备
- [ ] 兼容性已确认
- [ ] 数据风险已记录

## 提审材料

- [ ] App 名称、副标题、描述、关键词已准备
- [ ] iPhone 截图已准备
- [ ] Apple Watch 截图已准备
- [ ] App 图标已准备
- [ ] `App Review Notes` 已准备

## 发布约束

- [x] 已形成 PR
- [ ] 未自动合并 `main`
- [ ] 用户已确认最终发布动作
