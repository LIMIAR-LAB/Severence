---
title: 'Industrial visual overhaul for Equipment menus'
type: 'feature'
created: '2026-09-30'
status: 'done'
baseline_commit: '1b73d69daa2fa7fe1b81d3c3ad0aeb0dac516d38'
context:
  - 'docs/INVENTARIO.md'
  - 'docs/EQUIPAMENTO_0_17.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The pre-mission Equipment and in-mission Inventory are functional, but their flat technical presentation does not match the supplied concept. They lack the illustrated dieselpunk workshop atmosphere, strong riveted chrome, icon-led navigation, large item showcase, visual stat bars, and the equipped-loadout composition shown in the reference.

**Approach:** Recompose the shared Equipment screen around the reference hierarchy: contextual workshop/docks backdrop, ornate modular metal panels, icon-and-label tabs and filters, a 5×3 item grid, a large selected-item showcase with readable stats, and a compact equipped-loadout area. Keep preparation and mission as two data contexts of the same visual shell.

## Boundaries & Constraints

**Always:** preserve all current inventory, loadout, save, network-authority, pause and return behavior; keep runtime text and values authoritative; support mouse, keyboard and controller with visible focus; keep Portuguese player-facing copy; use the existing 1344×752 logical canvas and proportional scaling; visually verify both menu contexts at 1920×1080.

**Ask First:** remove or merge a functional tab, change gameplay statistics/economy, replace existing character identity art, or introduce a new item mechanic.

**Never:** use the flattened concept image as the interactive background; bake dynamic text or item quantities into raster art; duplicate simulation values in UI-only data; hide required information for visual fidelity; contaminate persistent inventory with mission resources.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Pre-mission | Equipment opens from preparation | Workshop backdrop, full industrial shell, Inventory selected, persistent loadout shown | Locked/empty slots remain legible and navigable |
| Active mission | `B` or Pause opens Mission Inventory | Docks backdrop, same shell, carried/found items and current loadout shown | Simulation stays paused offline; Back returns to Pause |
| Dense inventory | More than 15 visible items | 5×3 grid paginates without clipping or focus loss | Page controls expose every valid item |
| Selected item | Item has art and numeric attributes | Large art, rarity, description, bars/values and valid actions update together | Missing art falls back to its catalog icon; non-actions explain why |
| Small/ultrawide viewport | Window differs from 16:9 | Whole logical canvas remains usable and centered | Background may crop/letterbox; interactive content may not clip |

</frozen-after-approval>

## Code Map

- `scripts/equipment_screen.gd` -- shared procedural shell, visual composition, grid, details, loadout strip and focus graph.
- `scripts/terminal_ui.gd` -- Equipment screen placement, scaling and contextual routes.
- `data/inventario.json` -- item icon/detail-art references; quantities remain external.
- `assets/ui/equipamento/` -- generated modular chrome/pictograms and existing item/card art.
- `assets/environment/refuge/refuge_bg.png` -- pre-mission workshop backdrop.
- `assets/environment/docks12/entry/desembarque_painted_v1.png` -- mission backdrop.
- `tests/inventory_ui_test.gd` -- structural and navigation contracts for the redesigned shell.
- `tests/mission_inventory_ui_test.gd` -- live mission data, pause safety and contextual presentation.
- `tests/inventory_preview.gd` -- deterministic 1920×1080 captures for both contexts.
- `docs/INVENTARIO.md` -- final visual hierarchy and asset-source documentation.

## Tasks & Acceptance

