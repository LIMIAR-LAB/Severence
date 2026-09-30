---
title: 'Bring the encyclopedia into the game visual identity'
type: 'feature'
created: '2026-09-29'
status: 'in-progress'
baseline_commit: '41f296266cf478be895bd5637c8b80a77a279a30'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-enciclopedia-dinamica.md'
  - '{project-root}/docs/EQUIPAMENTO_0_17.md'
  - '{project-root}/docs/TELA_INICIAL_0_16.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The encyclopedia is functional and readable, but its flat teal panels look generic beside the game’s expressive pixel-art docks, brass machinery, temporal cyan energy, and industrial equipment interface.

**Approach:** Redesign only the encyclopedia presentation as an in-world “Temporal Archive” dossier: layered dock atmosphere, olive metal and brass framing, rivets and technical markings, cyan temporal accents, stronger entry cards, and a more dramatic record detail. Reuse existing game assets and preserve the data-driven behavior.

## Boundaries & Constraints

**Always:** Match the established palette of dark olive/blue metal, aged brass/gold, cyan energy, warm cream text, and restrained violet fracture light; preserve pixel-art filtering; retain the 1344×752 responsive stage; keep all existing categories, records, fallback behavior, scrolling, origin-aware Back behavior, and mouse/keyboard/controller navigation; keep text readable over decorative layers.

**Ask First:** Generating or commissioning new final artwork, changing the title/equipment/pause screens themselves, changing encyclopedia content, or altering discovery/progression behavior.

**Never:** Replace the data-driven catalog; bake names or descriptions into a background image; use a clean corporate-dashboard aesthetic; introduce smooth vector gradients that clash with pixel art; obscure controls with decoration; modify unrelated gameplay or art files.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Standard record | Existing monster, item, or robot | Layered dossier clearly presents category, index, portrait, title, description, and traits | N/A |
| Missing artwork | Entry resolves to no texture | Temporal silhouette/seal feels intentional, not like a placeholder bug | No empty white box or broken texture |
| Long content | Description or traits exceed the normal panel | Styled internal scroll remains visible and readable | Decoration never clips the scrollbar or text |
| Focus change | Keyboard/controller/mouse moves between tabs or entries | Brass/cyan selection language clearly follows focus and active state | Non-selected content remains legible |
| Small viewport | Stage scales below 1344×752 | Composition scales as one coherent screen | No control escapes the framed area |

</frozen-after-approval>

## Code Map

- `scripts/encyclopedia_screen.gd` -- current encyclopedia composition, styles, state binding, focus wiring, and fallback presentation.
- `assets/ui/menu.png` and `assets/ui/title/title_still.png` -- existing atmospheric identity references reusable as a subdued backdrop.
- `assets/ui/pause/pause_frame_pixellab.png` -- existing ornate brass pixel frame suitable for record imagery.
- `tests/encyclopedia_ui_test.gd` -- functional UI contract that the redesign must preserve and extend with identity markers.
- `test-output/ui-encyclopedia.png` -- real rendered screenshot used for before/after visual verification.

## Tasks & Acceptance

**Execution:**
- [ ] `scripts/encyclopedia_screen.gd` -- replace the flat composition with reusable archive chrome, industrial panels, dossier rows, intentional fallback seal, and themed control legend while leaving data/navigation contracts intact.
- [ ] `scripts/encyclopedia_screen.gd` -- integrate existing atmospheric and ornate-frame assets with nearest filtering and safe resource fallbacks.
- [ ] `tests/encyclopedia_ui_test.gd` -- assert stable semantic controls plus the new identity-bearing layers without testing fragile pixel coordinates.
- [ ] `test-output/ui-encyclopedia.png` -- regenerate and inspect a real 1280×800 capture after automated tests pass.

**Acceptance Criteria:**
- Given the encyclopedia beside the title and equipment screens, when a player sees it, then its brass, metal, cyan-energy, pixel-art, and docks-era cues visibly belong to the same game.
- Given any valid category or entry, when selection changes, then active, focused, and inactive states remain immediately distinguishable.
- Given missing art or overflowing text, when the detail renders, then the themed fallback and internal scrolling look intentional and remain usable.
- Given the existing encyclopedia and menu regression suites, when they run, then all prior navigation and data-driven behavior still passes.

## Spec Change Log

## Design Notes

The visual hierarchy should read as an artifact from the Refúgio rather than a separate application: atmospheric dock imagery at low contrast, a riveted olive-metal outer chassis, brass structural lines, cyan electrical traces, and cream dossier typography. Decoration belongs behind or around live controls. The data remains presentation-agnostic, and existing assets are reused as materials rather than stretched into an incompatible full-screen template.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/encyclopedia_ui_test.gd` -- expected: zero functional or identity-marker failures.
- Existing title-screen, equipment UI, inventory UI, and save-flow suites -- expected: zero regressions.
- `Godot_v4.7.2-stable_win64_console.exe --path . -- --capture-ui-encyclopedia --capture-tick=5` -- expected: refreshed capture and clean exit.

**Manual checks:**
- Compare the capture with `assets/ui/menu.png` and `assets/ui/equipment_v3.png`; confirm shared visual language without copying their layouts.
