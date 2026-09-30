---
title: 'Align equipment menus and attributes with playable mechanics'
type: 'bugfix'
created: '2026-09-30'
status: 'done'
baseline_commit: 'b6fd2a7'
context: []
---

<frozen-after-approval reason="user-requested menu correction">

## Intent

**Problem:** Equipment presents prototype loot with no gameplay use and combines mutually exclusive states into fictional character attributes. Selecting Titan and Omega currently advertises extra permanent hearts, while Spectre advertises defense it does not provide.

**Approach:** Present implemented equipment and expedition resources, identify uniforms as uniforms with their associated weapons, and separate Marty, temporary Omega, and robot attributes. Before departure show reference attributes; during a mission show actual health, shield, ammunition and robot condition separately from reference abilities.

## Boundaries & Constraints

**Always:** Preserve inventory/save identifiers, existing unlocks, selection actions, offline pause and online authority. Preserve unrelated work already present in terminal_ui.gd, main.gd and scenery. Read combat values from simulation constants/state. Communicate temporary effects and activation conditions in Portuguese. Keep keyboard/controller navigation.

**Ask First:** New progression, new combat rules, removal of playable equipment.

**Never:** Add fictional loot, sum robot integrity with Marty's health, present Omega as permanent health, offer meaningless consumable actions, modify balancing or erase prototype entries from existing saves.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
| --- | --- | --- | --- |
| Preparation | Padrão, Titan, Omega selected | Three distinct attribute groups; Marty has three base hearts | Missing robot displays none selected |
| Prototype save | Inventory contains repair kit or workshop prototype | Items remain stored but are absent from player-facing inventory | No save migration or deletion |
| Uniform selection | Choose Mecânico | Name identifies uniform and associated shotgun, existing equip behavior preserved | Locked uniforms show unlock requirement |
| Expedition | Wounded Marty, partial shield/fuel, bazooka ammo | Real current values, explicit inactive/active/stored states | Dead or occupied actors retain action restrictions |
| Online updates | Health, shield, ammo or robot state changes | Visible status refreshes without reopening | Preserve focus across refresh |

</frozen-after-approval>

## Code Map

- `scripts/equipment_screen.gd` — five tabs, inventory filtering, item actions and current incorrect aggregate status.
- `scripts/equipment_data.gd` — legacy cosmetic attribute aggregation; avoid it for player-facing status.
- `scripts/simulation.gd` — authoritative UNIFORMS, ARMORS, WEAPONS, loadout_stats, actors, mech and spectres.
- `data/inventario.json` — inventory names/descriptions, including prototype and transient records; retain IDs.
- `tests/inventory_ui_test.gd`, `tests/equipment_ui_test.gd`, `tests/mission_inventory_ui_test.gd` — affected menu behavior.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/equipment_screen.gd` — hide prototypes, replace misleading inventory capacity/empty-slot hints with actual item counts, distinguish uniforms, robots, Omega and expedition supplies in labels. Preserve available actions.
- [x] `data/inventario.json` — align equipment names and descriptions with what selection does, preserving IDs and saved data schema.
- [x] `scripts/equipment_screen.gd` — replace combined bars with separate reference panels sourced from simulation; distinguish current mission condition from reference values and remove false aggregate values from compatibility labels.
- [x] `tests/equipment_ui_test.gd`, `tests/inventory_ui_test.gd`, `tests/mission_inventory_ui_test.gd` — adjust outdated expectations and verify that robots/Omega do not inflate base hearts, prototypes remain hidden, and live state changes refresh the status.

**Acceptance Criteria:**
- Given preparation, when viewing status with Titan or Spectre selected, then Marty's base health remains three hearts and temporary shield/robot integrity are separate.
- Given inventory entries, when browsing, then each displayed item has an implemented gameplay role and uniforms explain their bundled weapon.
- Given a mission, when health or robot state changes, then visible current readings track the selected actor without inventing additive bonuses.
- Given menu navigation, when selecting equipment or changing tabs, then existing equipment actions, focus navigation and mission return remain functional.

## Design Notes

Use small readable panels instead of arbitrary universal power bars. A preview of Omega describes its active condition rather than claiming its bonuses are always enabled. Fuel and Spectre energy are robot condition, not consumables in a backpack. Existing persistence remains compatible, including prototype data that is intentionally hidden. This is a UI correction authorized by the user's request, not a request to rebalance gameplay or replace current menu artwork.

## Spec Change Log

## Verification

- Run equipment, inventory, mission inventory, inventory model/persistence and equipment unlock tests headlessly; expect zero failures.
- Capture the equipment and status screens using the real renderer and inspect text fit and separated state panels.

### Implementation verification (2026-09-30)

- Passed headless: equipment_ui_test, inventory_ui_test, mission_inventory_ui_test, inventory_model_test, inventory_persistence_test, equipment_unlock_test (zero failures).
- Godot editor headless compilation completed with no script errors.
- Continuous condition updates preserve label/control instances; regression test covers health, fuel and timer changes.
- docs/INVENTARIO.md updated to describe hidden prototype records, preserved saves and separated reference/current attributes.
- Final validation: seven suites passed with zero failures, including hearts_stats_test; diff whitespace check passed.
- Real renderer captures reviewed at 1600×1000 and 1280×720: inventory labels and separate reference/current status panels fit.
- Review fixes: robot equipped badges and comparisons use selected equipment, and fragment text no longer promises unavailable upgrades. A regression verifies stale inventory cannot mark the previous robot equipped.

## Suggested Review Order

- Separate character, armor and robot values before presenting live mission conditions.
  [equipment_screen.gd:452](../../scripts/equipment_screen.gd#L452)
- Hide unused prototypes without altering their saved records.
  [equipment_screen.gd:180](../../scripts/equipment_screen.gd#L180)
- Name uniforms and equipment according to their actual gameplay role.
  [inventario.json:5](../../data/inventario.json#L5)
- Verify live readings and equipped badges follow the selected robot.
  [mission_inventory_ui_test.gd:110](../../tests/mission_inventory_ui_test.gd#L110)
