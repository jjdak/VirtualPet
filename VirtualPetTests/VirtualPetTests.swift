import Foundation
import Testing
@testable import VirtualPet

struct VirtualPetTests {
    @Test @MainActor
    func daytimeOpeningHasNoPunitiveStats() {
        let defaults = makeDefaults()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(year: 2026, month: 7, day: 31, hour: 12))!
        let companion = CompanionStore(defaults: defaults, now: date, calendar: calendar)

        #expect(companion.mood == .calm)
        #expect(companion.reaction == .idle)
        #expect(!companion.message.isEmpty)
    }

    @Test @MainActor
    func responseUsesPhoebePersonality() {
        let defaults = makeDefaults()
        let companion = CompanionStore(defaults: defaults)
        let initialReaction = companion.reactionID

        companion.respond()

        #expect(companion.mood == .bright)
        #expect(companion.reaction == .chirp)
        #expect(companion.message.contains("菲比啾比"))
        #expect(companion.reactionID != initialReaction)
    }

    @Test @MainActor
    func repeatedCallsKeepTheChirpActionWhileVaryingTheRoast() {
        let companion = CompanionStore(defaults: makeDefaults())

        companion.respond()
        let firstMessage = companion.message
        companion.respond()
        let secondMessage = companion.message

        #expect(companion.reaction == .chirp)
        #expect(firstMessage != secondMessage)
        #expect(secondMessage.contains("叫我做什么"))
    }

    @Test @MainActor
    func touchRegionChoosesMatchingReaction() {
        let companion = CompanionStore(defaults: makeDefaults())

        companion.touch(.hat)
        #expect(companion.reaction == .hatTouch)

        companion.touch(.head, at: Date().addingTimeInterval(2))
        #expect(companion.reaction == .headPat)

        companion.touch(.body, at: Date().addingTimeInterval(4))
        #expect(companion.reaction == .bodyPoke)
    }

    @Test @MainActor
    func threeQuickTouchesTriggerRapidTapRoast() {
        let companion = CompanionStore(defaults: makeDefaults())
        let start = Date(timeIntervalSince1970: 100)

        companion.touch(.head, at: start)
        companion.touch(.body, at: start.addingTimeInterval(0.2))
        companion.touch(.hat, at: start.addingTimeInterval(0.4))

        #expect(companion.reaction == .rapidTap)
        #expect(companion.message.contains("共鸣税"))
    }

    @Test @MainActor
    func longPressSquashesWithoutCreatingAStat() {
        let companion = CompanionStore(defaults: makeDefaults())

        companion.longPress()

        #expect(companion.reaction == .longPress)
        #expect(companion.message.contains("菲比饼"))
    }

    @Test @MainActor
    func quietModePersistsAndSoftensFeedback() {
        let defaults = makeDefaults()
        let companion = CompanionStore(defaults: defaults)

        companion.isQuietMode = true
        companion.touch(.head)

        #expect(defaults.bool(forKey: "companion.quietMode"))
        #expect(companion.mood == .bright)
        #expect(companion.reaction == .headPat)
        #expect(companion.message == "轻轻的，收到了。")
    }

    @Test
    func motionProfilesExposeStableLive2DParameterContract() {
        let chirp = CompanionReaction.chirp.motionFrame.live2DParameters
        let longPress = CompanionReaction.longPress.motionFrame

        #expect(chirp[CompanionMotionParameter.mouthOpen] == 0.72)
        #expect(chirp[CompanionMotionParameter.hairSwing] == 0.42)
        #expect(chirp[CompanionMotionParameter.eyeLSmile] == 0.50)
        #expect(chirp[CompanionMotionParameter.hairBack] == 0.42)
        #expect(longPress.yScale == 0.76)
        #expect(longPress.mouthOpen == 0.82)
    }

    @Test
    func keyReactionTimingProfilesStayDistinct() {
        let chirp = CompanionReaction.chirp.animationProfile
        let headPat = CompanionReaction.headPat.animationProfile
        let sleepy = CompanionReaction.sleepy.animationProfile

        #expect(chirp.pulseDuration < headPat.pulseDuration)
        #expect(chirp.springResponse < headPat.springResponse)
        #expect(sleepy.springResponse > headPat.springResponse)
        #expect(sleepy.recoveryDuration > chirp.recoveryDuration)
    }

    @Test
    func hitRegionsShareTheSameBoundariesAcrossRenderers() {
        let size = CGSize(width: 200, height: 300)

        #expect(CompanionHitRegion.resolve(at: CGPoint(x: 100, y: 50), in: size) == .hat)
        #expect(CompanionHitRegion.resolve(at: CGPoint(x: 100, y: 140), in: size) == .head)
        #expect(CompanionHitRegion.resolve(at: CGPoint(x: 100, y: 250), in: size) == .body)
    }

    @Test
    func voiceToneMatchesReactionIntensity() {
        #expect(CompanionReaction.rapidTap.voiceTone == .angry)
        #expect(CompanionReaction.longPress.voiceTone == .angry)
        #expect(CompanionReaction.headPat.voiceTone == .soft)
        #expect(CompanionReaction.chirp.voiceTone == .soft)
        #expect(CompanionReaction.hatTouch.voiceTone == .mildlyAngry)
        #expect(CompanionReaction.bodyPoke.voiceTone == .mildlyAngry)
        #expect(CompanionReaction.idle.voiceTone == nil)
        #expect(CompanionReaction.sleepy.voiceTone == nil)
    }

    @Test
    func live2DRendererCannotBeReadyWithoutTheCore() {
        #expect(
            !CompanionLive2DRuntimeStatus.isRenderingBridgeReady
                || CompanionLive2DRuntimeStatus.isCoreLinked
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "VirtualPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
