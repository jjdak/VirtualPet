# 私人语音素材记录

## 使用中的 Q 版短音效

- 页面：[菲比一直在找咕咕嘎嘎...](https://www.bilibili.com/video/BV1cx776cE57/)
- BV 号：`BV1cx776cE57`
- 页面音轨时长：约 3 分 33.14 秒
- 用途：寻找 Q 版小人短促的“菲比啾比”音效，而不是角色本体的正式台词
- 本地 Whisper 在前三个目标位置分别识别为同音的“飞逼救逼”；识别结果只用于定位，不作为文字版权或台词判断
- 项目所有者已确认三条全部使用，并标注 01 为生气、02 为正常偏委屈、03 为轻微生气

| 候选 | 原音轨范围 | 情绪 | App 私人资源 |
| --- | --- | --- | --- |
| 01 | `00:00.000–00:01.780` | 生气 | `phoebe-chirubi-angry-private.m4a` |
| 02 | `00:02.940–00:04.400` | 正常、略委屈 | `phoebe-chirubi-soft-private.m4a` |
| 03 | `00:06.680–00:07.960` | 轻微生气 | `phoebe-chirubi-mildly-angry-private.m4a` |

三条均转换为单声道 44.1 kHz AAC、约 96 kbps，并统一到目标响度 -16 LUFS、峰值 -1.5 dBTP。明显生气用于三连点和长按，轻微生气用于帽子或身体被戳，正常偏委屈用于摸头和啾比按钮；安静模式不播放。

## 2026-08-31 A/B 听感候选

为避免用主观判断替换已经确认的声音，A 保持当前 App 使用的原始裁剪与响度处理，B 只增加轻量降噪：`afftdn=nr=2:nf=-35:tn=1`，随后仍按 `loudnorm=I=-16:LRA=7:TP=-1.5` 统一响度。B 不进入 App，除非项目所有者听感确认后再替换。

| 候选 | A（当前 App） | B（轻降噪） |
| --- | --- | --- |
| 01 生气 | `SharedAssets/PrivateAudio/phoebe-chirubi-angry-private.m4a` | `PrivateAssets/AudioCandidates/BV1cx776cE57/AB/01-light-denoise.m4a` |
| 02 正常、略委屈 | `SharedAssets/PrivateAudio/phoebe-chirubi-soft-private.m4a` | `PrivateAssets/AudioCandidates/BV1cx776cE57/AB/02-light-denoise.m4a` |
| 03 轻微生气 | `SharedAssets/PrivateAudio/phoebe-chirubi-mildly-angry-private.m4a` | `PrivateAssets/AudioCandidates/BV1cx776cE57/AB/03-light-denoise.m4a` |

连续试听文件位于同一目录：`01-ab-preview.m4a`、`02-ab-preview.m4a`、`03-ab-preview.m4a`。每个文件顺序均为 A、0.5 秒静音、B；长度分别约 4.08 秒、3.43 秒、3.10 秒，便于不看文件名直接比较前后听感。

B 版本仍为单声道 44.1 kHz AAC、约 96 kbps，仅作本地私人试听。生成命令：

```bash
ffmpeg -i input.m4a \
  -af 'afftdn=nr=2:nf=-35:tn=1,loudnorm=I=-16:LRA=7:TP=-1.5' \
  -ar 44100 -ac 1 -c:a aac -b:a 96k output.m4a
```

2026-08-31 本地编码审计（`ffprobe` + FFmpeg `loudnorm`）如下；这些数值只证明格式和响度一致，不替代项目所有者的听感选择：

| 候选 | A 时长 / 输入响度 | B 时长 / 输入响度 | 采样 / 声道 |
| --- | --- | --- | --- |
| 01 生气 | 1.780 s / -16.1 LUFS | 1.788 s / -16.0 LUFS | 44.1 kHz / mono |
| 02 正常、略委屈 | 1.460 s / -16.1 LUFS | 1.463 s / -16.7 LUFS | 44.1 kHz / mono |
| 03 轻微生气 | 1.280 s / -16.2 LUFS | 1.300 s / -16.0 LUFS | 44.1 kHz / mono |

下载命令：

```bash
yt-dlp --no-playlist -f ba \
  -o 'PrivateAssets/AudioSource/BV1cx776cE57-audio.%(ext)s' \
  'https://www.bilibili.com/video/BV1cx776cE57/'
```

## 已归档的朗读候选

- 页面：[菲比啾比！—菲八啾比！](https://www.bilibili.com/video/BV1vjKG6rEGn/)
- BV 号：`BV1vjKG6rEGn`
- 页面标记：含 AI 生成内容
- 页面时长：11 秒；下载到的独立音轨约 10 秒
- 本地 Whisper 原始识别：`00:00.000–00:02.000` 为同音的“飛比就比”；结合页面标题“菲比啾比！—菲八啾比！”将其判定为目标短语，而不是擅自改写识别记录
- App 裁剪：`00:00.000–00:02.150`，末尾 120 ms 淡出
- 输出：单声道、44.1 kHz、AAC、约 96 kbps，目标响度 -16 LUFS、峰值 -1.5 dBTP
- 可见范围：只用于项目所有者的私人非商业测试，不提交 GitHub

该片段不再进入 App，保存在可恢复的私人归档：

```text
PrivateAssets/AudioCandidates/Legacy/phoebe-chirubi-reading-private.m4a
```

## 淘汰的候选

`BV1zS3s6KERo` 虽然标题为“菲比啾比”，但 47.87 秒音轨经本地转写后是其他动画解说，未识别到目标短语，因此没有使用。原始候选、转写和模型均位于 `PrivateAssets/`，不会进入仓库或 App。

## 复现步骤

```bash
brew install yt-dlp ffmpeg whisper-cpp
```

从页面播放器取得独立 AAC 音轨后，先转为 Whisper 支持的 16 kHz 单声道 WAV：

```bash
ffmpeg -i source-audio.m4s -ar 16000 -ac 1 -c:a pcm_s16le source-16k.wav
whisper-cli -ng -m PrivateAssets/Models/ggml-base.bin \
  -f source-16k.wav -l zh -osrt -oj -of transcript
```

根据转写时间戳裁剪首句：

```bash
ffmpeg -ss 0 -t 2.15 -i source-audio.m4s \
  -af 'highpass=f=80,afade=t=in:st=0:d=0.04,afade=t=out:st=2.03:d=0.12,loudnorm=I=-16:LRA=7:TP=-1.5' \
  -ar 44100 -ac 1 -c:a aac -b:a 96k \
  PrivateAssets/AudioCandidates/Legacy/phoebe-chirubi-reading-private.m4a
```

资源更换时必须重新记录页面、BV 号、实际裁剪时间和本地转写结果，不能仅凭视频标题判断内容。
