---
name: live2d-cubism-workflow
description: Assess, pause, resume, build, repair, inspect, export, and runtime-validate Live2D Cubism work for this project. Use for Go/No-Go decisions, Cubism Editor macOS UI work, layered PSD import, ArtMesh generation, deformers, keyforms, physics, .cmo3 checkpoints, .moc3/model3.json export, watchOS atlas derivation, or Cubism Native R5 integration. Also use when Cubism selection, Java accessibility, export structure, model-version compatibility, or automation economics causes trouble.
---

# Live2D Cubism Workflow

Build the smallest verifiable model increment, save a recoverable checkpoint, and validate it visually before proceeding. Keep private character assets out of Git while keeping the workflow, manifests, and validation rules reproducible.

## Honor the current stop decision

- Read the continuation card first. When `activeTrack` is `spritekit-mainline`, `decision.live2dStatus` is `paused`, or `cubismActionRequired` is `false`, do not open Cubism, inspect its UI, install an MCP, build GUI/canvas automation, or continue the Native Metal host.
- Live2D can resume only after a human authors one visibly different mouth or eye keyform in an isolated checkpoint and `scripts/verify_live2d_model3_motion.sh` returns 0 with a changed Drawable vertex hash.
- A passing human proof resumes only `rig-lite-runtime` and the Native Metal host. It does not authorize custom Cubism automation or `production-v1`.
- A failed proof freezes Live2D for the current release. Continue SpriteKit on iOS/macOS and SwiftUI key poses or approved atlases on watchOS.

## Resume before rediscovery

1. Read the project [continuation card](../../../docs/live2d/continuation.json) before inspecting Cubism or private assets.
2. Recheck only drift-prone facts needed for its `nextAction`. Do not inspect any Editor UI when Live2D is paused or `cubismActionRequired` is `false`.
3. When Cubism UI work is required, read the [single-step runbook](../../../docs/live2d/CUBISM_RUNBOOK.md) and perform one object, parameter, or export increment.
4. Update the continuation card only with verified results, the recoverable checkpoint, and one directly executable next action.

## Choose the capability gate

- `rig-lite-runtime` proves model3 loading, texture display, one visible eye/mouth/breath parameter change, and the missing-model SpriteKit fallback. Full production parameters, physics, and motions do not block it.
- `production-v1` requires the formal layered PSD, occlusion fills, the complete runtime parameter contract, physics, motions, and visual quality gates.
- Never add an unbound or no-op parameter only to make a broader contract check pass. Parameter presence is not evidence of visible behavior.

## Route by Editor capability

1. Detect the Cubism Editor version and current model before editing.
2. For Cubism Editor 5.3 on macOS, read [references/cubism-5.3-macos-ui.md](references/cubism-5.3-macos-ui.md) and use the `computer-use` skill through `node_repl`.
3. Do not use Cubism 5.4 Alpha MCP or GUI automation under the current stop decision. Reconsider only if a stable API can write the required ArtMesh/Deformer geometry or an approved multi-model production case changes the economics.
4. For exported `.model3.json`, `.motion3.json`, `.physics3.json`, textures, and manifests, use deterministic file checks. If a Live2D CLI is already installed, it may supplement—not replace—Cubism Editor export validation.
5. Read [references/open-source-landscape.md](references/open-source-landscape.md) before adopting any external Live2D automation dependency.

## Execute the modeling pipeline

### 1. Establish the checkpoint

- Start from the continuation card, then inspect the current `.cmo3`, PSD, layer manifest, private asset paths, and Git state only as required by the active milestone.
- Confirm the selected ArtMesh by its Inspector `名称`/`ID`; do not infer selection from canvas position alone.
- Work on one object at a time unless a batch operation is explicitly intended.
- Save after each accepted mesh, parameter, or export milestone. If Cubism is editing a `/tmp` copy, copy the saved checkpoint back to the private project directory before ending the turn.

### 2. Validate layered art

- Require unique, stable layer names and restored pixels under moving overlaps.
- Recompose all control layers over the base and compare against the approved neutral image before importing.
- Treat face shape, chin length, eye proportions, and costume silhouette as visual invariants unless the user requests a redesign.
- Keep PSD, `.cmo3`, source art, audio, generated textures, and exported private models in ignored private paths.

### 3. Generate and inspect ArtMeshes

- Select exactly one target ArtMesh.
- Run `建模 → 纹理 → 自动网格生成...`.
- Choose density by the motion need: eyes and mouth need more deformation points than rigid accessories; the body needs enough structure for breath and sway but should not be uniformly dense.
- In the generator, the right-facing `>` button executes generation; there may be no blue OK button.
- Turn on `显示 → 显示图形网格顶点`, then `显示 → 聚焦到选中的对象`.
- Reject a mesh that remains a rectangle, misses opaque contours, bridges unrelated islands, or is too coarse for the intended keyform.
- Save and snapshot only after visual acceptance.

### 4. Bind parameters incrementally

- Add keys to one ArtMesh/deformer and one parameter at a time.
- Preserve the neutral key before editing the alternate key.
- For eye-open parameters, test open, half, and closed values and check that the face outline does not move.
- For mouth-open, preserve chin length and avoid scaling the whole head.
- For breath, use a torso deformer with subtle vertical/volume change; do not scale the entire character.
- Test parameter extremes and return every parameter to its default before saving.

### 5. Add physics and reactions

- Use different phase and amplitude for hat ornaments, front/side/back hair, and cape.
- Keep first touch feedback within the product target and allow a clean interpolation back to idle.
- Keep reaction names and runtime parameter IDs aligned with [references/project-live2d-contract.md](references/project-live2d-contract.md).

### 6. Export and verify

- Preserve the editable `.cmo3` before exporting.
- Export `.moc3`, textures, `.model3.json`, physics, motions, and user data required by the runtime.
- Verify every relative reference exists, filenames match case, textures decode, and motion/parameter IDs match the runtime contract.
- Validate the Native R5 host on iOS Simulator arm64 and macOS arm64; do not link Cubism Core into watchOS.
- Derive watchOS transparent motion atlases from the same approved model and motions.
- Update `docs/DEPENDENCIES.md` in the same change whenever a dependency or tool is added or downloaded.

## Work safely with Cubism UI

- Refresh the accessibility tree after every action; element indices are ephemeral.
- Prefer native macOS menu items over stale Java widget coordinates.
- Treat repeated `AccessibleHTML`/`this.grid is null` stack traces as a Cubism Java accessibility defect, not proof that model data is corrupt.
- Avoid dumping the full log panel repeatedly; inspect the relevant window, Inspector fields, and screenshots.
- When a Java control cannot be focused or edited reliably, ask the user for one exact click or value change, then immediately inspect the resulting state and continue.
- Never claim a mesh or keyform is complete solely because a command returned successfully; verify it on the canvas.

## Completion gate

Finish a milestone only when all are true:

- The active capability profile is named and its own requirements are used; a production-only requirement does not block RigLite.
- The continuation card's pause or stop decision is honored before any UI or runtime work begins.
- The intended object and parameter are identified by ID.
- The canvas behavior is visually checked at defaults and extremes.
- The `.cmo3` checkpoint is saved outside temporary storage.
- Exported references and runtime files pass deterministic checks when export is in scope.
- New dependencies, versions, licenses, and restore commands are documented.
- The continuation card records the verified result and the next directly executable action.
