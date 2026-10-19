---
title: Safe jumping across flooded cellar platforms
type: feature
created: 2026-10-03
status: done
baseline_commit: 87fe42e55592e2d8944b94ec8e17429994c312af
context: []
---
<frozen-after-approval>
## Intent
Make the flooded cellar a playable platform crossing using the existing jump, with water impassable on foot and a safe return after a missed landing.
## Boundaries & Constraints
Preserve all existing dirty work and user saves. Restrict behavior and geometry to the cellar. Coordinate exposed platform geometry with the art owner. No procedural generation, main/input/facing changes, commits, or new agents. The explicit implementation authorization covers this plan and inline review.
## I/O & Edge-Case Matrix
| State | Action | Expected |
|---|---|---|
| Grounded at shore | Walk into water | Blocked, including body radius |
| Jump airborne | Cross channel | Water traversable; solid obstacles remain solid |
| Landing over water | Jump expires | Valid previous base, otherwise safe platform checkpoint |
| Saved midair | Restore and land | Actor checkpoint survives, no water softlock |
| Old save without feature marker | Restore | Existing geometry preserved |
</frozen-after-approval>
## Code Map
- scripts/simulation.gd: existing gaps, jump movement, actor dictionaries and snapshot lifecycle.
- scripts/scenarios/cellar_platforms.gd: isolated geometry, checkpoint and relocation helpers.
- tests/cellar_platforms_test.gd: focused headless runtime tests.
## Tasks & Acceptance
- [x] Add shared cellar platform and water geometry with local coordinates and feature marker.
- [x] Add minimal simulation hooks for new runs, water clearance and safe landing.
- [x] Verify movement, landing recovery, coop checkpoint independence and snapshot continuity.
Given a new run, when the player enters the cellar, then solid platforms and channels form a crossing toward the existing chest.
Given a failed landing, when recovery runs, then the actor returns to a position accepted by clear_at and may move again.
Given an actor outside the cellar, when stepping or testing collision, then cellar changes do not alter existing behavior.
## Design Notes
Retain floor coverage under water for airborne movement, expose its complement as gaps for ground movement/navigation. Geometry marker lives in the existing serialized layout manifest; actor checkpoint lives in serialized actor dictionaries. Do not migrate old materialized saves. Art consumes the same exported rectangles.
## Verification
Run Godot headless with tests/cellar_platforms_test.gd. Review only new module/test and minimal simulation hunks; shared dirty changes remain untouched. No agents per user constraint.

## Verification results — 2026-10-03
Godot 4.7.2 headless, tests/cellar_platforms_test.gd: 15 PASS, zero failures, exit 0 after final changes. Verified actual step_actor jump motion through three channels, blocked walking/body overlap, failed landing recovery, blocked checkpoint fallback, coop separation, snapshot midair restoration, unchanged materialized geometry and nonmigration of saves without the feature marker.

Inline review performed instead of agents, as explicitly required by the user. Found and fixed landing radius mismatch (previous ground landing checked 10 while the actor uses 11). Added an early bounds rejection so non-cellar collision queries do not rebuild water rectangles. Only the listed cellar hooks in simulation.gd belong to this change; all other pre-existing dirty work preserved. No user save files touched, no commit. Rendering consumes exposed geometry under the art coordinator; this functional test does not claim visual acceptance.

## Suggested Review Order
- Shared platform rectangles and water complement:
  [cellar_platforms.gd:5](../../scripts/scenarios/cellar_platforms.gd#L5)
- Safe actor checkpoint and blocked-base recovery:
  [cellar_platforms.gd:32](../../scripts/scenarios/cellar_platforms.gd#L32)
- New-run installation without save migration:
  [simulation.gd:598](../../scripts/simulation.gd#L598)
- Runtime movement and snapshot acceptance checks:
  [cellar_platforms_test.gd:1](../../tests/cellar_platforms_test.gd#L1)
