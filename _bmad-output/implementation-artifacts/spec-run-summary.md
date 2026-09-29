---
title: 'Post-run summary and obituary'
type: 'feature'
created: '2026-09-29'
status: 'done'
baseline_commit: '1b938c7'
context:
  - '{project-root}/docs/ARQUITETURA_ROGUELIKE.md'
  - '{project-root}/docs/architecture.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Runs currently jump directly to the Refuge on party death or extraction, so the player never sees what was achieved, earned, or caused the end of the expedition. The game needs a memorable results screen that reports time, progress, enemies defeated, rewards, performance grade, and a humorous contextual obituary.

**Approach:** Capture an immutable run summary before returning the simulation to the Refuge, present it in a controller-friendly Godot screen matching the approved concept, and split production between PixelLab-authored ornament/loot art and deterministic local UI/assets.

## Boundaries & Constraints

**Always:** Preserve the existing 1344×752 UI stage, seeded-run determinism, offline saves, host-authoritative networking, and current arena restart behavior. Runtime text, values, grades, buttons, focus states, and obituary copy must remain live Godot controls. Preserve PixelLab source/provenance and generate normalized runtime assets reproducibly. Show the same captured summary to both online peers.

**Ask First:** Any change to rewards, balance, save migration, enemy identity, or the established visual concept; any paid PixelLab operation whose quoted cost materially exceeds the minimum asset set.

**Never:** Bake variable text or fake statistics into background art; use the full concept image as the runtime screen; let a network guest mutate run state; replace unrelated assets; change arena defeat behavior; commit generated Godot `.import` churn unrelated to this feature.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|---------------------------|----------------|
| Party defeat | All active actors die during a run | Capture defeat summary and obituary, return simulation to Refuge, then open summary | Unknown killer uses a deterministic fallback obituary and icon |
| Successful extraction | Boss defeated and extraction used | Capture victory summary, rewards, grade, and celebratory report | Reward is granted exactly once |
| Online run | Host ends the run | Host snapshot propagates one identical summary to guest | Guest actions cannot start a new run |
| Old or resumed save | Summary fields are absent or run is resumed | Existing saves load; active-run counters continue when present | Missing fields initialize safely |
| Asset unavailable | PixelLab decoration/icon fails to load | Functional code-drawn panels and existing enemy art remain usable | No broken texture or blocked flow |

</frozen-after-approval>

## Code Map

- `scripts/simulation.gd` -- run telemetry, damage attribution, immutable result capture, deterministic grade/obituary, snapshot fields.
- `scripts/main.gd` -- one-shot summary presentation, immediate progress save, capture flag, host-authoritative restart actions.
- `scripts/terminal_ui.gd` -- live results layout, controller focus, navigation and fallbacks.
- `tools/build_run_summary_assets.py` -- deterministic normalization/atlas pipeline for source art.
- `art/source/pixellab/run-summary/` -- PixelLab source exports and provenance record.
- `assets/ui/run_summary/` -- normalized runtime frame, slots, loot art and semantic icons.
- `tests/run_summary_test.gd` -- simulation, attribution, grading and snapshot coverage.
- `tests/run_summary_ui_test.gd` -- UI content, focus, actions and online authority coverage.
- `docs/RUN_SUMMARY.md` -- asset ownership, data contract, obituary rules and implementation notes.

## Tasks & Acceptance

**Execution:**
- [x] `art/source/pixellab/run-summary/` -- generate a text-free ornamental UI sheet and four transparent loot icons through PixelLab; retain job ids, seeds, prompts and source outputs.
- [x] `tools/build_run_summary_assets.py` and `assets/ui/run_summary/` -- normalize PixelLab outputs and create exact semantic icons/fallback decoration locally.
- [x] `scripts/simulation.gd` -- collect kills, damage dealt/received, max streak, opened chests and killer source; finish runs through a single captured-summary path.
- [x] `scripts/main.gd` and `scripts/terminal_ui.gd` -- display the summary once, save gains, support New Expedition/Return to Refuge, controller focus, captures and host authority.
- [x] `tests/run_summary_test.gd` and `tests/run_summary_ui_test.gd` -- cover matrix scenarios and regressions.
- [x] `docs/RUN_SUMMARY.md` and `README.md` -- document asset split, formulas, commands, controls and shipped behavior.

