import CoreGraphics
import Foundation

struct CompanionMotionFrame: Equatable {
    var xScale = 1.0
    var yScale = 1.0
    var rotation = 0.0
    var xOffset = 0.0
    var yOffset = 0.0
    var eyeSmile = 0.0
    var mouthOpen = 0.0
    var breath = 0.55
    var hairSwing = 0.0
    var hatSwing = 0.0
    var transitionDuration = 0.28

    var live2DParameters: [String: Double] {
        var parameters = [
            CompanionMotionParameter.angleX: max(-30, min(30, xOffset * 0.8)),
            CompanionMotionParameter.angleY: max(-30, min(30, -yOffset * 0.35)),
            CompanionMotionParameter.angleZ: rotation,
            CompanionMotionParameter.bodyAngleX: rotation * 0.55,
            CompanionMotionParameter.eyeSmile: eyeSmile,
            CompanionMotionParameter.mouthOpen: mouthOpen,
            CompanionMotionParameter.breath: breath,
            CompanionMotionParameter.hairSwing: hairSwing,
            CompanionMotionParameter.hatSwing: hatSwing
        ]

        // The lightweight export keeps separate eye-smile and hair-swing
        // controls. Keep the logical contract above while also exposing the
        // raw IDs that a Cubism host can apply without bespoke model logic.
        parameters[CompanionMotionParameter.eyeLSmile] = eyeSmile
        parameters[CompanionMotionParameter.eyeRSmile] = eyeSmile
        parameters[CompanionMotionParameter.hairFront] = hairSwing
        parameters[CompanionMotionParameter.hairSide] = hairSwing
        parameters[CompanionMotionParameter.hairBack] = hairSwing
        return parameters
    }
}

struct CompanionAnimationProfile: Equatable {
    var pulseX = 1.0
    var pulseY = 1.0
    var pulseRotation = 0.0
    var pulseDuration = 0.0
    var recoveryDuration = 0.22
    var springResponse = 0.34
    var springDamping = 0.66
}

enum CompanionMotionParameter {
    static let angleX = "ParamAngleX"
    static let angleY = "ParamAngleY"
    static let angleZ = "ParamAngleZ"
    static let bodyAngleX = "ParamBodyAngleX"
    static let eyeSmile = "ParamEyeSmile"
    static let eyeLSmile = "ParamEyeLSmile"
    static let eyeRSmile = "ParamEyeRSmile"
    static let mouthOpen = "ParamMouthOpenY"
    static let breath = "ParamBreath"
    static let hairSwing = "ParamHairSwing"
    static let hairFront = "ParamHairFront"
    static let hairSide = "ParamHairSide"
    static let hairBack = "ParamHairBack"
    static let hatSwing = "ParamHatSwing"
}

extension CompanionReaction {
    var animationProfile: CompanionAnimationProfile {
        switch self {
        case .chirp:
            CompanionAnimationProfile(
                pulseX: 1.035,
                pulseY: 1.05,
                pulseRotation: -0.8,
                pulseDuration: 0.11,
                recoveryDuration: 0.16,
                springResponse: 0.22,
                springDamping: 0.58
            )
        case .headPat:
            CompanionAnimationProfile(
                pulseX: 0.985,
                pulseY: 1.018,
                pulseRotation: 0.45,
                pulseDuration: 0.12,
                recoveryDuration: 0.20,
                springResponse: 0.28,
                springDamping: 0.72
            )
        case .sleepy:
            CompanionAnimationProfile(
                recoveryDuration: 0.70,
                springResponse: 0.54,
                springDamping: 0.88
            )
        default:
            CompanionAnimationProfile()
        }
    }

    var motionFrame: CompanionMotionFrame {
        switch self {
        case .idle:
            CompanionMotionFrame()
        case .hatTouch:
            CompanionMotionFrame(
                xScale: 0.99,
                yScale: 0.99,
                rotation: 3,
                xOffset: 3,
                yOffset: 2,
                hairSwing: 0.32,
                hatSwing: 1
            )
        case .headPat:
            CompanionMotionFrame(
                xScale: 1.04,
                yScale: 0.96,
                rotation: -1,
                yOffset: 7,
                eyeSmile: 0.72,
                hairSwing: 0.18
            )
        case .bodyPoke:
            CompanionMotionFrame(
                xScale: 0.98,
                yScale: 1.01,
                rotation: -5,
                xOffset: -10,
                mouthOpen: 0.25,
                hairSwing: -0.52,
                hatSwing: -0.22,
                transitionDuration: 0.22
            )
        case .rapidTap:
            CompanionMotionFrame(
                xScale: 1.04,
                yScale: 0.96,
                rotation: 6,
                xOffset: 8,
                yOffset: 3,
                mouthOpen: 0.62,
                hairSwing: 0.88,
                hatSwing: 0.64,
                transitionDuration: 0.16
            )
        case .longPress:
            CompanionMotionFrame(
                xScale: 1.12,
                yScale: 0.76,
                yOffset: 30,
                eyeSmile: 0.18,
                mouthOpen: 0.82,
                hairSwing: 0.12,
                hatSwing: 0.20,
                transitionDuration: 0.20
            )
        case .chirp:
            CompanionMotionFrame(
                xScale: 1.06,
                yScale: 1.06,
                rotation: -2,
                yOffset: -18,
                eyeSmile: 0.50,
                mouthOpen: 0.72,
                hairSwing: 0.42,
                hatSwing: 0.26,
                transitionDuration: 0.24
            )
        case .sleepy:
            CompanionMotionFrame(
                xScale: 0.97,
                yScale: 0.95,
                rotation: 2,
                yOffset: 10,
                eyeSmile: 0.82,
                breath: 0.30,
                hairSwing: 0.08,
                transitionDuration: 0.58
            )
        }
    }
}

extension CompanionHitRegion {
    static func resolve(at point: CGPoint, in size: CGSize) -> CompanionHitRegion {
        let verticalPosition = point.y / max(size.height, 1)
        if verticalPosition < 0.34 {
            return .hat
        }
        if verticalPosition < 0.63 {
            return .head
        }
        return .body
    }
}
