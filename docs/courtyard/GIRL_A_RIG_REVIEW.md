# 少女 A 文件与绑定实查

2026-09-13：用户提供 `Downloads/6309260419351179234.vrm.glb`。已保留原件副本并用 Blender 5.2.1 内置 glTF 导入器检查；没有重新生成或修改人物、头发、服装网格，没有安装插件或上传 Tripo。

## 可见结果

- [独立 Blender 检查工程](../../PrivateAssets/Courtyard/Characters/GirlA/girl-a-rig-review.blend)
- [实际渲染对照](../../PrivateAssets/Courtyard/Characters/GirlA/girl-a-rig-review.png)：画面左侧是放下手臂、轻微转头的测试姿势，右侧是源 T 姿势。不是动画或庭院最终效果。
- [形变测量](../../PrivateAssets/Courtyard/Characters/GirlA/rig-verification.json)、[重开检查](../../PrivateAssets/Courtyard/Characters/GirlA/reopen-verification.json)、[来源信息](../../PrivateAssets/Courtyard/Characters/GirlA/SOURCE.json)。

## 文件与实际能力

文件是完整可解析的 GLB 2.0，含 VRM 0.x 扩展；模型标题 `GirlA`、作者 `Kutsushita` 与所选角色一致。体积 2,444,204 字节，SHA256 `8ce09c753a14e2ad9d9a6ee46d00953637cead228bb27d9026765e94ec5533da`。

| 项目 | 实查结果 |
| --- | --- |
| 骨架 | Blender 导入为 58 根骨骼，含身体与手指 |
| 蒙皮网格 | face 1,942 顶点、other 6,420 顶点 |
| 头部转动 | 实际顶点最大位移约 0.0422 m |
| 手臂、膝盖、食指 | 实际最大位移约 0.2607 / 0.2157 / 0.0185 m |
| 表情 | 17 个 VRM 表情条目全部空绑定；7 个网格 primitive 均没有 morph targets；Blender Shape Keys 为 0 |
| 眼神 | 没有眼球骨骼，也没有视线形变；仅有 lookAt 配置不能产生独立眼球运动 |
| 动画与弹簧 | 没有动画片段；spring group 的 bones 为空，没有可直接复用的动态配置 |
| 材质 | 4 张原贴图已打包；为检查预览改为接受灯光的 Principled 材质，未改原始纹理 |

位移证明蒙皮确实响应，不表示动作自然、没有穿插或坐姿已经验收。模型中的 `face.baked` / `other.baked` 命名与空表情并不能单独证明文件下载方式，也不能证明作者不存在更完整的版本；已向用户询问来源。

## 当时的结论与下一步（已由 9 月 14 日用户决定调整）

**身体绑定够用，目标所需的眨眼和独立视线数据缺失。** 当前没有必要为了身体活动默认重绑 Tripo。基础身体自动绑骨不能被当作已经补齐眼睑、眼球与细微表情的证据。

先确认这是不是官网下载的原始文件，或是否存在作者提供的完整表情版本。如果这是作者唯一版本，则继续寻找外观相近、带实际眨眼和视线控制的开放模型；不在本轮自制面部网格来补洞。

保留少女 A 已获认可的脸与发型方向。当前文件仅用于外观和身体检查，尚未替换主庭院；`courtyard-b1-v3.blend` 保持原状。完整角色能力通过后再进行静态入景评审，随后才进入 B2 原生短动画。

## 2026-09-14 用户决定：缺少面部数据不阻挡进展

用户明确接受当前能力缺口，优先把场景整体做活。保留上述数据实查，但撤销寻找完整原件的制作前置条件；直接用现有身体骨架摆姿、入景，随后依据静态评审制作环境与身体的原生短片。不将静态脸冒充眨眼，不再因这一缺口停工。果蝇研究只作未来行为设计参考，见[研究](FLY_BRAIN_BEHAVIOR_RESEARCH.md)。
