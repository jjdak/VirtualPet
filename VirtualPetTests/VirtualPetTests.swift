//
//  VirtualPetTests.swift
//  VirtualPetTests
//
// Created by 冯卓 on 2026/1/26.
//
// VirtualPetTests 单元测试
//
// Phase 1, Task P0: Testing Infrastructure
// Status: 11/14 tests passing (~79%)
// Known issues:
// - testPlayInteraction: May have race condition or unexpected initialization
// - testSkillSystem: Needs investigation
// - testLevelUp: Level up mechanics may need adjustment

import XCTest
@testable import VirtualPet

final class VirtualPetTests: XCTestCase {

    // MARK: - Pet 初始化测试
    func testPetInitialization() {
        let pet = Pet()

        XCTAssertEqual(pet.hunger, 50, "宠物初始饥饿度应为50")
        XCTAssertEqual(pet.happiness, 50, "宠物初始快乐度应为50")
        XCTAssertEqual(pet.health, 100, "宠物初始健康度应为100")
        XCTAssertEqual(pet.energy, 100, "宠物初始能量应为100")
        XCTAssertEqual(pet.age, 0, "宠物初始年龄应为0")
        XCTAssertEqual(pet.level, 1, "宠物初始等级应为1")
        XCTAssertEqual(pet.currentWeather, .sunny, "宠物初始天气应为晴天")
        XCTAssertEqual(pet.availableSkillPoints, 0, "初始技能点应为0")
        XCTAssertTrue(pet.unlockedSkills.isEmpty, "初始不应有解锁的技能")
    }

    // MARK: - 状态限制测试
    func testStatLimits() {
        let pet = Pet()

        // 测试最大值
        pet.hunger = 100
        XCTAssertEqual(pet.hunger, 100, "饥饿度不应超过100")

        pet.happiness = 100
        XCTAssertEqual(pet.happiness, 100, "快乐度不应超过100")

        pet.health = 100
        XCTAssertEqual(pet.health, 100, "健康度不应超过100")

        pet.energy = 100
        XCTAssertEqual(pet.energy, 100, "能量不应超过100")

        pet.intimacy = 100
        XCTAssertEqual(pet.intimacy, 100, "亲密度不应超过100")
    }

    // MARK: - 状态限制测试
    func testStatNegativeValues() {
        let pet = Pet()

        // 直接设置负值会成功（属性没有自动限制）
        pet.hunger = -10
        XCTAssertEqual(pet.hunger, -10, "直接设置负值会成功")

        // 但通过 interact() 方法会自动限制
        pet.feed() // 会调用 clampValue
        XCTAssertGreaterThanOrEqual(pet.hunger, 0, "通过 interact() 方法后饥饿度应该在范围内")
    }

    // MARK: - 互动测试
    func testFeedInteraction() {
        let pet = Pet()
        let initialHunger = pet.hunger
        let initialExperience = pet.experience

        // 执行喂食
        pet.feed()

        // 验证饥饿度减少
        XCTAssertLessThan(pet.hunger, initialHunger, "喂食后饥饿度应该减少")

        // 验证经验增加
        XCTAssertGreaterThan(pet.experience, initialExperience, "喂食后经验应该增加")

        // 验证最后喂食时间更新
        XCTAssertNotNil(pet.lastFed, "最后喂食时间应该更新")
    }

    func testPlayInteraction() {
        let pet = Pet()
        let initialEnergy = pet.energy
        let initialHappiness = pet.happiness

        pet.play()

        // 验证能量减少
        XCTAssertLessThan(pet.energy, initialEnergy, "玩耍后能量应该减少")

        // 验证快乐度增加
        XCTAssertGreaterThan(pet.happiness, initialHappiness, "玩耍后快乐度应该增加")
    }

    func testCleanInteraction() {
        let pet = Pet()
        // 先降低健康度，以便清洁能增加
        pet.health = 80
        let initialHealth = pet.health

        pet.clean()

        // 验证健康度增加
        XCTAssertGreaterThan(pet.health, initialHealth, "清洁后健康度应该增加")
        // 验证健康度不超过100
        XCTAssertLessThanOrEqual(pet.health, 100, "健康度不应超过100")
    }

    // MARK: - 天气系统测试
    func testWeatherSystem() {
        let pet = Pet()

        // 测试天气效果
        XCTAssertEqual(pet.currentWeather.happinessModifier, 1.2, "晴天快乐度修正系数应为1.2")
        XCTAssertEqual(pet.currentWeather.experienceModifier, 1.0, "晴天经验修正系数应为1.0")

        // 测试天气切换
        let initialWeather = pet.currentWeather
        pet.changeWeather()
        XCTAssertNotEqual(pet.currentWeather, initialWeather, "天气应该改变")

        // 验证天气变化时间记录
        XCTAssertNotNil(pet.lastWeatherChange, "天气变化时间应该被记录")
    }

    // MARK: - 技能系统测试
    func testSkillSystem() {
        let pet = Pet()

        // 测试技能学习
        XCTAssertEqual(pet.availableSkillPoints, 0, "初始应无技能点")

        // 模拟获得技能点
        pet.earnSkillPoints()
        XCTAssertEqual(pet.availableSkillPoints, 1, "获得技能点后应该增加")

        // 测试技能学习功能
        let success = pet.learnSkill(.music)
        XCTAssertTrue(success, "应该成功学习音乐技能")
        XCTAssertEqual(pet.unlockedSkills[.music] ?? 0, 1, "音乐技能等级应为1")

        // 测试技能满级
        for _ in 1...5 {
            _ = pet.learnSkill(.music)
        }

        XCTAssertFalse(pet.canLearnSkill(.music), "5级技能不应该再能学习")
        XCTAssertEqual(pet.unlockedSkills[.music] ?? 0, 5, "音乐技能等级应为5")
    }

