# Deep Dive — Enemy AI & Partner AI (Echo)

**Date:** 2026-09-25 · Source: `scripts/simulation.gd`

## 1. Shared Navigation Substrate

Both enemy pursuit and Echo's pathing ride on the same `AStar2D` graph, rebuilt from scratch every time the level geometry changes (`build_navigation()`, called by `make_hub()`, `start_arena()`, `start_run()`, and `open_secret()`):

- Grid step: **50px** in dungeon (`mode == "run"`), **40px** in hub/arena.
- A node is added at `(x, y)` only if `clear_at(Vector2(x, y), 15)` (walkable with a 15px radius).
- Edges connect right/down neighbors only (`Vector2i(step, 0)` and `Vector2i(0, step)`) when both ends are walkable, height-difference `< 15`, and the midpoint is also clear — so diagonal-only gaps are not traversable by the graph even if a player could dash through them.
- `path_direction(from, to)` (`simulation.gd:298`) caches the computed `PackedVector2Array` path in `ai_path` for **0.4s** (`ai_path_timer`) before recomputing, and pops waypoints once the mover is within 30px — this is a shared helper, so both Echo and every alerted enemy reuse the exact same throttling.

## 2. Enemy Perception & Aggro (`step_enemies`, `simulation.gd:624`)

- **Perf guard for big rooms:** an enemy that is not yet `alerted` and is not the boss only re-checks line-of-sight every **0.3s** (`e.los_t`), not every frame — necessary because the dungeon has dozens of enemies across large rooms.
- **Detection range:** `detection_range(a, base)` (`simulation.gd:620`) returns `base * 0.55` if the *player* is wearing the "Espião" (spy) uniform and not piloting the mech — i.e. stealth is a player-uniform property, not a per-enemy stat. Base ranges: boss `900`, everyone else `700`; once `alerted`, the effective reach is clamped to at least `640` (so an alerted enemy won't instantly lose the player at the boundary).
- **Acquisition:** for each actor, compute distance; the *closest* actor within range **and** with line-of-fire (`line_of_fire`) or already `alerted` (or is the boss, who ignores LoS for acquisition) becomes `target`. If no target is found this frame, the enemy does nothing (`continue`) — no idle wander/patrol behavior exists.
- **Once alerted, `e["alerted"] = true` is permanent** for that enemy instance (never reset) — enemies do not lose aggro or return to a dormant state.

## 3. Per-Enemy Movement & Attack Patterns

All 4 non-boss kinds share one movement rule — close to a **preferred distance**, then fire on a per-kind cooldown — but with different numbers (`simulation.gd:647-674`):

| Kind | Preferred dist. | Move speed | Attack cooldown | Attack |
|---|---|---|---|---|
| `cult` (Cultista Atirador) | 240 | 100 | 0.9s | 1 magenta orb toward player, +35% chance of a 2nd orb at +0.18 rad spread |
| `fish` (Arpoador) | 210 | 85 | 1.4s | 1 harpoon shot; on hit, applies `a.snare = 0.9` (60% speed penalty) to the victim, handled in `step_actor` |
| `brute` (Soldado Possuído) | 220 | 95 | 1.2s | 6-bullet violet fan, ±0.12 rad step each, all in one volley |
| `crawler` (Rastejante Tentacular) | 110 | 140 | 0.8s | only fires (3-shot acid fan) if within 220px; otherwise just closes distance |
| `crawler_small` (split spawn) | 18 | 170 | 0.55s | no projectile — deals 8 contact damage directly if within 34px |

**Crawler split:** on death, if `e.kind == "crawler"`, two `crawler_small` are spawned at ±(18,∓6) offsets (only if `clear_at`) — handled in the death-cleanup pass at the bottom of `step_enemies`, not inside the attack `match`.

**Death rewards (applies to every enemy):** +4 money, always drops a coin pickup, 20% chance of an extra key pickup, and a `"corpse"` VFX effect that fades over 1.2s (2.6s for the boss).

## 4. Boss AI — "O Almirante das Profundezas" (`step_boss`, `simulation.gd:688`)

3 HP-ratio-gated stages, each with its own attack `match e.phase % N`:

- **Stage transition** (`e.hp/e.max` crossing 66% or 33%) resets `e.cd`/`e.spin`/`e.charge`, plays a `"weapon_drop"` VFX, and announces the stage via `say()`.
- **Stage 1 (>66% HP):** alternates every phase between a 16-orb full ring (odd phases) and a 7-bullet aimed fan (even phases), cadence ~1.1–1.4s.
- **Stage 2 (33–66% HP):** every 3rd phase does a **0.9s charge-up** then fires one heavy `"cannon"` bullet (24 dmg, radius 13, pierces via 4s lifetime); other phases trigger a **2.2s spinning barrage** (`e.spin`), firing 2–3 orbs every 0.11s at an incrementing angle.
- **Stage 3 / Fury (<33% HP):** cycles 3 attacks by `phase % 3`: (0) 3-shot ink volley, (1) 1 harpoon + a 6-bullet flame cone if the player is within 260px, (2) a 20-orb full ring.
- **Defeat:** at `hp <= 0`, `boss_dead = true`, unlocking the extraction capsule back at spawn; the boss corpse fades over 2.6s with a distinct death sprite.

## 5. Partner AI — Echo (`ai_input`, `simulation.gd:319`)

Runs only when `coop == "ai"` and it's actor id 1's turn in `step()` (`if a.id == 1 and coop == "ai": cmd = ai_input()`) — so switching to `"local"`/`"online"` coop fully disables this function for that slot.

Decision order per frame:
1. **Base movement:** path toward the leader (actor 0) if farther than 100px, else stand still.
2. **If an enemy is within 720px:** aim at it; `fire = line_of_fire(...)`. If no line of fire or it's farther than 330px, path toward the enemy instead of the leader. If within 145px, back away (`-delta_enemy.normalized()`); between 145–330px with line of fire, strafe orthogonally (`0.55` weight) rather than closing further. Melee triggers automatically under 65px.
3. **Self-preservation:** if any enemy bullet is within 65px, override movement with a dodge-perpendicular vector and set `command.dodge = true` (checked *after* the targeting block, so it can override the strafe direction that frame).
4. **Auto-armor:** if unarmored, off cooldown, an enemy is within 300px, and not piloting the mech, requests `command.armor = true` — Echo will self-activate the Ômega armor in a fight without being told to.
5. **Reviving:** if the leader is `dead`, Echo paths to the leader's position and, once within 75px, sets `command.interact = true` (the same interact channel used for mech/chests/portals — `interact()` resolves it to "revive nearby dead partner" because that check comes first in its `match`-like priority chain).
6. **Opportunistic mech use:** if not already piloting/fused, there's a live target, the Titan is deployed/unoccupied/alive, and Echo is within 220px of it, Echo will path to and board the Titan instead of continuing to fight on foot.
7. **Jump assist:** mirrors the leader's jump state (`if leader.jump > 0: command.jump = true`) and, in dungeon mode, force-jumps whenever standing over a `gaps[]` rect (grown by 35px) — Echo does not independently decide to jump for any other reason (e.g. it does not dodge incoming melee via jump).

**Known limitation (acknowledged in `README.md`):** "Sua inteligência e equilíbrio ainda são básicos" — Echo has no formation/flanking logic beyond the single strafe-offset rule above, and reuses Marty's sprite atlas tinted gold rather than having unique art or a distinct kit.

---

_Deep-dive generated by BMAD Method `document-project` workflow_
