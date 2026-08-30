import SpriteKit
import SwiftUI

#if os(macOS)
import AppKit
#endif

#if !os(watchOS)
struct CompanionSpriteView: View {
    let reaction: CompanionReaction
    let reactionID: UUID
    let phase: DayPhase
    let onTouch: (CompanionHitRegion) -> Void
    let onLongPress: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene = CompanionSpriteScene()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                CompanionTheme.warmWhite.opacity(0.62),
                                CompanionTheme.sky.opacity(0.16),
                                .clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: proxy.size.width * 0.52
                        )
                    )

                SpriteView(scene: scene, options: [.allowsTransparency])
                    .background(.clear)

                if let symbol = reaction.symbol {
                    ReactionGlyph(symbol: symbol, reaction: reaction)
                        .scaleEffect(0.78)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, proxy.size.height * 0.08)
                }
            }
            .contentShape(Rectangle())
            .gesture(touchGesture(in: proxy.size))
            .onAppear {
                scene.configure(
                    size: proxy.size,
                    imageName: CompanionAssets.artworkName(for: reaction),
                    reduceMotion: reduceMotion
                )
                scene.apply(reaction, reactionID: reactionID)
            }
            .onChange(of: proxy.size) { _, newSize in
                scene.resize(to: newSize)
            }
            .onChange(of: reactionID) {
                scene.setArtwork(
                    imageName: CompanionAssets.artworkName(for: reaction),
                    animated: true
                )
                scene.apply(reaction, reactionID: reactionID)
            }
            .onChange(of: reduceMotion) { _, newValue in
                scene.setReduceMotion(newValue)
            }
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
}

@MainActor
private final class CompanionSpriteScene: SKScene {
    private let motionNode = SKNode()
    private let artworkNode = SKSpriteNode()
    private var artworkSize = CGSize.zero
    private var fittedArtworkScale: CGFloat = 1
    private var reduceMotion = false
    private var configuredImageName: String?
    private var appliedReactionID: UUID?

