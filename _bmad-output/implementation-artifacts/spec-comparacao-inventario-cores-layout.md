---
title: 'Fix inventory comparison colors and layout'
type: 'bugfix'
created: '2026-09-30'
status: 'ready-for-dev'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The mission inventory comparison renders every value with the same text color, making changes difficult to scan. Entering comparison mode also overlaps the item description, crosses its panel border, can encroach on the action buttons, and shows a large tooltip over the controls.

**Approach:** Give comparison mode its own bounded, color-capable content area; classify values using the normalized scores already supplied by the simulation; and restore the normal detail layout whenever the selection or mode changes.

## Boundaries & Constraints

**Always:** Show improvements in green, regressions in red, unchanged values in a neutral color, and changed values without a reliable score in teal without claiming better/worse. Keep labels, arrows, and the previous/selected relationship legible; contain all comparison content above the action buttons; allow long comparisons to scroll instead of overflowing; restore the normal description and stats layout when another item is selected; keep keyboard/controller focus behavior and both mission/preparation inventory modes working; use the real catalog and simulation data.

**Ask First:** Any redesign of the entire inventory screen, removal of attributes from comparisons, or change to the gameplay values used by the comparison.

**Never:** Infer semantic quality only from formatted strings when a normalized score is available; hide overflow behind buttons; use color as the only indicator without retaining the before/after values and arrow; weaken existing inventory behavior or tests.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Clear improvement | Selected item has a higher normalized score | Selected value is green; previous value remains readable | Keep label and arrow neutral |
| Clear regression | Selected item has a lower normalized score | Selected value is red; previous value remains readable | Keep label and arrow neutral |
| Same item or equal stat | Scores and displayed values are equal | Values use neutral styling and the same-item note remains visible | Do not imply improvement |
| Text-only changed stat | Values differ but have no normalized score | Changed selected value is teal | Do not label it better or worse |
| Long robot comparison | Union contains more rows than fit naturally | Content remains inside its panel and scrolls above buttons | No clipping or overlap |
| Selection changes after comparing | User focuses/clicks a different inventory item | Normal detail geometry and content return before refreshing | No stale colors or comparison rows |
| Bazooka special comparison | Mission bazooka is compared with the basic weapon | Color distinction and bounded layout also apply | Preserve ammunition and area-damage wording |

</frozen-after-approval>

## Code Map

- `scripts/equipment_screen.gd` -- builds the inventory detail panel, derives comparison data, and currently moves one plain `Label` into overlapping geometry.
- `scripts/simulation.gd` -- `loadout_stats()` already exposes normalized scores where higher means better, including cooldown/dash semantics.
- `scripts/terminal_ui.gd` -- proportionally fits the 1344×752 equipment canvas; should remain unchanged unless verification reveals an outer-scaling defect.
- `tests/inventory_ui_test.gd` -- interaction coverage for the inventory, comparison button, and detail nodes.
- `tests/mission_inventory_ui_test.gd` -- mission-mode behavior and live inventory state.
- `tests/weapon_menu_bugfix_preview.gd` -- visual captures at large and small viewports; currently exercises only the bazooka comparison path.

## Tasks & Acceptance

**Execution:**
- [ ] `scripts/equipment_screen.gd` -- preserve display text plus normalized scores, render styled comparison rows in a dedicated bounded/scrollable area, shorten the tooltip, and fully reset comparison geometry/content on refresh.
- [ ] `tests/inventory_ui_test.gd` -- cover improvement, regression, equality, text-only changes, geometry bounds, and restoration after selection changes.
- [ ] `tests/mission_inventory_ui_test.gd` -- confirm mission inventory comparison remains navigable and does not alter live equipment behavior.
- [ ] `tests/weapon_menu_bugfix_preview.gd` -- capture standard and long robot comparisons at 1920×1080 and 960×720 so overlap/clipping is visible in regression artifacts.

**Acceptance Criteria:**
- Given two comparable items, when the user presses COMPARAR, then each changed selected value uses the correct semantic color while equal values remain neutral and before/after text stays explicit.
- Given a long comparison at the smaller supported viewport, when the comparison is displayed, then no text crosses the comparison panel or overlaps the action/reason controls.
- Given comparison mode is active, when the user selects another item, then the normal description and stats layout is restored with no stale markup or geometry.
- Given mission mode and the bazooka special case, when comparison is used with mouse, keyboard, or controller focus, then the action remains usable and gameplay state is unchanged.

## Spec Change Log

## Design Notes

Use the score already returned alongside each row by `loadout_stats()` as the semantic source of truth. A rich-text comparison node can color individual values while preserving accessible textual arrows. The comparison panel should end before the existing action row at y=454; long content must scroll inside that boundary. Normal detail mode keeps the existing description box and stats positions.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/inventory_ui_test.gd` -- expected: zero failures, including semantic colors and geometry assertions.
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/mission_inventory_ui_test.gd` -- expected: zero failures and unchanged mission behavior.
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/weapon_menu_bugfix_preview.gd` -- expected: comparison captures at both resolutions with no overlap or clipping.
- `git diff --check` -- expected: no patch errors.

**Manual checks (if no CLI):**
- Inspect the generated large/small comparison images and confirm green/red/neutral/teal values remain readable and contained above the buttons.
