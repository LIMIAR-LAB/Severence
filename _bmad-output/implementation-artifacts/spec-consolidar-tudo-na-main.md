---
title: 'Consolidate all completed work on main'
type: 'chore'
created: '2026-09-29'
status: 'in-progress'
baseline_commit: '6d4443f'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The local `main`, remote `origin/main`, uncommitted files, and one completed feature branch contain different pieces of finished work. A previous transient merge state also produced Godot parser errors, so consolidation must prove that no conflict markers or syntax failures remain.

**Approach:** Create a recoverable safety point, commit every current local artifact, integrate the remote animated-chapel commit and the unique run-summary branch into `main`, preserve both sides of overlapping scenery changes, validate the unified project, and push the resulting `main`.

## Boundaries & Constraints

**Always:** Preserve every tracked modification and untracked project artifact currently present; retain both the animated chapel and boss-arena behavior where they overlap; include unique completed work from `codex/resumo-fiel-conceito`; use an explicit merge/cherry-pick history; scan the final tree for conflict markers; verify the Godot parser and focused/full tests before pushing; keep a recoverable branch or tag pointing to the pre-consolidation state.

**Ask First:** Any deletion of an existing artifact, any choice that replaces one implementation with another instead of combining them, or any destructive rewrite of published history.

**Never:** Use hard reset, discard local edits, overwrite files wholesale with one merge side, duplicate the chapel patch already represented by `origin/main`, or claim success while parser/test failures remain unexplained.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Local and remote histories diverge | Seven local commits and one remote chapel commit | Both histories become ancestors of unified `main` | Resolve conflicts by preserving both behaviors |
| Dirty worktree contains finished assets and code | Modified and untracked files | All project artifacts are committed before integration | Stop if any file cannot be safely classified or staged |
| Same scenery file has chapel and boss-arena work | Overlapping `dock_scenery.gd` changes | Chapel animation and boss-arena rendering both remain | Manually combine constants, loading, drawing, and visibility rules |
| Historical parser errors reappear | Conflict markers or malformed dictionaries | `main.gd` and `simulation.gd` parse cleanly | Do not push until root cause is corrected and cascades disappear |

</frozen-after-approval>

## Code Map

- `scripts/dock_scenery.gd` -- main overlap point between remote chapel work and local boss-arena work.
- `scripts/docks_map.gd` -- generated map data touched by both scenery efforts.
- `scripts/world_view.gd` -- combines local weapon visuals with remote chapel visibility/drawing.
- `scripts/main.gd` -- previously showed a transient conflict marker; final parser target.
- `scripts/simulation.gd` -- previously showed a transient malformed actor dictionary; root dependency for many tests.
- `tests/` -- Godot headless regression suites, including run summary, chapel, boss arena, weapons, and save flow.
- `_bmad-output/implementation-artifacts/` -- specifications that must be retained with the implementation.

## Tasks & Acceptance

**Execution:**
- [x] Repository history -- create a recoverable pre-consolidation reference and commit all current tracked/untracked project work without omission.
- [x] `main` -- merge `origin/main`, resolving overlaps as a union of chapel and boss-arena behavior.
- [x] `codex/resumo-fiel-conceito` -- integrate its unique completed run-summary commit without duplicating already-applied work.
- [x] `scripts/main.gd` and `scripts/simulation.gd` -- confirm resolved syntax and absence of VCS markers; change only if validation exposes a current defect.
- [ ] Tests and repository -- run marker/whitespace checks and Godot headless suites, then push unified `main` to `origin/main`.

**Acceptance Criteria:**
- Given all current local files and divergent commits, when consolidation finishes, then every intended artifact is reachable from `main` and the safety reference remains available.
- Given chapel and boss-arena changes, when the final scenery code is inspected and tested, then neither feature has been replaced or omitted.
- Given the reported parser cascade, when Godot loads the project and executes the relevant suites, then no VCS-marker, dictionary-key, unresolved-script, or inferred-type cascade remains.
- Given successful validation, when `main` is pushed, then local `main` and `origin/main` point to the same unified history.

## Spec Change Log

## Design Notes

The parser report corresponds to an intermediate merge state rather than a committed revision. The final merge should preserve the already-resolved union in `main.gd` (both `summary` and `encyclopedia` UI pages) and `simulation.gd` (both damage-source and run-weapon fields). The chapel branch is patch-equivalent to the remote PR and must not be applied twice.

## Verification

**Commands:**
- `rg -n "^(<<<<<<<|=======|>>>>>>>)" scripts tests` -- expected: no matches.
- `git diff --check` -- expected: no patch whitespace errors.
- `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/run_summary_test.gd` -- expected: zero failures and no parser errors.
- `Get-ChildItem tests\*_test.gd | ForEach-Object { Godot ... --headless --path . --script $_ }` -- expected: all suites exit successfully.
- `git status --short --branch` -- expected: clean `main` synchronized with `origin/main` after push.