**Acceptance Criteria:**
- Given a run ends, when the final state is captured, then time, progress, kills, loot, grade, damage, max combo, outcome and seed remain stable after the simulation returns to the Refuge.
- Given a fish projectile is the fatal hit, when the summary opens, then the obituary identifies the mutant fish and selects a deterministic humorous variation.
- Given extraction succeeds, when rewards are captured, then persistent fragments and clear count are granted once and displayed accurately.
- Given a controller, when the summary opens, then the primary action has focus and every action is reachable without a mouse.
- Given an online guest, when the shared summary is visible, then its numbers match the host and the guest cannot mutate or restart the run.
- Given PixelLab runtime art is missing, when the screen builds, then the complete flow remains legible and functional through deterministic fallbacks.

## Spec Change Log

- 2026-09-29 — Review patches kept intent intact: real rewards replaced proxy
  values; time entered the grade; host/guest transition, retry state, victory
  presentation, packed-resource loading and secret-room progress were hardened.

## Design Notes

PixelLab owns ornamental authorship only: the report frame, obituary plate, grade ring, loot slot/button plates, and four loot illustrations. Local tooling owns sizing, transparency, semantic glyphs, enemy portrait extraction and fallbacks. Godot owns all variable content and interaction. Progress percentage is based on discoverable run rooms plus boss/extraction milestones; grade is a pure deterministic function of outcome, progress, time, kills and optional objectives. Obituary selection is seeded from the run seed and fatal-source key, so replays and network peers agree.

## Verification

**Commands:**
- `godot --headless --path . --script tests/run_summary_test.gd` -- expected: zero failures.
- `godot --headless --path . --script tests/run_summary_ui_test.gd` -- expected: zero failures.
- `godot --headless --path . --editor --quit` -- expected: all assets import without parse or texture errors.
- `godot --path . -- --capture-ui-summary` -- expected: readable 1344×752 results capture with no clipping.
- Full `tests/*_test.gd` suite -- expected: zero regressions.

**Manual checks:**
- Compare the runtime capture with `art/concept/resumo-pos-run-ux-v1.png`; verify hierarchy, Portuguese accents, controller focus and missing-asset fallback.

**Recorded result (2026-09-29):** 38/38 project tests passed, both focused
summary suites passed, network host/client integration passed without engine
errors, the asset builder completed, metadata parsed, and the 1344×752 runtime
capture was visually inspected.

## Suggested Review Order

**Result capture and authority**

- Centralizes immutable outcome, real rewards, grading and obituary selection.
  [`simulation.gd:397`](../../scripts/simulation.gd#L397)

- Opens each result once and keeps restart authority with the host.
  [`main.gd:209`](../../scripts/main.gd#L209)

- Reconciles host snapshots so guests leave the report when play resumes.
  [`main.gd:300`](../../scripts/main.gd#L300)

**Presentation and assets**

- Builds the controller-first report entirely from live Godot controls.
  [`terminal_ui.gd:318`](../../scripts/terminal_ui.gd#L318)

- Loads packed resources first while retaining clean-install PNG fallback.
  [`terminal_ui.gd:290`](../../scripts/terminal_ui.gd#L290)

- Rebuilds normalized PixelLab ornament and deterministic local fallbacks.
  [`build_run_summary_assets.py:81`](../../tools/build_run_summary_assets.py#L81)

**Verification and documentation**

- Exercises defeat, victory, determinism, rewards, saves and telemetry edges.
  [`run_summary_test.gd:10`](../../tests/run_summary_test.gd#L10)

- Exercises focus, actions, guest authority, snapshot resume and fallback.
  [`run_summary_ui_test.gd:9`](../../tests/run_summary_ui_test.gd#L9)

- Records formulas, ownership, rebuild commands and shipped behavior.
  [`RUN_SUMMARY.md:1`](../../docs/RUN_SUMMARY.md#L1)
