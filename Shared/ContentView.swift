import SwiftUI

#if os(watchOS)
import WatchKit
#endif

struct ContentView: View {
    var body: some View {
#if os(watchOS)
        WatchCompanionView()
#else
        CompanionHomeView()
#endif
    }
}

#if !os(watchOS)
private struct CompanionHomeView: View {
    @EnvironmentObject private var companion: CompanionStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            CompanionBackground(phase: companion.phase)

            GeometryReader { proxy in
                let compact = proxy.size.height < 690
                let contentWidth = min(
                    max(proxy.size.width - 36, 300),
                    horizontalSizeClass == .regular ? 530 : 440
                )
                let characterHeight = min(
                    proxy.size.height * (compact ? 0.43 : 0.51),
                    410
                )

                VStack(spacing: compact ? 9 : 14) {
                    header

                    SpeechBubble(
                        message: companion.message,
                        reaction: companion.reaction,
                        phase: companion.phase
                    )

                    CompanionRendererView(
                        reaction: companion.reaction,
                        reactionID: companion.reactionID,
                        phase: companion.phase,
                        onTouch: handleTouch,
                        onLongPress: handleLongPress
                    )
                    .frame(width: characterHeight * 0.82, height: characterHeight)
                    .frame(maxWidth: .infinity)

                    TouchGuide()

                    interactionPanel
                }
                .frame(width: contentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, compact ? 12 : 20)
            }
        }
        .foregroundStyle(CompanionTheme.foreground(for: companion.phase))
        .frame(minWidth: 320, minHeight: 540)
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("菲比")
                    .font(.title2.weight(.bold))
                Text("\(companion.phase.label) · 私人非商业测试")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(CompanionTheme.secondaryForeground(for: companion.phase))
            }

            Spacer()

            Label(
                companion.mood.accessibilityDescription,
                systemImage: companion.mood.symbol
            )
            .labelStyle(.iconOnly)
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(CompanionTheme.gold)
            .padding(10)
            .background(.ultraThinMaterial, in: Circle())
            .accessibilityLabel("心情")
            .accessibilityValue(companion.mood.accessibilityDescription)
        }
    }

    private var interactionPanel: some View {
        HStack(spacing: 10) {
            Button {
                companion.chirp()
                playReactionFeedback(for: companion.reaction)
            } label: {
                Label("啾比", systemImage: "waveform")
                    .frame(minWidth: 72)
            }
            .buttonStyle(CompanionSecondaryButtonStyle(phase: companion.phase))

            Button {
                companion.respond()
                playReactionFeedback(for: companion.reaction)
            } label: {
                Label("叫她一声", systemImage: "sparkles")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CompanionPrimaryButtonStyle())

            Toggle(isOn: $companion.isQuietMode) {
                Image(systemName: companion.isQuietMode ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .frame(width: 26)
            }
            .labelsHidden()
            .toggleStyle(.button)
            .buttonStyle(CompanionSecondaryButtonStyle(phase: companion.phase))
            .accessibilityLabel("安静陪伴")
            .accessibilityValue(companion.isQuietMode ? "已开启" : "已关闭")
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(CompanionTheme.warmWhite.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: CompanionTheme.ink.opacity(0.09), radius: 16, y: 8)
    }

    private func handleTouch(_ region: CompanionHitRegion) {
        companion.touch(region)
        playReactionFeedback(for: companion.reaction)
    }

    private func handleLongPress() {
        companion.longPress()
        playReactionFeedback(for: companion.reaction)
    }

    private func playReactionFeedback(for reaction: CompanionReaction) {
        CompanionFeedback.play(for: reaction)
        if !companion.isQuietMode {
            CompanionAudioPlayer.shared.play(for: reaction)
        }
    }
}
#endif

private struct CompanionBackground: View {
    let phase: DayPhase

    var body: some View {
        ZStack {
            LinearGradient(
                colors: CompanionTheme.background(for: phase),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(CompanionTheme.warmWhite.opacity(phase == .night ? 0.07 : 0.42))
                .frame(width: 380, height: 380)
                .blur(radius: 10)
                .offset(x: -170, y: -280)

            Circle()
                .fill(CompanionTheme.gold.opacity(phase == .night ? 0.08 : 0.15))
                .frame(width: 270, height: 270)
                .blur(radius: 24)
                .offset(x: 190, y: 330)
        }
        .ignoresSafeArea()
    }
}

private struct SpeechBubble: View {
    let message: String
    let reaction: CompanionReaction
    let phase: DayPhase

    var body: some View {
        HStack(spacing: 10) {
            if let symbol = reaction.symbol {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(CompanionTheme.cobalt)
                    .frame(width: 22)
                    .transition(.scale.combined(with: .opacity))
            }

            Text(message)
                .font(.body.weight(.medium))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(CompanionTheme.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CompanionTheme.warmWhite.opacity(0.92), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .bottom) {
            SpeechBubbleTail()
                .fill(CompanionTheme.warmWhite.opacity(0.92))
                .frame(width: 18, height: 10)
                .offset(y: 8)
        }
        .shadow(color: CompanionTheme.ink.opacity(0.08), radius: 12, y: 6)
        .id(message)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .animation(.easeOut(duration: 0.22), value: message)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("菲比说：\(message)")
    }
}

private struct SpeechBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct TouchGuide: View {
    var body: some View {
        HStack(spacing: 14) {
            hint("帽子", icon: "hat.widebrim")
            hint("摸头", icon: "hand.point.up.left.fill")
            hint("戳戳", icon: "hand.tap.fill")
            hint("长按", icon: "arrow.down.to.line")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(CompanionTheme.secondaryInk)
        .accessibilityLabel("可以碰帽子、摸头、戳戳她，或者长按")
    }

    private func hint(_ label: String, icon: String) -> some View {
        Label(label, systemImage: icon)
            .labelStyle(.titleAndIcon)
    }
}

private struct CompanionPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                configuration.isPressed ? CompanionTheme.cobalt.opacity(0.78) : CompanionTheme.cobalt,
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct CompanionSecondaryButtonStyle: ButtonStyle {
    let phase: DayPhase

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(CompanionTheme.foreground(for: phase))
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(
                CompanionTheme.warmWhite.opacity(configuration.isPressed ? 0.64 : 0.82),
                in: Capsule()
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#if os(watchOS)
private struct WatchCompanionView: View {
    @EnvironmentObject private var companion: CompanionStore

    var body: some View {
        let compact = WKInterfaceDevice.current().screenBounds.width < 170

        ZStack {
            CompanionBackground(phase: companion.phase)

            GeometryReader { proxy in
                let characterWidth = min(
                    proxy.size.width * (compact ? 0.44 : 0.44),
                    compact ? 80 : 82
                )
                let characterHeight = min(
                    proxy.size.width * (compact ? 0.50 : 0.46),
                    compact ? 84 : 82
                )

                VStack(spacing: compact ? 1 : 2) {
                    if compact {
                        Text("菲比 · \(companion.phase.label)")
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                            .foregroundStyle(CompanionTheme.secondaryForeground(for: companion.phase))
                    }

                    PhoebeCharacterView(
                        reaction: companion.reaction,
                        reactionID: companion.reactionID,
                        phase: companion.phase,
                        onTouch: handleTouch,
                        onLongPress: handleLongPress
                    )
                    .frame(
                        width: characterWidth,
                        height: characterHeight
                    )

                    if !compact {
                        Text("菲比 · \(companion.phase.label)")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                            .foregroundStyle(CompanionTheme.secondaryForeground(for: companion.phase))
                    }

                    Text(watchMessage)
                        .font(
                            compact
                                ? .system(size: 11, weight: .medium)
                                : .system(size: 12, weight: .medium)
                        )
                        .multilineTextAlignment(.center)
                        .frame(width: max(proxy.size.width - 14, 1))
                        .padding(.horizontal, 4)
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(CompanionTheme.foreground(for: companion.phase))

                    Button {
                        companion.chirp()
                        playReactionFeedback(for: companion.reaction)
                    } label: {
                        Label("啾比", systemImage: "waveform")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    .frame(height: compact ? 34 : 38)
                    .frame(maxWidth: .infinity)
                    .tint(CompanionTheme.cobalt)
                    .font(.caption.weight(.semibold))
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: compact ? .center : .top
                )
                .padding(.horizontal, 7)
                .padding(.top, compact ? 5 : 74)
                .padding(.bottom, compact ? 0 : 4)
                .scaleEffect(compact ? 0.92 : 1)
            }
        }
    }

    private func handleTouch(_ region: CompanionHitRegion) {
        companion.touch(region)
        playReactionFeedback(for: companion.reaction)
    }

    private func handleLongPress() {
        companion.longPress()
        playReactionFeedback(for: companion.reaction)
    }

    private func playReactionFeedback(for reaction: CompanionReaction) {
        CompanionFeedback.play(for: reaction)
        if !companion.isQuietMode {
            CompanionAudioPlayer.shared.play(for: reaction)
        }
    }

    private var watchMessage: String {
        let characters = Array(companion.message)
        guard characters.count > 12 else { return companion.message }

        let splitIndex = (characters.count + 1) / 2
        return String(characters[..<splitIndex])
            + "\n"
            + String(characters[splitIndex...])
    }
}
#endif
