//
//  WeatherView.swift
//  VirtualPet
//
//  天气系统视图组件
//  显示当前天气、天气效果说明，以及手动切换天气的按钮
//

import SwiftUI

struct WeatherView: View {
    @ObservedObject var pet: Pet

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: pet.currentWeather.icon)
                    .foregroundColor(pet.currentWeather.color)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("天气")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(pet.currentWeather.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(pet.currentWeather.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Button(action: {
                    pet.changeWeather()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(pet.currentWeather.color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(pet.currentWeather.color, lineWidth: 1)
                    )
            )
    }
}
