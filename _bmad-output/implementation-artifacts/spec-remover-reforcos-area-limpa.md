---
title: 'Stop enemy reinforcements in cleared rooms'
type: 'refactor'
created: '2026-09-29'
status: 'done'
baseline_commit: '4389843'
context:
  - '{project-root}/docs/architecture.md'
  - '{project-root}/docs/REGRAS_0_12.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** During a normal expedition, clearing every enemy from certain locked rooms starts a delayed reinforcement wave in the same room. This feels like enemies respawning on the same screen and prevents a cleared encounter from ending immediately.

**Approach:** Remove room reinforcement waves from expedition encounters so a room opens as soon as its current enemies are defeated. Preserve the initial enemy population across the rest of the map, so new enemies continue to appear naturally as the player advances into other rooms.

## Boundaries & Constraints

**Always:** Keep the hand-authored initial enemy spawns from `DOCKS.SPAWNS`; keep room gates closing while the current room still contains enemies; mark and open a room immediately after its last threat dies; preserve seeded run behavior and the enemies already placed in rooms the player has not visited.

**Ask First:** Any rebalance of initial enemy counts, enemy types, health, damage, room geometry, gate timing, or encounter rewards.

**Never:** Disable enemies globally; remove enemies from later rooms; change the separate training arena's repeating wave system; suppress crawler splitting into `crawler_small`; change the optional challenge encounter or boss/warden spawning.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|---------------------------|----------------|
| Room cleared | Player kills the last non-optional enemy in a locked expedition room | Room is marked cleared and its gates open without a delayed second wave | No reinforcement portal or replacement enemy is created |
| Player advances | A cleared room is left and the player enters another populated room | The other room's original enemies remain present and its gates work normally | Previous room remains cleared and does not repopulate |
| Training arena | Player clears an arena wave | The existing arena delay and next wave still run | Expedition change does not alter arena state |
| Splitting enemy | A crawler dies | Its intended child crawlers still spawn | Child spawning is treated as an enemy ability, not room respawn |

</frozen-after-approval>

## Code Map

- `scripts/simulation.gd` -- copies room wave data during `start_run()`, schedules reinforcements in `step_gates()`, and contains the separate arena and crawler-spawn mechanisms that must remain intact.
- `scripts/docks_map.gd` -- defines the initial `SPAWNS` and obsolete room `WAVES` data.
- `tools/build_docks_map.py` -- authoritative map generator that must stop defining, validating, and emitting room reinforcement waves.
- `tests/dynamic_map_test.gd` -- currently asserts that the unwanted second wave appears; it must instead verify immediate clearing, untouched enemies in later rooms, and crawler-child gate ordering through the real death pipeline.
- `tests/combat_regression_test.gd` -- protects the independent arena wave behavior.
- `README.md`, `docs/CENARIO_0_13.md`, and `docs/COMBATE_0_18.md` -- contain current-facing descriptions of the removed reinforcement behavior and must not contradict runtime rules.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/simulation.gd` -- remove the expedition-room reinforcement path and its unused per-room runtime state/helper while preserving the optional `step_gates` call signature, gate transitions, initial spawns, arena waves, and crawler splitting.
- [x] `scripts/docks_map.gd` and `tools/build_docks_map.py` -- remove the obsolete `WAVES` data from both generated output and its authoritative generator so rebuilding the map cannot restore same-room repopulation.
- [x] `tests/dynamic_map_test.gd` -- replace the reinforcement expectation with coverage for immediate clearing, no delayed repopulation, continued enemy presence in a different room, and crawler children retaining their room and gate lock through the real death pipeline.
- [x] `docs/REGRAS_0_12.md`, `docs/architecture.md`, `README.md`, `docs/CENARIO_0_13.md`, and `docs/COMBATE_0_18.md` -- update current-facing encounter documentation to state that each expedition room has one initial population and does not repopulate after being cleared; keep genuinely historical version notes clearly labeled.

**Acceptance Criteria:**
- Given a populated expedition room has locked its gates, when the last current threat dies, then the room opens and stays empty for at least the former reinforcement delay.
- Given the player clears one room, when they proceed to another room, then that room's initial enemies are still available and its normal lock-and-clear flow works.
- Given the player uses the training arena, when a wave is eliminated, then the next arena wave continues to spawn as before.
- Given a crawler dies in an expedition, when its death behavior resolves, then its child crawlers still appear and must be defeated before the room clears.

## Spec Change Log

- **Iteration 2 — generator durability and integration coverage:** Review found that `tools/build_docks_map.py` would regenerate `DOCKS.WAVES`, current-facing docs still promised second waves, and the test bypassed crawler death ordering. The Code Map and tasks now require generator cleanup, consistent documentation, compatibility for the optional `step_gates` parameter, and an expedition crawler/gate integration test. This avoids a future map rebuild silently restoring respawn and protects gates from opening before crawler children are resolved. **KEEP:** immediate room clearing, preserved later-room populations, unchanged arena waves and crawler splitting, and the three previously passing focused regressions.

## Design Notes

Room reinforcement waves and initial map population are independent systems. Removing both would incorrectly make later areas empty; therefore only the `DOCKS.WAVES` path is removed. Arena waves and crawler splitting are explicitly retained because they represent a game mode loop and an enemy ability rather than a cleared-room respawn.

## Verification

**Commands:**
- `godot --headless --path . --script tests/dynamic_map_test.gd` -- expected: a cleared expedition room opens without reinforcement and another room remains populated.
- `godot --headless --path . --script tests/combat_regression_test.gd` -- expected: the training arena still replenishes waves.
- `godot --headless --path . --script tests/enemies_test.gd` -- expected: crawler split behavior and ordinary enemy combat remain passing.

## Suggested Review Order

**Encounter lifecycle**

- Cleared expedition rooms now unlock immediately without scheduling replacement enemies.
  [`simulation.gd:386`](../../scripts/simulation.gd#L386)

- The generated map retains only each room's initial enemy population.
  [`docks_map.gd:193`](../../scripts/docks_map.gd#L193)

**Generator durability**

- Validation and emission no longer model or regenerate reinforcement waves.
  [`build_docks_map.py:409`](../../tools/build_docks_map.py#L409)

- The legacy updater no longer injects a stale `WAVES` reference.
  [`implement_update017.py:10`](../../tools/implement_update017.py#L10)

**Regression coverage**

- Room clearing, later-room enemies, and crawler-child gate ordering are exercised together.
  [`dynamic_map_test.gd:47`](../../tests/dynamic_map_test.gd#L47)

**Player-facing rules**

- Current gate documentation states that cleared rooms never repopulate.
  [`REGRAS_0_12.md:17`](../../docs/REGRAS_0_12.md#L17)

- Historical reinforcement notes remain labeled while current behavior is corrected.
  [`CENARIO_0_13.md:39`](../../docs/CENARIO_0_13.md#L39)
