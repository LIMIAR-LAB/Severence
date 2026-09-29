---
title: 'Remake the first-stage boss with PixelLab'
type: 'feature'
created: '2026-09-29'
status: 'draft'
context:
  - '{project-root}/docs/SPRITES_0_6.md'
  - '{project-root}/docs/deep-dive-boss.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The first-stage boss, “O Almirante das Profundezas,” still uses an older extracted concept-sheet set whose poses vary in scale and visual finish. It should be remade as a coherent production-ready PixelLab sprite set while retaining the established abyssal naval identity.

**Approach:** Use the current Almirante artwork as the visual reference in PixelLab, create one strong canonical boss design, derive the seven existing gameplay poses from that design, and replace the corresponding transparent PNGs without changing boss logic.

## Boundaries & Constraints

**Always:** Preserve the recognizable giant abyssal octopus admiral: navy bicorne with gold anchor, purple/teal flesh, multiple tentacles, brass naval weapons, grotesque single-eye/sea-horror details, and a heavy boss silhouette. Keep all seven filenames and their semantic poses (`idle`, `ring`, `spiral`, `charge`, `hurt`, `fury`, `defeat`), transparent backgrounds, crisp native pixel art, consistent palette/lighting, readable silhouettes at gameplay zoom, and a shared foot/waterline anchor compatible with the existing renderer. Keep the replacement inside `assets/boss/`; retain source/reference output under an Almirante-specific `art/source/pixellab/` folder.

**Ask First:** Any change to projectiles, combat behavior, collision sizes, renderer code, the Almirante’s established identity, or unrelated dirty working-tree files.

**Never:** Modify or discard unrelated user changes; introduce smooth non-pixel rendering, opaque backgrounds, text, frames, or scenery; overwrite a production pose with an incomplete/failed generation; use a pose whose subject is visibly a different character.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Complete remake | PixelLab returns a consistent canonical boss and all required states | Seven transparent, correctly named boss PNGs load through the existing `world_view.gd` state machine | Preserve original production files until the full set is validated |
| Inconsistent state | A generated pose changes anatomy, palette, scale, or anchor materially | Reject or regenerate that pose; do not ship a mixed character set | Keep the prior pose and record the failed candidate outside `assets/boss/` |
| Generation failure | PixelLab job fails or returns unusable output | No production asset is replaced by that result | Retry within the same visual brief; report if a complete coherent set cannot be obtained |

</frozen-after-approval>

## Code Map

- `assets/boss/almirante_*.png` -- seven runtime poses loaded by filename in the renderer.
- `art/source/boss-almirante-v1.png` -- current concept sheet and identity reference.
- `art/source/pixellab/almirante/` -- retained PixelLab source exports and generation notes for reproducibility.
- `scripts/world_view.gd` -- read-only integration reference defining pose priority, placement, rotation, and health-bar offsets.
- `scripts/main.gd` -- existing boss capture entry point used for visual verification.

## Tasks & Acceptance

**Execution:**
- [ ] `art/source/pixellab/almirante/` -- create and retain the canonical PixelLab boss output plus pose candidates and a concise generation record -- preserves provenance and enables later refinement.
- [ ] `assets/boss/almirante_*.png` -- normalize and replace all seven runtime poses with the coherent PixelLab set -- keeps the existing loading/state contract intact.
- [ ] `assets/boss/almirante_*.png` -- verify transparency, dimensions, pixel-grid sharpness, stable waterline/foot anchor, pose readability, and visual consistency -- prevents jitter and broken combat presentation.
- [ ] `test-output/` -- capture the boss at representative health/states using the existing game capture flow -- validates the assets in the real arena rather than only in isolation.

**Acceptance Criteria:**
- Given the boss is above 66% HP, when idle and firing, then the new `idle` and `ring` poses clearly depict the same Almirante and align to the same world anchor.
- Given the boss enters charge, spiral, hurt, fury, and defeat states, when each state renders, then the matching new pose is transparent, visually distinct, correctly scaled, and does not clip or jump unexpectedly.
- Given the project is imported and the boss capture is run, when the arena frame is produced, then all boss textures load without errors and the health bar/name remain legible above the sprite.
- Given the existing dirty working tree, when implementation completes, then no unrelated tracked or untracked file has been modified or removed by this work.

## Spec Change Log

## Design Notes

The canonical design should favor a compact, centered 256px-class canvas and a strong triangular silhouette: bicorne and head as the focal mass, weapon-bearing tentacles widening the middle, and a stable dark water/ship-turret base at the anchor. Action poses may widen within their canvases, but the perceived body scale and central eye/head position should remain stable. `hurt` should read as a flash/recoil rather than a new white character; `fury` may lose the hat and intensify eyes/ink, matching established stage-three language; `defeat` should collapse and sink while remaining recognizable.

## Verification

**Commands:**
- `godot --headless --path . --editor --quit` -- expected: all replacement PNGs import without texture errors.
- `godot --path . -- --capture-boss --boss-hp=0.8` -- expected: stage-one arena capture shows the new boss, aligned and unobstructed.
- `godot --path . -- --capture-boss --boss-hp=0.2` -- expected: fury-state capture loads and remains readable in combat.
- `git status --short -- assets/boss art/source/pixellab/almirante _bmad-output/implementation-artifacts/spec-refazer-boss-primeira-fase-pixellab.md` -- expected: only scoped boss/source/spec files appear.

