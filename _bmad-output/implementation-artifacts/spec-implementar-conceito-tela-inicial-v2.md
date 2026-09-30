---
title: 'Implement the new full-screen title concept'
type: 'feature'
created: '2026-09-29'
status: 'done'
baseline_commit: 'c9a104ee601eeb63377dbbb285f5d9be830e9b9e'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-unificar-tela-inicial.md'
  - '{project-root}/docs/architecture.md'
  - '{project-root}/docs/TELA_INICIAL_0_16.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The current title still reads as a repaired sidebar placed over artwork. The approved concept replaces that composition entirely, and the user explicitly wants Direct Expedition removed.

**Approach:** Reframe the existing animated dock footage as a full-screen cinematic background, then recreate the approved concept as a single bottom command deck plus a compact upper-left title lockup. Keep only New Expedition, Continue, Online, Options, and Exit; Continue absorbs saved-game loading.

## Boundaries & Constraints

**Always:** Preserve the existing animated `title_loop.ogv`; use `title_still.png` or the procedural background when playback is unavailable; keep the five visible actions keyboard-, mouse-, and controller-operable; render Portuguese labels; preserve current destination flows for New Expedition, Online, Options, and Exit; make Continue resume an active run first and otherwise load a valid saved run; keep the generated concept image as the visual reference rather than displaying it as a static replacement for animation.

**Ask First:** Replacing or regenerating the source video, changing screens beyond the title, removing save loading, or changing what New Expedition/Online/Options do.

**Never:** Show Direct Expedition on the title; show a separate Load Game button; restore the old vertical sidebar; distort the animated background non-uniformly; bake interaction state into several unrelated image patches; edit `.import` files by hand.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fresh boot | No active run and no save | New Expedition is primary; Continue is disabled | Focus starts on New Expedition |
| Active run | `app.playing` is true | Continue is enabled, primary, and resumes the current run | Active state takes precedence over any save |
| Saved run | No active run; valid save exists | Continue is enabled and loads the saved run | Existing load validation remains authoritative |
| No video playback | Headless or missing video | Cropped/reframed still remains full-screen behind the deck | Missing still falls back to `MenuBackground` |
| Network status | Any short or long status | Status fits inside the right side of the command deck | Long text trims without covering actions |

</frozen-after-approval>

## Code Map

- `art/concept/tela-inicial-conceito-v2.png` -- approved visual target for composition, hierarchy, materials, and spacing.
- `scripts/terminal_ui.gd` -- title background crop, title lockup, command deck, callbacks, state styling, and focus graph.
- `tests/title_screen_test.gd` -- deterministic fresh/active/saved state, removed-action, focus, and callback coverage.
- `tests/save_game_flow_test.gd` -- saved expedition integration currently reaches the separate Load button and must follow Continue instead.
- `docs/TELA_INICIAL_0_16.md` -- player-facing behavior and asset ownership documentation.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/terminal_ui.gd` -- crop and uniformly scale the scene portion of the existing video/still to fill the stage; rebuild the title as one upper lockup and one bottom command deck matching the approved concept.
- [x] `scripts/terminal_ui.gd` -- reduce the main menu to five actions, route Continue to active-run resume or saved-run load, and rebuild explicit focus navigation without the seed/load controls.
- [x] `tests/title_screen_test.gd` and `tests/save_game_flow_test.gd` -- verify fresh, active, saved, hover/focus, destinations, removed actions, and saved-run loading through Continue.
- [x] `docs/TELA_INICIAL_0_16.md` -- document the full-screen composition and five-action contract.

**Acceptance Criteria:**
- Given the title opens, when the background renders, then no portion of the legacy sidebar or stacked plates is visible and the dock scene fills the composition without non-uniform stretching.
- Given the main menu is inspected, when controls are enumerated, then exactly five live actions exist and neither Direct Expedition nor a separate Load button appears.
- Given no run exists, when a valid save becomes available, then Continue enables and loads it without changing the deck layout.
- Given an active run exists, when Continue is pressed, then it resumes that run instead of loading the save.
- Given mouse or controller navigation, when selection changes, then exactly one action is highlighted and traversal follows the visual deck order.

## Spec Change Log

## Design Notes

The reference uses one visual gesture: the title belongs to the environment, while every action belongs to one low command deck. The runtime implementation may use code-native brass/cyan styling instead of reproducing every pixel, but it must preserve that silhouette, horizontal hierarchy, and full-screen breathing room. Background reframing should crop the old sidebar out at the source layer rather than covering it with another panel.

## Verification

**Commands:**
- `Godot --headless --path . --script tests/title_screen_test.gd` -- expected: all title composition/state/navigation checks pass.
- `Godot --headless --path . --script tests/save_game_flow_test.gd` -- expected: saving and Continue-based loading pass.
- `Godot --path . -- --capture-ui-main` -- expected: full-screen dock scene, new lockup, one bottom deck, and no legacy sidebar.

**Manual checks (if no CLI):**
- Compare the capture against `art/concept/tela-inicial-conceito-v2.png` at 1280×800 and 1920×1080.

## Suggested Review Order

**Composition and navigation**

- Start with the five-action deck and state-dependent Continue behavior.
  [`terminal_ui.gd:192`](../../scripts/terminal_ui.gd#L192)

- Review uniform aspect-cover compensation for the animated title scene.
  [`terminal_ui.gd:57`](../../scripts/terminal_ui.gd#L57)

- Inspect source cropping, video placement, and fallback selection.
  [`terminal_ui.gd:148`](../../scripts/terminal_ui.gd#L148)

**Fallback and contract**

- Confirm the procedural fallback also removes the painted legacy sidebar.
  [`menu_background.gd:22`](../../scripts/menu_background.gd#L22)

- Read the documented five-action player contract.
  [`TELA_INICIAL_0_16.md:17`](../../docs/TELA_INICIAL_0_16.md#L17)

**Verification**

- Follow deterministic fresh, active, saved, focus, and exact-count coverage.
  [`title_screen_test.gd:15`](../../tests/title_screen_test.gd#L15)

- Verify saved expeditions now load through Continue.
  [`save_game_flow_test.gd:40`](../../tests/save_game_flow_test.gd#L40)
