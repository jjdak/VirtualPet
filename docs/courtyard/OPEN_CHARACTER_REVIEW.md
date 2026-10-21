# 现成人物模型选择

2026-09-13：用户明确要求「人物建模不要自己做，去找一个开源的模型」。本项目采用提供源工程且许可明确的现成人物；停止自制服装、发型、人物网格。保持 `courtyard-b1-v3.blend` 环境主工程，之前的 `courtyard-b1-character-*` 仅保留为停止的实验，未升级为主工程。

## 当前外观要求与短名单（2026-09-13）

用户原话：「不喜欢rain，喜欢最初那个亚系短发少女」。Rain 明确退出候选，不能因它的控制器较成熟就再次默认选用。目标是最初概念图中的黑/深棕短发、柔和克制的五官、朴素服装和安静的气质。

| 候选 | 作者与开放许可 | 已看见的外观 | 尚有差距 |
| --- | --- | --- | --- |
| [少女A](https://hub.vroid.com/characters/5271108759876567944/models/9069514665234246177) | くつした；作者明确 CC0 1.0，页面允许改编、再分发与商业使用；VRM 0.0 | 黑色波波头、灰色眼睛、简单线条；已检查[作者预览](../../PrivateAssets/Courtyard/Characters/ShortHairCandidates/girl-a-author.png) | 眼睛更大、偏日系动画；水手服不是概念图布裙，不能称完全匹配 |
| [千駄ヶ谷渋 / beta AvatarSample_1](https://hub.vroid.com/characters/675572020956181239/models/4479743608263344465) | VRoid Project/pixiv；[官方 CC0 说明](https://vroid.pixiv.help/hc/ja/articles/360012381793)，VRM 0.0 | 深色短发、较圆脸型；已检查[作者预览](../../PrivateAssets/Courtyard/Characters/ShortHairCandidates/shibu-author.png) | 校服与发卡的校园气息较强，网页展示高光较重，仍不等同概念图 |

用户随后评价「不错不错」，**少女A的脸与发型方向已认可**；不推断水手服、完整模型质量或庭院动态已经验收。目前没有找到同时匹配短发、克制五官和灰蓝素裙的完整开放模型。初选时两者仅取得公开预览和许可信息。随后用户提供少女A文件，身体绑定检查通过，但缺失眨眼和独立视线数据，详见[文件实查](GIRL_A_RIG_REVIEW.md)；坐姿和入景仍未完成。少女A作者说明从 Hub 下载需要 Pixiv 登录；不从网页预览提取受登录控制的模型数据。

帮助页的一张图片实际是奇幻变体，已检查并排除；实际对照使用上面两个准确模型页面的图片。另检索到 Nire、reveria 等免费条目，未核实其完整开放许可，不纳入当前开放模型短名单。

## 历史候选与判断

| 模型 | 一手来源与许可 | 适合之处 | 成本与限制 |
| --- | --- | --- | --- |
| Rain（用户已否决） | [Blender Studio](https://studio.blender.org/characters/rain/v3/)，CC BY 4.0，页面 2025-05-08 更新 | 原生 Blender 模型，身体 IK/FK 和分层面部控制完整；作者称适用于 4.1 及以后，无需另装插件 | 风格偏欧美动画，现代装束，不等同于概念图人物。完整控件 UI 依赖内嵌脚本，5.2.1 全流程兼容性未验证 |
| Spring（历史候选，不再优先） | [Blender Studio](https://studio.blender.org/characters/spring/v1/)，CC BY，官方页含署名要求 | 自然题材动画主人公，朴素的角色方向值得对照 | 官方限定 Blender 2.8–3.6，建议配套 BlenRig；当前 5.2.1 可能带来迁移成本，未下载或测试 |
| Ellie（暂不优先） | [Blender Studio](https://studio.blender.org/characters/ellie/v1/)，CC BY | 已完成的动画角色和控制骨架 | 官方明确要求 3.3–3.6，不能假定当前版本直接可用，未下载或测试 |

这里的开放指源模型可获取且许可允许使用/修改；没有把所有免费模型都当作开放资产。未采用只有基础人体、未绑定网格或来源不明的角色，避免把后续工作重新变成人物建模。

## 已获取 Rain

- [原始解压工程](../../PrivateAssets/Courtyard/Characters/Rain/Rain%20v3.3/rain_v3.2.blend)
- [官方形象展示](../../PrivateAssets/Courtyard/Characters/Rain/official-preview.jpg)
- [来源及哈希](../../PrivateAssets/Courtyard/Characters/Rain/SOURCE.json)、[署名](../../PrivateAssets/Courtyard/Characters/Rain/ATTRIBUTION.txt)、[基础打开检查](../../PrivateAssets/Courtyard/Characters/Rain/inspection.json)

官方包名为 v3.3，里面 `.blend` 名为 v3.2，网页沿用标记 Rain v2 的宣传图。原文件命名完整保留，宣传图不冒充本项目渲染。ZIP 完整性检查通过。文件只读检查禁用内嵌 Python 自动运行；基本可读不等于控件 UI、所有驱动器或动画已验收。

网页文本工具直接打开 Studio 一度失败，改用普通 HTTP 成功取得官方公开页面和下载链接；未绕过登录或购买限制。无需付费下载 Rain。

## 接下来

取得少女A原始 VRM，检查原有骨架和实际眨眼等表情形变。用户进一步要求研究 Tripo，已完成[绑骨与自然动作研究](TRIPO_RIGGING_RESEARCH.md)：优先保留可用原绑定，必要时对独立副本评估 Tripo。没有账户接入、上传或收费任务。保留环境 v3，不自制人物网格；先静态坐姿评审，再原生动画。

### 2026-09-13 下载入口实查

Safari 官方模型页的 `Use this model` 显示需要 Pixiv 登录，当前会话未登录，已打开登录入口。原始 VRM 尚未取得；等待所有者完成登录或提供本地原文件路径。此结果不构成骨架、表情或 Blender 导入验证。

### 用户提供文件后的实查

下载阻碍已由用户提供本地文件解除。少女A GLB 导入与 58 骨骼身体形变通过，17 个表情绑定全空且无形变目标/眼球骨骼。先确认文件是否为原始下载、寻找完整表情版本；独立预览与证据见[绑定实查](GIRL_A_RIG_REVIEW.md)。

### 2026-09-14 接受静态脸，继续制作

用户明确缺面部数据不影响当前进度。保留少女A，撤销“必须先寻找完整表情文件”的前置步骤；当前以原有身体骨架入景，下一优先是整体氛围与身体/环境节奏。
