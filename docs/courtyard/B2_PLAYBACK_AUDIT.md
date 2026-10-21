# B2 v4 播放与编码检查 — 2026-10-02

上一轮属于实际进展：工程、静帧、完整视频与计划记录均已落地。本轮检查当前文件，不重新渲染 Blender。

## 实际发现

原 PNG 序列的首尾帧变化与普通相邻帧接近；旧 CRF18 MP4 的首尾差异较大。所有数字均为降采样到 160×90 的灰度平均绝对差（0–255），只用于定位编码变化，不是感知质量分数。

| 版本 | 相邻帧差中位数 | 首尾差 | 文件大小 |
| --- | ---: | ---: | ---: |
| 原始 PNG 序列 | 0.02257 | 0.01958 | 保留原帧 |
| 原 CRF18 MP4 | 0.01507 | 0.10313 | 259 KB |
| 新 CRF6 MP4 | 0.02021 | 0.04972 | 1.24 MB |
| ProRes 422 HQ 母版 | 0.03000 | 0.02708 | 52.9 MB |

CRF12 + GOP24 未消除接缝；CRF12/16 全帧独立编码增加了相邻帧波动，因此未选用。新 MP4 的首尾差下降约 52%，ProRes 约 74%。这是图像差异指标改善，不声称人眼已确认没有闪烁。

## 新交付

- [当前轻便 MP4](../../PrivateAssets/Courtyard/Blender/B2/b2-presence-v4-review.mp4)
- [ProRes 高质量母版](../../PrivateAssets/Courtyard/Blender/B2/b2-v4-master.mov)
- [统一审阅页](../../PrivateAssets/Courtyard/Blender/B2/b2-v4-review.html)
- [编码对照与交付验证](../../PrivateAssets/Courtyard/Blender/B2/v4-playback-delivery.json)

两份视频均为原 192 帧、960×540、24 fps、8 秒，无音轨；均通过整段解码检查。Blender 工程、静帧、源 PNG 和原 MP4 保留。没有新增依赖或素材。

重现命令（在私有 B2 目录内运行；`-n` 防止覆盖）：

```sh
ffmpeg -v error -n -framerate 24 -i frames-presence-v4/%04d.png -frames:v 192 -c:v libx264 -crf 6 -pix_fmt yuv420p -movflags +faststart b2-presence-v4-review.mp4
ffmpeg -v error -n -framerate 24 -i frames-presence-v4/%04d.png -frames:v 192 -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le -vendor apl0 b2-v4-master.mov
```

## 仍未证明

QuickTime 实时播放检查遇到 Mac 锁屏，工具明确报告无法自动解锁；已请求用户方便时解锁。未完成实时播放观察，不将逐帧检查或解码通过替代静谧感/自然度验收。本地浏览器拒绝 file URL，未通过本地服务器等方式绕过限制；视频继续通过原生播放器/文件预览交付。

下一步在可操作的播放器中观察两个完整循环，重点看局部水光、树影与人物停顿；若播放暴露问题，从现有 v4 工程另存定向修复。锁屏不阻挡后续离线场景与逐帧检查。

## 2026-10-03 原生播放已恢复

QuickTime 已打开准确的当前 MP4，开启循环后持续播放。计时观察窗口为 **34.475 秒**，窗口起止时间线分别为 5.934 秒和 0.368 秒，播放开关均为 on；期间间歇获取 UI 状态与截图，确认时间线回绕、头部姿态变化及恢复，未见播放器错误或观测画面的明显位置突变。检查后暂停，并恢复先前的循环设置。

这是原生播放器的实时运行与间歇画面检查，**不是逐帧连续视觉观察**，不能证明细小局部闪动完全不存在。用户对自然度、静谧感的主观验收仍待反馈。截图中的全景动作仍偏轻，微缩模型感仍在。

[原生播放器记录](../../PrivateAssets/Courtyard/Blender/B2/v4-native-playback.json)包含文件哈希和具体观察值。旧“Mac 锁屏”限制已解除，不应再作为下一轮阻塞理由。当前工程和媒体未修改、未重渲染；已询问下一轮优先人物存在感还是插画质感。
