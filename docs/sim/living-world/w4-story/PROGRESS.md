# W4 · 一条线索的后来

2026-11-13。本轮计划先记录于 [PLAN.md](PLAN.md)，从 main `2e45e46ce4f420f5eab28767d17e32a6d89a8be9` 创建短期分支 `codex/w4-intervention-story-2026-11-13`。实现与本地验证完成，玩家是否看得懂、是否有参与感仍待体验反馈。已推送到 [PR #5](https://github.com/jjdak/VirtualPet/pull/5)，目标 main；实现与验证固定于 [7318cb6](https://github.com/jjdak/VirtualPet/commit/7318cb6daf97c3aa500e08b40b6a856fa06ad8f8)。2026-11-22 已合入 main，玩家体验反馈待收集。

## 可以体验什么

运行 `./living_world/w4.command`，打开 <http://127.0.0.1:4198/>。页面先准备场景，不自动干预。点击“给出这条线索”，再点“看下一段”：播放会停在下一段真实记录，也可点四张卡片跳转、自由播放或拖动时间轴。

默认选用已有的食物效果互换机制示例，原档第 480 步、种子 4。它是一个可说明机制的具体案例，不是对任意建议成功率的承诺：

| 线索之后 | 发生的事 | 证据 |
| --- | --- | --- |
| +0 | 玩家只建议阿禾去紫穗地 | 新增一次地点建议，不是食物事实 |
| +56 | 阿禾亲自尝到紫穗，感觉不错 | 新的亲历报告 `A:536` |
| +59 | 阿禾把这条亲历告诉小岚 | 接收方实际接受了同一报告；不是此前 +54 的另一条差异消息 |
| +66 | 小岚从此前的青禾改选紫穗 | 无建议世界同一步选青禾；只从本次决策副本移除 `A:536`，仍选青禾 |

关闭分支后双方交流的原有匹配对照中，小岚在该 240 步观察窗内没有行为差异，支持这条传播路径。页面在 +66 只描述本次选择，不声称以后一直偏好紫穗。

桌面版把四段过程和两个世界并排放置，当前事件在右侧地图标出；窄屏依次排列。未回放到的结果不提前写入故事文案，完整统计只在 +240 展开。保留三个起点、换人、换地点和完整 W2 导入；修改选项先标记待应用，成功生成后才换画面。请求失败保留原档与当前结果。

## 实现边界

- `intervention_story.py` 是每个世界各自拥有的观察层，沿“本次建议 → 新亲历 → 同一报告送达 → 携带该有效报告的决策”关联。没有全局补丁。
- 先运行原 `fork_study.compare`，再独立观察重放；逐帧核对天气、身体与选择一致。决策检查只复制当前角色并删除一条消息，不改正在运行的角色。正式策略、随机规则、存档结构与冻结研究输出均未改。
- “同伴改选”须同时满足非随机探索、前次与本次选址不同、同一步无建议对照选址不同、去掉该报告使本次选择翻转，以及原匹配静默对照支持。证据不足时仅展示收到消息和实际选择。
- 线索过期、没有亲历、到访扑空、未送达、尚无后续决策、收到但未改选分别如实说明。新测试确认旧亲历和同类不同身份的报告不能补成这条链。
- 仍是 W3 原按时钟抽样规则，未切换为 W3-coupling 的按出发次数配对规则；没有新增学习策略、训练或 LLM。展示有限 240 步的单次建议观察，不能据此证明持久人格或长期学习。
- W4 在原 `web/w3` 和只读分支服务上迭代，原 `w3.command` 也显示新版；旧 W3 研究数据与浏览器证据保留为当时版本。新的浏览器检查为 `browser-w4-story.cjs`，不要用旧 UI 检查覆盖历史证据。
- 没有新增依赖或素材。复用已安装的 Python、Playwright 与 Chromium；私有模型、用户存档、缓存未加入提交。

## 验证与证据

- 小世界 Python 回归 **61/61 通过**，包括新增 11 项：准确报告链、原结果与输入不变、跨天气完整存档一致、并发请求隔离、不同报告拒绝关联、探索／无同一步对照／原地继续选择不冒充改选、同一步消息晚于决策、短窗与旧亲历隔离、过期、扑空、零影响。见 [python-verification.json](review/python-verification.json)。
- 隔离 Chromium 的 **13 项体验检查通过**：先准备后干预、无未来结果叙述、逐段播放停止、节点回退、播放控制、待应用选项、失败恢复、零影响、导入与错误保留、未完成链条、HTTP 边界、390px 窄屏、无未捕获脚本异常。见 [browser-verification.json](review/browser-verification.json)。
- 已实际查看 [桌面截图](review/choice-desktop.png) 和 [窄屏截图](review/choice-mobile.png)：故事、两边地图和文字正常，未见横向溢出；属于本地截图检查，不等于用户体验认可。
- [默认示例的结构化事件证据](review/example-story.json) 保留完整报告身份与同次决策检查。研究数据与 W1/W2 原存档不被写入。
- 首轮检查修正了测试夹具的有效出发上限、天气模式、浏览器导入等待时机，以及超限请求提前拒绝时的测试客户端断管竞争；产品的最终验证结果如上。未对未改动的 Godot、美术工程或 E1–E6 重复运行测试。

复现：

```sh
python3 -m unittest discover -s living_world/tests -p 'test_*.py' -v
PLAYWRIGHT_MODULE_PATH=/Users/fengzhuo/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright \
PLAYWRIGHT_BROWSERS_PATH=/Users/fengzhuo/Documents/VirtualPet/PrivateAssets/Tools/playwright-browsers \
node living_world/tests/browser-w4-story.cjs
```

## 2026-11-22 里程碑

在 PR 最终提交 `380e9a67e4079dc4dd20b25b2c9d39a7b4036a2c` 的隔离副本复跑，61 项 Python 回归和 13 项浏览器检查均通过。GitHub 当时未登记远端检查或审阅讨论。合并后逐树核对，合并版本与测试版本内容一致。

[PR #5](https://github.com/jjdak/VirtualPet/pull/5) 的[合并提交](https://github.com/jjdak/VirtualPet/commit/bb3182bab015f8081f6e55d57957395e2b269f9c)已用[注释标签 living-world-w4-story-2026-11-22](https://github.com/jjdak/VirtualPet/tree/living-world-w4-story-2026-11-22)标记。核对祖先关系后已清理本地与远端 W4 功能分支。

## 下一步待讨论

W4 的一次干预发生在起点，玩家随后观看 240 步。下一轮要讨论玩家最希望亲自决定的事情。一个可试玩的小范围提案是让世界先自行运转，让玩家看到一次取食结果，再决定何时提醒谁，或继续旁观。体验反馈将决定是否开发这一方向。
