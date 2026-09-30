---
title: 'Complete missing enemy portraits and consolidate every branch into main'
type: 'feature'
created: '2026-09-29'
status: 'in-progress'
baseline_commit: 'd1ab100'
context:
  - '{project-root}/_bmad-output/implementation-artifacts/spec-enciclopedia-identidade-visual.md'
  - '{project-root}/_bmad-output/implementation-artifacts/spec-enciclopedia-dinamica.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Several encyclopedia dossiers still use missing art, tiny inventory icons, or gameplay sprite sheets instead of the approved illustrated-card standard, while completed work is spread across dirty files and multiple local or remote branches instead of one authoritative `main`.

**Approach:** Use PixelLab to create a cohesive illustrated-card set for every encyclopedia record that lacks the approved visual standard; connect it through the data-driven catalog without replacing gameplay art; preserve and reconcile all current work; merge every branch that contributes commits absent from `main`; verify the unified game; then push the resulting `main` to `origin`.

## Boundaries & Constraints

**Always:** Preserve every tracked and untracked user change; use native crisp pixel art; match the supplied maximalist arcade-card reference with dramatic stormy dock scenes, dense detail, saturated cyan/magenta/orange effects, aged brass framing, and recognizable 1941 naval-horror silhouettes; retain source exports under `art/source/pixellab/`; use stable runtime copies under `assets/enemies/encyclopedia/`; keep encyclopedia behavior data-driven; fetch before reconciliation; inspect branch ancestry and diffs before merging; resolve conflicts by integrating both compatible sides; run import, automated tests, and a real encyclopedia capture before push; push only after local `main` contains the latest `origin/main`.

**Ask First:** Dropping a commit or file because two variants cannot coexist; force-pushing; rewriting published history; deleting branches; changing enemy gameplay, collisions, stats, or encyclopedia prose.

**Never:** Discard dirty work, use `reset --hard`, overwrite conflict sides blindly, generate smooth/non-pixel illustrations, ship opaque portrait backgrounds, hardcode dossiers into the UI, or claim branch consolidation without proving no contributing branch remains ahead of `main`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|---------------------------|----------------|
| Missing portrait | One of the four named monster entries | A cohesive full-bleed PixelLab bestiary card loads in its dossier | Keep the intentional seal until a candidate passes inspection |
| Dirty work | Tracked and untracked changes from parallel features | All files are preserved in explicit commits before branch reconciliation | Stop if ownership is ambiguous or a file cannot be safely retained |
| Divergent branch | Branch contains commits absent from `main` | Relevant history/content becomes reachable from unified `main` | Inspect conflicts and integrate both sides; never favor a side automatically |
| Remote advanced | `origin/main` has commits absent locally | Remote work is merged before final push | No force push; re-run verification after reconciliation |
| Duplicate history | Branch content is already reachable or patch-equivalent | Avoid redundant merge noise while proving content is present | Record as already integrated rather than re-merging |

</frozen-after-approval>

## Code Map

- `data/enciclopedia.json` -- data-driven image paths for the four missing monster dossiers.
- `art/source/enemies-docas-v2.png` -- established enemy identity and silhouette reference.
- `art/source/pixellab/encyclopedia-enemies/` -- retained PixelLab source exports and generation notes.
- `assets/enemies/encyclopedia/` -- transparent runtime portraits loaded by the encyclopedia.
- `scripts/encyclopedia_screen.gd` -- safe texture loading and themed fallback behavior.
- `tests/encyclopedia_data_test.gd` -- catalog and image-path validation.
- `tests/encyclopedia_ui_test.gd` -- rendered portrait, fallback, focus, and archive identity contract.
- `.git/` -- branch ancestry, preserved dirty work, merge state, and final `main` publication.

## Tasks & Acceptance

**Execution:**
- [x] `art/source/pixellab/encyclopedia-enemies/` -- create four cohesive illustrated enemy cards in PixelLab and retain both source passes with provenance.
- [x] `assets/enemies/encyclopedia/` -- normalize accepted portraits for runtime use with crisp nearest-filtered output.
- [x] `data/enciclopedia.json` -- bind each named monster to its matching portrait without changing the schema.
- [x] `tests/encyclopedia_data_test.gd` and `tests/encyclopedia_ui_test.gd` -- prove every monster image resolves and missing-art fallback still works for bad paths.
- [x] `art/source/pixellab/encyclopedia-completion-v3/`, `assets/enemies/encyclopedia/`, and `assets/items/encyclopedia/` -- replace remaining sprite-sheet, tiny-icon, and missing-art dossier visuals with nine cohesive cards while preserving gameplay assets.
- [ ] Repository history -- commit all current dirty work, fetch, reconcile `origin/main`, then merge every local/remote branch with unique contributing commits into `main`.
- [ ] Full project -- import, run relevant regression suites, capture the encyclopedia, audit ancestry, and push unified `main` to `origin`.

**Acceptance Criteria:**
- Given any of the four previously incomplete monster dossiers, when opened, then its matching PixelLab card fills the frame with the supplied saturated arcade-poster identity.
- Given an invalid or absent future image path, when the dossier opens, then the intentional archive seal still renders safely.
- Given the pre-existing dirty files and branch tips, when consolidation completes, then all content is retained, `main` includes the latest remote history, and no contributing branch has unique commits left outside `main`.
- Given verification passes, when `main` is pushed, then `origin/main` points at the verified unified commit without force rewriting.

## Spec Change Log

- 2026-09-29 — User rejected the sparse transparent-sprite treatment and supplied a maximalist Almirante card reference; acceptance now requires illustrated full-bleed cards with dramatic environments and saturated effects. The original sprites remain as exploration, while the v2 cards are promoted to runtime.
- 2026-09-30 — Visual audit found three remaining monster sprite sheets, five tiny equipment icons, and one missing item image. A nine-card PixelLab completion pass now makes every monster and item dossier use purpose-built artwork; existing gameplay resources remain untouched.

## Design Notes

The portraits are illustrated dossier cards rather than gameplay animation sets. They reuse the recognizable forms already established in `enemies-docas-v2.png`: hooded cultist with candle and rifle, amphibious harpooner in striped dockwear, one-eyed corrosive crawler, and helmeted tentacled heavy soldier. The accepted 256×256 pass places each enemy in a different dock battle while sharing the same brass border, storm lighting, neon tracers, palette density, and close action framing.

Branch consolidation is content-oriented: merge commits are preferred when they preserve meaningful independent history, while branches already reachable or patch-equivalent are documented as integrated rather than merged redundantly.

## Verification

**Commands:**
- Godot headless import -- expected: all new PNGs import without loader errors.
- Encyclopedia data and UI suites -- expected: zero failures and all monster image paths resolve.
- Title, equipment, inventory, mission inventory, save-flow, and affected gameplay suites -- expected: zero regressions.
- Encyclopedia capture at 1280×800 -- expected: four new portraits render clearly within the Temporal Archive frame.
- Git ancestry audit against every local and remote branch -- expected: no contributing branch remains ahead of `main`.
- Final `git status` and remote comparison -- expected: clean tree and `main` synchronized with `origin/main` after push.
