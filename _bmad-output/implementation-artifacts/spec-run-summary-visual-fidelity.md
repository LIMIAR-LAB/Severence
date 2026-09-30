---
title: 'Run summary visual fidelity correction'
type: 'bugfix'
created: '2026-09-29'
status: 'done'
baseline_commit: '622e963'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-run-summary.md'
  - '{project-root}/docs/RUN_SUMMARY.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The shipped post-run screen is functionally correct but visually diverges from the approved concept: it loses the cinematic docks backdrop, dense brass chassis, oversized title and grade badge, obituary photography, illustrated typography and visual hierarchy. Generic Godot panels, low-opacity ornaments, an enlarged gameplay sprite and non-uniform scaling make it look like a fallback rather than the intended screen.

**Approach:** Rebuild the results presentation around a high-fidelity, text-free art layer derived from the approved concept, then place all changing text, values, portraits and actions as live Godot controls on top. Use uniform 16:9 scaling, dedicated illustrated obituary portraits and full-strength ornaments while retaining the existing telemetry, authority and fallback behavior.

## Boundaries & Constraints

**Always:** Treat `art/concept/resumo-pos-run-ux-v1.png` as the visual target. Preserve the current summary data contract, real rewards, controller navigation, saves and host authority. Keep dynamic titles, grade, numbers, obituary copy and buttons as live/selectable runtime content. Preserve Portuguese accents. Record generation prompts/provenance and keep the art pipeline reproducible. PixelLab remains the source of the four loot illustrations; ImageGen/local tooling owns the faithful background, chassis, portrait treatment and normalization.

**Ask First:** Any change to gameplay rewards, grade balance, obituary meaning, enemy identity or the approved information hierarchy.

**Never:** Ship the original flattened concept as the runtime screen; leave baked fake statistics or variable text in generated art; stretch the 16:9 composition non-uniformly; replace unrelated UI; weaken the existing missing-asset fallback.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|---------------------------|----------------|
| Defeat by fish | Fish is fatal source | Concept-faithful obituary card shows a large illustrated mutant-fish portrait and deterministic live copy | Unknown/missing portrait uses a styled silhouette without changing layout |
| Victory | Extraction succeeds | Same premium shell presents a live victory title, nucleus portrait and real rewards | No death cause or skull treatment appears |
| Different viewport | 16:9, 16:10, ultrawide or windowed | The 1672×941 composition scales uniformly and remains centered | Letterbox/pillarbox absorbs surplus space; no stretching |
| Art unavailable | Any faithful raster fails to load | Existing code-drawn presentation remains legible and operable | No blocked actions or invisible values |

</frozen-after-approval>

## Code Map

- `art/concept/resumo-pos-run-ux-v1.png` -- approved composition, material and color target.
- `art/source/run-summary-faithful/` -- generated clean masters, prompts, provenance and portrait sources.
- `tools/build_run_summary_assets.py` -- validate and normalize faithful masters into runtime assets.
- `assets/ui/run_summary/faithful/` -- production background, shell, obituary, badge, buttons, icons and portraits.
- `scripts/terminal_ui.gd` -- proportional canvas, art layering, live typography, controls and fallback route.
- `scripts/main.gd` -- representative death/victory capture inputs; gameplay flow remains unchanged.
- `tests/run_summary_ui_test.gd` -- layout, focus, fallback, victory/death and scaling regression coverage.
- `docs/RUN_SUMMARY.md` -- asset ownership, generation prompts and visual pipeline.

## Tasks & Acceptance

**Execution:**
- [x] `art/source/run-summary-faithful/` -- create a clean, text-free master matching the approved docks/chassis composition plus illustrated obituary portraits; preserve prompts and generation metadata.
- [x] `tools/build_run_summary_assets.py` and `assets/ui/run_summary/faithful/` -- emit deterministic 1672×941 runtime layers, validate dimensions/alpha and retain PixelLab loot art.
- [x] `scripts/terminal_ui.gd` -- replace generic normal-path panels with full-strength art, uniform scaling, concept-aligned geometry, outlined live typography and transparent interactive buttons.
- [x] `scripts/main.gd` -- capture representative defeat and victory screens without changing run rules.
- [x] `tests/run_summary_ui_test.gd` -- cover focus, fallback, portrait selection, victory treatment and aspect-ratio invariants.
- [x] `docs/RUN_SUMMARY.md` -- document the corrected visual system, ownership and rebuild/capture workflow.

