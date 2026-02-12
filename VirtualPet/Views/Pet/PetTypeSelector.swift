//
//  PetTypeSelector.swift
//  VirtualPet
//
//  宠物类型选择器组件
//  用户可以切换不同的宠物类型（猫、狗、兔子、仓鼠、鸟）
//

import SwiftUI

struct PetTypeSelector: View {
    @ObservedObject var pet: Pet

    var body: some View {
        Picker("", selection: $pet.petType) {
            ForEach(PetType.allCases) { type in
                Text(type.rawValue).tag(type)
            }
            .pickerStyle(.segmented)
    }
}