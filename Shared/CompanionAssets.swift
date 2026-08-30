import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum CompanionAssets {
    static let privateArtworkName = "PhoebePrivate"
    static let publicArtworkName = "PhoebePlaceholder"
    static let headPatArtworkName = "PhoebeHeadPatPrivate"
    static let bodyPokeArtworkName = "PhoebeBodyPokePrivate"
    static let chirpArtworkName = "PhoebeChirpPrivate"
    static let live2DModelDirectory = "PhoebeLive2D"
    static let live2DModelFile = "phoebe.model3"
    static let watchAtlasDirectory = "PhoebeWatch"
    static let watchAtlasFile = "phoebe-watch-atlas"

    static var artworkName: String {
        imageExists(privateArtworkName) ? privateArtworkName : publicArtworkName
    }

    static func artworkName(for reaction: CompanionReaction) -> String {
        let preferredName: String
        switch reaction {
        case .headPat, .sleepy:
            preferredName = headPatArtworkName
        case .hatTouch, .bodyPoke, .rapidTap, .longPress:
            preferredName = bodyPokeArtworkName
        case .chirp:
            preferredName = chirpArtworkName
        case .idle:
            preferredName = privateArtworkName
        }

        return imageExists(preferredName) ? preferredName : artworkName
    }

    private static func imageExists(_ name: String) -> Bool {
#if os(macOS)
        NSImage(named: NSImage.Name(name)) != nil
#else
        UIImage(named: name) != nil
#endif
    }

    static func live2DModelURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(
            forResource: live2DModelFile,
            withExtension: "json",
            subdirectory: live2DModelDirectory
        )
    }

    static func watchAtlasURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(
            forResource: watchAtlasFile,
            withExtension: "json",
            subdirectory: watchAtlasDirectory
        )
    }
}