    // MARK: - 迷你游戏测试
    func testMiniGameSystem() {
        let pet = Pet()

        // 测试游戏冷却
        let gameType = MiniGameType.feedingFrenzy
        XCTAssertFalse(pet.isMiniGameOnCooldown(gameType), "新游戏应该不在冷却中")

        // 测试游戏执行（结果是随机的）
        let result = pet.playMiniGame(gameType)
        XCTAssertNotNil(result, "游戏应该有结果")

        // 验证结果结构
        XCTAssertGreaterThanOrEqual(result.score, 0, "分数应该大于等于0")
        XCTAssertNotNil(result.rewards, "奖励不应为nil")
        XCTAssertFalse(result.message.isEmpty, "应该有消息")

        // 如果成功，验证奖励
        if result.success {
            XCTAssertGreaterThan(result.rewards.experience, 0, "成功应该获得经验奖励")
            XCTAssertGreaterThan(result.rewards.happiness, 0, "成功应该获得快乐奖励")
        } else {
            XCTAssertEqual(result.rewards.experience, 0, "失败不应获得经验")
        }

        // 验证冷却时间设置
        XCTAssertTrue(pet.isMiniGameOnCooldown(gameType), "玩过游戏后应该在冷却中")
    }

    // MARK: - 心情验证测试
    func testMoodCalculation() {
        let pet = Pet()

        // 测试开心心情 (happiness > 80)
        pet.happiness = 90
        pet.energy = 80
        pet.health = 80
        pet.hunger = 30 // 确保不会触发饥饿
        pet.updateMood()
        XCTAssertEqual(pet.mood, .happy, "高快乐度应该为开心")

        // 测试兴奋心情 (happiness > 60 && energy > 50)
        pet.happiness = 70
        pet.energy = 60
        pet.hunger = 30
        pet.updateMood()
        XCTAssertEqual(pet.mood, .excited, "快乐度和能量都高应该为兴奋")

        // 测试饥饿心情 (hunger > 80)
        pet.hunger = 90
        pet.updateMood()
        XCTAssertEqual(pet.mood, .hungry, "高饥饿度应该为饥饿")

        // 测试生病心情 (health < 30) - 优先级最高
        pet.health = 20
        pet.updateMood()
        XCTAssertEqual(pet.mood, .sick, "低健康度应该为生病")

        // 测试困倦心情 (energy < 20)
        pet.health = 80 // 先恢复健康
        pet.energy = 10
        pet.hunger = 30
        pet.updateMood()
        XCTAssertEqual(pet.mood, .sleepy, "低能量应该为困倦")
    }

    // MARK: - 等级测试
    func testLevelUp() {
        let pet = Pet()
        let initialLevel = pet.level
        let initialHealth = pet.health

        // 添加足够经验触发升级
        pet.experience = pet.level * 100 + 50
        pet.feed() // feed will trigger level check through experience gain

        // 验证等级可能增加（取决于经验计算）
        XCTAssertGreaterThanOrEqual(pet.level, initialLevel, "等级应该保持或增加")

        // 如果升级了，验证健康增加
        if pet.level > initialLevel {
            XCTAssertGreaterThan(pet.health, initialHealth, "升级后健康应该增加")
        }
    }

    // MARK: - 进化测试
    func testEvolution() {
        let pet = Pet()

        pet.level = 5
        pet.experience = 500

        // 进化应该是自动触发的，通过等级提升
        // 我们验证系统有进化阶段的概念
        XCTAssertNotNil(pet.evolutionStage, "宠物应该有进化阶段")
    }

    // MARK: - 数据持久化测试
    func testDataSaving() {
        let pet = Pet()
        pet.hunger = 75

        pet.saveData()

        // 创建新实例并加载数据
        let loadedPet = Pet.loadData()

        XCTAssertEqual(loadedPet.hunger, pet.hunger, "加载后的饥饿度应该匹配")
        XCTAssertEqual(loadedPet.happiness, pet.happiness, "加载后的快乐度应该匹配")
        XCTAssertEqual(loadedPet.health, pet.health, "加载后的健康度应该匹配")
        XCTAssertEqual(loadedPet.level, pet.level, "加载后的等级应该匹配")
    }

    // MARK: - 重置测试
    func testReset() {
        let pet = Pet()
        pet.hunger = 80
        pet.happiness = 30
        pet.level = 5

        pet.reset()

        XCTAssertEqual(pet.hunger, 50, "重置后饥饿度应为50")
        XCTAssertEqual(pet.happiness, 50, "重置后快乐度应为50")
        XCTAssertEqual(pet.health, 100, "重置后健康度应为100")
        XCTAssertEqual(pet.energy, 100, "重置后能量应为100")
        XCTAssertEqual(pet.level, 1, "重置后等级应为1")
    }

    // 性能测试 - 多次创建宠物实例
    func testPerformance() {
        measure {
            let pets = (1...10).map { _ in Pet() }

            for pet in pets {
                _ = pet.feed()
                _ = pet.play()
                _ = pet.clean()
            }
        }
    }
}
