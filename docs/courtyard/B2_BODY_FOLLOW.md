# B2 v5：肩背跟随 — 2026-10-03

P6 默认优先改善全景下人物动作可读性；从保存的 v4 另存，不改人物/环境网格、相机和光色。

## 动作设计与修正

头部沿用 v4 转头；身体于 2.65 秒后跟随，4.15 秒达到目标，5.15 秒后开始恢复，7.6 秒结束。Spine 最多约 3°挺起，Chest 最多约 6°偏转，并有轻微呼吸。原水面、叶簇、头颈动作保留。

第一版幅度过轻，保留为 `courtyard-b2-body-v5-soft-study.blend`。加大幅度后撑手目标误差达到 2.824 mm，超过 2 mm 检查上限，因此未保存为交付。随后通过原有肩关节旋转沿锁骨弧线调整手臂可达范围，不拉长骨骼；最终腕目标误差小于 0.001 mm、双脚漂移为 0。坐姿支撑与原始网格保持。

关键帧 1/101/157 已渲染；放大对照观察肩背和手部，未见明显异常伸展。此判断不能代替完整动画自然度验收。

## 检查与交付状态

原生工程保存重开、真实人物顶点位移、腕部稳定及首尾循环通过。全部网格顶点与相机未修改，原 v4 保留。2026-10-09 已完成正式静帧与 192 帧视频交付；当前美术主工程已继续到 v6，v5 留作动作和视频基线。

- 工程：`PrivateAssets/Courtyard/Blender/B2/courtyard-b2-body-v5.blend`
- 作者记录：`b2-body-v5-authoring.json`
- 重开检查：`b2-body-v5-motion-verification.json`
- 骨段长度对照：`b2-body-v5-arm-lengths.json`
- 关键姿态放大图：`body-v5-final-pose-detail.png`，左 v4 / 右 v5；仅诊断放大，不是新机位。

不增加表情、声音、交互或学习。没有新增依赖、下载素材或费用。当前属于动作对照试做，用户未验收 v5。

## 2026-10-09 视频修复与交付

静帧 1280×720 / 128 samples；MP4 与 ProRes HQ 均为 960×540、24 fps、192 帧、8 秒，完整解码通过。查看了静帧、肩背对照与解码关键帧；未把旧 v4 原生播放证据当成 v5 验收。

最初混用了早期帧 1/101/157 与后续批量帧，边界灰度差约 0.40。单独重渲染仍复现早期外观；复现“128 samples 静帧→48 samples 动画”顺序后，对照帧 2 与原批量灰度差为 0.000347，证实与渲染流程状态有关，未确定 Cycles 内部根因。替换三帧并重新编码后，最大相邻差由 0.39278 降至 0.036875，首尾差由 0.39986 降至 0.05111（160×90 灰度 0..255，指标不是主观无闪动证明）。旧帧和旧视频完整保存在 `v5-before-sampling-repair/`。

- [当前 v5 MP4](../../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-review.mp4)
- [母版](../../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-master.mov)
- [交付与哈希](../../PrivateAssets/Courtyard/Blender/B2/b2-body-v5-delivery.json)
- [采样修复记录](../../PrivateAssets/Courtyard/Blender/B2/b2-v5-sampling-repair.json)

后续渲染应从单一确定的流程生成完整序列；不要只凭工程哈希与 samples 相同就混用试帧。当前视频仍是 v5 光色，不能代替 v6 静帧的动画。
