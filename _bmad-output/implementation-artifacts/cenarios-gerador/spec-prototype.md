---
title: SCN-04 preparatory graph experiment
type: feature
created: 2026-09-30
status: done
baseline_commit: 0d028db1bed4ba6c9a5863c9b57aae316fd436f8
context: []
---

<frozen-after-approval>
## Intent
Prepare a reproducible discrete expedition graph experiment, comparing GDQuest BasicDungeonGenerator and MST without replacing the existing game. Authorization explicitly covers isolated implementation, research and tests without routine confirmation.

## Boundaries & Constraints
Always preserve concurrent changes. Write only within tools/scenarios/prototype, tests/scenarios_prototype and this evidence directory. Explicitly identify provisional outputs. Never mark SCN stories integrated or complete before their dependencies. No runtime, art or shared contract edits. Request coordinator release before widening scope.

## I/O & Edge-Case Matrix
| Input | Expected behavior |
| --- | --- |
| Seed and supported profile | Stable ordered rooms, edges, unique entry/boss and required progression |
| Reordered profile dictionary | Same canonical manifest |
| Invalid bounds or unsupported profile | Explicit rejection without partial output |
| Optional branches/cycles | Respect configured counts; no shortcut bypassing required roles |
</frozen-after-approval>

## Code Map
Reference lives in tools/scenarios/prototype/reference. Prototype is a standalone Godot project; graph generator is independent of Node lifecycle. Tests run headless using local Godot.

## Tasks & Acceptance
- [x] Reference research: pinned origin/licenses, actual Godot experiment and algorithm comparison.
- [x] Implement provisional graph, profiles and explicit validation in tools/scenarios/prototype.
- [x] Test fixed seed corpus across separate processes in tests/scenarios_prototype; save reports here.
- [x] Review findings, record limitations and send coordinator evidence.

Given identical seed/profile/version, when separate processes generate output, then canonical manifest hashes coincide. Given required roles, when traversing any entry-to-boss route, then required roles cannot be bypassed. Given profiles, when generating, then topological rules differ rather than only colors. Given graph success, geometry and production gameplay remain unverified.

## Design Notes
Build a staged backbone, attach optional subgraphs within stages, and add bounded cycles within those optional subgraphs. This guarantees role separators and avoids physics settling as a seed contract. Discrete preview coordinates are schematic, not template placement or corridor geometry. Catalog and substream integration wait for SCN-01.04.

## Verification
Headless Godot checks structural invariants and a fixed corpus. Cross-process hashes exclude timing. No aesthetic or collision acceptance is implied.

## Spec Change Log
User-assigned ownership takes precedence over generic workflow paths and story-status updates. Approval already supplied for preparatory implementation.

Review fixes: test actual canonical API, record engine/generator versions, reject malformed fixture arrays safely, cover additional bounds and seeds. Scope remains preparatory; done here does not mark either SCN story done. No shared-checkout commit created.

## Suggested Review Order
- Start with provisional API and scope: [README.md](../../../tools/scenarios/prototype/README.md).
- Inspect graph invariants: [graph_generator.gd](../../../tools/scenarios/prototype/graph_generator.gd#L51).
- Inspect reference findings and origin: [research.md](research.md).
- Reproduce checks: [run.ps1](../../../tests/scenarios_prototype/run.ps1).
- Review measured evidence and remaining dependencies: [status.md](status.md).
