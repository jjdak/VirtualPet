# 庭院专业制作软件选型

**2026-09-12 后续决定：用户已选择 Blender，B0 迁移已完成。当前入口见 [Blender 制作](../../blender/README.md)。下文“尚未选择/安装”属于调研时状态。**

调研日期：2026-09-12。用户要求先调研专业建模软件；本轮不安装、不采购、不迁移工程。推荐属于选型建议，未视为用户已决定使用某款软件。

## 结论（按用户最新澄清修订）

用户明确：「不一定要回去适配浏览器呀，在软件中建模优化就可以了」。浏览器回传不再是软件选型或本阶段验收条件。先在专业软件中制作、精修、渲染，交付可编辑工程、同机位渲染图，动画阶段再交付短片；未来交互与发布平台待定。既有浏览器原型保留为布局与动作参考。

首选建议仍为 Blender，依据改为综合制作能力、免费许可、可编辑源工程与脚本协作便利；Cinema 4D + Redshift 提升为认真考虑的付费备选，尤其当重心是画面与短片、或协作者熟悉 C4D 时。VRM 导入只用于尽可能延续人物资产，不再以是否能导回网页排名。不要同时建立多套 DCC 工程。

选择依据依次是：美术与动画控制、实际制作投入、可编辑性、许可和工具维护成本；资产迁移作为辅助。以下适配判断是项目分析，不是软件厂商排名；没有对这些软件进行本机画质或速度实测。下表中浏览器导出限制是早先研究的技术备查，不再作为当前淘汰条件。

## 主制作软件比较

| 软件 | 能承担的工作 | 本项目适配与代价 | 费用及 Mac 情况 |
| --- | --- | --- | --- |
| Blender | 建模、雕刻、UV、材质、骨骼动画、渲染与合成 | 推荐。庭院与人物能在同一源工程维护；有 VRM 插件和 glTF 流程。支持 Python/命令行，可把资产整理、参数修改、导出与检查做成可复现步骤。仍需要逐镜头美术判断，脚本本身不会提高审美完成度 | 软件免费；支持 Mac。官方安装文档说明 5.0 起面向 Apple Silicon，不能把旧 Intel Mac 支持沿用到新版本 |
| Cinema 4D + Redshift | 综合建模、动画、运动图形、灯光与渲染 | 可选。若以后主交付变成插画、宣传片，或协作者熟悉 C4D，值得考虑。已有 glTF/GLB 支持，但官方说明材质会有视觉差异；不能将 Redshift 画质直接当成浏览器效果 | 付费订阅，当前产品说明包含 Redshift GPU；支持 Mac。官方价格页动态金额未读取成功，不引用旧价格或其他地区价格冒充本地报价 |
| Maya | 角色建模、绑定、关键帧/非线性/动捕动画及综合制作 | 若以后由专业角色动画师接手复杂表演，是合理候选。目前只有一个坐姿角色，尚无足够收益证明值得另建 Maya 流程；现有 VRM 与网页导出链还需验证 | 付费产品，支持 macOS。当前地区和许可方案报价未核实，不假定满足 Indie 或教育资格 |
| Houdini Indie | 程序化建模、资产生成、KineFX 角色与模拟 | 若以后批量生成很多庭院、植被或复杂特效，价值更明显。本次只有一个固定小场景，节点系统搭建与烘焙管理可能增加投入，暂不推荐作为主工具 | 官网标价 USD 299/年或 449/两年，Indie 有收入/融资等适用条件。当前 H22 要求 Apple Silicon Mac；Karma XPU 官方只列 CPU 与 NVIDIA OptiX，不能假定使用 Mac GPU 加速 |

## 辅助软件

