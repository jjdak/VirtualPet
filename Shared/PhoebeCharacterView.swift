import SwiftUI

struct PhoebeCharacterView: View {
    let reaction: CompanionReaction
    let reactionID: UUID
    let phase: DayPhase
    let onTouch: (CompanionHitRegion) -> Void
    let onLongPress: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false
    @State private var reactionKick = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CompanionTheme.warmWhite.opacity(0.72),
                                CompanionTheme.sky.opacity(0.20),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: proxy.size.width * 0.52
                        )
                    )
                    .scaleEffect(isFloating ? 1.02 : 0.96)

                character

                if let symbol = reaction.symbol {
                    ReactionGlyph(symbol: symbol, reaction: reaction)
#if os(watchOS)
                        .scaleEffect(0.78)
#endif
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
#if os(watchOS)
                        .padding(.top, proxy.size.height * 0.06)
                        .padding(.trailing, proxy.size.width * 0.01)
#else
                        .padding(.top, proxy.size.height * 0.12)
                        .padding(.trailing, proxy.size.width * 0.06)
#endif
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(Rectangle())
            .gesture(touchGesture(in: proxy.size))
        }
        .aspectRatio(0.82, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("菲比")
        .accessibilityValue(reaction.accessibilityDescription)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("轻点不同位置互动，长按会把她压扁")
        .accessibilityAction {
            onTouch(.head)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                isFloating = true
            }
        }
        .onChange(of: reactionID) {
            guard !reduceMotion else { return }
            reactionKick = true
            Task { @MainActor in
                await Task.yield()
                withAnimation(reactionAnimation) {
                    reactionKick = false
                }
            }
        }
        .animation(reactionAnimation, value: reaction)
    }

    private var character: some View {
        Image(CompanionAssets.artworkName(for: reaction))
            .resizable()
            .scaledToFit()
            .id(CompanionAssets.artworkName(for: reaction))
            .transition(.opacity.combined(with: .scale(scale: 0.96)))
            .padding(4)
            .scaleEffect(
                x: reactionKick ? pose.xScale * 0.94 : pose.xScale,
                y: reactionKick ? pose.yScale * 0.94 : pose.yScale
            )
            .scaleEffect(isFloating && !reduceMotion ? 1.012 : 1)
            .rotationEffect(.degrees(pose.rotation))
            .offset(
                x: pose.xOffset,
                y: pose.yOffset + (isFloating && !reduceMotion ? -5 : 4)
            )
            .shadow(
                color: CompanionTheme.ink.opacity(phase == .night ? 0.36 : 0.17),
                radius: 20,
                x: 0,
                y: 16
            )
    }

    private func touchGesture(in size: CGSize) -> some Gesture {
        LongPressGesture(minimumDuration: 0.62, maximumDistance: 26)
            .exclusively(before: SpatialTapGesture())
            .onEnded { value in
                switch value {
                case .first:
                    onLongPress()
                case .second(let tap):
                    onTouch(CompanionHitRegion.resolve(at: tap.location, in: size))
                }
            }
    }

    private var pose: CompanionMotionFrame {
        reaction.motionFrame
    }

    private var reactionAnimation: Animation {
        let profile = reaction.animationProfile
        return .spring(
            response: profile.springResponse,
            dampingFraction: profile.springDamping
        )
    }
}

struct ReactionGlyph: View {
    let symbol: String
    let reaction: CompanionReaction

    var body: some View {
        #if os(watchOS)
        let glyphFont = Font.system(size: 16, weight: .bold, design: .rounded)
        let glyphPadding: CGFloat = 7
        #else
        let glyphFont = Font.system(size: 20, weight: .bold, design: .rounded)
        let glyphPadding: CGFloat = 10
        #endif

        Image(systemName: symbol)
            .font(glyphFont)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .padding(glyphPadding)
            .background(CompanionTheme.warmWhite.opacity(0.92), in: Circle())
            .shadow(color: CompanionTheme.ink.opacity(0.12), radius: 8, y: 4)
            .accessibilityHidden(true)
    }

    private var color: Color {
        switch reaction {
        case .headPat, .chirp:
            CompanionTheme.rose
        case .rapidTap, .bodyPoke:
            CompanionTheme.gold
        default:
            CompanionTheme.cobalt
        }
    }
}
