//
//  ContentViewOverlays.swift
//  VirtualPet
//
//  主视图的覆盖层组件
//  包含：错误提示、亲密度动画、随机事件动画
//

import SwiftUI

struct ContentViewOverlays: View {
    @Binding var errorMessage: String?
    @Binding var showingError: Bool
    @Binding var intimacyHeartPulse: Bool

    var body: some View {
        ZStack {
            // 错误提示
            if let error = errorMessage, showingError {
                ErrorAlert(
                    errorMessage: error,
                    isPresented: $showingError
                )
                    .zIndex(2)
            }

            // 亲密度心跳动画
            if intimacyHeartPulse {
                IntimacyHeartAnimation()
                    .zIndex(1)
            }

            // 随机事件动画（如果需要）
            // RandomEventAnimationView(pet: pet)
        }
    }
}

struct ErrorAlert: View {
    let errorMessage: String
    @Binding var isPresented: Binding<Bool>

    var body: some View {
        VStack(spacing: 16) {
            Text("⚠️")
                .font(.largeTitle)
            Text(errorMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            Button("确定") {
                isPresented.wrappedValue = false
            }
            .buttonStyle(.bordered)
            .buttonControlSize(.large)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .frame(maxWidth: 300)
    }
}

struct IntimacyHeartAnimation: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var body: some View {
        Image(systemName: "heart.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 60)
            .foregroundColor(.pink)
            .scaleEffect(scale)
            .opacity(opacity)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: scale)
            .onAppear {
                scale = 1.2
                opacity = 1.0
            }
    }
}