- **VRoid Studio：人物基础候选。** 免费，提供 Mac 版本；适合基于预设制作日系人物与发型服装，不承担庭院建模。当前官方换装功能已经支持导入 VRM 基础模型；旧 FAQ 中“不能重新导入 VRM”的表述不能作为整个产品现在的统一结论。但换装导入也不等于能还原成完整 `.vroid` 参数化源文件。现有 sample.vrm 的适配未测试；需要自由改网格/坐姿时仍以 Blender 为主。
- **Substance 3D Painter：材质绘制候选。** 在模型上绘画、遮罩和导出贴图，适合明确进入大量材质精修时引入。不是完整建模和动画工具；本轮未核实本地区价格，未订阅。初次样块可先用 Blender 现有绘制能力或之前研究的 Krita，避免提前建立付费工具依赖。
- **ZBrush：雕刻候选。** 擅长有机造型与雕刻绘制；若后续确需专门角色或复杂石材雕刻再考虑。本项目当前需要的是完整形体、配色、光影协调，未证明需要额外雕刻工具。高密度雕刻后仍需整理成浏览器可用的网格、贴图和绑定。

## 与本机及当前工程的关系

只确认当前系统为 macOS 26.6.2；CPU/内存查询被当前执行权限限制，未据此确认硬件满足任一软件配置，也未申请额外权限。软件支持 Mac 不等于其当前版本已认证本机 OS/GPU 组合。安装前再确认芯片、内存、软件与插件的兼容版本；当前不需要用户为选型补交信息。

VRM Add-on 当前官方文档标明支持 Blender 2.93–5.2，并提供 Python 自动化 API。优先选择插件明确支持的稳定 Blender 版本，不追逐开发版；这只是文档兼容性证据，不是现有角色已成功往返的证据。

按最新范围，建议最小验证为：将现有布局/相机作为底稿，在所选软件内完成石阶、水岸和人物协调的小样，保存原生可编辑工程并渲染同机位对照。角色导入后单独验证眨眼、坐姿和转头，再制作短片。无需导回浏览器，也不必提前把所有节点、约束、光照和水体烘焙成网页可用资产。保留源工程与绘制源文件；选型与实施仍未开始。

## 一手资料

1. [Blender 功能](https://www.blender.org/features/)；[许可](https://www.blender.org/about/license/)；[Mac 安装文档（开发版页面，含 5.0 起的硬件变更）](https://docs.blender.org/manual/en/dev/getting_started/installing/macos.html)。
2. [Blender 命令行](https://docs.blender.org/manual/en/5.1/advanced/command_line/arguments.html)；[Khronos Blender 转 glTF 示例](https://github.com/KhronosGroup/glTF-Tutorials/blob/main/BlenderGltfConverter/README.md)。
3. [VRM Add-on 当前支持版本及自动化入口](https://vrm-addon-for-blender.info/en-us/)。
4. [Cinema 4D 当前功能与订阅组成](https://www.maxon.net/en/cinema-4d?type=0)；[文件格式](https://www.maxon.net/en/cinema-4d/features/supported-file-formats)；[glTF 材质差异](https://help.maxon.net/c4d/en-us/Content/html/FGLTFEXPORTER.html)；[动态价格页](https://www.maxon.net/en/buy)。
5. [Maya 产品与平台](https://www.autodesk.com/products/maya/overview)；[角色与制作功能](https://www.autodesk.com/ca-en/products/maya/features)。产品概览正文过大未完整打开，以搜索返回的官方平台摘要为证；未确认具体售价。
6. [Houdini Indie 价格与适用条件](https://www.sidefx.com/products/houdini-indie/)；[H22 系统和 Karma XPU 要求](https://www.sidefx.com/Support/system-requirements/)。
7. [VRoid Studio 产品](https://vroid.com/en/studio)；[当前换装导入流程](https://vroid.pixiv.help/hc/en-us/articles/38722733769241-Getting-Started-with-the-Dress-up-Feature-for-those-who-want-to-dress-up-their-characters)；[旧版重新编辑 FAQ](https://vroid.pixiv.help/hc/en-us/articles/360020275314-How-to-edit-a-VRM-file-Can-I-re-edit-a-VRM-file-in-VRoid-Studio)。
8. [Painter 建立贴图项目](https://experienceleague.adobe.com/en/docs/substance-3d-painter/using/getting-started/project-creation)；[导出](https://experienceleague.adobe.com/en/docs/substance-3d-painter/using/export/export)。
9. [ZBrush 功能](https://www.maxon.net/en/zbrush)。

价格与能力按检索日记录；页面抓取时间不视为功能发布日期。未新增软件或素材依赖，无需将研究候选登记为已安装依赖。
