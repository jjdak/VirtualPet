# Cubism 单步操作与恢复手册

这份手册用于减少每轮重新扫描 Cubism 界面和项目文件的成本。开始工作前先读取 [`continuation.json`](continuation.json)，只验证与当前 `nextAction` 有关、可能已经变化的状态。

> 当前状态（2026-08-28）：Live2D 已暂停，自研 Cubism MCP/GUI/画布自动化已停止。只要继续工作卡仍是 `spritekit-mainline`、`live2dStatus: paused`、`cubismActionRequired: false`，就不要打开 Cubism、扫描 UI 或继续 Native Metal host。本手册仅供人工恢复门禁通过后的未来会话使用。

## 先选择工作轨道

### RigLite Runtime（暂停的历史轨道）

目标曾是用现有轻量导出打通 Native R5 加载、显示和参数驱动。只要 `continuation.json` 的 `cubismActionRequired` 为 `false`，就不要打开或修改 Cubism 模型。

RigLite 完成条件：

- `phoebe.model3.json` 和纹理能在 macOS、iOS Simulator arm64 显示
- `ParamMouthOpenY` 或一个眼睛参数能产生可见变化
- 私人模型缺失时仍回退到 SpriteKit
- 保存可重复的构建、运行和验证命令

暂停原因：Native R5 已能持久化加载 `model3`，但对现有 checkpoint 的角度、眼睛、嘴、呼吸、头发和帽子参数逐一写入极值后，Core 顶点均不变。参数 ID 不能替代 keyform；代理继续操作 Cubism 不能经济地消除这个人工建模瓶颈。

`ParamHatSwing`、正式帽子/头发/披风拆层、物理和动作不阻塞这条轨道。禁止添加没有绑定真实变形的空参数来通过完整契约。

### Production V1

只有 RigLite Runtime 闭环完成，或当前工作明确属于正式美术制作时才进入这条轨道。它要求正式 PSD、遮挡补画、完整参数、物理、动作和视觉验收。

## Cubism 会话开始

1. 读取 `continuation.json`，确认 `activeTrack`、`nextAction`、模型路径和 checkpoint。
2. 确认 Editor 版本。5.3.03 是正式基线；5.4 Alpha 只能打开隔离副本。
3. 确认当前窗口中的模型路径，不根据窗口缩略图或画布内容猜测。
4. 记录本轮唯一目标对象、Inspector `名称`/`ID`、目标参数和预期视觉变化。
5. 如果无法把任务缩小为一个对象、一个参数或一个导出动作，先拆分任务，不开始批量编辑。

## 单步动作循环

每轮只重复以下闭环：

```text
确认 Editor 和模型
→ Inspector 确认对象 ID
→ 执行一个 UI 动作
→ 检查默认值与极值
→ 保存局部截图
→ 保存新的 .cmo3 checkpoint
→ 更新 continuation.json
```

- 缓存菜单名称、菜单路径和对象 ID，不缓存 accessibility element index。
- 每个 UI 动作后刷新界面状态；优先读取当前窗口、Inspector 和截图，不重复读取完整 accessibility 树或日志面板。
- 参数验收必须观察默认值和至少一个极值；参数存在但没有可见效果不算完成。
- 自动网格生成后必须检查内部顶点、透明轮廓和不相关像素岛，不能只依据命令成功返回。
- 完成一个已接受的网格、参数或导出节点就保存 checkpoint；不得只保存在 `/tmp`。

## 唯一允许的恢复验证

这不是代理 UI 自动化任务。由熟悉 Cubism 的人只完成以下一次验证：

1. 在隔离的可编辑 checkpoint 中，为 `ParamMouthOpenY` 或一个眼睛参数制作默认值与一个极值 keyform。
2. 肉眼确认默认值和极值确实产生嘴部开合或眼睛开合，不修改 5.3 基线。
3. 保存可恢复 `.cmo3`，只导出一次运行时文件。
4. 运行 `scripts/verify_live2d_model3_motion.sh`。

脚本返回 0 且报告至少一个 Drawable 顶点哈希变化时，只恢复 RigLite Native Metal host；仍不建设 Cubism MCP 或自研自动化。脚本仍返回 2 时，当前版本冻结 Live2D，继续 SpriteKit / SwiftUI / 动作图集主线。除此之外没有待处理的 Cubism 单步。

## UI 失效时的停止规则

- 首次失败：刷新一次状态并重新解析当前控件。
- 再次失败：缩小到相关窗口或截图，不读取完整树。
- Java 控件仍无法可靠聚焦或输入：请用户只完成一个明确点击或数值输入，然后立即检查结果并继续。
- 出现 `AccessibleHTML`、`this.grid is null` 等错误时，不据此重启 Editor、丢弃模型或判断模型损坏。

## MCP 与自动化停止规则

- 不安装或启用 Cubism MCP。
- 不开发关键形桥接、坐标录制、视觉点击、画布拖拽或 accessibility index 自动化。
- 5.4 Alpha 只保留现有隔离 checkpoint，不再作为当前工作环境。
- 只有稳定版 API 明确支持 ArtMesh 顶点或 Deformer 几何写入，或项目进入可复用的多模型批量生产，并且用户基于新证据明确重开评估时，才重新讨论自动化。

## 会话结束

结束前必须：

1. 把参数恢复默认值并保存可恢复 `.cmo3`。
2. 记录截图或确定性命令的验证结果。
3. 只把已验证事项加入 `lastVerified`。
4. 把 `nextAction` 写成下一轮可以直接执行的一句话。
5. 明确 `cubismActionRequired`；若为 `false`，下一轮不得重新侦察 Cubism UI。
