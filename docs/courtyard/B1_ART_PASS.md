# B1：根据艺术家制作经验精修庭院

日期：2026-09-12。用户要求搜索专家建模经验并应用于画面，随后授权继续。基于已保存的 Blender 主工程编辑并另存，保留完整庭院布局、原相机和人物坐姿。没有重跑迁移来重建整个场景。

## 参考资料与实际采用范围

| 一手经验 | 本项目采用的方法 | 没有据此声称完成的工作 |
| --- | --- | --- |
| [Antonin Pardon：Hidden Pathway，2026-03-04](https://80.lv/articles/breakdown-how-to-create-a-peaceful-fantasy-nature-environment) | 石块分开处理，先改轮廓和边缘，再补材质细节；在原镜头下判断效果 | 本轮使用可编辑切角网格和倒角修改器实现边缘设计，没有假称逐块手工雕刻，也没有完整复刻作者雕刻流程 |
| [Frankie Povarchik：Howl's Cottage，2026-04-07](https://80.lv/articles/creating-a-painterly-like-and-stylized-environment-inspired-by-howl-s-moving-castle) | 固定镜头、大中尺度色块、分组植被和有方向的暖光；材料颜色控制在同一组色调里 | 未使用其素材、Substance 节点或 Unreal 技术；本轮是 Blender 原生节点实现，程序色差不等于真正手绘笔触 |
| [Alexander Maznev：Last Days of Warmth，2025-08-19](https://80.lv/articles/breakdown-making-3d-landscape-look-like-painting) | 用成组叶簇与柔化法线组织冠层受光 | 本轮显式计算冠层导向法线，未安装 Houdini/SpeedTree，也不是直接调用作者的法线投射工程 |

来源只提供制作方法参考，不能保证结果达到作者作品质量。没有下载作者作品作为项目素材。

## 本轮编辑

- 把规则石阶、池沿改成保留位置的切角石块，倒角保留为可编辑修改器；原大坐台分为三块，中央坐姿和掌面支撑的顶面高度保持。
- 使用统一的石灰石色组与墙面材质，降低摄影贴图重复感；墙脚增加低矮潮湿色带。
- 树枝骨架保留，树冠改为十组疏密不同的叶簇，使用弯曲叶片网格、冠层法线和少量透光；地面植被集中到若干接缝与树根附近。
- 调整池底材质并增加水下石块，水面改为原生透射材质；主光与补光重新分工。
- 人物保留现有模型和蒙皮，只调整皮肤散射和布料材质响应。发型、衣服轮廓与表演不宣称已完成重做。

这些编辑由 `blender/scripts/refine-b1.py` 实施，输入为现有 `.blend`，输出单独版本；替换的旧网格保留在禁渲染集合。脚本遇到已存在的输出会拒绝覆盖。

## 状态

首轮启动 Blender 曾被自动审批服务以用量上限阻止，脚本当时仅保存而未执行。用户继续后，原操作已重新获准执行，制作与检查已完成。

实图检查了三版：v1 的叶冠太平，水下规则砖片与硬墙脚色带显得人工；v2 将叶片分布改为有厚度的冠层、独立倾斜，水底替换为 65 个不规则圆石，水体改成封闭薄体，墙脚使用带噪声的高度过渡，并收窄铺石色差。v2 的叶片切向基底翻转造成面朝向错误，出现黑冠；v3 反转面绕序并重建匹配法线，已实际查看确认修复。未把中间失败版作为最终效果。

## 交付与核验

- 当前工程：[courtyard-b1-v3.blend](../../PrivateAssets/Courtyard/Blender/courtyard-b1-v3.blend)。从这一版继续编辑，B0、v1、v2 均保留。
- 当前图：[b1-v3-preview.png](../../PrivateAssets/Courtyard/Blender/b1-v3-preview.png)，Cycles 1280×720，96 samples；[B0 对照图](../../PrivateAssets/Courtyard/Blender/migration-preview.png)。
- 重开报告：[courtyard-b1-v3-verification.json](../../PrivateAssets/Courtyard/Blender/courtyard-b1-v3-verification.json)：pass，154 骨骼、7 个表情网格，17 张当前图像均打包；眨眼/头骨编辑实际最大顶点位移 0.03532 / 0.05968 米。不是仅验证参数存在。
- 原相机矩阵与正交尺度保留，原坐台支撑高度保持。B0 SHA256 仍为 `dfeddb81eaba7177a68914f8ff6cbab90f0b7938aa7160d838f85ef603f09c63`，未覆盖。
- 最终工程 SHA256：`ec1a65ac8c7c4ddfff34fc0bb0525a19dc33c3ee149d7d529fbbd9c1e2a56349`。
- 没有新插件、下载素材或收费依赖。网格与程序材质属于本地制作；没有将其称为手绘纹理或手工雕刻作品。

## 美术判断与下一步

水下黑斑、硬墙脚色带和扁平树冠已修正。画面仍偏整齐的微缩模型：石材外形变化有限，树枝与冠层的衔接需要设计，现代人物的发型和服装轮廓尚未与环境统一，也没有真正的绘画笔触。这一轮不能称为达到了最初概念插画。

下一步由用户评审这张静帧，选择最影响感觉的一项继续打磨；建议优先人物整体风格与坐姿剪影。B2 原生动画尚未启动，主观静谧感、插画完成度仍待用户反馈。
