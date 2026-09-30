---
title: 'Add a data-driven encyclopedia for monsters, items, and robots'
type: 'feature'
created: '2026-09-29'
status: 'done'
baseline_commit: '4fec09402a641a622c014e1e05047bc1127bcd92'
context:
  - '{project-root}/docs/architecture.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The game has monsters, equipment, inventory items, and robots spread across code and separate JSON files, but players have no single place to learn what they are. Adding a new encyclopedia entry would currently require UI code changes.

**Approach:** Add a data-driven encyclopedia with Monster, Item, and Robot categories, accessible from the title screen and pause menu. Entries live in one JSON catalog so future content can be added gradually without changing the encyclopedia UI.

## Boundaries & Constraints

**Always:** Keep encyclopedia content in a standalone UTF-8 JSON file; validate malformed entries and skip them safely; support mouse, keyboard, and controller focus; show a readable fallback when an optional image is missing; preserve all existing menu and gameplay behavior; use the existing 1344×752 menu layout and visual language.

**Ask First:** Adding discovery/hidden-entry progression, changing gameplay balance, creating new final artwork, or replacing existing item/equipment data as the gameplay source of truth.

**Never:** Duplicate encyclopedia text inside the UI script; make encyclopedia entries affect combat or inventory behavior; require every entry to have artwork; modify unrelated dirty files; expose internal IDs to players.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Browse catalog | Valid entries in all three categories | Category tabs, entry list, image/fallback, description, traits, and navigation render correctly | N/A |
| Grow catalog | A valid JSON entry is appended | The entry appears automatically in its category in catalog order | N/A |
| Missing image | Entry has an empty or unavailable image path | Detail panel shows a styled initial/silhouette fallback | No load error interrupts the screen |
| Invalid entry | Missing/duplicate ID, unsupported category, or blank name | Other entries remain usable | Invalid record is excluded by the loader |
| Empty category | No valid entries for a category | Screen shows an explicit empty-state message | Controls remain usable and Back still works |

</frozen-after-approval>

## Code Map

- `data/enciclopedia.json` -- new append-friendly catalog for monster, item, and robot entries.
- `scripts/encyclopedia_data.gd` -- new cached loader, validation, category lookup, and safe image-path helpers.
- `scripts/encyclopedia_screen.gd` -- new self-contained browse/detail UI with tabs, list selection, fallback art, and focus wiring.
- `scripts/terminal_ui.gd` -- small routing integration for title/pause entry points and Back behavior.
- `tests/encyclopedia_data_test.gd` -- catalog contract, ordering, validation, and known-entry coverage.
- `tests/encyclopedia_ui_test.gd` -- screen routing, categories, detail rendering, fallback, and focus integration.
- `scripts/main.gd` -- include the encyclopedia page in existing UI capture routing only if needed by verification.

## Tasks & Acceptance

**Execution:**
- [x] `data/enciclopedia.json` -- seed representative entries from current monsters, inventory/equipment, Titan, and Spectre while keeping the schema append-only and documented in-file.
- [x] `scripts/encyclopedia_data.gd` -- expose only validated entries and deterministic per-category queries so UI code is content-agnostic.
- [x] `scripts/encyclopedia_screen.gd` -- build the three-category browsing experience with safe optional images, readable details, and full focus navigation.
- [x] `scripts/terminal_ui.gd` -- add encyclopedia routes from title and pause, remember the correct return destination, and preserve existing control behavior.
- [x] `tests/encyclopedia_data_test.gd` and `tests/encyclopedia_ui_test.gd` -- cover the I/O matrix and menu integration.

**Acceptance Criteria:**
- Given the title screen or an offline paused expedition, when the player opens the encyclopedia, then the same catalog appears and Back returns to the originating screen.
- Given mouse, keyboard, or controller input, when the player changes category or selection, then focus and detail content follow the active entry without requiring a pointer.
- Given a developer appends a valid catalog record, when the game next loads the encyclopedia, then the record is displayed without a UI code change.
- Given existing title, pause, inventory, and equipment flows, when their regression tests run, then their prior behavior remains intact.

## Spec Change Log

- 2026-09-29 — Integração com o deck cinematográfico de cinco ações: acesso inicial movido para Opções; acesso pela pausa preservado.

## Design Notes

The JSON catalog is presentation metadata, not a second gameplay database. It may reference existing asset paths and describe current behavior, while simulation and equipment/inventory files remain authoritative for mechanics. The loader owns schema tolerance; the screen receives only clean dictionaries and therefore does not scatter defensive parsing across controls.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/encyclopedia_data_test.gd` -- expected: all catalog tests pass.
- `Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/encyclopedia_ui_test.gd` -- expected: all encyclopedia UI tests pass.
- Existing title-screen, equipment UI, inventory UI, and save-flow test scripts -- expected: zero regressions.

**Manual checks (if no CLI):**
- Open from title and pause; browse all three categories; confirm Back destination, readable 1280×800 layout, and missing-image fallback.

## Suggested Review Order

**Entry point and browsing**

- Start with the complete category, list, detail, fallback, scrolling, and focus composition.
  [`encyclopedia_screen.gd:26`](../../scripts/encyclopedia_screen.gd#L26)

- Category rebuilding stays content-agnostic and preserves selection per category.
  [`encyclopedia_screen.gd:113`](../../scripts/encyclopedia_screen.gd#L113)

**Data contract and safety**

- The append-friendly catalog documents its own minimal schema beside the content.
  [`enciclopedia.json:3`](../../data/enciclopedia.json#L3)

- Validation rejects malformed records, unsafe IDs, duplicates, and invalid ordering values.
  [`encyclopedia_data.gd:20`](../../scripts/encyclopedia_data.gd#L20)

- Optional artwork accepts only loadable textures and otherwise activates the fallback.
  [`encyclopedia_data.gd:67`](../../scripts/encyclopedia_data.gd#L67)

**Menu integration**

- A single route remembers whether the player came from title or pause.
  [`terminal_ui.gd:345`](../../scripts/terminal_ui.gd#L345)

- Escape returns to the originating menu without accidentally resuming gameplay.
  [`main.gd:374`](../../scripts/main.gd#L374)

**Verification**

- Catalog tests cover ordering, malformed input, growth, and artwork boundaries.
  [`encyclopedia_data_test.gd:10`](../../tests/encyclopedia_data_test.gd#L10)

- UI tests cover origin routing, pointer-free focus, fallback, growth, and empty categories.
  [`encyclopedia_ui_test.gd:15`](../../tests/encyclopedia_ui_test.gd#L15)

- Title regression coverage now includes the sixth live action.
  [`title_screen_test.gd:15`](../../tests/title_screen_test.gd#L15)
