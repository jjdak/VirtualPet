import SwiftUI

/// 新手引导视图
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "欢迎来到虚拟宠物世界",
            description: "在这里，你将体验照顾电子宠物的乐趣。看着它从一颗蛋开始，慢慢成长进化。",
            iconName: "heart.fill",
            color: .pink
        ),
        OnboardingPage(
            title: "照顾你的宠物",
            description: "通过喂食、玩耍、清洁等互动保持宠物的状态。注意观察饥饿、快乐、健康和能量值！",
            iconName: "hand.wave.fill",
            color: .blue
        ),
        OnboardingPage(
            title: "见证进化奇迹",
            description: "随着等级提升，你的宠物将经历7个进化阶段，最终成为传说中的存在！",
            iconName: "sparkles",
            color: .purple
        ),
        OnboardingPage(
            title: "个性化培养",
            description: "选择不同的进化路径，培养独特性格的宠物。解锁技能和特质，打造专属伙伴！",
            iconName: "star.fill",
            color: .orange
        ),
        OnboardingPage(
            title: "开始你的旅程",
            description: "准备好迎接你的新伙伴了吗？点击下方按钮，开始你的虚拟宠物养成之旅！",
            iconName: "figure.walk",
            color: .green
        )
    ]

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [
                    pages[currentPage].color.opacity(0.3),
                    pages[currentPage].color.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 跳过按钮
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("跳过") {
                            completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                        .padding()
                    }
                }

                // 页面内容
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                #endif

                // 下一步/完成按钮
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        completeOnboarding()
                    }
                }) {
                    Text(currentPage < pages.count - 1 ? "下一步" : "开始体验")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(pages[currentPage].color)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 50)
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation {
            isPresented = false
        }
    }
}

/// 新手引导页面数据
struct OnboardingPage {
    let title: String
    let description: String
    let iconName: String
    let color: Color
}

/// 新手引导单页视图
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // 图标
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 150, height: 150)

                Image(systemName: page.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(page.color)
            }

            // 文本内容
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .lineLimit(nil)
            }

            Spacer()
            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
