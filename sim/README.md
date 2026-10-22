# 庭院 S1：Godot 控制与第一视角小样

2026-10-22。Godot 4.7.2 stable，macOS / Apple M4，Compatibility 渲染。当前是可控制的迁移验证，尚无自然步态、智能行为或物品交互。

## 启动

双击本目录 [`run.command`](run.command)，或在仓库根目录运行 `./sim/run.command`。它先更新本地导入缓存，再打开小样。也可在 Godot 导入 [`project.godot`](project.godot) 后按 F6/F5 运行场景/项目。

| 操作 | 效果 |
| --- | --- |
| W / A / S / D | 相对当前视角移动角色 |
| F 或 Tab | 切换观察视角/第一视角 |
| 鼠标移动 | 第一视角捕获鼠标后环顾 |
| 方向键 | 第一视角环顾，鼠标释放时也可用 |
| Esc | 释放鼠标；点击场景重新捕获 |
| P | 原 B2 坐姿动画预览/返回控制 |
| R | 回到起点，恢复初始朝向 |

底栏也可点击切换视角、预览和重置。失去应用焦点自动释放鼠标。第一视角释放鼠标时暂停 WASD，避免操作其他窗口时继续走动。观察视角保留原 B2 相机构图；第一视角进入角色控制副本的眼高。

## 已迁入什么

- 从 v6 focused 读取的 289 个可见环境网格，保留完整庭院布局。
- 少女A原网格、贴图和 58 骨骼；独立站姿副本供移动/相机验证。
- 原 B2 身体动画和原坐姿位置，以 P 独立预览。
- 74 处建筑网格碰撞与明确池边/侧边控制边界。

站姿副本骨架缩放为 1.8，约 2.10 场景单位高，眼高 1.78；坐姿预览保留 B2 原缩放 2.25 和位置。两者是同一人物的不同验证模式，不是两个居民。未修改原人物网格，也未覆盖 `.blend`。

## 资产恢复与公开范围

`assets/private/`、`.godot/`、`evidence/` 全部 Git 忽略。首次克隆只有代码，没有可公开分发的完整角色画面。先按 [B2 恢复记录](../docs/archive/B2_CLOSEOUT.md) 放回私人源工程，再运行 `./sim/prepare-assets.command`。它调用 `blender/scripts/export-sim-s1.py` 导出三个独立 GLB 和迁移清单，并由 Godot 导入。

工具安装：从 [Godot 官方 macOS 页](https://godotengine.org/download/macos/) 获取 **4.7.2 stable / Universal / 非 .NET**，解压为 `/Applications/Godot.app`。本机已安装；校验和、签名和公证记录见 [验证回执](../docs/sim/S1_VERIFICATION.json)。Blender 使用原有 5.2.1 LTS。未安装 VRM 插件或额外动作包。

## 验证

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path sim --quit-after 1800 -- --s1-test
/Applications/Godot.app/Contents/MacOS/Godot --path sim --quit-after 1800 -- --s1-test
```

检查完成后自动退出，以 `passed` 和退出码判断，不以“窗口打开”代替成功。两种模式分别输出 `evidence/s1-runtime-check-headless.json` 与 `evidence/s1-runtime-check-graphical.json`。无窗口模式无法捕获鼠标，此项只由图形模式验证；图形检查会暂时控制小样角色并切换相机。

## 明确限制

- 移动目前是站姿平移和转向，没有走路/起身动画；自然步态属于 S2。
- 程序材质暂转换为主要色块；没有复制 Cycles 光照链接、合成与精细水体。实时版更硬、更平，不能称为还原 B2 画质。
- 水面是简化的不透明动态 shader，没有流体仿真。树冠当前静态。
- 第一视角隐藏自身完整模型，只保留影子，暂不显示身体和手。坐姿/站姿切换没有起身过渡。
- 地形控制限于庭院台地与池沿前方，不包含游泳、跳跃或自动登阶。
- 无表情、LLM、AI 接管、寻路、纸船交互或学习。

下一阶段从现成走路/转身动作重定向和纸船世界状态开始，见 [SIM 计划](../docs/SIM_STAGE_PLAN.md)。
