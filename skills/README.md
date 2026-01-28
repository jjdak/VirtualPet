# VirtualPet Skills

这是一个完整的技能系统，用于创建和管理虚拟宠物iOS应用。

## 技能系统结构

```
skills/
├── README.md                    # 技能系统总览
├── usage-example.sh             # 使用示例脚本
└── virtual-pet/                 # 虚拟宠物技能
    ├── skill.json               # JSON配置文件
    ├── skill.js                 # JavaScript实现
    ├── config/                  # 技能配置
    │   └── default.json         # 默认设置
    ├── docs/                    # 文档
    │   ├── README.md            # 使用指南
    │   ├── API.md               # API参考
    │   └── examples.md         # 示例代码
    └── templates/               # 代码模板
        ├── pet-model.swift      # 宠物模型模板
        ├── pet-view.swift       # 宠物视图模板
        ├── pet-app.swift        # 应用入口模板
        └── pet-assets.json      # 资源模板
```

## 支持的宠物类型

- 🐱 **Cat** (橙色) - 默认宠物类型
- 🐶 **Dog** (棕色) - 忠诚的伙伴
- 🐰 **Rabbit** (粉色) - 温顺可爱
- 🐹 **Hamster** (黄色) - 活泼好动
- 🐦 **Bird** (蓝色) - 自由飞翔

## 使用方法

### JavaScript版本

```bash
# 列出可用技能
node skills/virtual-pet/skill.js list

# 创建新项目
node skills/virtual-pet/skill.js create --project-name MyPet --pet-type dog
```
