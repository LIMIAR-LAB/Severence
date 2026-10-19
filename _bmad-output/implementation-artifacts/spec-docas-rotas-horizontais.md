---
title: 'Docas: rotas horizontais até o Almirante'
type: feature
created: '2026-10-03'
status: done
baseline_commit: 87fe42e55592e2d8944b94ec8e17429994c312af
context: []
---

<frozen-after-approval reason="user authorized autonomous implementation in a shared workspace">

## Intent

**Problem:** The current vertical bridge is 1,000 units long, taking about 1.3 seconds at the motorcycle's real speed. It reaches the boss too early and does not deliver the intended final journey.

**Approach:** Two large parallel horizontal routes depart from the antechamber and converge at the relocated boss arena. The motorcycle route takes approximately 20 seconds of forward travel with obstacles, enemies and a pursuing collapse. The enclosed mangrove provides a walking alternative with its miniboss.

## Boundaries & Constraints

**Always:** Preserve external edits and existing saved expeditions. Require Omega and Faísca's loan for mounting. Provide a safe checkpoint before departure, retry after falling, and prevent dismounting during the crossing. Trigger the existing boss presentation only upon actual arena entry.

**Ask First:** Any expansion beyond the requested route redesign.

**Never:** Edit world_view.gd, dock_scenery.gd, main.gd or UI files while the other chat owns them; consume image-generation credits; teleport a test player across the arena as a substitute for traversing the route.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected behavior | Handling |
|---|---|---|---|
| Ride | Omega and loan, forward movement | Approximately 20-second horizontal journey | Obstacles leave room to steer |
| Fall | Rider is caught by collapse | Checkpoint and repaired bridge | Existing damage/defeat rules apply |
| Arrival | Rider physically exits into arena | Crossing complete, dismount allowed, presentation eligible | No completion from y alone |
| Walk | Walking player enters mangrove | Enclosed parallel route with miniboss | Combat gates protect arena exit |
| Old save | Legacy geometry snapshot | Original geometry and bridge behavior retained | Do not overwrite disk saves |
| New save | Mid-crossing snapshot | Geometry, timer, riding state restored | Retry remains possible |

</frozen-after-approval>

## Code Map

- `tools/build_docks_map.py` — generator and connectivity validation, content authored in fixed coordinates.
- `scripts/docks_map.gd` — generated data for simulation and rendering.
- `scripts/simulation.gd` — route state, collapse, interaction, snapshots; preserve enemy confinement helpers.
- `tests/route_p12_test.gd` — route regression suite, currently assumes vertical geometry.
- `scripts/main.gd` — existing presentation checks actual boss room entry; read only.

## Tasks & Acceptance

**Execution:**
- [x] `tools/build_docks_map.py`, `scripts/docks_map.gd` — author parallel routes, relocate arena content and extraction, remove bypass connections, validate and regenerate.
- [x] `scripts/simulation.gd` — adapt collapse, arrival, dismounting, checkpoint and saved geometry handling.
- [x] `tests/route_p12_test.gd` — verify movement over time, fall/retry, mounting rules, saves and actual arrival.
- [x] `docs/DOCAS_ROTAS_HORIZONTAIS.md` — document rendering integration points in externally owned files.

**Acceptance Criteria:**
- Given the current motorcycle speed, when the rider travels the full route, then forward travel takes approximately 20 seconds before entering the arena.
- Given either route, when actors remain outside the arena, then the boss introduction remains ineligible.
- Given the new layout, when an actor follows either route, then both end at the same arena without a direct shortcut.
- Given legacy saved geometry, when loaded, then the old expedition remains coherent.

## Spec Change Log

## Design Notes

The bridge length is speed multiplied by duration: 780 × 20 = 15,600. Collapse starts behind the rider with enough allowance for steering. Arena props move by a common translation to retain the authored composition. Existing intro logic already uses room membership; relocating the arena prevents premature introduction without changing its owner file.

## Verification

- Run map generation with connectivity and obstacle validation.
- Run Godot headless route, boss intro, enemy confinement and save regressions.
- Review only changes owned by this request against the shared working tree baseline.

### Results

- Map generator: passed connectivity validation for 17 rooms, 15 corridors, 432 obstacles.
- `route_p12_test.gd`: passed; actual motorcycle journey 21.37 seconds with encounters. Includes Omega-only mounting, walking and blink rejection, physical arrival, collapse/retry, resumed saves, legacy geometry and missing legacy points, crawler offspring cleanup and split-route co-op.
- `boss_intro_test.gd`: passed; actual ride reaches the arena before intro eligibility, then presentation freezes combat and resumes normally.
- `boss_arena_scenery_test.gd`: passed; translated props, hazards, water and navigation preserve arena composition.
- `enemy_room_bounds_test.gd`, `boss_music_test.gd`: passed.
- Broader `simulation_test.gd`: 23/27 checks pass; three old Farol ramp assertions and the old synchronous extraction assertion fail. These assertions predate the Farol geometry/capsule flow already present in the shared working tree. No changes made to those unrelated tests or systems.
- Three independent review agents completed review. Fixed blink bypass, crawler offspring cleanup and split-route co-op gathering; expanded save continuation/retry tests. A speculative early gate closure finding was rejected: negative room margin shrinks the room, and real traversal confirms arrival succeeds.
- No local commit: the workspace contains ongoing external changes, including other modifications to simulation.gd. No external code or saves were reverted, staged or committed.
- Painting/capture follow-up is documented in `docs/DOCAS_ROTAS_HORIZONTAIS.md`; externally owned rendering/UI files were preserved. The new arena currently uses the renderer's normal tile fallback.

## Suggested Review Order

- Review the two horizontal routes and their shared destination.
  [build_docks_map.py:73](../../tools/build_docks_map.py#L73)
- Review collapse timing, physical arrival and retry.
  [simulation.gd:1147](../../scripts/simulation.gd#L1147)
- Review legacy saved geometry handling.
  [simulation.gd:2577](../../scripts/simulation.gd#L2577)
- Review movement, save and co-op regressions.
  [route_p12_test.gd:1](../../tests/route_p12_test.gd#L1)
- Review integration notes for files owned by the other chat.
  [DOCAS_ROTAS_HORIZONTAIS.md:1](../../docs/DOCAS_ROTAS_HORIZONTAIS.md#L1)
