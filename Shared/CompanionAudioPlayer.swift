import AVFoundation

enum CompanionVoiceTone: String, CaseIterable {
    case angry
    case soft
    case mildlyAngry

    var resourceName: String {
        switch self {
        case .angry: "phoebe-chirubi-angry-private"
        case .soft: "phoebe-chirubi-soft-private"
        case .mildlyAngry: "phoebe-chirubi-mildly-angry-private"
        }
    }
}

extension CompanionReaction {
    var voiceTone: CompanionVoiceTone? {
        switch self {
        case .rapidTap, .longPress:
            .angry
        case .headPat, .chirp:
            .soft
        case .hatTouch, .bodyPoke:
            .mildlyAngry
        case .idle, .sleepy:
            nil
        }
    }
}

@MainActor
final class CompanionAudioPlayer {
    static let shared = CompanionAudioPlayer()

    private var player: AVAudioPlayer?

    private init() {}

    @discardableResult
    func play(for reaction: CompanionReaction, in bundle: Bundle = .main) -> Bool {
        guard let tone = reaction.voiceTone else { return false }

        let supportedExtensions = ["m4a", "caf", "wav"]
        guard let url = supportedExtensions.lazy.compactMap({
            bundle.url(forResource: tone.resourceName, withExtension: $0)
                ?? bundle.url(
                    forResource: tone.resourceName,
                    withExtension: $0,
                    subdirectory: "PrivateAudio"
                )
        }).first else { return false }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            self.player = player
            return player.play()
        } catch {
            return false
        }
    }
}