    override init() {
        super.init(size: CGSize(width: 160, height: 196))
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(motionNode)
        motionNode.addChild(artworkNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(size: CGSize, imageName: String, reduceMotion: Bool) {
        self.reduceMotion = reduceMotion
        resize(to: size)

        setArtwork(imageName: imageName, animated: false)
        updateIdleMotion()
    }

    func setArtwork(imageName: String, animated: Bool) {
        guard configuredImageName != imageName else { return }

        let texture: SKTexture
#if os(macOS)
        // Asset-catalog names resolve reliably through NSImage on macOS.
        // Constructing the SpriteKit texture from that image avoids the
        // imageNamed cache path returning a zero-sized texture in a freshly
        // launched unsigned preview bundle.
        if let image = NSImage(named: NSImage.Name(imageName)) {
            texture = SKTexture(image: image)
        } else {
            texture = SKTexture(imageNamed: imageName)
        }
#else
        texture = SKTexture(imageNamed: imageName)
#endif
        artworkNode.texture = texture
        artworkNode.size = texture.size()
        artworkSize = texture.size()
        configuredImageName = imageName
        fitArtwork()
        updateIdleMotion()

        artworkNode.removeAction(forKey: "artwork-transition")
        guard animated, !reduceMotion else {
            artworkNode.alpha = 1
            return
        }
        artworkNode.alpha = 0.18
        let reveal = SKAction.fadeAlpha(to: 1, duration: 0.12)
        reveal.timingMode = .easeOut
        artworkNode.run(reveal, withKey: "artwork-transition")
    }

    func resize(to newSize: CGSize) {
        guard newSize.width > 0, newSize.height > 0 else { return }
        size = newSize
        fitArtwork()
        updateIdleMotion()
    }

    func setReduceMotion(_ value: Bool) {
        reduceMotion = value
        updateIdleMotion()
    }

    func apply(_ reaction: CompanionReaction, reactionID: UUID) {
        guard appliedReactionID != reactionID else { return }
        appliedReactionID = reactionID
        motionNode.removeAction(forKey: "reaction")

        let frame = reaction.motionFrame
        let profile = reaction.animationProfile
        let duration = reduceMotion ? 0 : frame.transitionDuration
        let target = [
            SKAction.scaleX(to: frame.xScale, duration: duration),
            SKAction.scaleY(to: frame.yScale, duration: duration),
            SKAction.rotate(
                toAngle: frame.rotation * .pi / 180,
                duration: duration,
                shortestUnitArc: true
            ),
            SKAction.move(
                to: CGPoint(x: frame.xOffset, y: -frame.yOffset),
                duration: duration
            )
        ]
        target.forEach { $0.timingMode = .easeOut }

        var sequence: [SKAction] = [.group(target)]
        if !reduceMotion, profile.pulseDuration > 0 {
            let pulseDuration = profile.pulseDuration
            let pulse = [
                SKAction.scaleX(to: frame.xScale * profile.pulseX, duration: pulseDuration),
                SKAction.scaleY(to: frame.yScale * profile.pulseY, duration: pulseDuration),
                SKAction.rotate(
                    toAngle: (frame.rotation + profile.pulseRotation) * .pi / 180,
                    duration: pulseDuration,
                    shortestUnitArc: true
                )
            ]
            pulse.forEach { $0.timingMode = .easeInEaseOut }

            let recoveryDuration = profile.recoveryDuration
            let recovery = [
                SKAction.scaleX(to: frame.xScale, duration: recoveryDuration),
                SKAction.scaleY(to: frame.yScale, duration: recoveryDuration),
                SKAction.rotate(
                    toAngle: frame.rotation * .pi / 180,
                    duration: recoveryDuration,
                    shortestUnitArc: true
                )
            ]
            recovery.forEach { $0.timingMode = .easeInEaseOut }
            sequence.append(.group(pulse))
            sequence.append(.group(recovery))
        }

        motionNode.run(.sequence(sequence), withKey: "reaction")
    }

    private func fitArtwork() {
        guard artworkSize.width > 0, artworkSize.height > 0 else { return }
        let availableWidth = size.width * 0.90
        let availableHeight = size.height * 0.92
        let scale = min(
            availableWidth / artworkSize.width,
            availableHeight / artworkSize.height
        )
        fittedArtworkScale = scale * 1.10
        artworkNode.setScale(fittedArtworkScale)
    }

    private func updateIdleMotion() {
        artworkNode.removeAction(forKey: "idle-breathe")
        artworkNode.setScale(fittedArtworkScale)
        artworkNode.position = .zero
        artworkNode.zRotation = 0
        guard !reduceMotion else { return }

        // Keep the idle loop readable as breathing rather than a uniform
        // transform: a tiny inhale, settle, and exhale gives the character
        // life without changing her silhouette or fighting reaction motion.
        let inhale = SKAction.group([
            SKAction.scale(to: fittedArtworkScale * 1.012, duration: 1.55),
            SKAction.move(to: CGPoint(x: 0, y: 2.6), duration: 1.55),
            SKAction.rotate(toAngle: 0.45 * .pi / 180, duration: 1.55)
        ])
        inhale.timingMode = .easeInEaseOut

        let exhale = SKAction.group([
            SKAction.scale(to: fittedArtworkScale * 0.998, duration: 1.75),
            SKAction.move(to: CGPoint(x: 0, y: -1.1), duration: 1.75),
            SKAction.rotate(toAngle: -0.30 * .pi / 180, duration: 1.75)
        ])
        exhale.timingMode = .easeInEaseOut

        let settle = SKAction.group([
            SKAction.scale(to: fittedArtworkScale, duration: 0.65),
            SKAction.move(to: .zero, duration: 0.65),
            SKAction.rotate(toAngle: 0, duration: 0.65)
        ])
        settle.timingMode = .easeInEaseOut

        artworkNode.run(
            .repeatForever(.sequence([inhale, exhale, settle])),
            withKey: "idle-breathe"
        )
    }
}
#endif
