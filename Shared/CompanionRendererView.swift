import SwiftUI

#if canImport(PhoebeLive2DRuntime) && !os(watchOS)
import PhoebeLive2DRuntime
#endif

#if !os(watchOS)
struct CompanionRendererView: View {
    let reaction: CompanionReaction
    let reactionID: UUID
    let phase: DayPhase
    let onTouch: (CompanionHitRegion) -> Void
    let onLongPress: () -> Void

    var body: some View {
        // Keep the proven SpriteKit renderer until the private module can load
        // a real model. This seam prevents a half-integrated blank Metal view.
        CompanionSpriteView(
            reaction: reaction,
            reactionID: reactionID,
            phase: phase,
            onTouch: onTouch,
            onLongPress: onLongPress
        )
    }
}

enum CompanionLive2DRuntimeStatus {
    static var isCoreLinked: Bool {
#if canImport(PhoebeLive2DRuntime)
        PLDCubismCoreVersion() > 0
#else
        false
#endif
    }

    static var isRenderingBridgeReady: Bool {
#if canImport(PhoebeLive2DRuntime)
        PLDRenderingBridgeReady()
#else
        false
#endif
    }

    static var isModel3Loadable: Bool {
#if canImport(PhoebeLive2DRuntime)
        guard let modelURL = CompanionAssets.live2DModelURL() else {
            return false
        }
        var result = PLDModel3ProbeResult()
        return modelURL.path.withCString {
            PLDProbeModel3File($0, &result)
        }
#else
        false
#endif
    }
}
#endif
