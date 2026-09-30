---
title: 'Robot switching and combat identity polish'
type: 'feature'
created: '2026-09-29'
status: 'draft'
context:
  - '{project-root}/docs/SPRITE_POSE_STANDARD.md'
  - '{project-root}/docs/PADRAO_SPRITES_MARTY_0_19.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Players who own Titan and Spectre cannot switch between them during a mission, the lower-left robot panel has no recognizable face, and the current Marty portrait and Omega equip effect look substantially simpler than the surrounding presentation.

**Approach:** Add a safe, remappable robot-cycle command backed by authoritative simulation rules; rebuild the robot HUD around the selected unit's face and contextual state; replace the old Marty HUD face and flash-only Omega equip moment with dedicated pixel-art assets and a staged armor assembly overlay.

## Boundaries & Constraints

**Always:** Preserve existing local changes; allow selection only among unlocked, owned robot modules; reconcile older saves so unlocked robot entitlements are not silently missing; preserve Titan fuel and integrity plus Spectre energy across switches; keep host authority, snapshots, keyboard/controller support, nearest-neighbor filtering, 96×96 Marty foot anchoring, and current combat timing. A mid-mission selection is run-local and must never leave Titan deployed while Spectre follows, or vice versa.

**Ask First:** Change robot availability/progression, make mid-mission selection permanently replace the player's saved pre-run preference, or replace the approved character/armor silhouette with a different visual direction.

**Never:** Delete or overwrite unrelated uncommitted work; permit switching while piloting, fused, dead, or in a cockpit transition; heal/refuel a robot by switching; bake weapons into Marty body sprites; require an image service at runtime.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Cycle owned robot | V / mapped input or D-pad Left; both robots owned and current robot stored/following | Current unit is safely stored, next owned unit becomes selected, resources are preserved, HUD face/state updates | No duplicate deployed/following unit |
| Unsafe cycle | Marty is piloting, fused, dead, or transforming through the cockpit | Selection remains unchanged | Show a short actionable message explaining what must end first |
| One or no robot | Only one eligible module, or none | No false switch; HUD shows that unit or an empty slot accurately | Message states no alternative robot is available |
| Existing save | Robot is unlocked but its inventory module is absent | Entitlement reconciliation restores the corresponding owned module | Do not duplicate modules or alter unrelated inventory |
| Omega equip | R activates a ready armor | 1.4 s mechanics remain intact while armor plates/visor visibly assemble, followed by the existing burst | Repeated/blocked activation follows existing cooldown rules |

</frozen-after-approval>

## Code Map

- `scripts/main.gd` -- input defaults, remapping, controller mapping, network command validation, save reconciliation, and capture flags.
- `scripts/simulation.gd` -- authoritative robot selection, safe storage rules, Omega state/timing, and snapshots.
- `scripts/combat_hud.gd` -- Marty portrait plus lower-left robot face, resources, prompts, and empty-state rendering.
- `scripts/equipment_screen.gd` -- mission ownership policy and compatibility with direct robot cycling; preserve current bazooka work.
- `scripts/world_view.gd` -- Marty/Omega rendering and staged transformation overlay.
- `assets/ui/equipamento/icones/` -- existing Titan/Spectre face icons to reuse.
- `assets/ui/hud/` -- new dedicated Marty and Omega HUD portraits.
- `assets/characters/marty/omega/` -- new transparent armor-assembly overlay sheet.
- `tests/solo_robot_test.gd` -- switching, resource preservation, and mutually exclusive deployment.
- `tests/input_remap_test.gd` -- new keyboard/controller action and persistence.
- `tests/mission_inventory_ui_test.gd` -- owned/unlocked robot availability during missions and save migration.
- `tests/marty_actions_test.gd` -- portrait/overlay resource dimensions and pivot contract.

## Tasks & Acceptance

**Execution:**
- [ ] `scripts/simulation.gd`, `scripts/main.gd` -- implement authoritative owned-robot cycling, safe transition guards, remappable V/D-pad Left input, networking, and old-save entitlement reconciliation.
- [ ] `scripts/equipment_screen.gd` -- expose every owned robot during a mission without disturbing the existing transient bazooka inventory changes.
- [ ] `scripts/combat_hud.gd` -- redesign the lower-left panel with Titan/Spectre face, contextual bars/prompts and switch hint; use dedicated state-aware Marty/Omega portraits at top-left.
- [ ] `assets/ui/hud/`, `assets/characters/marty/omega/`, `scripts/world_view.gd` -- create and integrate polished pixel-art HUD portraits and a 6–8-frame feet-anchored armor assembly overlay while retaining the current pillar, ring, shockwave, and 1.4 s mechanics.
- [ ] `tests/solo_robot_test.gd`, `tests/input_remap_test.gd`, `tests/mission_inventory_ui_test.gd`, `tests/marty_actions_test.gd` -- cover the matrix and prevent regressions.

**Acceptance Criteria:**
- Given both modules are owned, when the player presses the mapped switch control in a safe state, then Titan and Spectre alternate immediately, retain their resources, and never coexist as active units.
- Given Titan, Spectre, or no robot is selected, when combat HUD renders, then the lower-left panel shows the correct face/empty state, only relevant controls and resources, and a visible switch control.
- Given Marty is standard or wearing Omega, when the HUD and world render at native gameplay scale, then his face is recognizable, crisp, and state-appropriate; activating Omega visibly assembles armor before the final flare without changing combat timing.
- Given an older save with unlocked robot IDs, when it loads, then corresponding modules become owned exactly once and both can be selected without resetting inventory.

## Spec Change Log

## Design Notes

Use the existing equipment icons for robot faces instead of generating redundant art. New raster work is limited to clean HUD busts and the Omega assembly overlay, derived from approved Marty/Omega references. The body remains separate from weapons and large effects. Mid-mission cycling changes the current actor selection only; pre-run equipment remains the persistent loadout authority.

## Verification

**Commands:**
- `Get-ChildItem tests\*_test.gd | ForEach-Object { & 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script "tests/$($_.Name)" }` -- expected: every test exits successfully.
- `& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture-arena --transform-demo` -- expected: captures show crisp HUD portraits, both robot faces/states, and readable start/mid/lock/final Omega stages at native scale.

