---
title: 'Rebuild the title, character, and adventure screens from approved concepts'
type: 'bugfix'
created: '2026-09-30'
status: 'done'
baseline_commit: '779af10'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The shipped menus expose loose controls over a cropped background, while the approved visual concepts show finished brass and cyan structures, character portraits, and adventure cards. Character and adventure screens currently appear empty or broken.

**Approach:** Rebuild the three connected screens from the approved concept artwork with working Godot controls mapped to the visible actions. Keep the animated title scenery, preserve the exact name “Severence — Ecos do Tempo”, and show Marty in both the roster and selected-player display. A local two-player choice presents the two-player character composition before equipment.

## Boundaries & Constraints

**Always:** Keep five title actions only; use Marty as the sole currently unlocked character; retain gamepad, mouse, and keyboard navigation; preserve continue/save behavior and game launch; keep the existing title video visibly animated; make selected and disabled states understandable.

**Ask First:** Removing existing game modes or changing unlock/progression rules.

**Never:** Reintroduce Direct Expedition on the title; substitute a static screenshot for all animation; allow decorative art to consume button input.

## I/O & Edge-Case Matrix

| Scenario | Input | Expected behavior | Failure handling |
| --- | --- | --- | --- |
| New game | Title → Marty → adventure | Concept-faithful screens and live actions | Return and focus remain available |
| Local coop | Select local → confirm | Two selected Marty displays, then equipment | Locked characters stay unavailable |
| Continue unavailable | No run or save | Button appears unavailable and cannot load | New Expedition gets focus |

</frozen-after-approval>

## Code Map

- `scripts/terminal_ui.gd` — screen assembly, scaling, focus, navigation.
- `art/concept/tela-inicial-conceito-v3-severence.png` — title composition.
- `art/concept/selecao-personagem-conceito-v3.png` and `selecao-personagem-coop-conceito-v3.png` — roster compositions.
- `art/concept/selecao-aventura-conceito-v2.png` — adventure composition.
- `tests/title_screen_test.gd` — connected flow and visible-state checks.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/terminal_ui.gd` — render the approved title structure while preserving its animated scenery and five functional actions.
- [x] `scripts/terminal_ui.gd` — show the full character concept, six aligned slots, selected Marty, and a return action.
- [x] `scripts/terminal_ui.gd` — show the adventure concept with Solo, Solo + IA, local coop, back, and equipment actions; support two-player confirmation.
- [x] `tests/title_screen_test.gd` — verify the visual layers and all affected navigation paths.

**Acceptance Criteria:**
- Given the title screen, when it opens, then the approved mechanical logo/deck are visible and the scenery animates.
- Given character selection, when Marty is selected, then the roster remains visible and adventure selection opens.
- Given local coop, when the player confirms, then both sides show Marty selected before equipment opens.
- Given a supported window shape, when any of the three screens is displayed, then controls align with their painted cards and are operable.

## Spec Change Log

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/title_screen_test.gd` — zero failures.
- `tests/solo_robot_test.gd` — zero failures.
- Full `tests/*_test.gd` suite — first 19 pass; execution stalls in `inventory_ui_test.gd`, which is being changed independently.
- Captured main, characters, adventure, and two-player characters at 16:10; adventure also captured at 16:9.

## Review outcome

Three independent reviews completed. Fixed active-run protection, hero portrait mouse activation, selected-mode focus and dimming, network badge placement, and the animated sky mask. A control-remapping overflow from concurrent robot work was outside this menu patch.

## Suggested Review Order

- Approved artwork and responsive screen assembly.
  [terminal_ui.gd:249](../../scripts/terminal_ui.gd#L249)
- Character roster, adventure choice, and local coop confirmation.
  [terminal_ui.gd:344](../../scripts/terminal_ui.gd#L344)
- Original animation remains visible through the temporal sky.
  [title_concept_overlay.gdshader:1](../../shaders/title_concept_overlay.gdshader#L1)
- Connected navigation and continued-game behavior.
  [title_screen_test.gd:14](../../tests/title_screen_test.gd#L14)