**Acceptance Criteria:**
- Given the approved concept and a runtime death capture, when compared side by side, then the docks backdrop, metal chassis, title scale, grade medallion, obituary card, right-hand panels and bottom actions share the same composition and visual weight.
- Given any supported viewport, when the summary is displayed, then circles remain circular, proportions remain unchanged and all controls fit inside the centered composition.
- Given fish-caused death, when the report opens, then the portrait is a large editorial monster illustration rather than an enlarged gameplay sprite.
- Given victory or defeat, when content changes, then every variable word/value remains a live Godot control and no generated fake value is visible.
- Given controller or mouse input, when navigating the screen, then focus, hover, disabled guest state and both actions remain obvious and functional.

## Spec Change Log

- 2026-09-29 — Replaced the generic normal path with a text-free 1672×941
  cinematic shell, editorial fish/victory portraits, uniform centered scaling,
  live outlined controls and preserved code-drawn fallback. Builder, tests,
  provenance, defeat/victory captures and documentation were updated.
- 2026-09-29 — Review patches hardened the complete-asset gate, restored the
  legacy fallback at its original visual size, added portrait and text-overflow
  containment, validated alpha in the builder, strengthened title/grade weight
  and exercised real fallback plus 16:10/ultrawide placement in tests.

## Design Notes

Render order: opaque cinematic backdrop → clean console/surfaces → live portraits, icons, labels and values → foreground metal highlights → focus/hover glow. The reference master is 1672×941 (approximately 16:9); scale it uniformly with `min(viewport / master)` rather than the menu stage's current asymmetric 1280×800 transform. Generated art must contain empty content zones, not erased text patches over the flattened concept.

## Verification

**Commands:**
- `python tools/build_run_summary_assets.py` -- expected: all faithful masters validate and runtime outputs rebuild.
- `godot --headless --path . --script tests/run_summary_ui_test.gd` -- expected: zero failures.
- Full `tests/*_test.gd` suite -- expected: zero regressions.
- `godot --path . -- --capture-ui-summary --capture-name=run-summary-faithful` -- expected: readable 1672×941-equivalent capture with no clipping or distortion.

**Manual checks:**
- Compare the runtime capture beside the approved concept at equal height; verify composition, material density, title/grade prominence, portrait quality and button hierarchy.

## Suggested Review Order

**Runtime presentation**

- Start with the live overlay that reconstructs the approved concept composition.
  [`terminal_ui.gd:380`](../../scripts/terminal_ui.gd#L380)

- Uniform master-canvas placement prevents distortion across display aspect ratios.
  [`terminal_ui.gd:61`](../../scripts/terminal_ui.gd#L61)

- Complete-asset gating preserves the operable legacy fallback under failures.
  [`terminal_ui.gd:361`](../../scripts/terminal_ui.gd#L361)

- Summary routing selects faithful or recovery presentation without touching gameplay.
  [`terminal_ui.gd:467`](../../scripts/terminal_ui.gd#L467)

**Art pipeline and provenance**

- Deterministic builder validates dimensions, alpha and PixelLab-derived loot outputs.
  [`build_run_summary_assets.py:109`](../../tools/build_run_summary_assets.py#L109)

- Generation prompts preserve reproducibility for the shell and editorial portraits.
  [`README.md:10`](../../art/source/run-summary-faithful/README.md#L10)

- User-facing documentation explains ownership, rebuilding and capture workflows.
  [`RUN_SUMMARY.md:45`](../../docs/RUN_SUMMARY.md#L45)

**Verification peripherals**

- Regression test exercises faithful, fallback, viewport, focus and victory paths.
  [`run_summary_ui_test.gd:12`](../../tests/run_summary_ui_test.gd#L12)

- Capture-only flag supplies deterministic death and victory visual fixtures.
  [`main.gd:159`](../../scripts/main.gd#L159)

