# Deep Dive — Progression & Economy System

**Date:** 2026-09-25 · Source: `scripts/simulation.gd`, `scripts/main.gd`

## 1. Two Persistence Tiers

| Tier | Fields | File | Written by | Lifetime |
|---|---|---|---|---|
| **Per-run currency** | `money`, `keys` | not persisted | reset every `start_run()`/`start_arena()` | resets on death/return to hub |
| **Cross-run meta-progress** | `materials` (fragments), `upgrade` (0–3), `clears`, `armor_unlocked` | `user://progress.json` | `main.gd: save_progress()` | survives app restarts |

`save_progress()` writes `{"version": 1, "materials", "upgrade", "clears", "armor_unlocked"}` — note **`money`/`keys` are deliberately excluded**, matching the README's stated design ("Dinheiro e chaves reiniciam por tentativa"). The write is atomic: it serializes to `user://progress.tmp` then `DirAccess.rename_absolute` to `progress.json`, and skips the write entirely if the serialized string is unchanged since last save (`last_save` comparison) — called every 2s from `_physics_process`, plus once on `NOTIFICATION_WM_CLOSE_REQUEST`.

`load_progress()` validates `data.get("version", 0) != 1` and bails (no migration logic yet — a future version bump would need explicit handling). In online play, only the host persists progress (`if online and not hosting: return`); guest progression is an explicitly acknowledged gap (README: "progressão própria do convidado ainda não foi implementada").

## 2. Currency Sources (dungeon run)

| Source | Money | Keys | Other | Where |
|---|---|---|---|---|
| Kill any enemy | +4 | +20% chance +1 | — | `step_enemies` death cleanup |
| Open a normal chest | — | −1 (cost) | +10 money, +25 HP, armor cooldown reset to 0 | `interact()` "run" chest branch |
| Open the **secret** chest | — | −1 (cost) | same as above **+1 material (fragment)** | same branch, `if chest.secret: materials += 1` |
| Pick up a coin/key world object | +2 / +1 | — | — | `collect_pickups()` |
| Shopkeeper purchase (one-time per run) | −15 | +1 | +40 HP (capped) | `interact()` "shop" branch, gated by `shop_bought` |
| Optional side-challenge (55s, 7 guardians) | +25 | +2 | +35 HP (capped), **+1 material** | `interact()` "side" branch to start; completion handled in `step()` |
| Boss defeat + reach extraction | — | — | **+3 materials**, `clears += 1`, `armor_unlocked = true` (one-time via `reward_claimed` guard) | `interact()` "run" extraction branch |

**Starting stake per run:** `start_run()` sets `money = 12; keys = 1` unconditionally — the run economy always begins from the same baseline regardless of meta-progress.

## 3. Spending Permanent Fragments (Hub "Bancada")

`interact()` hub `"bench"` branch: costs **2 materials** for **+10 max HP** (`upgrade += 1`), capped at **`upgrade < 3`** (so max +30 HP total, i.e. up to 130 base HP via `max_hp = 100 + upgrade * 10`, referenced in `combat_hud.gd:46` and `start_run()`'s `a.hp = 100 + upgrade * 10`). Attempting to buy past the cap or without enough materials just prints the current progress via `say()` without spending.

## 4. Side-Challenge State Machine

Fields: `side_active`, `side_complete`, `side_failed`, `side_time` (55s countdown).

1. **Trigger:** player interacts near `DOCKS.POINTS.side` while none of active/complete/failed are true. Spawns exactly 7 enemies (`cult`/`brute` alternating) tagged `side: true` at fixed offsets, starts the 55s timer.
2. **Each `step()` tick while active:** `side_time -= dt`.
   - **Timeout (`side_time <= 0`):** `side_active = false; side_failed = true` — permanently failed for the rest of the run, no retry.
   - **All `side`-tagged enemies dead:** `side_active = false; side_complete = true` and grants the reward listed above, exactly once (checked via `enemies.filter(side).is_empty()`, which naturally becomes true only once and `side_active` immediately flips off).
3. Both `side_complete` and `side_failed` permanently block re-triggering the challenge for that run (checked in the trigger condition itself).

## 5. Chests & Keys

- 3 fixed chest positions per run (`DOCKS.CHESTS`), 1 flagged `secret` (only reachable after `open_secret()`, itself triggered by a melee hit near `DOCKS.POINTS.secret_wall`).
- Each chest independently tracks `open: bool`; opening is a one-time, key-gated action (`keys <= 0` blocks it with a message, no partial/discounted retry).
- Opening plays a `"chest_burst"` VFX and **fully resets that actor's armor cooldown to 0**, not the whole party's — a subtle detail: only the actor who pressed E gets the free armor recharge.

## 6. Settings vs. Progress — Two Independent JSON Files

- `user://settings.json` (`pref_outfit`, `pref_robot`, `volume_percent`, plus legacy `armor`/`gun` fields still written for backward compatibility but not meaningfully used by current loadout logic) — purely cosmetic/input preference, no version field, defensive `.get(key, default)` per field, including a one-line migration (`"londres"` → `"espiao"` string remap) for saves from before the Espião uniform rename.
- `user://progress.json` — the actual meta-progression economy described above, with a `version` guard.

These are never merged into one file and are loaded/saved independently (`load_settings`/`save_settings` vs `load_progress`/`save_progress`), so a corrupted/incompatible `progress.json` does not affect loadout preferences and vice versa.

---

_Deep-dive generated by BMAD Method `document-project` workflow_
