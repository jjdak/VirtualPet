# VirtualPet Live2D contract

Read the current project files before acting because paths and deployment targets may evolve. The authoritative project documents are `docs/LIVE2D_PIPELINE.md`, `docs/DEPENDENCIES.md`, and `docs/live2d/phoebe-layer-manifest.json`.

## Private and public boundaries

Keep these classes of files private and ignored:

- Source character art, layered PSD, and editable `.cmo3`
- Cubism SDK/Core and generated XCFrameworks
- Extracted voice clips and source videos
- Runtime model exports and watchOS motion atlases derived from private art

Keep scripts, manifests, dependency records, bridge source, tests, and reproducible build instructions in the repository.

## Current private paths

```text
PrivateAssets/Live2D/
PrivateAssets/SDK/CubismSdkForNative-5-r.5/
PrivateAssets/Live2D/Exports/PhoebeLive2D/
SharedAssets/PrivateMotionAtlases/PhoebeWatch/
```

## Runtime parameter IDs

The following is the `production-v1` contract. It does not block the `rig-lite-runtime` milestone, which proves model loading, texture display, one visible eye/mouth/breath parameter change, and the missing-model SpriteKit fallback. Do not add an unbound parameter only to make the production contract pass.

The shared reaction state ultimately expects:

```text
ParamAngleX
ParamAngleY
ParamAngleZ
ParamBodyAngleX
ParamEyeSmile
ParamMouthOpenY
ParamBreath
ParamHairSwing
ParamHatSwing
```

Standard reactions:

```text
idle
hatTouch
headPat
bodyPoke
rapidTap
longPress
chirp
sleepy
```

Do not rename IDs in the model without updating the Swift runtime contract and tests in the same change.

## Platform split

- iOS and macOS current release: SpriteKit key poses and lightweight transforms.
- iOS and macOS conditional future: Cubism Native R5 + Core + Metal renderer only after the human keyform proof changes a Drawable vertex hash.
- watchOS: no Cubism Core; use SwiftUI key poses and add transparent motion atlases only when they materially improve the experience.
- Public checkout without private Core/model files: remain buildable through the same SpriteKit/SwiftUI mainline.

While the continuation card marks Live2D paused, do not install Cubism automation dependencies, inspect the Editor UI, or continue the Metal host.

## Current quality gates

- No visible seams at rest.
- Eye closing does not distort the face outline.
- Head turns preserve chin length.
- Hat, hair, and cape move with distinct phase delays.
- Touch reactions show first feedback within 300 ms.
- Reduce Motion disables looping float and shortens transitions.
- Editable `.cmo3`, source PSD, textures, physics, motions, and runtime exports remain recoverable.
