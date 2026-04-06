# Task Contract 001

## 基本信息

- 任务名称：Watch 主流程闭环第一阶段
- 任务目标：实现 `WorkoutSessionViewModel` 的最小可运行版本，并让 Watch 端从占位首页进入可联调的训练主流程骨架
- 优先级：`P0`
- 当前阶段：`阶段 2：可开工`

## owner 与协作

- 直接 owner：`开发 Agent`
- 协作方：`总控 Agent`、`产品 Agent`、`UI Agent`、`测试 Agent`
- 是否需要总控介入：`是`

## 输入与输出

- 输入文档：
  - `PRD/PRD_V1.md`
  - `docs/architecture/ARCHITECTURE.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/CURRENT_SPRINT.md`
- 输入代码范围：
  - `Shared/Models/`
  - `SquatCounterWatchExtension/App/`
  - `SquatCounterWatchExtension/Features/`
- 预期输出：
  - `WorkoutSessionViewModel` 最小实现
  - Watch 端主流程页面骨架
  - 训练状态切换最小闭环
  - 与主流程直接相关的首批测试

## 执行边界

- 可修改文件范围：
  - `Shared/Models/`
  - `SquatCounterWatchExtension/App/`
  - `SquatCounterWatchExtension/Features/`
  - `SquatCounterTests/`
- 不可擅自变更项：
  - 不修改 `PRD` 既定范围
  - 不引入真实动作识别实现
  - 不引入 iPhone companion 新功能
  - 不引入 HealthKit 完整授权流
  - 不修改同步链路边界
- 是否允许自动化执行：`是`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务是主线第一优先级，文件范围集中，适合在主线程由总控协调、开发直接推进；现阶段更需要快速形成最小闭环，而不是拆出长期独立开发分支

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 如何用最小状态机先跑通主流程，再接识别与同步
  - 如何在 `vibe coding` 协作中先冻结边界，再补实现

## 验收与风险

- 验收标准：
  - 已有 `WorkoutSessionViewModel` 能表达 `idle / countdown / training / resting / paused / completed`
  - Watch 端不再停留在纯占位首页，能进入主流程骨架
  - 至少支持开始、取消、单组完成、结束训练四类主状态切换
  - 相关测试已覆盖最小主流程状态流转
  - 不依赖真实识别与完整计时，也能完成结构联调
- 风险与依赖：
  - 需要产品 Agent 补充暂停 / 恢复和结束训练的边界口径
  - 需要测试 Agent 确认首批状态机测试范围
  - 需要总控判断页面骨架是否先走简化版本
- 最快验证方式：
  - 先跑相关单元测试
  - 再执行一次 Watch 目标的最小构建检查

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
