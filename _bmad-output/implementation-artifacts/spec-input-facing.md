---
title: Movement facing with deliberate aim priority
type: bugfix
created: 2026-10-03
status: done
baseline_commit: 87fe42e55592e2d8944b94ec8e17429994c312af
context: []
---
<frozen-after-approval>
## Intent
Walking must turn the sprite toward movement unless the player deliberately aims elsewhere. Right stick outside deadzone and P2 aiming keys have priority; releasing aim restores movement facing. At rest retain the last direction. Active mouse movement and mouse attack respect cursor aim, but a stationary cursor cannot lock walking forever.
## Boundaries & Constraints
Always preserve existing dirty changes, saved progress, controls/remapping and combat behavior. Never modify scenarios, generate assets, create agents/chats or commit. Work directly under implementation authorization from origin chat.
## I/O & Edge-Case Matrix
| Input | Expected |
|---|---|
| Keyboard/left stick movement, no active aim | Move direction becomes aim/body facing |
| Opposing right stick/P2 IJKL | Explicit aim wins |
| Right stick released or below deadzone | Movement immediately wins |
| Idle without explicit aim | Last direction retained |
| Recent physical mouse motion or mouse attack | Cursor aim wins unless right stick overrides |
| Mouse stops and grace expires | Movement wins; camera motion is not input |
</frozen-after-approval>
## Code Map
- scripts/main.gd: builds player commands, device assignment, mouse events.
- scripts/simulation.gd: consumes cmd.aim, assigns actor facing, applies weapon direction and Titan state.
- scripts/world_view.gd: regular actors use aim; fusion fallback and Titan currently substitute movement.
## Tasks & Acceptance
- [x] scripts/main.gd: replace sticky aim with per-frame explicit aim arbitration; finite mouse grace; preserve remapped keys and device ownership.
- [x] scripts/world_view.gd: align piloted Titan/fusion fallback with resolved actor aim.
- [x] tests/input_facing_test.gd: exercise actual command path with keyboard/mouse/joy events and save-free app fixture; simulation and visual helpers.
Given movement and released aim, when command is consumed, then aim/body follows movement. Given deliberate opposing aim, when moving, then body/weapon face aim. Given idle, when input ceases, then direction remains. Given a parked cursor after grace, when camera/player moves, then cursor cannot reassert aim. Given local coop, when P1 mouse aims, then P2 direction remains independently controlled.
## Design Notes
Resolve aim in command assembly so existing simulation/combat/network inputs remain compatible. Mouse activity uses actual event time with180ms grace, not changing world mouse position. UI blocked actions do not activate mouse attack aiming. Shared dirty files are edited surgically. Direct implementation and no agents were explicitly requested; review is local.
## Verification
Run focused headless input-facing test and existing dialogue/controller regression. Do not instantiate main scene or invoke save/load/startup in fixture.
## Spec Change Log

## Review result

Local review of the task-only diffs covered stale aim, zero/deadzone input, coop device ownership, mouse/UI priority, simulation consumption and piloted versus autonomous visual directions. No unresolved finding. External agents were not used under explicit task restriction. Dirty baseline preserved in input-facing/*.before; task-only diffs are recorded separately. No save access and no commit.

## Verification result

Godot4.7.2 headless: input_facing_test.gd20 checks passed; dialogue_controller_regression_test.gd21 checks passed. Tests inject keyboard/joypad/mouse events into actual player_input; no physical controller playtest claimed. Existing simulation consumes resolved aim unchanged.

## Suggested Review Order

- Per-frame aim priority and finite mouse activity.
  [main.gd:464](../../scripts/main.gd#L464)

- Movement fallback and idle retention.
  [main.gd:521](../../scripts/main.gd#L521)

- Resolved aim also governs fusion and piloted Titan.
  [world_view.gd:1080](../../scripts/world_view.gd#L1080)

- Save-free input, simulation and visual regressions.
  [input_facing_test.gd:24](../../tests/input_facing_test.gd#L24)