**Execution:**
- [x] `assets/ui/equipamento/industrial/` -- create a project-owned modular dieselpunk atlas for panel chrome and ten tab/filter pictograms; reuse existing character, item and environment art elsewhere.
- [x] `scripts/equipment_screen.gd` -- implement the reference hierarchy, 5×3 pagination, contextual backdrop, large item art, data-backed stat visualization and equipped-loadout composition without changing domain behavior.
- [x] `scripts/terminal_ui.gd` -- preserve routes and make the richer shell scale and layer correctly across supported viewports.
- [x] `data/inventario.json` -- replace traceable placeholder icons with existing project assets and add presentation-only art references where needed.
- [x] `tests/inventory_ui_test.gd`, `tests/mission_inventory_ui_test.gd`, `tests/inventory_preview.gd` -- lock visible nodes, focus, pagination, fallbacks, live updates and both 1920×1080 outputs.
- [x] `docs/INVENTARIO.md` -- document the new visual system, contextual backgrounds and remaining provisional art.

**Acceptance Criteria:**
- Given either Equipment context, when the screen opens at 1920×1080, then its composition recognizably matches the supplied reference hierarchy and has no overlapping or clipped interactive content.
- Given mouse, keyboard or controller, when navigating tabs, filters, a 5×3 grid, page controls and actions, then every available control is reachable with visible focus and deterministic neighbors.
- Given any selected catalog or mission item, when selection changes or live quantities update, then showcase art, rarity, description, stats, action state and equipped indicators remain mutually consistent.
- Given the existing save, network, inventory and equipment regressions, when the complete headless suite runs, then all tests pass without changing gameplay semantics.

## Spec Change Log

## Design Notes

Use existing `refuge_bg.png` and `desembarque_painted_v1.png` beneath a dark teal veil so the world remains visible at the edges. Generate only the missing modular UI chrome and pictograms; reuse existing 256/360px item cards, equipment icons and Marty/robot/armor art. Runtime controls sit above NinePatch panels, never above a flattened screenshot. Tabs retain their five functional pages, while the Inventory page carries the closest one-screen match to the supplied concept.

## Verification

**Commands:**
- Godot headless targeted UI, mission, controller, persistence and equipment tests -- expected: zero failures.
- Complete `tests/*_test.gd` suite -- expected: every script exits 0.
- Godot preview capture for preparation and mission at 1920×1080 -- expected: both PNGs render the industrial shell without clipping and visibly match the reference hierarchy.

**Results:**
- Inventory, mission inventory, equipment, controller and save-flow tests pass with zero failures.
- Complete suite: 46/47 scripts pass; the pre-existing missing generated WAV fixture failure is recorded in `deferred-work.md`.
- Preparation and mission previews render at exactly 1920×1080 and were visually inspected after `frame_post_draw`.
- Independent review fixed pagination focus, empty-filter navigation, normalized stat bars and visible rarity/selection chrome.

## Suggested Review Order

**Visual shell and hierarchy**

- Establishes contextual scenery, industrial chrome and the shared five-tab entry point.
  [`equipment_screen.gd:98`](../../scripts/equipment_screen.gd#L98)

- Rebuilds Inventory around the 5×3 grid and compact equipped-loadout strip.
  [`equipment_screen.gd:227`](../../scripts/equipment_screen.gd#L227)

- Presents catalog art, authoritative values, normalized bars and contextual actions.
  [`equipment_screen.gd:399`](../../scripts/equipment_screen.gd#L399)

**Interaction and scaling**

- Defines deterministic focus routes for populated, paginated and empty states.
  [`equipment_screen.gd:322`](../../scripts/equipment_screen.gd#L322)

- Keeps the 1344×752 shell centered and proportionally scaled by the host menu.
  [`terminal_ui.gd:94`](../../scripts/terminal_ui.gd#L94)

**Catalog and documentation**

- Connects items to existing project-owned showcase art and resource icons.
  [`inventario.json:5`](../../data/inventario.json#L5)

- Records contextual backgrounds, modular assets and remaining provisional content.
  [`INVENTARIO.md:23`](../../docs/INVENTARIO.md#L23)

**Verification**

- Exercises empty-filter and real pagination-focus edge cases.
  [`inventory_ui_test.gd:37`](../../tests/inventory_ui_test.gd#L37)

- Waits for final rendering before saving both 1920×1080 visual proofs.
  [`inventory_preview.gd:11`](../../tests/inventory_preview.gd#L11)
