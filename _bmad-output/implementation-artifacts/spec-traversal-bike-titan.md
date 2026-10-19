---
title: Traversal, motorcycle and Titan recovery
type: feature
created: 2026-10-04
status: done
baseline_commit: 87fe42e55592e2d8944b94ec8e17429994c312af
---

## Intent
Implement the user's grouped corrections: Omega crosses jump gaps while hovering; motorcycle traversal requires steering, has acceleration and a rechargeable turbo, faster shots, collision penalties, readable sprites, improved collapse and automatic dismount. The Titan is the cult-protected machine and a multi-stage quest reward, retaining its hostile encounter. A separate eastern copy remains capturable. Mission objectives appear on the map. Faisca receives a purple-leather cyberpunk sprite.

## Boundaries
Preserve concurrent changes, existing ownership, combat attacks and authored collision walls. Never edit real saves or publish. Tests use simulation fixtures. The user clarified the quest reward is the pilotable Titan. Controls reuse existing boost/dash binding. Hover does not bypass walls or sealed gates and does not replace the motorcycle bridge route.

## Code Map
- scripts/simulation.gd: actor physics, bridge completion, projectiles, acquisition and snapshots.
- scripts/bike_handling.gd: acceleration, turbo, alternating road obstacles and collapse debris.
- scripts/titan_recovery.gd: chassis recovery, generator power and Admiral core requirements.
- scripts/mission_markers.gd: objective positions shared by full map and minimap.
- scripts/world_view.gd, scripts/bike_visuals.gd: sprites and world effects.
- scripts/main.gd, scripts/combat_hud.gd: camera look-ahead, portrait, turbo gauge and map.

## Tasks & Acceptance
- [x] Omega movement: given Omega, walking across a jump gap succeeds without jump; normal actors remain blocked, walls remain solid.
- [x] Motorcycle handling: given mounted rider, sustained direction accelerates; turbo exceeds cruise and drains/recharges; firing outruns turbo; road contact damages and slows; successful steering completes with dismount; a stopped rider falls and can retry.
- [x] Visuals: larger bike, visible barriers, falling debris, cyberpunk Faisca with transparent background and matching portrait.
- [x] Titan progression: defeating the cult machine still requires combat; chassis, generator and extracted core jointly unlock Titan, once; prior owners keep entitlement.
- [x] Eastern copy: hostile copy can be stunned and captured with robobola; repeated capture cannot duplicate quest rewards.
- [x] Map objectives: markers track unfinished objectives and disappear/change after completion.
- [x] Verify with focused simulation tests and actual rendered capture, preserving user data.

## Verification
Headless Godot fixture tests for movement, collision, projectile velocity, progression, capture and markers. Render a local disposable preview for sprite scale and transparency.

Results: traversal revision 22 checks passed; cult encounter 25 passed, including preserved attack patterns and unchanged save hash; existing Omega suite passed. The updated route_p12 suite also passed, covering midpoint restore, legacy bridge geometry, restart and split-route co-op. Actual OpenGL captures verified Faisca, riding scale, barriers/debris and mission map. No real profile writes. Reviewed inline under the session's no-delegation constraint.

## Suggested Review Order

- Motorcycle control, collision penalty and collapse presentation: [bike_handling.gd](../../scripts/bike_handling.gd#L1).
- Three-stage persistent restoration and copy migration: [titan_recovery.gd](../../scripts/titan_recovery.gd#L1).
- Map objectives follow current progression: [mission_markers.gd](../../scripts/mission_markers.gd#L1).
- End-to-end simulation checks: [traversal_revision_test.gd](../../tests/traversal_revision_test.gd#L1).
