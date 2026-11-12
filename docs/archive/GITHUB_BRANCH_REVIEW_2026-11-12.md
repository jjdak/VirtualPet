# GitHub 分支整理检查

2026-11-12，用户询问能否使用 gh 管理积累但未合入的分支。已使用本机 gh 2.95.0 核对 GitHub 默认分支、PR 和远端引用，并执行 fetch 更新本地引用。

## 当前结果

- 默认分支为 `main`，本次检查提交 `775f235b99c38e776966229c5b291bfa6ed1aba9`。已有 PR #1 只合入了早期庭院转向计划，后续同名工作分支继续向前开发。
- 远端有 10 条 codex 成果分支，均沿一条祖先链积累。最新 `codex/w3-departure-coupling-2026-11-12` 的 `c18c15b423d66dcf8f0effa78b4e2af59570ecff` 已包含另外 9 条的完整提交。
- 该最新成果相对 main 提前 20 个提交、落后 1 个合并提交。`git merge-tree --write-tree` 验证无冲突，未修改 main 或工作分支。
- 检查时没有开放 PR。现已创建 [整合草稿 PR #2](https://github.com/jjdak/VirtualPet/pull/2)，源为上述已公开分支，目标 main。GitHub 返回 OPEN、Draft、MERGEABLE、CLEAN。
- PR 范围涵盖后续 S1/S2、E1–E6、W1–W3 到随机配对实验的既有成果。本轮 26 对节奏诊断仍在独立本地分支，不在 PR #2 内。
- 本次只建立草稿，没有合并或删除分支。没有改远端保护设置。各阶段历史验证以归档日志为准，不把无冲突当成功能全量回归。

## 成果分支

下表“尚未进入 main 的提交数”基于上述 main 快照，并非彼此独立的提交数，不能相加。

| 分支 | 本次核对提交 | 尚未进入 main 的提交数 |
| --- | --- | ---: |
| `codex/agent-lab-e1-e5-archive-2026-11-02` | `ac3c2fd` | 5 |
| `codex/courtyard-sim-transition-2026-10-21` | `2d2b95f` | 4 |
| `codex/e6-unresolved-anomalies-2026-11-02` | `57beef4` | 6 |
| `codex/w1-living-world-2026-11-06` | `103c6ce` | 8 |
| `codex/w2-context-learning-2026-11-06` | `83c8797` | 10 |
| `codex/w3-choice-attribution-2026-11-10` | `1a9c828` | 18 |
| `codex/w3-departure-coupling-2026-11-12` | `c18c15b` | 20 |
| `codex/w3-endpoint-trips-2026-11-09` | `6639ec3` | 16 |
| `codex/w3-extended-observation-2026-11-09` | `b1d6da9` | 14 |
| `codex/w3-paired-worlds-2026-11-09` | `8233ab1` | 12 |

## 后续整理建议

整体审查 PR #2 后，用 merge commit 保留原提交祖先关系。合入后重新 fetch，用 `git branch -r --merged origin/main` 核对，再清理已经被 main 完整包含的旧成果分支。避免先逐个 squash，以免阶段提交的包含关系变得难以核对。

本次对源提交的跟踪文件检查，未发现以这些 codex 分支名为目标的 GitHub tree/blob 链接。清理应保留现有里程碑标签和固定提交引用；私有素材仍在本地忽略目录，不能把公共源码合入称为完整资产备份。

后续建议每阶段使用短期工作分支，通过 PR 合入 main；里程碑用固定提交或标签记录，不再让一串长期分支承担归档索引。这是建议，尚未自动更改仓库流程。

## 用户确认与执行

用户已明确授权将节奏诊断补入 PR #2，检查通过后合并 main 并清理已合入分支；采用短期分支、PR 与里程碑标签。上文保留初次检查快照，最新执行状态见[主线整合记录](integration-2026-11-12/PROGRESS.md)，工作规范见[Git 流程](../GIT_WORKFLOW.md)。
