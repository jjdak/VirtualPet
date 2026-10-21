# Blender 制作入口

## 阶段收束（2026-10-21）

B2 已归档，用户肯定当前整体优化并授权转向小型 sim。下述 v6/v7/v5 均保留为美术与动作来源；本页旧美术“下一步”不再是自动执行队列。新阶段见 [SIM 计划](../docs/SIM_STAGE_PLAN.md)，恢复见 [B2 收束](../docs/archive/B2_CLOSEOUT.md)。Godot 迁移须输出新文件，不能覆盖现有 Blender 工程；当前未完成运行时迁移。

工具：Blender 5.2.1 LTS / Apple Silicon，`/Applications/Blender.app`。直接原生制作，无浏览器回传要求。

## 当前工程与交付 — 2026-10-09

当前为 **v6 focused 光色小样**。从 v5 另存，按社区案例的参考驱动、有限候选比较方法修改灯光和环境材质；保留全庭院、相机、人物网格与所有动作。v5 增加的肩背跟随也保留。

| 用途 | 文件 |
| --- | --- |
| 继续编辑 | [v6 focused 工程](../PrivateAssets/Courtyard/Blender/B2/courtyard-b2-reference-v6-focused.blend) |
| 当前静帧 | [1280×720 / 128 samples](../PrivateAssets/Courtyard/Blender/B2/b2-reference-v6-focused.png) |
| 同机位比较 | [左 v5 / 右 v6](../PrivateAssets/Courtyard/Blender/B2/b2-v5-v6-comparison.png) |
| 静帧及重开证据 | [v6 review](../PrivateAssets/Courtyard/Blender/B2/b2-reference-v6-review.json) |
| 动作基线短片 | [v5 MP4：8 秒、24 fps、960×540](../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-review.mp4) |
| 动作基线母版 | [v5 ProRes HQ](../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-master.mov) |
| 动作/编码证据 | [v5 原生验证](../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-motion-verification.json) / [视频交付](../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-delivery.json) |

**视频为 v5 光色；v6 只渲染正式帧 1、101、193，未输出完整动画。** 人物含 58 骨骼、静态脸，21 张图像打包；无声音、交互或学习。

继续时从当前 `.blend` 另存，禁止重跑迁移或人物入景脚本。旧 v4、v5、v6 soft 候选均保留。私有资产仍 Git 忽略，本地保存不等于远程备份。

## 判断与下一步

[调研及应用记录](../docs/courtyard/AI_BLENDER_COMMUNITY_RESEARCH.md) / [执行计划](../docs/courtyard/B2_NEXT_PLAN.md) / [进度](../docs/courtyard/PROGRESS.md)。两版草稿、正式静帧和峰值姿态已查看；光色较集中，但树冠仍碎、微缩模型感明显，尚未达到概念插画。树冠研究已完成：[v7 候选与对照](../docs/courtyard/B2_CANOPY_STUDY.md)。较轻盈的 v7 与浓密 v6 均保留，正在收集画面偏好；不继续叠加同类微调。选定画面后再制作同版短片。

v4 曾完成原生循环播放观察；该证据不适用于新 v5/v6。v5 混合渲染批次的三张测试帧已用原批次顺序复现并修复，见身体跟随记录；完整实时观看和主观静谧感仍待评价。

## 历史版本与恢复边界

- B2 v5：`courtyard-b2-body-v5.blend`；[身体跟随](../docs/courtyard/B2_BODY_FOLLOW.md)。v4：`courtyard-b2-presence-v4.blend`，保留为历史对照。
- B2 v3：`courtyard-b2-shapes-v3.blend`，圆润叶簇与石块磨损；[记录](../docs/courtyard/B2_SHAPE_PASS.md)。
- B2 v2：`courtyard-b2-color-v2.blend`，光色分区；[记录](../docs/courtyard/B2_COLOR_PASS.md)。
- B2 v1：`courtyard-b2-light-motion-v1.blend`，首段原生动画；[记录](../docs/courtyard/B2_LIGHT_MOTION_STUDY.md)。原 `b2-motion-v1.mp4`、CRF18 `b2-presence-v4.mp4` 都是历史交付，不是当前播放入口。
- B1 入景：`courtyard-b1-girl-a-v3.blend`；环境基线：`courtyard-b1-v3.blend`；B0：`courtyard.blend`。均在私有 Blender 目录中保留。
- `export-source.cjs` / `create-project.py` 是 B0 恢复工具，不用于正常继续。`place-girl-a.py`、`refine-girl-a-pose.py`、`refine-girl-a-support.py` 为历史入景记录。
- `refine-b2-presence.py` 记录从 v3 制作 v4；`verify-b2-study.py` 验证保存工程；`render-b2-preview.py` 渲染与哈希/采样配置一致的序列。重现当前视频编码命令见播放检查记录。

旧 SpriteKit/SwiftUI、浏览器 C2 仅保留为基线。Live2D/Cubism 继续暂停；不自行制作人物、衣服、头发或面部网格，不自动扩展聊天/学习或发布平台。
