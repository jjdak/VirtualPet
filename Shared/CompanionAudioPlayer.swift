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
#if os(iOS)
    private var audioSessionPrepared = false
#endif

    private init() {}

    @discardableResult
    func play(for reaction: CompanionReaction, in bundle: Bundle = .main) -> Bool {
        guard let tone = reaction.voiceTone else { return false }

#if os(iOS)
        // Configure the session once so a real iPhone has an active output
        // route. `.ambient` keeps the companion respectful of the system
        // silent switch, while `.mixWithOthers` avoids interrupting music or
        // a podcast. Quiet mode is still enforced by the caller before this
        // method is reached.
        if !audioSessionPrepared {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
                try session.setActive(true)
                audioSessionPrepared = true
            } catch {
                // Keep trying the player below. Some simulator, Bluetooth,
                // or interrupted-session states reject activation while an
                // AVAudioPlayer route is still usable.
            }
        }
#endif

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
