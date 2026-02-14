import SwiftUI

/// 帮助视图
struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    private let faqs: [FAQ] = [
        FAQ(
            question: "如何快速增加亲密度？",
            answer: "多进行拥抱和夸奖互动可以有效增加亲密度。选择快乐型进化路径也能提升亲密度增长速度。"
        ),
        FAQ(
            question: "宠物生病了怎么办？",
            answer: "当健康值过低时宠物会生病。及时喂食、清洁和休息可以恢复健康。避免饥饿和脏乱状态。"
        ),
        FAQ(
            question: "如何让宠物进化？",
            answer: "通过互动获得经验值，提升等级。达到指定等级后可以选择进化路径，解锁新的进化阶段。"
        ),
        FAQ(
            question: "不同进化路径有什么区别？",
            answer: "平衡型：各项属性平均发展；强力型：健康和能量更高；快乐型：快乐和饥饿优势；健康型：健康值大幅提升；神秘型：随机属性加成。"
        ),
        FAQ(
            question: "如何获得技能点？",
            answer: "每次升级获得技能点，完成特殊成就和随机事件也能获得额外技能点。用于解锁和升级宠物技能。"
        ),
        FAQ(
            question: "特质系统如何工作？",
            answer: "特质是可传承的个性特征。完成特定条件可解锁特质，重生后可以选择传承给下一代宠物。"
        ),
        FAQ(
            question: "天气系统影响什么？",
            answer: "不同天气会影响宠物状态。晴天心情更好，雨天容易生病，雪天能量消耗增加等。注意天气变化调整照顾策略。"
        ),
        FAQ(
            question: "宠物会死亡吗？",
            answer: "会。当健康值降为0或年龄超过寿命限制时宠物会死亡。但可以通过重生系统继续培育下一代。"
        ),
        FAQ(
            question: "如何获得更多经验？",
            answer: "训练互动获得最多经验，其次是学习和运动。保持宠物快乐状态也能提升经验获取效率。"
        ),
        FAQ(
            question: "存档保存在哪里？",
            answer: "当前使用 UserDefaults 保存，未来将支持多存档位和云同步功能。"
        )
    ]

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(faqs) { faq in
                        FAQRow(faq: faq)
                    }
                } header: {
                    Text("常见问题")
                } footer: {
                    Text("长按界面元素可以查看更多帮助信息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("帮助中心")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// FAQ 数据模型
struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

/// FAQ 行视图
struct FAQRow: View {
    let faq: FAQ
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(faq.question)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(faq.answer)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
    }
}

/// 帮助提示覆盖层
struct HelpTooltipView: View {
    let text: String
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            if isPresented {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }

                VStack(spacing: 12) {
                    Text("💡 提示")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(text)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("知道了") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemBackground)
                        .shadow(radius: 20)
                )
                .padding(.horizontal, 40)
            }
        }
    }
}

// iOS 特定的背景颜色
extension Color {
    #if os(iOS)
    static var systemBackground: Color {
        return Color(UIColor.systemBackground)
    }
    #else
    static var systemBackground: Color {
        return Color(NSColor.controlBackgroundColor)
    }
    #endif
}

#Preview {
    HelpView()
}
