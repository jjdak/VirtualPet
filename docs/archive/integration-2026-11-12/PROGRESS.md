# 主线整合与归档流程

2026-11-12。用户已授权将节奏诊断纳入 [PR #2](https://github.com/jjdak/VirtualPet/pull/2)，检查通过后合入 main、清理已合入分支，并采用短期分支／PR／标签流程。[执行计划](PLAN.md) · [工作流程](../../GIT_WORKFLOW.md)

## 合并前验证

- 小世界完整 Python 回归 50 项通过，包含 HTTP、存档、情境记忆、同档对照、归因、随机配对和节奏诊断。
- E1–E6 测试分别通过 5／7／12／14／12／14 项，共 64 项；合计 114 项 Python 检查通过。
- Godot 4.7.2 无窗口控制检查通过。受限执行环境曾报系统字体加载警告；正常本机权限复核通过且无 ERROR 日志。未更改项目来绕过警告。
- 没有配置 GitHub 自动检查，此次以本机实际测试及合并树核对为依据。这不包含新一轮图形效果、真机或主观体验验收。

[机器验证摘要](review/verification.json) · [小世界日志](review/living-world-tests.txt) · [E1–E6 日志](review/experiment-tests.txt)

## 整合范围与顺序

PR #2 原来包含后续 S1/S2、E1–E6、W1–W3 至随机配对实验。本轮补入节奏诊断 `bba1f2c`、上述回归证据和仓库工作流程，使用现有 PR 源分支快进更新。各阶段原提交保留。

合入采用 merge commit；核对 main 包含完整源提交后，才建立／读回阶段标签并清理已合入分支。[里程碑映射](milestones.json)列出本轮计划建立的 10 个注释标签，原有 E1–E5 与 B2 标签保留。私有素材、模型权重、本机存档继续留在忽略目录。

实际合并、标签及清理均已完成，回执通过短期文档 PR 回填。后续每阶段使用短期分支与 PR，里程碑使用不可移动的标签或固定提交。

## 完成回执

- [PR #2](https://github.com/jjdak/VirtualPet/pull/2) 已以 merge commit 合入，源提交 `a52982c96da60c53a6bd659ff996342a4095722d`，合并提交 [be705063](https://github.com/jjdak/VirtualPet/commit/be705063912b52681d9e839aa89ca22923786b1c)。节奏诊断 `bba1f2c` 已被 main 包含。
- 实际合并树与检查时生成的合并树一致，为 `d52b3561d97ef61b383c9fc908c7bbcbc015939b`。
- 新建并读回验证 10 个注释标签，原 E1–E5 与 B2 两个标签保留。节奏诊断可从 [living-world-w3-rhythm-2026-11-12](https://github.com/jjdak/VirtualPet/tree/living-world-w3-rhythm-2026-11-12) 定位。
- 删除 10 条远端旧成果分支。每条均先确认当前分支头是 main 祖先，再用精确提交租约进行原子删除，避免删掉核对后新出现的提交。
- 本地 main 快进更新后，用安全删除清理 12 条已合入旧分支，包括早期 reboot 分支与本轮诊断分支。没有未合入分支或其他 worktree 占用需要保留。
- 旧分支清理完成时，远端只保留 main，本地 main 与远端一致且工作区干净。随后创建本次短期回执分支；其文档 PR 合入后按相同规则删除，不作为新的长期归档分支。

[合并回执](review/merge-receipt.json) · [标签回执](review/tag-receipt.json) · [旧分支清理明细](review/cleanup-receipt.json)。回执中的 main SHA 是 PR #2 完成时的快照，后续文档 PR 会使 main 正常前进。
