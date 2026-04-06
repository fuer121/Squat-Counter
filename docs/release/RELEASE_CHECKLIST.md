# 发布检查清单

## 构建与签名

- [ ] Bundle ID 已确认
- [ ] 签名、证书、Provisioning 可用于 Archive
- [ ] `Debug / Beta / Release` 构建配置可用

## 权限与隐私

- [ ] HealthKit capability 已配置
- [ ] 权限文案与真实用途一致
- [ ] 拒权降级策略已确认
- [ ] `PrivacyInfo.xcprivacy` 已补齐
- [ ] App Privacy 信息与实际行为一致

## 质量门禁

- [ ] 核心状态机测试通过
- [ ] 计时逻辑测试通过
- [ ] 识别逻辑测试通过
- [ ] 真机验证矩阵已执行
- [ ] 已知风险已记录

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

- [ ] 已形成 PR
- [ ] 未自动合并 `main`
- [ ] 用户已确认最终发布动作
