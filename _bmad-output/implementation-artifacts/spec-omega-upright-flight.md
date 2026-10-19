---
title: 'Omega upright propulsion flight'
type: bugfix
created: '2026-10-03'
status: done
baseline_commit: 87fe42e55592e2d8944b94ec8e17429994c312af
context: ['{project-root}/docs/SPRITE_POSE_STANDARD.md']
---

<frozen-after-approval reason="Execution authorized directly by the user through the coordinating chat">
## Intent
The existing Omega glide keeps fists raised and does not communicate propulsion from both palms and both soles. Replace its locomotion/jump presentation with upright powered flight, retaining the approved compact ivory/gold/cyan armor and purple cape.

## Boundaries & Constraints
Always preserve simulation, input, damage, jump duration, collision, armor lifetime, saves and all unrelated dirty changes. Keep 112px cells and the existing 124px rendering scale. Use dedicated generated flight poses; attach separate dynamic exhaust to actual palms and soles. Keep combat, teleport, hurt, death and mounted states distinct. No new gameplay flight ability. No subagents, new chats or commits, per explicit delegation. Implementation and local review proceed under existing authorization without redundant checkpoints.

## I/O & Edge-Case Matrix
| State | Expected visual |
|---|---|
| Omega moving, all eight facings | Upright legs, lowered palms, four exhaust sources |
| Existing jump | Same physical arc and duration, upright flight body, exhaust ramps down on landing |
| Stop moving | Short visual landing transition, no stuck jets |
| Melee/teleport/hurt/death/mounted/other form | Preserve existing action presentation and avoid displaced palm exhaust |
</frozen-after-approval>

## Code Map
- `scripts/world_view.gd`: body selection and layered rendering.
- `scripts/omega_flight.gd`: isolated visual state, exhaust anchors and flame drawing.
- `tools/import_omega_flight.py`: deterministic native atlas packing and provenance.
- `assets/characters/marty/omega/rounded_v4/flight.png`: dedicated eight-direction body poses.
- `art/source/characters/marty/omega/flight/`: generated originals, selections and review.
- `tests/omega_flight_test.gd`, `tests/omega_flight_preview.gd`: save-free checks and real renderer evidence.

## Tasks & Acceptance
- [x] Generate and inspect eight upright flight views with consistent identity and native size.
- [x] Integrate visual flight and four directional exhaust anchors, including landing and state cancellation.
- [x] Run focused tests, Omega combat regression and real-renderer captures.

Given Omega locomotion or a jump, when rendered in any direction, then the body remains upright and exhaust begins at both hands and both feet, never chest or head.
Given a landing or state transition, when flight ends, then jets fade or stop and no stale pose persists.
Given identical simulation commands, when visual flight is rendered, then gameplay state remains unchanged.

## Verification
Focused Godot flight tests, existing Omega regression, native atlas validation, eight-direction contact sheet and DockView captures. Review locally because delegation explicitly forbids subagents. Report actual captures separately from manual playtesting.

## Spec Change Log
Initial implementation scoped to presentation only; existing armor reference already approved.

The first v3 animated batch changed profile directions and raised hands, so it was rejected. A dedicated native pose state now supplies all eight flight bodies. One stable pose per view plus animated runtime exhaust avoids fabricated idle-derived animation. Local review found palm jets hidden by the cape; corrected front/back layering before final capture. No unresolved findings from the local acceptance, edge-case and diff reviews. No independent reviewers were spawned, following the explicit delegation constraint.

## Results
30 focused checks passed. Existing Omega combat and Marty action suites passed with zero failures. Eight-direction sheet and real-renderer flight/landing captures inspected. Simulation, input, fish assets and saves were not edited. No manual playtest or commit.

## Suggested Review Order
- Flight eligibility, state cancellation and landing remain presentation-only.
  [omega_flight.gd](../../scripts/omega_flight.gd)
- Dedicated flight pose and correctly layered palm/sole exhaust.
  [world_view.gd](../../scripts/world_view.gd#L984)
- Native provenance, reproducible padding and measured anchors.
  [README.md](../../art/source/characters/marty/omega/flight/README.md)
- State isolation and bounded original jump regression checks.
  [omega_flight_test.gd](../../tests/omega_flight_test.gd)
