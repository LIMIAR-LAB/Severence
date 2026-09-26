# Deep Dive — Boss Fight: O Almirante das Profundezas

**Date:** 2026-09-25 · Source: `scripts/simulation.gd` (`step_boss`, `spawn_enemy`), `scripts/world_view.gd` (`draw_boss`, `boss_pose`), `tests/enemies_test.gd`

## 1. Stats & Placement

- **HP:** 600 (`spawn_enemy`'s hardcoded `{"boss": 600.0, ...}` table, `simulation.gd:238`) — by far the tankiest enemy; regular enemies range 18–95 HP.
- **Spawn point:** `DOCKS.POINTS.boss = Vector2(2600, 1000)`, inside room `09 • O ALMIRANTE DAS PROFUNDEZAS` (2000×1500 + two side wings, `docks_map.gd`), with 4 pillar obstacles for player cover.
- **Detection:** uses the boss-specific 900px base detection range (vs 700px for regular enemies) and, unlike regular enemies, **ignores line-of-sight for initial acquisition** (`e.kind == "boss" or line_of_fire(...)` — boss short-circuits the LoS requirement).
- **Extraction gating:** the capsule at `DOCKS.POINTS.extraction` (visually sealed, `combat_hud.gd`/`world_view.gd draw_capsule`) only activates once `boss_dead == true`; reaching it then grants the permanent-armor unlock and 3 fragments (see `deep-dive-economy.md` §2).

## 2. Stage Machine

Driven purely by current HP ratio at the top of every `step_boss()` call — **not** a one-way ratchet by itself, but healing isn't possible so in practice it only ever moves forward:

```
ratio = hp / max
stage = 1 if ratio > 0.66
       = 2 if ratio > 0.33
       = 3 otherwise   ("Fúria")
```

On any **increase** in `stage` (`stage > e.stage`): reset `e.cd = 1.2`, `e.spin = 0`, `e.charge = 0`; spawn a `"weapon_drop"` VFX at `e.p + (60, -60)`; announce via `say()`:
- → Stage 2: *"O Almirante larga a espingarda! Agora ele gira e carrega o canhão."*
- → Stage 3: *"FÚRIA! O Almirante perdeu o chapéu: tinta, chamas e arpões!"*

## 3. Attack Patterns by Stage

All bullets use `add_bullet(pos, dir, team=1, damage, speed, radius, owner=-1, kind, life)`.

### Stage 1 (HP > 66%) — cadence ~1.1s (`e.cd = 1.1` after each volley, `e.shot = 0.4` for the muzzle-flash pose window)
Alternates by `e.phase % 2` (phase increments every volley):
- **Odd phase — full ring:** 16× `"orb"` bullets, evenly spaced (`n*TAU/16`), each volley rotated by `+phase*0.2` rad so the ring pattern precesses over time. Damage 12, speed 150, radius 7.
- **Even phase — aimed fan:** 7× `"orb"` bullets spread ±0.14 rad around the direction to the player. Damage 10, speed 215, radius 6.

*(Verified by `tests/enemies_test.gd`: "fase 1: anel radial de 16 orbes" — asserts exactly 16 bullets, all kind `"orb"`.)*

### Stage 2 (33–66% HP) — the only stage with a distinct "telegraphed" attack
`e.phase % 3 == 0` → **charge attack**: `e.charge = 0.9`, `e.cd = 1.0`. While `e.charge > 0` the boss is locked in the `"charge"` pose (a violet glow VFX grows around it in `world_view.gd`) and does nothing else; when the charge timer expires, fires **one** `"cannon"` bullet — damage 24, speed 200, radius 13 (largest hitbox of any projectile in the game), 4s lifetime (long-range threat).
Any other phase → **spin barrage**: `e.spin = 2.2s`. While spinning, every `0.11s` (`e.cd`) fires 2 bullets (this stage) at `spin_angle`, `spin_angle + TAU/2`, incrementing `spin_angle += 0.42` rad each tick — a rotating double-beam pattern that sweeps the whole arena over ~2.2s. Damage 10, speed 165, radius 6, kind `"orb"`.

*(Verified by `tests/enemies_test.gd`: stage-2 transition drops a `"weapon_drop"` VFX; a 900-tick soak test confirms both `spin > 0` and a `"cannon"` bullet are eventually observed.)*

### Stage 3 / Fury (HP < 33%) — cadence 0.8s, cycles `e.phase % 3`
- **Phase 0 — ink volley:** 3× `"ink"` bullets, ±0.35 rad spread. Damage 14, speed 115 (slowest projectile — meant to zone rather than snipe), radius 11, life 4.5s.
- **Phase 1 — harpoon + flame cone:** 1 `"harpoon"` bullet (damage 18, speed 280) that applies the same 0.9s snare-on-hit as the regular Arpoador enemy; **additionally**, if the player is within 260px, fires a 6-bullet `"flame"` cone (±0.12 rad each, damage 8, speed 280, life 0.7s) — this is the only attack in the game that combines a ranged projectile with a conditional close-range follow-up in the same volley.
- **Phase 2 — full ring, upsized:** 20× `"orb"` bullets in a full-circle ring, precessing by `+phase*0.3` rad per volley (denser and faster-precessing than the stage-1 ring). Damage 12, speed 175, radius 7.

*(Verified by `tests/enemies_test.gd`: a 400-tick soak test at 33% HP confirms all three of `"ink"`, `"harpoon"`, `"flame"` are eventually fired.)*

## 4. Visual State Machine (`world_view.gd: boss_pose`)

Rendering picks one of 7 sprite poses (`assets/boss/almirante_*.png`) purely from current simulation flags, checked in this priority order:
1. `hurt` (flickers this pose every 3rd frame while `e.hurt > 0`, i.e. right after taking damage)
2. `charge` (stage-2 telegraph)
3. `spiral` (stage-2 spin barrage) — this pose is also rotated on-screen by `spin_angle * 0.35` to visually sell the spin
4. `fury` (any time `stage >= 3`, overrides the idle/ring distinction for the rest of the fight)
5. `ring` (any time `e.shot > 0`, i.e. just fired — the generic "attacking" flash pose for stages 1)
6. `idle` (fallback)

Health bar and name label are drawn above the sprite unconditionally (`draw_boss`); on death, a dedicated `defeat` sprite sinks 50px over 2.6s as part of the shared corpse-fade VFX system (`draw_corpse`).

## 5. Enrage Timer (implemented)

To prevent a passive/under-leveled party from stalling the fight indefinitely, `step_boss()` now tracks accumulated active-combat time per boss instance:

- **Fields (added to the boss's `Dictionary` in `spawn_enemy()`):** `fight_time` (accumulates by `dt` every frame `step_boss()` runs — i.e. only while the boss has an acquired target, so kiting out of range pauses the clock) and `enraged` (one-way latch, never resets).
- **Trigger:** `const BOSS_ENRAGE_TIME := 150.0` — once `fight_time` exceeds 150s of active combat, `enraged = true` permanently and `say()` announces *"O Almirante entra em furor: os ataques ficam bem mais rápidos!"*.
- **Effect:** `const BOSS_ENRAGE_SCALE := 0.6` and a helper `enrage_scale(e) -> float` (returns `0.6` if enraged, else `1.0`) multiplies every attack-cadence assignment in `step_boss()` — the stage-1 shot cadence (`1.1 * enrage_scale`), the spin-barrage tick rate (`0.11 * enrage_scale`), the stage-2 post-charge pause (`1.0 * enrage_scale`), the stage-3 shot cadence (`0.8 * enrage_scale`), and the stage-transition reset (`1.2 * enrage_scale`). Attack *telegraphs* (the 0.9s charge windup itself) are deliberately left unscaled so the cannon shot stays dodgeable — only the pacing between volleys speeds up (~40% faster attacks after enrage).
- **Test coverage:** `tests/enemies_test.gd` sets `boss.fight_time` just under the threshold, steps once, and asserts `enraged` flips true and the resulting `cd` reflects the scaled-down cooldown.

## 6. Design Notes / Tuning Knobs

- All 3 stages' cadence numbers (`e.cd` resets) and per-bullet stats are **inline literals inside `step_boss()`**, not pulled from a shared table like `UNIFORMS`/`ARMORS` — rebalancing the boss means editing this one function directly, with no risk of accidentally affecting regular enemies (they have their own separate literal table in `step_enemies`). The two new enrage constants follow the same convention and live right above `enrage_scale()`/`step_boss()`.
- HP is 600 (confirmed current in `spawn_enemy()`); the sprite-era doc `SPRITES_0_6.md` previously stated a stale 420 HP figure from before the v0.11 difficulty pass — this has been corrected to reference `docs/DOCAS_0_11.md` as the source of truth.
- `BOSS_ENRAGE_TIME`/`BOSS_ENRAGE_SCALE` are the two knobs to retune if 150s/60% ends up too lenient or too punishing in playtesting; both are top-level `const`s in `scripts/simulation.gd`, not buried inside `step_boss()`.

---

_Deep-dive generated by BMAD Method `document-project` workflow_
