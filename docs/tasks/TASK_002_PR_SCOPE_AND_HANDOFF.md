# Task Contract 002

## 基本信息

- 任务名称：PR / 分支收口（承接 `TASK_001` 交付）
- 任务目标：冻结当前首个可交付 PR 的范围、直接 owner、文件边界、验收口径与自动化边界，并判断本次 PR 是否必须连同当前未纳管的项目基线一起收口
- 优先级：`P0`
- 当前阶段：`阶段 1：待调度`

## owner 与协作

- 直接 owner：`总控 Agent`
- 协作方：`开发 Agent`
- 是否需要总控介入：`是`

## 输入与输出

- 输入文档：
  - `AGENTS.md`
  - `docs/agents/AGENT_SYSTEM.md`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
  - `docs/planning/DECISIONS.md`
  - `docs/planning/RISKS.md`
  - `docs/tasks/TASK_001_WATCH_SESSION_CORE.md`
  - `docs/release/RELEASE_CHECKLIST.md`
- 输入代码范围：
  - 仓库当前 `git status`
  - 当前已落地但尚未纳入 Git 的工程与文档文件
- 预期输出：
  - 首个 PR 的交付范围判断结论
  - 分支与 PR 收口任务的验收标准
  - 是否允许继续执行 Git/PR 动作的结论
  - 若允许，后续 Git / PR 执行任务的派单输入

## 执行边界

- 可修改文件范围：
  - `docs/tasks/`
  - `docs/planning/CURRENT_SPRINT.md`
  - `docs/planning/PROJECT_WBS.md`
- 不可擅自变更项：
  - 不继续实现 `6.4 训练控制能力`
  - 不直接创建分支
  - 不直接提交
  - 不直接创建 PR
  - 不自动合并 `main`
- 是否允许自动化执行：`否`
- 是否需要子线程：`否`
- 是否需要 worktree：`否`
- 使用理由：当前任务是交付收口判断与文档冻结，不是中等以上实现任务；目标是明确 PR 范围，而不是开展新的并行开发

## 经验沉淀判断

- 是否可能产生可复用经验：`是`
- 若是，候选主题：
  - 当仓库存在大面积未纳管基线文件时，如何判断首个 PR 不应伪装成功能增量 PR
  - 如何在 `vibe coding` 项目中区分“功能完成”与“可交付范围已冻结”

## 验收与风险

- 验收标准：
  - 已明确当前仓库跟踪文件与未跟踪文件的实际边界
  - 已明确本次首个 PR 不能仅包含 `TASK_001` 增量，而必须连同未纳管的工程与共享文档基线一起收口，或给出反证
  - 已明确后续 Git / PR 操作的直接 owner、可操作范围与前置条件
  - 在未满足范围冻结前，不执行 Git 分支、提交或 PR 创建
- 风险与依赖：
  - 当前仓库仅跟踪极少量文件，若直接创建 PR，会导致任务边界与基线初始化混杂
  - `README.md` 当前存在已跟踪修改，需在后续交付任务中判断是否并入首个 PR
  - 后续 Git / PR 收口前需要再次执行总控 checkpoint
- 最快验证方式：
  - `git status --short --branch`
  - `git ls-files`
  - 对照 `CURRENT_SPRINT`、`PROJECT_WBS`、`TASK_001` 与当前代码状态判断 PR 范围是否一致

## 部署与数据影响

- 是否影响部署：`否`
- 是否影响环境变量：`否`
- 是否影响数据库：`否`
- 是否需要 migration：`否`
- 是否需要回滚方案：`否`
- 发布后验证方式：`不适用`
