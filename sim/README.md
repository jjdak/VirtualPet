# 庭院 S2：脚步与纸船

2026-10-23。Godot 4.7.2 stable / macOS Apple M4 / Compatibility。现成待机、行走动作已接入少女A；新增 CMU 左右转身/停步与有限脚底校正；池边移动与纸船碰撞/清障可体验，运行时泛白已修正。自然度仍待反馈，没有 LLM 或学习。

## 启动与操作

双击 [`run.command`](run.command)，或在仓库根目录运行 `./sim/run.command`。也可在 Godot 导入 `project.godot` 后按 F5。

建议先按 **G** 看她走到池边，等待纸船碰到树枝，再按 **B** 移开树枝。按 **C** 近看步态，用 WASD 走动和转弯；按 **R** 重来，提前移开树枝也能改变结果。

| 操作 | 效果 |
| --- | --- |
| WASD | 相对当前镜头走动；打断“去池边” |
| C | 全景 / 人物近景 |
| F / Tab | 全景 / 第一视角 |
| 鼠标 / 方向键 | 第一视角环顾 |
| Esc | 释放鼠标；点击场景重新捕获 |
| G | 一次“去池边”规则指令；不可达时明确失败 |
| B | **导演操作**：移动 / 放回水中树枝 |
| R | 重置人物、纸船和树枝 |
| P | 原 B2 坐姿参考 / 返回控制 |

失去焦点自动释放鼠标。第一视角释放鼠标时暂停 WASD。角色清障的手部接触动画尚未实现，B 不表示少女伸手搬物。

## 本轮交付

- GirlA 原 58 骨骼、网格和贴图；Quaternius Idle/Walk 与 CMU TurnLeft/TurnRight/Stop，位移经过碰撞，低位脚部做有限 IK 校正。
- 原完整庭院和 74 处建筑碰撞。去池边沿直接可行路线执行；受阻/超时有失败结果，**不是完整 NavMesh 绕路系统**。
- 纸船沿简化水路推进，扫掠碰撞检测树枝；移开后继续，提前移开则不被挡住，漂过之后放回不会倒退。
- 近景和简化控制栏；环境光/曝光重新收敛，修正泛白。原 B2 主工程没有改写。
- [约 24 秒运行视频](evidence/s2-contact-demo.mp4) · [最新进展及验收边界](../docs/sim/S2_CONTACT_PASS.md) · [调研](../docs/sim/S2_RESEARCH_NOTES.md)。视频和截图仅本地可用。

## 恢复资产

`assets/private/`、`.godot/`、`evidence/` 全部 Git 忽略，公开克隆不带私人模型或视频。先按 [B2 恢复](../docs/archive/B2_CLOSEOUT.md) 放回原工程，再从 [Quaternius 作者页面](https://quaternius.itch.io/universal-animation-library) 免费下载 **Standard**（CC0）并解压至：

`PrivateAssets/Courtyard/Animations/Quaternius/Universal Animation Library[Standard]/`

另按 [CMU 来源/许可/哈希](../docs/sim/S2_CONTACT_PASS.md) 恢复三个 FBX 至 `PrivateAssets/Courtyard/Animations/CMU/`（非 CC0）。然后执行 `./sim/prepare-assets.command`，顺序为独立导出 S1 环境/站姿 → `retarget-sim-s2.py` 生成 Idle/Walk → `retarget-sim-s2-transitions.py` 生成转身/停步 → Godot 导入。已有资产可只执行重定向脚本，不必重导环境。脚本不保存原 `.blend`。

工具：已有 Blender 5.2.1 LTS 和 `/Applications/Godot.app` 4.7.2 stable Universal 非 .NET。没有安装 VRM/MCP 插件、付费服务或全局 skill。

## 验证与录制

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path sim -- --s2-test
/Applications/Godot.app/Contents/MacOS/Godot --path sim -- --s2-test
/Applications/Godot.app/Contents/MacOS/Godot --path sim --fixed-fps 30 --write-movie "$PWD/sim/evidence/s2-contact-demo.avi" -- --s2-film
```

测试约 40 秒，成功输出 `S2_CHECK` / `passed: true` 并退出 0。图形模式额外保存画面，报告分别为 `evidence/s2-check-headless.json` 和 `s2-check-graphical.json`。旧 `--s1-test` 仅适用于 S1 历史提交。

## 限制与下一步

- 已有现成转身/停步和有限脚部 IK；180° 掉头仍分两段，Stop 未按支撑脚匹配，转身/停步播放中不能即时改向。台阶、碰撞与动作混合仍可能滑脚，不能称为成品自然动作。
- 目标跟随只做直接路线和失败检测，不会绕开任意新增障碍。无自动上台阶、跳跃、游泳。
- 面部静态、裙摆沿原权重；没有自制人物、布料或头发模拟。站/坐模式切换没有起身过渡。
- 实时材质、静态树冠和水面仍简化，没有还原 Cycles/概念插画画质。影片不代表实时连续人工手感验收。
- 第一视角隐藏自身模型，只保留影子；没有身体/手部第一视角表现。
- S3 控制权协议、局部感知和 S4 LLM 尚未实施；先看本轮脚步与因果互动是否值得继续。
