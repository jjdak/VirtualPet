# 庭院 · 午后片刻

独立浏览器 3D 交互切片，保留旧 Swift App。一个固定镜头、一个临时 VRM 角色、一处可以点的水面；没有聊天、学习、风铃或叶子交互。当前无声音。

## 本地运行

需要 Node.js 22.12+ 或本轮已验证的 24.13.0，首次安装和素材恢复需要网络。

```sh
cd courtyard
npm ci
npm run assets
npm run dev
```

打开 http://127.0.0.1:4173/ 。服务仅绑定本机。模型下载会验证固定 SHA-256，下载后的模型保持 Git 忽略。没有模型时页面明确提示，不用静态图片冒充成功。

点击水面立即产生涟漪；约 0.32 秒后角色开始调整视线和头部，约 3 秒后收回注意力。连续输入更新落点，但不无限延后回应。点石阶与人物不触发涟漪。聚焦场景后可按 Enter/空格；右下角可暂停。系统减少动态效果偏好会抑制环境待机运动和自发眨眼；用户主动点水仍有有限回应。

`npm test` 验证注意力边界，`npm run build` 生成 dist，`npm run preview` 预览构建产物（需先停止同端口开发服务）。`?inspect=1` 仅供制作检查，提供近看、眼睑开合、实时状态与十二秒画布录屏，不属于正常体验界面。

## 结构

- src/attention.js：输入延迟、注视与恢复；固定逻辑，未实现学习。
- src/character.js：VRM 坐姿、眨眼、眼球目标、头颈平滑转动。
- src/environment.js：庭院、植被、水面及静态环境倒影。
- src/surfaces.js：可复现的灰泥、石板、树叶及接触阴影纹理。
- src/main.js：输入命中、水波、渲染循环与预览检查工具。
- scripts/prepare-model.mjs：可复现的官方模型下载、完整性和结构检查。

角色来源和许可见 public/models/NOTICE.md；依赖版本及范围见 ../docs/DEPENDENCIES.md。计划、验收及限制见 ../docs/courtyard/PROGRESS.md。

这是一版动作与氛围验证：人物外观、长发、服装与概念图不同；环境材质简化。自然感由用户体验确认，不能从编译或参数变化推断。最终模型与发布平台尚未选定。

## 可复现浏览器检查

`browser-check.cjs` 使用 Playwright 1.62.1（QA 专用，不进入应用依赖）。本环境可设置 `PLAYWRIGHT_MODULE_PATH` 到已提供的 Playwright 模块目录，`PLAYWRIGHT_BROWSERS_PATH` 到项目 `.runtime/courtyard/browsers` 后运行 `node scripts/browser-check.cjs`。其他环境可提供同版本 Playwright，先执行其 `install chromium --only-shell`。保持预览服务开启。

检查会在 `.runtime/courtyard/` 保存 JSON、截图和真实画布录屏。无界面渲染的捕获帧率可能较低，动作自然度以交互预览和用户反馈为准。

## 2026-09-09 画面改进

已拉近固定构图，改为镜头内庭院；加入磨损石阶、细叶树影和水面环境倒影。公共 `public/textures/` 含一张 CC0 原始石材贴图及来源说明，随代码资源保留。无需安装 Blender 或额外依赖。倒影仅含静态环境，不反射动态人物；最终角色和插画级精修尚未完成。工具调查及后续判断见 [画面评审](../docs/courtyard/ART_DIRECTION_REVIEW.md)。

## 2026-09-10 布局与质感合并

按用户反馈恢复最初的完整庭院布局、围墙、池沿与整体镜头，保留 9 月 9 日材质、细叶树影和环境倒影。`scripts/layout-check.cjs` 沿用上述 Playwright 环境变量，针对实际点水/转头、石阶/池沿/池外拒绝输入、暂停、窄窗口与浏览器错误检查，并在 `.runtime/courtyard/layout-art/` 保存截图及 JSON。本轮无新增依赖或素材。

## 2026-09-11 人物坐姿与受光

人物改为一手支撑石阶、一手放在腿上；`seated-support.js` 保持骨长并维持固定坐姿的手部目标。运行时调整皮肤/头发材质对场景光的响应，源模型不变。整体庭院布局未改。`npm test` 当前包含 3 项注意力检查及 2 项支撑求解检查。

[同机位对照](../docs/courtyard/POSE_LIGHT_PASS.md)同时提供整体和近景图。完整浏览器检查的输出目录可设为 `.runtime/courtyard/pose-light/full`；然后运行 `node scripts/support-check.cjs`，从该完整运行的左右注视/恢复快照复核支撑腕误差和手指骨骼高度，不重复启动浏览器。角色最终形象与自然度仍待用户反馈。
