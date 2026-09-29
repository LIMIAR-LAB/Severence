---
title: 'Unify the title screen'
type: 'refactor'
created: '2026-09-29'
status: 'in-review'
baseline_commit: '1b938c74108d518d569049316856852211df8201'
context:
  - '{project-root}/docs/architecture.md'
  - '{project-root}/docs/TELA_INICIAL_0_16.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The title screen looks patched together because baked-in menu artwork, extracted button plates, and live replacement labels overlap. Every state-specific correction adds another visual layer, weakens hierarchy, and makes the screen harder to maintain.

**Approach:** Keep the animated dock artwork and the game logo as the cinematic identity, but replace the entire old control area with one live, cohesive industrial console. Give clear priority to starting/resuming play, group secondary expedition routes, and move settings, exit, build information, and connection status into a restrained footer.

## Boundaries & Constraints

**Always:** Preserve all seven existing actions and their callbacks; keep keyboard, mouse, and controller focus navigation; expose disabled states for Continue and Load Game; retain the video loop with the still-image/headless fallback; scale and center with the current 1344×752 stage; use Portuguese player-facing labels; keep controls legible over every video frame.

**Ask First:** Replacing the source video or logo artwork, changing the navigation flow after selecting an action, removing an action, or introducing a new external font or art dependency.

**Never:** Overlay more extracted `btn_N` image patches, edit generated `.import` metadata by hand, alter gameplay/save/network semantics, or redesign screens beyond the title screen.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Fresh boot | No active or saved expedition | New Expedition has primary emphasis; Continue and Load are visibly unavailable | Focus skips disabled actions and lands on New Expedition |
| Active run | `app.playing` is true | Continue is enabled and becomes the first primary action | Closing the menu resumes without changing run state |
| Saved run | Save exists | Load Game is enabled in the expedition group | Failed loading remains delegated to the existing app flow |
| Network state | Status differs from `OFFLINE` | Current status appears in the console footer without covering artwork | Long status text is clipped or fitted within its reserved area |
| Missing title media | Still or video unavailable | Existing procedural menu background remains usable behind the live console | All actions remain present and operable |

</frozen-after-approval>

## Code Map

- `scripts/terminal_ui.gd` -- constructs the title background, live controls, focus behavior, action callbacks, and responsive stage placement.
- `tests/title_screen_test.gd` -- verifies title actions, disabled states, initial focus, media fallback, and destination screens.
- `assets/ui/title/title_still.png` -- static fallback and visual baseline; retained without baking new controls into code-owned UI.
- `assets/ui/title/title_loop.ogv` -- animated cinematic backdrop; retained as a decorative layer only.
- `docs/TELA_INICIAL_0_16.md` -- title-screen behavior and maintenance documentation to update after the refactor.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/terminal_ui.gd` -- replace extracted button plates with one live console and reusable title-button styling; establish primary, secondary, utility, disabled, hover, focus, and pressed states while preserving callbacks.
- [x] `scripts/terminal_ui.gd` -- make the background fallback independent of button-image availability and keep connection/build metadata in a stable footer.
- [x] `tests/title_screen_test.gd` -- update structural assertions for the unified console and cover fresh, active-run, saved-run, focus, and navigation states.
- [x] `docs/TELA_INICIAL_0_16.md` -- document the new layer ownership and remove obsolete plate-generation guidance.

**Acceptance Criteria:**
- Given a fresh launch, when the title appears, then it reads as one composition with a single dominant New Expedition action and no visible patched labels or mismatched button plates.
- Given mouse, keyboard, or controller input, when focus moves among enabled actions, then exactly one action has a clear highlighted state and disabled actions cannot receive focus.
- Given an active or saved expedition, when the title is rebuilt, then Continue and Load Game independently reflect the correct availability without changing layout.
- Given any supported aspect ratio, when the stage is fitted, then the console, logo, and cinematic subject remain inside the intended 1344×752 composition without overlap or cropped controls.
- Given missing video playback or headless execution, when the title is built, then the still/procedural fallback and every live action remain functional.

## Spec Change Log

- 2026-09-29: console unificado implementado e validado em modo headless, incluindo estados sem expedição e com expedição ativa.

## Design Notes

The console should be an intentional foreground object, not a translucent patch: one outer frame, one interior rhythm, and one footer. Use a large full-width primary action; place expedition variants in a compact secondary group; keep Options and Exit visually quiet. Colors should reuse the existing oxidized green, brass, cyan energy, and near-black palette so the interface belongs to the dock scene while remaining code-owned and stateful.

## Verification

**Commands:**
- `Godot --headless --path . --script tests/title_screen_test.gd` -- expected: all title-screen assertions pass with zero failures.
- `Godot --path . -- --capture-ui-main` -- expected: a current title screenshot is saved for visual inspection.

**Manual checks (if no CLI):**
- Inspect the captured title at 1280×800 and 1920×1080; confirm hierarchy, text clarity, safe margins, and that no baked button text shows through.
- Navigate the full console once with a controller and once with a mouse; confirm focus order and hover/focus parity.
