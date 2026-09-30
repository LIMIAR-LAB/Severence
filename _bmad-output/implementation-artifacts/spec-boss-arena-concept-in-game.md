---
title: 'Bring the Almirante concept arena into gameplay'
type: 'feature'
created: '2026-09-29'
status: 'in-review'
baseline_commit: 'd1ab1005c1020b8ace25481b3e980553010efa2e'
context:
  - '{project-root}/docs/deep-dive-boss.md'
  - '{project-root}/docs/CENARIO_0_18.md'
  - '{project-root}/docs/architecture.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Almirante fight uses a repetitive procedural stone floor and generic room dressing that undersell the remade boss. The approved gameplay concept establishes a much stronger abyssal 1941 naval arena, but it is not yet represented in the playable room.

**Approach:** Translate `art/concept/arena-boss-almirante-gameplay-v1.png` into a clean gameplay environment layer and boss-specific perimeter dressing while preserving the existing room footprint, entrances, combat geometry, boss logic, and camera behavior.

## Boundaries & Constraints

**Always:** Keep the boss room `Rect2(3000,400,2400,1800)`, both entrances, boss/extraction points, obstacle collision boxes, hazards, navigation, and attack readability intact. Preserve a clear central dodge ring and unobstructed projectile lanes. Match the concept's wet steel, aged brass, black-teal water, cyan bioluminescence, restrained violet fractures, orange braziers, chains, wreckage, and sealed floodgate. Use crisp nearest-filtered pixel art and keep all new assets under the boss environment folder.

**Ask First:** Any change to collision geometry, boss movement or attacks, hazard positions/damage, room dimensions, camera zoom, extraction behavior, or non-boss room rendering.

**Never:** Use the concept screenshot directly as the runtime background with Marty or the boss baked into it; stretch the 16:9 concept across the 4:3 room; place opaque scenery over the combat center; overwrite unrelated dirty encyclopedia, inventory, character-selection, or weapon work; regenerate `docks_map.gd` blindly from the currently divergent Python generator.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|---------------------------|----------------|
| Normal fight | Player enters the boss room from either entrance | Dedicated arena art appears beneath live entities; center and routes remain readable and navigable | Fall back to existing boss floor tiles if the dedicated texture cannot load |
| Multi-stage combat | Ring, spiral, charge, fury, and defeat states render | Telegraphs, bullets, boss silhouette, health bar, and player remain legible against the arena | Reduce local floor contrast/glow rather than altering attacks or HUD |
| Camera edge | Camera follows actors near room edges and wings | Water, chains, walls, and set dressing end cleanly without seams or baked characters | Clip or extend boss-only background layers outside the walkable floor |

</frozen-after-approval>

## Code Map

- `art/concept/arena-boss-almirante-gameplay-v1.png` -- approved visual target and composition reference.
- `assets/environment/docks12/boss/` -- existing boss floor tiles/props and new clean arena layer assets.
- `scripts/dock_scenery.gd` -- asset loading plus boss-specific ground/perimeter rendering.
- `scripts/world_view.gd` -- ground render order before walls, decor, entities, bullets, and VFX.
- `scripts/docks_map.gd` -- canonical room style and visual-only surrounding water declarations.
- `tests/boss_arena_scenery_test.gd` -- new arena asset, geometry, safe-zone, and navigation contract coverage.

## Tasks & Acceptance

**Execution:**
- [x] `assets/environment/docks12/boss/` -- create a clean 4:3 gameplay arena layer and any transparent supporting pieces derived from the approved concept, without baked entities or UI.
- [x] `scripts/dock_scenery.gd` and `scripts/world_view.gd` -- render the dedicated arena beneath gameplay, skip repetitive boss-floor treatment where replaced, and preserve the normal wall/entity order.
- [x] `scripts/docks_map.gd` -- add only visual surrounding-water coverage and concept-consistent boss decor while keeping physical geometry unchanged.
- [x] `tests/boss_arena_scenery_test.gd` -- verify assets, room contract, entrances, central safe ring, extraction, and navigation.
- [x] `test-output/` -- capture clean arena, stage 1, stage 2/charge, fury, and defeat at current room coordinates for visual review.

**Acceptance Criteria:**
- Given the player enters from either boss-room entrance, when the arena is revealed, then it reads as the approved abyssal naval ritual dock and both routes to the center remain open.
- Given any Almirante phase, when attacks and telegraphs render, then the playable center remains visually calm enough to read projectiles and dodge paths.
- Given the normal gameplay camera moves across the room and wings, when the viewport reaches each edge, then no texture seam, stretched circle, baked character, or empty visual void is exposed.
- Given the existing dirty worktree, when implementation completes, then only boss-arena/spec/test files are added or modified by this work.

## Spec Change Log

- 2026-09-29: Implemented the dedicated 4:3 arena plate, visual-only water perimeter, fallback rendering, geometry/navigation contract test, and gameplay captures for the fight states.

## Design Notes

The concept is a direction reference, not a drop-in background. The runtime composition must be adapted to the room's 4:3 footprint and partial-camera views. Prefer one clean floor plate for the central naval compass/anchor composition plus transparent or procedural perimeter layers for water, chains, machinery, and lighting. Preserve the current collision map as the source of truth; visual structures must align with it rather than redefine it.

## Verification

**Commands:**
- `godot --headless --path . --editor --quit` -- expected: all new textures import without script or resource errors.
- `godot --headless --path . --script tests/boss_arena_scenery_test.gd` -- expected: arena contract passes with zero failures.
- `godot --headless --path . --script tests/simulation_test.gd` -- expected: spawn-to-boss navigation remains valid.
- `godot --headless --path . --script tests/enemies_test.gd` -- expected: all Almirante phase/attack tests remain green.
- `godot --path . -- --capture-docks-v04 --visit-all --no-enemies --at=4200,1350 --capture-name=boss-arena-scenery` -- expected: clean arena capture matches the concept direction without gameplay entities baked in.

**Manual checks (if no CLI):**
- Inspect clean, stage 1, charge/spin, fury, and defeat captures at gameplay zoom for seams, occlusion, contrast, and concept fidelity.
