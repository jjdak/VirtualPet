#!/usr/bin/env node

/**
 * VirtualPet技能 - 创建和管理虚拟宠物iOS应用
 *
 * 使用方法:
 * node skill.js create --project-name MyPet --pet-type dog
 * node skill.js list
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 配置
const SKILL_CONFIG = {
  name: "virtual-pet",
  version: "1.0.0",
  description: "创建和管理虚拟宠物iOS应用的技能",
  petTypes: {
    cat: { name: "猫咪", emoji: "🐱", color: "orange", description: "可爱的猫咪，橙色，默认宠物类型" },
    dog: { name: "狗狗", emoji: "🐶", color: "brown", description: "忠诚的狗狗，棕色" },
    rabbit: { name: "兔子", emoji: "🐰", color: "pink", description: "温顺的兔子，粉色" },
    hamster: { name: "仓鼠", emoji: "🐹", color: "yellow", description: "活泼的仓鼠，黄色" },
    bird: { name: "小鸟", emoji: "🐦", color: "blue", description: "自由的小鸟，蓝色" }
  },
  templates: {
    petModel: "templates/pet-model.swift",
    petView: "templates/pet-view.swift",
    petApp: "templates/pet-app.swift"
  }
};

// 模板定义
const TEMPLATES = {
  petModel: `//
//  Pet.swift
//  {{project_name}}
//
//  Created by VirtualPet Creator on {{current_date}}
//

import Foundation
import Combine
import SwiftUI

// 宠物心情枚举
enum PetMood: String, CaseIterable {
    case happy = "开心"
    case normal = "正常"
    case hungry = "饥饿"
    case sad = "伤心"
    case sick = "生病"
    case excited = "兴奋"
    case sleepy = "困倦"
}

// 宠物类型
enum PetType: String, CaseIterable {
    case cat = "🐱"
    case dog = "🐶"
    case rabbit = "🐰"
    case hamster = "🐹"
    case bird = "🐦"

    var color: Color {
        switch self {
        case .cat: return .orange
        case .dog: return .brown
        case .rabbit: return .pink
        case .hamster: return .yellow
        case .bird: return .blue
        }
    }
}

// 活动记录
struct Activity: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
    let date: Date
    let value: Int?
}

// 状态记录
struct PetStatsRecord {
    let date: Date
    let hunger: Int
    let happiness: Int
    let health: Int
}

// 成就
class Achievement: ObservableObject, Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let requirement: () -> Bool
    @Published var unlocked: Bool = false

    init(title: String, description: String, icon: String, requirement: @escaping () -> Bool) {
        self.title = title
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.unlocked = false
    }
}

class Pet: ObservableObject {
    @Published var hunger: Int = {{initialHunger}}
    @Published var happiness: Int = {{initialHappiness}}
    @Published var health: Int = {{initialHealth}}
    @Published var energy: Int = {{initialEnergy}}
    @Published var age: Int = 0
    @Published var experience: Int = {{initialExperience}}
    @Published var level: Int = {{initialLevel}}
    @Published var lastFed = Date()
    @Published var petType: PetType = .cat
    @Published var mood: PetMood = .normal
    @Published var totalInteractions: Int = 0
    @Published var maxHappiness: Int = {{initialHappiness}}
    @Published var careStreak: Int = 0
    @Published var unlockedAchievements: Int = 0
    @Published var activities: [Activity] = []
    @Published var statsHistory: [PetStatsRecord] = []
    @Published var achievements: [Achievement] = []

    // 辅助方法：确保值在有效范围内
    private func clampValue(_ value: Int) -> Int {
        max(0, min(100, value))
    }

    // 初始化方法
    init(hunger: Int = {{initialHunger}}, happiness: Int = {{initialHappiness}}, health: Int = {{initialHealth}}, energy: Int = {{initialEnergy}}) {
        self.hunger = clampValue(hunger)
        self.happiness = clampValue(happiness)
        self.health = clampValue(health)
        self.energy = clampValue(energy)
        setupAchievements()
        updateMood()
    }

    // 设置成就
    private func setupAchievements() {
        let achievement1 = Achievement(
            title: "初次见面",
            description: "第一次与宠物互动",
            icon: "star.fill",
            requirement: { self.totalInteractions >= 1 }
        )

        let achievement2 = Achievement(
            title: "美食家",
            description: "喂养宠物10次",
            icon: "fork.knife",
            requirement: { self.activities.filter { $0.icon == "fork.knife" }.count >= 10 }
        )

        let achievement3 = Achievement(
            title: "快乐源泉",
            description: "让宠物快乐度达到100",
            icon: "heart.fill",
            requirement: { self.maxHappiness >= 100 }
        )

        let achievement4 = Achievement(
            title: "健康达人",
            description: "连续7天保持宠物健康度80+",
            icon: "leaf.fill",
            requirement: {
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                return self.statsHistory.filter { record in
                    record.date >= sevenDaysAgo && record.health >= 80
                }.count >= 7
            }
        )

        achievements = [achievement1, achievement2, achievement3, achievement4]
    }

    // 更新宠物心情
    func updateMood() {
        if health < 30 {
            mood = .sick
        } else if hunger > 80 {
            mood = .hungry
        } else if energy < 20 {
            mood = .sleepy
        } else if happiness > 80 {
            mood = .happy
        } else if happiness < 20 {
            mood = .sad
        } else if happiness > 60 && energy > 50 {
            mood = .excited
        } else {
            mood = .normal
        }
    }

    // 记录活动
    func logActivity(_ activity: Activity) {
        activities.append(activity)
        if activities.count > 100 {
            activities.removeFirst()
        }

        // 更新最高快乐度
        if happiness > maxHappiness {
            maxHappiness = happiness
        }

        // 检查成就
        checkAchievements()
    }

    // 检查成就
    func checkAchievements() {
        for achievement in achievements {
            if !achievement.unlocked && achievement.requirement() {
                achievement.unlocked = true
                unlockedAchievements += 1
                logActivity(
                    Activity(
                        title: "成就解锁：\\(achievement.title)",
                        icon: "trophy.fill",
                        color: .yellow,
                        date: Date(),
                        value: nil
                    )
                )
            }
        }
    }

    // 互动
    func interact(type: String) {
        switch type {
        case "play":
            happiness = clampValue(happiness + 15)
            energy = clampValue(energy - 10)
            experience += 5
            logActivity(
                Activity(
                    title: "玩耍",
                    icon: "gamecontroller",
                    color: .purple,
                    date: Date(),
                    value: 15
                )
            )
        case "feed":
            hunger = clampValue(hunger - 25)
            happiness = clampValue(happiness + 5)
            lastFed = Date()
            experience += 3
            logActivity(
                Activity(
                    title: "喂养",
                    icon: "fork.knife",
                    color: .orange,
                    date: Date(),
                    value: 25
                )
            )
        case "clean":
            health = clampValue(health + 15)
            happiness = clampValue(happiness + 5)
            experience += 2
            logActivity(
                Activity(
                    title: "清理",
                    icon: "sparkles",
                    color: .green,
                    date: Date(),
                    value: 15
                )
            )
        case "exercise":
            health = clampValue(health + 10)
            hunger = clampValue(hunger + 15)
            energy = clampValue(energy - 20)
            experience += 8
            logActivity(
                Activity(
                    title: "运动",
                    icon: "figure.walk",
                    color: .blue,
                    date: Date(),
                    value: 10
                )
            )
        case "cuddle":
            happiness = clampValue(happiness + 20)
            health = clampValue(health + 5)
            energy = clampValue(energy - 5)
            experience += 4
            logActivity(
                Activity(
                    title: "拥抱",
                    icon: "heart.fill",
                    color: .red,
                    date: Date(),
                    value: 20
                )
            )
        }

        totalInteractions += 1
        updateMood()
        checkLevelUp()
        saveData()
    }

    // 检查升级
    private func checkLevelUp() {
        let requiredExp = level * 100
        if experience >= requiredExp {
            level += 1
            experience = 0
            // 升级奖励
            health = min(100, health + 20)
            logActivity(
                Activity(
                    title: "升级到\\(level)级！",
                    icon: "star.fill",
                    color: .yellow,
                    date: Date(),
                    value: nil
                )
            )
        }
    }

    // 自动衰减：每分钟饥饿度+1，快乐度-1，能量-2
    func decay() {
        hunger = clampValue(hunger + 1)
        happiness = clampValue(happiness - 1)
        energy = clampValue(energy - 2)
        age += 1
        updateMood()
        saveData()
    }

    // 保存数据到UserDefaults
    func saveData() {
        let defaults = UserDefaults.standard
        defaults.set(hunger, forKey: "pet_hunger")
        defaults.set(happiness, forKey: "pet_happiness")
        defaults.set(health, forKey: "pet_health")
        defaults.set(energy, forKey: "pet_energy")
    }

    // 从UserDefaults加载数据
    static func loadData() -> Pet {
        let defaults = UserDefaults.standard
        let hunger = defaults.integer(forKey: "pet_hunger")
        let happiness = defaults.integer(forKey: "pet_happiness")
        let health = defaults.integer(forKey: "pet_health")
        let energy = defaults.integer(forKey: "pet_energy")

        // 如果是第一次加载，使用默认值
        if hunger == 0 && happiness == 0 && health == 0 && energy == 0 {
            return Pet()
        }

        return Pet(hunger: hunger, happiness: happiness, health: health, energy: energy)
    }
}`,

  petView: `//
//  ContentView.swift
//  {{project_name}}
//
//  Created by VirtualPet Creator on {{current_date}}
//

import SwiftUI

struct ContentView: View {
    @StateObject private var pet = Pet.loadData()
    @State private var showingAchievements = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 宠物显示区域
                PetDisplayView(pet: pet)

                // 状态指示器
                StatusGridView(pet: pet)

                // 互动按钮
                InteractionButtonsView(pet: pet)

                // 快速统计
                QuickStatsView(pet: pet)
            }
            .navigationTitle("我的宠物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAchievements = true
                    }) {
                        Image(systemName: "trophy")
                    }
                }
            }
            .sheet(isPresented: $showingAchievements) {
                AchievementsView(pet: pet)
            }
        }
        .onAppear {
            // 设置定时器
            Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
                pet.decay()
            }
        }
    }
}

// 宠物显示视图
struct PetDisplayView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 20) {
            // 宠物头像和类型
            Text(pet.petType.rawValue)
                .font(.system(size: 100))
                .padding()

            // 宠物信息
            PetHeaderView(pet: pet)

            // 心情标签
            Text(pet.mood.rawValue)
                .font(.title2)
                .foregroundColor(pet.petType.color)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// 宠物信息头
struct PetHeaderView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 8) {
            Text("等级 \\(pet.level)")
                .font(.headline)
            Text("经验值: \\(pet.experience)")
                .font(.subheadline)
            Text("年龄: \\(pet.age)分钟")
                .font(.subheadline)
        }
    }
}

// 状态指示器网格
struct StatusGridView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
            StatusIndicator(title: "饥饿度", value: pet.hunger, color: .orange)
            StatusIndicator(title: "快乐度", value: pet.happiness, color: .pink)
            StatusIndicator(title: "健康度", value: pet.health, color: .green)
            StatusIndicator(title: "能量", value: pet.energy, color: .blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

// 单个状态指示器
struct StatusIndicator: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            ProgressView(value: Double(value), total: 100)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(color)
            Text("\\(value)%")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// 互动按钮视图
struct InteractionButtonsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 15) {
            // 第一行按钮
            HStack(spacing: 15) {
                InteractionButton(icon: "gamecontroller", action: { pet.interact(type: "play") }, color: .purple)
                InteractionButton(icon: "fork.knife", action: { pet.interact(type: "feed") }, color: .orange)
                InteractionButton(icon: "sparkles", action: { pet.interact(type: "clean") }, color: .green)
            }

            // 第二行按钮
            HStack(spacing: 15) {
                InteractionButton(icon: "figure.walk", action: { pet.interact(type: "exercise") }, color: .blue)
                InteractionButton(icon: "heart.fill", action: { pet.interact(type: "cuddle") }, color: .red)
            }
        }
        .padding()
    }
}

// 单个互动按钮
struct InteractionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 快速统计视图
struct QuickStatsView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("总互动次数:")
                Spacer()
                Text("\\(pet.totalInteractions)")
            }
            HStack {
                Text("最高快乐度:")
                Spacer()
                Text("\\(pet.maxHappiness)")
            }
            HStack {
                Text("解锁成就:")
                Spacer()
                Text("\\(pet.unlockedAchievements)/4")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
}

// 成就视图
struct AchievementsView: View {
    @ObservedObject var pet: Pet
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("成就")
                    .font(.largeTitle)
                    .padding()

                ScrollView {
                    ForEach(pet.achievements) { achievement in
                        HStack {
                            Image(systemName: achievement.icon)
                                .font(.title2)
                                .foregroundColor(achievement.unlocked ? .yellow : .gray)
                            VStack(alignment: .leading) {
                                Text(achievement.title)
                                    .font(.headline)
                                Text(achievement.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if achievement.unlocked {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("成就")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}`,

  petApp: `//
//  {{project_name}}App.swift
//  {{project_name}}
//
//  Created by VirtualPet Creator on {{current_date}}
//

import SwiftUI

@main
struct {{project_name}}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}`
};

// 工具函数
function parseCommandLine() {
  const args = process.argv.slice(2);
  const command = args[0];
  const options = {};

  // 解析参数
  for (let i = 1; i < args.length; i++) {
    const arg = args[i];

    if (arg.startsWith('--')) {
      const key = arg.substring(2);
      const nextArg = args[i + 1];

      if (nextArg && !nextArg.startsWith('--')) {
        options[key] = nextArg;
        i++;
      } else {
        options[key] = true;
      }
    }
  }

  return { command, options };
}

// 将kebab-case转换为camelCase
function toCamelCase(str) {
  return str.replace(/-([a-z])/g, (g) => g[1].toUpperCase());
}

// 填充模板
function fillTemplate(template, data) {
  let content = template;

  for (const [key, value] of Object.entries(data)) {
    const regex = new RegExp(`{{${key}}}`, 'g');
    content = content.replace(regex, value);
  }

  return content;
}

// 确保目录存在
function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

// 列出宠物类型
function listPetTypes() {
  console.log('🐾 支持的宠物类型:');
  console.log('');

  for (const [key, pet] of Object.entries(SKILL_CONFIG.petTypes)) {
    console.log(`${pet.emoji} ${pet.name} (${key})`);
    console.log(`   描述: ${pet.description}`);
    console.log('');
  }
}

// 创建Xcode项目
function createXcodeProject(options) {
  const projectName = options['project-name'];
  const petType = options['pet-type'] || 'cat';
  const deploymentTarget = options['deployment-target'] || '17.0';
  const bundleId = options['bundle-id'] || `com.example.${projectName.toLowerCase()}`;
  const outputDir = options['output-dir'] || process.cwd();
  const projectDir = path.join(outputDir, projectName);

  // 检查宠物类型是否有效
  if (!SKILL_CONFIG.petTypes[petType]) {
    console.error(`❌ 错误: 不支持的宠物类型 '${petType}'`);
    listPetTypes();
    process.exit(1);
  }

  // 检查项目是否已存在
  if (fs.existsSync(projectDir)) {
    console.error(`❌ 错误: 项目目录 '${projectDir}' 已存在`);
    process.exit(1);
  }

  // 获取当前日期
  const currentDate = new Date().toLocaleDateString('zh-CN');

  // 准备模板数据
  const templateData = {
    project_name: projectName,
    project_name_camel: projectName.replace(/(^|\\s)(\\w)/g, (_, c1, c2) => c1 + c2.toUpperCase()),
    pet_type: petType,
    pet_type_camel: petType.charAt(0).toUpperCase() + petType.slice(1),
    deployment_target: deploymentTarget,
    bundle_id: bundleId,
    current_date: currentDate,
    initialHunger: options['initial-hunger'] || 30,
    initialHappiness: options['initial-happiness'] || 50,
    initialHealth: options['initial-health'] || 80,
    initialEnergy: options['initial-energy'] || 70,
    initialExperience: options['initial-experience'] || 0,
    initialLevel: options['initial-level'] || 1
  };

  console.log(`🚀 创建虚拟宠物项目: ${projectName}`);
  console.log(`🐱 宠物类型: ${SKILL_CONFIG.petTypes[petType].name}`);
  console.log(`📱 iOS版本: ${deploymentTarget}`);
  console.log(`📦 Bundle ID: ${bundleId}`);

  // 创建项目目录
  ensureDir(projectDir);

  // 创建子目录
  ensureDir(path.join(projectDir, 'VirtualPet'));
  ensureDir(path.join(projectDir, 'VirtualPet.xcodeproj'));
  ensureDir(path.join(projectDir, 'VirtualPet.xcodeproj'));
  ensureDir(path.join(projectDir, 'VirtualPetTests'));
  ensureDir(path.join(projectDir, 'VirtualPetUITests'));

  // 生成并写入文件
  const files = [
    {
      path: path.join(projectDir, 'VirtualPet', 'Pet.swift'),
      content: fillTemplate(TEMPLATES.petModel, templateData)
    },
    {
      path: path.join(projectDir, 'VirtualPet', 'ContentView.swift'),
      content: fillTemplate(TEMPLATES.petView, templateData)
    },
    {
      path: path.join(projectDir, 'VirtualPet', `${projectName}App.swift`),
      content: fillTemplate(TEMPLATES.petApp, templateData)
    }
  ];

  // 创建Xcode项目文件（简化版）
  const pbxprojContent = `
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
		/* Begin PBXBuildFile section */
		/* End PBXBuildFile section */
		/* Begin PBXFileReference section */
		{{project_name_camel}}/Info.plist = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		{{project_name_camel}}/Main.storyboard = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.storyboard; path = Main.storyboard; sourceTree = "<group>"; };
		{{project_name_camel}}/ContentView.swift = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		{{project_name_camel}}/{{project_name_camel}}App.swift = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {{project_name_camel}}App.swift; sourceTree = "<group>"; };
		/* End PBXFileReference section */
		/* Begin PBXFrameworksBuildPhase section */
		/* End PBXFrameworksBuildPhase section */
		/* Begin PBXGroup section */
		{{project_name_camel}} = {
			isa = PBXGroup;
			children = (
				{{project_name_camel}}App.swift,
				ContentView.swift,
				Main.storyboard,
				Info.plist,
			);
			path = {{project_name_camel}};
			sourceTree = "<group>";
		};
		/* End PBXGroup section */
		/* Begin PBXNativeTarget section */
		/* End PBXNativeTarget section */
		/* Begin PBXProject section */
		/* End PBXProject section */
	};
	rootObject = 1;
};
  `;

  fs.writeFileSync(path.join(projectDir, 'VirtualPet.xcodeproj', 'project.pbxproj'),
    fillTemplate(pbxprojContent, templateData));

  // 写入所有文件
  files.forEach(file => {
    fs.writeFileSync(file.path, file.content);
    console.log(`✅ 已创建: ${file.path}`);
  });

  console.log('');
  console.log(`🎉 项目创建成功！`);
  console.log(`📍 项目位置: ${projectDir}`);
  console.log(`📱 使用 Xcode 打开: ${path.join(projectDir, 'VirtualPet.xcodeproj')}`);
  console.log('');
  console.log('📝 下一步:');
  console.log('   1. 打开 Xcode');
  console.log('   2. 选择设备运行');
  console.log('   3. 开始与你的宠物互动吧！');
}

// 主函数
function main() {
  try {
    const { command, options } = parseCommandLine();

    switch (command) {
      case 'list':
        listPetTypes();
        break;

      case 'create':
        createXcodeProject(options);
        break;

      default:
        console.error(`❌ 未知命令: ${command}`);
        console.log('使用方法:');
        console.log('  node skill.js list                    # 列出支持的宠物类型');
        console.log('  node skill.js create --project-name MyPet --pet-type dog');
        console.log('');
        console.log('可用选项:');
        console.log('  --project-name    项目名称 (必需)');
        console.log('  --pet-type        宠物类型 (可选: cat, dog, rabbit, hamster, bird)');
        console.log('  --deployment-target iOS部署目标 (默认: 17.0)');
        console.log('  --bundle-id       Bundle ID (默认: com.example.项目名)');
        console.log('  --initial-hunger  初始饥饿度 (默认: 30)');
        console.log('  --initial-happiness 初始快乐度 (默认: 50)');
        console.log('  --initial-health  初始健康度 (默认: 80)');
        console.log('  --initial-energy  初始能量 (默认: 70)');
        process.exit(1);
    }
  } catch (error) {
    console.error(`❌ 错误: ${error.message}`);
    process.exit(1);
  }
}

// 运行主函数
if (require.main === module) {
  main();
}

module.exports = { SKILL_CONFIG, TEMPLATES, listPetTypes, createXcodeProject };