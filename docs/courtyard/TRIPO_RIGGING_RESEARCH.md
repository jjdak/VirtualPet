# Tripo：现成人物绑骨与自然动作可行性

核对日期：2026-09-13。用户对少女A的脸与发型方向评价「不错不错」，并要求研究 Tripo 绑骨能否让人物动作更真实。该反馈不表示衣服、场景效果或动态表演已经验收。本文是资料研究与试验方案，没有上传模型、调用收费任务或修改主工程。

## 判断

Tripo 能给已有模型自动绑骨，并把预设动作应用到其骨架。它适合减少基础绑骨和动作起稿的工作量。我们要的静谧感仍取决于视线、头部、呼吸的先后顺序，身体支撑是否稳定，以及动作间如何衔接。这些需要用实际镜头检查，不能从“生成骨架成功”推断。

少女A是 VRM 0.0，完整文件尚未取得。[VRM 0.0 规范](https://github.com/vrm-c/vrm-specification/blob/master/specification/0.0/README.md)包含 humanoid 骨骼映射与 BlendShape 分组。应先检查该模型已有的真实骨架、蒙皮和眨眼形变；格式描述不能证明这一个模型的表演质量。如果现有绑定够用，优先保留它。

## 已确认的 Tripo 能力

| 能力 | 官方证据 | 对本项目的意义 |
| --- | --- | --- |
| 外部模型自动绑骨 | [帮助页](https://www.tripo3d.ai/help/features/is-it-possible-to-upload-my-existing-model-for-animation)说明可上传已有 GLB/OBJ/STL/FBX，人体使用 T-pose，文件不超过 150 MB | 不必让 Tripo 重新生成角色外观；从原始站姿副本准备输入，不能上传庭院坐姿合并模型当作理想输入 |
| 可绑骨检查 | [Rig Check API](https://developers.tripo3d.ai/en/docs/animations-rig-check)返回 `riggable` 和建议类别，输入格式明确列 GLB | 先做输入检查，避免盲目重复绑骨；VRM 不在其输入列表，需要正确转换，不能仅改扩展名 |
| 绑骨规格与导出 | [Auto Rig API](https://developers.tripo3d.ai/en/docs/animations-rig)提供 `biped`、Tripo/Mixamo 命名规格以及 GLB/FBX 输出 | 骨架及动作可以作为 Blender 的输入；Mixamo 命名兼容不等于任何外部动作自动无损适配 |
| 预设动作 | [Animation Retarget API](https://developers.tripo3d.ai/en/docs/animations-retarget)列出 `sit`、`idle`、`look_around`、`wait` 等，支持单个或多个预设 | 用于坐下、待机、环顾的动作来源；该接口不是文字/视频任意动作生成器，也没有提供自定义 BVH 输入字段 |

API 有容易混淆的版本区别：人形 `v1.0-20240301` 文档列 90 多个 `preset:biped:*` 动作；`v2.5-20260210` 的动作集合不同。Auto Rig 页面模型说明与示例对 v2.5 人形的描述不完全一致，不能只复制示例再混用 v1 动作名。若测试 `sit/idle/look_around`，应核对当时接口版本和对应清单。

Retarget 文档输入要求是已绑骨任务的 `task_id`，没有承诺任意已有 VRM 骨架可以跳过其处理直接使用。所以“只给少女A套 Tripo 动作且保留全部原表情”仍是需要实测的问题，不能预先声称已经支持。

## 没有证实的部分

目前官方 API/帮助文档未足以确认：能为此角色自动完成精细眼睑、眼球、手指表演；能保留原有全部表情形变和材质；能处理头发/裙摆动态；能自动保持手掌与石阶、脚部与地面的接触。没有据此断言产品绝不支持，只是不作为本项目交付保证。

“laugh/cry”等身体动作预设也不能当作已有完整面部表情系统的证据。自动重绑或转换后须比对眼睛、手指、裙摆、贴图和原始脸型。若需要大量改人物网格或重做服装，停止此路线，遵守用户使用现成模型的要求。

## 怎么用：最小路线

1. 获取少女A原始 VRM；保存未修改源文件与许可。用 Blender 检查原骨架和表情的真实形变，先做好静态坐姿。
2. 如果原绑定不足，再把**独立角色的 T-pose 副本**导出 GLB；保留原 VRM 和 `.blend`。检查纹理与人体方向，不改变人物外观。
3. 按官方网页帮助流程：上传模型 → Animate → Auto Rig → 动作库预览 → 导出 GLB/FBX。API 则为上传 → rig-check → rig → retarget → 查询结果；研究阶段无需为一个模型建设自动化平台。
4. 静态方向认可后，取坐姿/待机/环顾作为素材，在 Blender 中制作一段短镜头。关键是眼神先注意到水面、头部轻微跟随、身体保持支撑，然后自然恢复。约 8 秒是建议评审长度，不是 Tripo 动作原始时长保证。
5. 同机位对照原绑定与 Tripo 分支，确认实际变好才采用。新增动画制作仍遵守 B1 静态评审后再 B2 的顺序。

[Blender 动画功能](https://www.blender.org/features/animation/)提供姿态、IK/FK 和约束工具。用它们保持手部支撑、编辑动画曲线，是动画制作，不是重做人形或服装网格。

## 费用与执行边界

[当前 API 价格页](https://developers.tripo3d.ai/en/pricing)列：1 credit = 0.01 美元，Rig Check 免费，Auto Rig 25 credits，Retarget 每动作 10 credits。按表计算，一次绑骨加三个动作是 55 credits，约 **0.55 美元的操作费**；不含额外转换、重试或最低充值要求。接口示例中的 30/20 credits 只是示例，和价格表不同，不能拿来报价。实际提交前以账户当时计费为准。

[Studio 套餐页](https://www.tripo3d.ai/pricing)与 API 计费分开，免费档当前标注公开模型、非商用和导出限制；不能把 API 单次估价当作网页套餐价格，也不能因为原模型 CC0 就假定平台所有服务均免费。

没有安装 Tripo 插件，没有连接账户或读取 API Key，没有上传私人资产，没有发生付费任务。少女A脸与发型方向已认可；衣服、完整文件质量、静态坐姿与动态自然度仍待检查。

## 本项目建议

先取现成 VRM 并检查原绑定。Tripo作为可选的基础绑骨/动作素材工具，Blender负责最终表演与场景接触。这样把投入集中在能看到的动作改善上，不重新陷入人物建模。
