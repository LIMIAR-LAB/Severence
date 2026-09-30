---
title: 'Consolidate the official name Severence — Ecos do Tempo'
type: 'chore'
created: '2026-09-29'
status: 'done'
baseline_commit: '61ca44f586371900532ed636a550582a5ea91ae6'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The project still exposes the former working title “Marty — Fraturas do Tempo” in runtime UI, application metadata, the Windows launcher, and canonical documentation. Some newer materials already use “Severence”, but punctuation is inconsistent and the old title remains baked into legacy background art.

**Approach:** Adopt the exact official display name **“Severence — Ecos do Tempo”** everywhere the product is identified, create an updated title-screen concept with the new logo, update the live title lockup without disturbing the animated background, prevent active secondary screens from exposing baked legacy branding, and retain “fraturas” only where it describes the story world or historical artifacts.

## Boundaries & Constraints

**Always:** Preserve the spelling “Severence” exactly as supplied; use the em-dash form “Severence — Ecos do Tempo” for the official title; keep Marty as the protagonist; keep the animated title background; preserve narrative references to temporal fractures; keep existing navigation and gameplay behavior unchanged.

**Ask First:** Replacing raster art beyond the approved new title-screen concept, renaming historical files, changing the protagonist, or altering the story meaning of “fraturas”.

**Never:** Correct the supplied name to “Severance”; globally replace every occurrence of “fraturas”; leave the old product title visible in an active screen; edit completed implementation specs solely to rewrite their historical context.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Main menu | Title screen opens with animated or still fallback background | Live lockup reads “SEVERENCE” and “ECOS DO TEMPO” without clipping; footer uses the official title | Static fallback preserves the same live title and layout |
| Secondary menu | A menu previously displayed the full legacy background image | No old baked product title is visible behind the active panel | Use the existing unbranded crop/fallback rather than deleting legacy art |
| Narrative text | “fraturas” refers to temporal anomalies | The narrative term remains unchanged | Repository scan distinguishes product-title patterns from lore terms |

</frozen-after-approval>

## Code Map

- `project.godot` and `Jogar.cmd` -- application and launcher captions.
- `scripts/terminal_ui.gd` -- live title lockup, footer, and secondary-menu background selection.
- `scripts/main.gd` -- non-playing HUD identity string.
- `scripts/encyclopedia_screen.gd` -- backdrop currently sourced from art that contains the former title.
- `tests/title_screen_test.gd` -- title text and legacy-brand visibility regression coverage.
- `art/concept/tela-inicial-conceito-v3-severence.png` -- approved visual target with the new logo and without “Expedição Direta”.
- `README.md`, `docs/`, `_bmad-output/planning-artifacts/epics.md` -- canonical repository and planning identity.
- `art/storyboard/higgsfield-60s/` -- current presentation metadata whose separators must match the official form.

## Tasks & Acceptance

**Execution:**
- [x] `art/concept/tela-inicial-conceito-v3-severence.png` -- retain the revised concept showing “SEVERENCE / ECOS DO TEMPO” and the five-action console as the naming/layout reference.
- [x] `project.godot`, `Jogar.cmd`, `scripts/main.gd` -- replace application-facing identity strings with the exact official name.
- [x] `scripts/terminal_ui.gd` -- rebuild the two-line live lockup as “SEVERENCE” / “ECOS DO TEMPO”, fit both lines in the existing title area, update the footer, and reuse an unbranded crop for secondary screens that would otherwise reveal the old baked logo.
- [x] `scripts/encyclopedia_screen.gd` -- crop or obscure the legacy-logo portion of its atmospheric backdrop while retaining the existing archive layout.
- [x] `README.md`, canonical `docs/`, `_bmad-output/planning-artifacts/epics.md`, and current storyboard text metadata -- normalize product-title references to “Severence — Ecos do Tempo” while leaving lore terminology intact.
- [x] `tests/title_screen_test.gd` -- assert the exact live title strings and stable lockup bounds/fallback behavior.

**Acceptance Criteria:**
- Given any active menu state, when its interface is displayed, then the former product title is not visible and the main screen presents “Severence — Ecos do Tempo” without clipping.
- Given Godot and the Windows launcher, when the project starts, then their configured captions use the official name.
- Given canonical repository documentation, when product-title variants are scanned, then current materials use the exact official form and remaining legacy references are limited to intentionally historical implementation records or asset names.
- Given the completed migration, when focused and full headless suites run, then navigation, title-screen behavior, and gameplay regressions remain at zero failures.

## Spec Change Log

## Design Notes

The title remains a live two-line control over the animated background. `tela-inicial-conceito-v3-severence.png` is the new visual reference; legacy images remain as source/history, while active UI crops away their embedded sidebar logo instead of destructively rewriting every generated artwork during this naming pass.

## Verification

**Commands:**
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/title_screen_test.gd` -- expected: exact title and layout checks pass.
- `Get-ChildItem tests\*_test.gd | ForEach-Object { Godot ... --headless --path . --script $_ }` -- expected: every suite exits successfully.
- `rg -n -i "Marty\\s*[—:-]\\s*Fraturas do Tempo|FRATURAS DO TEMPO|Severence[:·] Ecos do Tempo"` with historical paths reviewed -- expected: no current product-identity mismatches.
- `git diff --check` -- expected: no whitespace errors.

## Suggested Review Order

**Live title and active backgrounds**

- Live two-line branding is the primary runtime identity entry point.
  [`terminal_ui.gd:246`](../../scripts/terminal_ui.gd#L246)

- Shared cropped scenery preserves branding safety, aspect ratio, and fallback behavior.
  [`terminal_ui.gd:206`](../../scripts/terminal_ui.gd#L206)

- Video geometry applies the same safe crop to the animated layer.
  [`terminal_ui.gd:175`](../../scripts/terminal_ui.gd#L175)

- Archive atmosphere reuses the shared unbranded background pipeline.
  [`encyclopedia_screen.gd:156`](../../scripts/encyclopedia_screen.gd#L156)

**Application identity**

- Godot exposes the official name as the application caption.
  [`project.godot:17`](../../project.godot#L17)

- Windows launcher enables UTF-8 before using the official em dash.
  [`Jogar.cmd:2`](../../Jogar.cmd#L2)

- Repository identity now leads with the consolidated official title.
  [`README.md:1`](../../README.md#L1)

**Regression protection**

- Tests validate exact text, rendered fit, video crop, fallback, and background proportions.
  [`title_screen_test.gd:16`](../../tests/title_screen_test.gd#L16)

- Current storyboard metadata uses the exact official separator.
  [`manifest.json:5`](../../art/storyboard/higgsfield-60s/manifest.json#L5)
