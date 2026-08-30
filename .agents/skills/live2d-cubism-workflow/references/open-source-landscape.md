# Open-source Live2D automation landscape

Review these projects for ideas or optional future integration. Do not copy code or add a dependency without checking the current license, compatibility, and project dependency record.

## CubismExternalEditMCP

- Repository: https://github.com/nana7chi/CubismExternalEditMCP
- License reported by the repository: MIT
- Scope: wraps Cubism Editor External Application Integration as MCP tools for inspection, selection, parameter/key editing, parts, deformers, ArtMesh properties, and transactions.
- Reusable ideas: always check connection; obtain the model UID; inspect structure and IDs before edits; prefer typed operations; batch edits in one transaction with rollback.
- Compatibility caveat: full structure/edit support targets Cubism Editor 5.4 Alpha. The current project is pinned to Editor 5.3.03, so this does not replace the macOS UI workflow today.

## CLI-Anything Live2D skill

- Skill: https://github.com/HKUDS/CLI-Anything/blob/main/skills/cli-anything-live2d/SKILL.md
- Scope: command-line inspection, linting, diffing, dependency checks, motion/expression metadata edits, packaging, and deployment for exported Live2D files.
- Reusable ideas: emit machine-readable output; back up before edits; validate referenced files; detect orphans; create manifests and checksums; distinguish editor authoring from exported-bundle validation.
- Compatibility caveat: it does not author ArtMesh geometry or replace Cubism Editor rigging.

## live2d-automation MCP

- Repository: https://github.com/J621111/live2d-automation
- Scope: image-analysis-to-Live2D pipeline orchestration, resumable sessions, output confinement, calibration artifacts, and a native GUI adapter contract.
- Reusable ideas: resume from compatible checkpoints; record fallback reasons; confine generated output; separate dry-run, partial, and execute modes; calibrate UI sequences against the actual Editor version.
- Compatibility caveat: its documented exporter creates a mock intermediate bundle rather than a production-ready model, and its native GUI controller is Windows-oriented.

## Adoption rule

Decision recorded 2026-08-28: use these projects only as architectural references and do not install them for the current release. Cubism 5.4 Alpha's external API does not expose the ArtMesh vertex-coordinate writing needed to remove the actual rigging bottleneck.

Reconsider automation only when at least one of these is true:

1. A stable Cubism API supports ArtMesh vertex or Deformer geometry writes needed by real keyforms.
2. The project enters a reusable multi-model production workload that can amortize calibration and maintenance.
3. The user explicitly reopens the evaluation based on new capability evidence.

Until then, use project-local validation scripts and deterministic exported-bundle checks. Cubism 5.3 manual authoring is permitted only for the one human resume gate; SpriteKit/SwiftUI remains the current-release path.
