---
title: 'Integrate the animated PixelLab cult chapel'
type: 'feature'
created: '2026-09-29'
status: 'implemented'
baseline_commit: 'e61905899034d6bbcd24ce9f21bc8262ee3e7508'
context:
  - 'docs/CENARIO_0_16.md'
  - 'docs/architecture.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Cult Chapel still uses procedural tiles and small legacy props, so it no longer matches the scale, finish, or temporal atmosphere of the approved PixelLab environment. The approved 1344×752 artwork and its ambient loop exist only as source artifacts and are not rendered by the game.

**Approach:** Integrate the approved chapel as an animated environment plate in the existing room, driven by expedition time. Preserve the current room bounds, connections, gameplay, navigation, and collisions; replace only the chapel's visual presentation and suppress legacy art that is already baked into the new plate.

## Boundaries & Constraints

**Always:** Preserve the approved artwork's aspect ratio and crisp nearest-neighbor pixels; keep the chapel at `Rect2(200, 3600, 1300, 1400)` with its north, east, and south connections; animate at 110 ms per frame with a seamless 12-frame loop; keep actors, combat effects, chests, labels, fog reveal, gates, and additive lighting above the environment; retain collision and navigation behavior; load assets once rather than per frame.

**Ask First:** Changing room geometry, corridor positions, encounter/story behavior, camera zoom, or collision layout; regenerating or materially repainting the approved PixelLab image.

**Never:** Stretch the 1344×752 artwork to 1300×1400; render the GIF directly at runtime; remove gameplay objects merely because their art is baked into the background; alter other rooms; overwrite the existing v1/v2 source artifacts.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Chapel discovered | Camera intersects the chapel during a run | Current animation frame appears aspect-correct in the chapel sanctum; procedural floor remains only in the uncovered connector area | Missing frame falls back to the static chapel plate |
| Chapel hidden | Room has not been discovered | Artwork and its lights remain hidden by the existing discovery rules | No special handling |
| Animation wrap | Expedition time crosses 1.32 seconds | Frame selection wraps from 11 to 0 without changing geometry | Clamp/modulo protects out-of-range indices |
| Other room | Camera does not intersect the chapel | Rendering and gameplay remain unchanged | N/A |

</frozen-after-approval>

## Code Map

- `assets/environment/docks12/chapel/animated/` -- production PNG frames derived from the approved PixelLab loop.
- `scripts/dock_scenery.gd` -- loads chapel frames, selects the active frame, draws the plate and suppresses baked duplicate decoration.
- `scripts/world_view.gd` -- invokes the chapel plate at the correct ground-layer point and keeps entities/effects above it.
- `tools/build_docks_map.py` -- aligns the chapel's collision boxes with the painted pew bases while preserving all three approaches.
- `tools/build_chapel_animation.py` -- reproducibly exports production frames from the approved PixelLab source.
- `tests/chapel_animated_test.gd` -- asset, timing, fallback, and render-boundary checks.

## Tasks & Acceptance

**Execution:**
- [x] `tools/build_chapel_animation.py` -- export twelve lossless 1344×752 PNG frames plus the review GIF from the approved source -- make runtime assets reproducible and avoid unsupported GIF playback.
- [x] `assets/environment/docks12/chapel/animated/` -- add optimized production frames and static fallback with nearest filtering/no mipmaps -- provide runtime-ready art.
- [x] `scripts/dock_scenery.gd` -- load frames once, expose deterministic frame selection, draw the aspect-correct plate only for the discovered chapel, and skip legacy visuals baked into the plate.
- [x] `scripts/world_view.gd` -- place the chapel draw call above procedural walls and below entities, labels, and effects.
- [x] `tools/build_docks_map.py` -- align eight collision boxes to the painted pew bases while keeping the central aisle and north/east/south approaches open.
- [x] `tests/chapel_animated_test.gd` -- verify dimensions, frame cadence/wrap, fallback, geometry, visibility, collision alignment, and approach traversal.

**Acceptance Criteria:**
- Given a run in the discovered chapel, when the camera views the altar area, then the approved PixelLab environment renders at its original aspect ratio with animated relic, rift, candles, and stars.
- Given Marty, enemies, chests, or effects inside the chapel, when they render, then they remain visible above the environment and use the existing collisions and navigation.
- Given the north, east, and south chapel approaches, when Marty traverses each connection, then the route remains passable and the uncovered connector space blends into the existing procedural floor.
- Given any non-chapel room, when it renders, then its visuals and timing are unchanged.

## Design Notes

The approved plate covers the upper chapel sanctum at its native 1344×752 presentation scale and is clipped to the chapel bounds. The lower portion of the existing 1300×1400 room remains the approach nave and uses the current procedural floor, avoiding vertical distortion and keeping all three connections intact. Runtime animation uses PNG frames selected from `sim.tick_time`; the GIF remains a review artifact.

The approved frames and reproducible generator are preserved in the consolidated branch. Runtime activation now uses eight shallow collision boxes aligned to the visible bases of the painted pews. The central aisle and the north, east, and south approaches remain open.

## Verification

**Commands:**
- `godot --headless --path . -s tests/chapel_animated_test.gd` -- expected: all chapel animation assertions pass.
- `godot --headless --path . -s tests/scenery_016_test.gd` -- expected: existing chapel microbiome and scenery checks pass.
- `godot --headless --path . -s tests/scenery_test.gd` -- expected: general scenery checks pass.
- `godot --path . -- --capture-docks-v04 --visit-all --no-enemies --at=850,4100 --capture-name=chapel-animated` -- expected: the integrated plate is crisp, aligned, animated, and layered below actors.

## Suggested Review Order

**Runtime integration**

- Defines native plate bounds, cadence, cached frames, visibility, and fallback behavior.
  [`dock_scenery.gd:8`](../../scripts/dock_scenery.gd#L8)

- Draws the discovered chapel plate without stretching, clipped to the existing room.
  [`dock_scenery.gd:143`](../../scripts/dock_scenery.gd#L143)

- Places the plate below walls and gameplay while suppressing baked duplicate props.
  [`world_view.gd:147`](../../scripts/world_view.gd#L147)

**Reproducible artwork**

- Generates twelve lossless frames, fallback PNG, and the review GIF from approved source.
  [`build_chapel_animation.py:31`](../../tools/build_chapel_animation.py#L31)

**Regression coverage**

- Verifies assets, timing, fallback, geometry, visibility, and all three approaches.
  [`chapel_animated_test.gd:15`](../../tests/chapel_animated_test.gd#L15)

