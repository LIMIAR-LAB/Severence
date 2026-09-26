# Marty — Fraturas do Tempo - Architecture

**Date:** 2026-09-25
**Engine:** Godot 4.7.2 (GL Compatibility)

## 1. High-Level Shape

Three GDScript layers, instantiated entirely in code (no `.tscn` scenes besides the empty `scenes/main.tscn` root):

```
scenes/main.tscn (root Node2D)
  └─ scripts/main.gd  (extends Node2D)   ← app/controller: input, camera, save, ENet networking
       ├─ scripts/simulation.gd (Expedition, extends RefCounted)  ← pure game state + rules
       ├─ scripts/world_view.gd (DockView, extends Node2D)        ← world/sprite rendering (_draw)
       ├─ scripts/combat_hud.gd (CombatHUD, extends Control)      ← HUD overlay (_draw)
       └─ scripts/terminal_ui.gd (TemporalTerminal, extends Control) ← all menus
scripts/docks_map.gd (DocksMap, extends RefCounted)   ← static dungeon layout data used by Expedition
```

`main.gd` owns one `Expedition` instance (`sim`) and drives it every physics frame; `world_view.gd` and `combat_hud.gd` only *read* `sim` to draw — they hold no gameplay state themselves.

## 2. Technology Stack (detail)

- **Engine/Renderer:** Godot 4.7.2, `renderer/rendering_method = "gl_compatibility"` (both desktop and mobile) — see `project.godot`. Viewport 1280×800, `canvas_items` stretch mode.
- **Language:** 100% GDScript for runtime code; 100% Python for offline art tooling (never imported by GDScript).
- **Networking:** Godot's built-in high-level multiplayer API over `ENetMultiplayerPeer`, fixed port `24871` (`main.gd: const PORT := 24871`).
- **Persistence:** Two flat JSON files via `FileAccess`, written to the OS user-data directory (`user://`): `progress.json` (cross-run unlocks) and `settings.json` (input/loadout prefs + volume).
- **RNG:** `RandomNumberGenerator` seeded per run (`Expedition.rng`, `Expedition.seed_value`) — same seed ⇒ same enemy-type rolls (not room layout, which is fixed).

## 3. Data Architecture (state management, no DB)

There is no database. All state lives in in-memory GDScript `Dictionary`/`Array` values owned by `Expedition` (`scripts/simulation.gd:5-50`):

| Field | Type | Purpose |
|---|---|---|
| `actors` | `Array[Dictionary]` | 2 player slots (id 0 = Marty, id 1 = Echo/partner/P2); see `actor()` factory, `scripts/simulation.gd:55` |
| `enemies` | `Array[Dictionary]` | Live enemies incl. boss; created by `spawn_enemy()` |
| `bullets` | `Array[Dictionary]` | Projectiles (team 0 = player-aligned, 1 = enemy) |
| `pickups`, `effects`, `chests` | `Array[Dictionary]` | Coins/keys, VFX timers, lootable chests |
| `rooms`, `floors`, `obstacles`, `ramps`, `raised`, `gaps` | `Array[Rect2/Dictionary]` | Collision/level geometry, populated per mode (`make_hub`, `start_arena`, `start_run`) |
| `mech` | `Dictionary` | Single shared Titan mech state (HP, occupant, position) |
| `spectres` | `Array[Dictionary]` | One Spectre drone per actor slot |
| `money`, `keys`, `materials`, `upgrade`, `clears`, `armor_unlocked` | scalars | Run/meta economy; the last 4 persist across runs |
| `nav` (`AStar2D`), `nav_points` | graph | Rebuilt per mode via `build_navigation()`; drives `path_direction()` for AI/companion pathing |

**Serialization contract:** `snapshot()` (`scripts/simulation.gd:872`) returns a `Dictionary` of ~30 named fields (everything above plus `spectres`); `apply_snapshot(data)` does `for name in data: set(name, data[name])`. This dictionary is exactly what gets `var_to_bytes()` + zlib-compressed and sent to network clients (`main.gd: receive_state`), and what `tests/*.gd` use to assert round-trip correctness (e.g. `simulation_test.gd:82`).

**Uniform/Armor data tables** (`scripts/simulation.gd:63-76`): `UNIFORMS` and `ARMORS` are `const Dictionary` lookup tables keyed by id (`"padrao"`, `"mecanico"`, `"espiao"` / `"omega"`), each holding weapon id, speed, melee damage, damage-taken multiplier and (for armor) duration/cooldown. `uniform_of(a)` / uses of `ARMORS[a.armor_type]` are the single source of truth read by simulation, HUD and world-view — changing a balance number only requires editing these tables.

## 4. Component Overview (per-file responsibilities)

### `scripts/simulation.gd` — `Expedition` (43.5 KB, ~880 lines)
Pure rules engine, no engine draw calls, no `_ready`/`_process`. Key method groups:
- **Mode setup:** `make_hub()`, `start_arena()`, `start_run(seed)` — each resets `actors/enemies/bullets/...` and geometry for that mode.
- **Per-frame tick:** `step(dt, commands)` → `step_actor()` (movement/dash/jump/shoot/melee/armor per actor) → `step_spectres()` → `step_enemies()` → `step_boss()` → `step_bullets()` → `collect_pickups()`.
- **Combat:** `fire_actor()`, `melee()`, `sword_attack()` (Ômega 3-hit combo), `damage_actor()` (routes damage through mech HP / fused-Spectre HP / actor HP+armor multiplier).
- **Titan weapons (v0.12):** while `a.mech`, `fire_actor()`'s `"mech"` branch fires a slow splash-damage shell (`MECH_SHELL`: 70 dmg, 0.85s cooldown, explodes for 34 dmg in an 80px radius on any impact); the armor input (R) is redirected to `throw_bomb()` instead of `toggle_armor()` while piloting, lobbing an arced explosive (`MECH_BOMB`: 95 dmg, 125px radius, 2.6s cooldown) resolved by `step_bomb()`/`explode()`. `explode()` calls `line_of_fire()` per enemy so splash damage cannot cross a wall/obstacle. See `docs/TITAN_0_12.md` and `tests/titan_weapons_test.gd`.
- **Interaction:** `interact(a)` — single dispatcher for mech embark/disembark, reviving a downed partner, and every hub/run point-of-interest (portal, bench, armor rack, mural, hangar, chests, shop, side-challenge, extraction).
- **Robots:** `summon_robot()`, `toggle_fusion()`, `end_fusion()`.
- **Nav/physics helpers:** `clear_at()`, `move_body()` (swept sub-stepped collision), `build_navigation()`, `path_direction()`, `line_of_fire()`, `height_at()` (ramp elevation).
- **Persistence surface:** `equip()` (validates + applies loadout), `snapshot()`/`apply_snapshot()`.

### `scripts/docks_map.gd` — `DocksMap` (static data only)
Hand-authored dungeon: `ROOMS` (9 rooms + 1 secret, each a named `Rect2`), `CORRIDORS`, `EXTRA_FLOORS`, `RAISED`/`RAMPS` (one elevated balcony), `GAPS` (one jumpable water channel), `POINTS` (named world positions: spawn, shop, boss, extraction, etc.), `CHESTS`, `OBSTACLES` (~70 placed props with type tags), `DECOR`, `SPAWNS`/`GROUPS` (enemy spawn points + per-point enemy-type pools sampled by the run's RNG).

### `scripts/main.gd` — app controller (25.7 KB, ~450 lines)
- **Bootstrap (`_ready`):** creates `sim`, `world`, `camera`, calls `build_ui()`, loads save data, wires multiplayer signals, and parses `OS.get_cmdline_user_args()` for a large set of `--capture*`/`--network-*-test` developer flags used by the test/screenshot pipeline.
- **Mode launchers:** `start_solo/start_single/start_local/start_seed/host_game/join_game`.
- **Networking:** `submit_input` (client→host RPC, whitelists exact keys), `receive_state` (host→client RPC, decompress + `apply_snapshot`), `request_loadout`/`change_loadout` and `request_robot_action`/`robot_action` (host-authoritative RPC pairs for equipment/robot actions issued by a guest).
- **Input:** `player_input(index, use_primary)` reads keyboard (primary: WASD/mouse; secondary: arrows/IJKL) and gamepad axes/buttons into one normalized command `Dictionary` consumed by `Expedition.step_actor`.
- **`_physics_process`:** the real game loop — menu/map toggles, calls `sim.step()` (or forwards input via RPC if a network client), camera follow + zoom + screen-shake, HUD/audio triggers, periodic `save_progress()` (every 2s, only if data changed), and the screenshot-capture developer path.
- **Persistence:** `save_settings/load_settings` (`user://settings.json`), `save_progress/load_progress` (`user://progress.json`, versioned, host-only in online play).

### `scripts/world_view.gd` — `DockView` (49 KB, ~900 lines)
Pure `_draw()`-based renderer, no state of its own beyond loaded `Texture2D`s. Draws, per mode: hub background (parallax starfield/nebulae/debris + painted `refuge_bg.png` + animated portal/crack/lamp overlays) or dungeon ground (tiled water/floor textures, ramps, gaps, quay edges); then depth-sorted entities (actors, enemies, boss, mech, spectre, obstacles) via a single `drawable` array sorted by `y`; then bullets and every `effects[]` VFX kind (slash/impact/shockwave/transform/chest_burst/stomp/…). `marty_pose(facing)` maps an 8-way aim vector to one of 5 sprite-sheet rows (front/¾/side/¾back/back, mirrored for left).

### `scripts/combat_hud.gd` — `CombatHUD` (10.7 KB)
Also pure `_draw()`. Reads `app.sim` directly to draw: portrait + heart bar (`hp / (100 + upgrade*10)`), dash-charge pips, uniform/armor status box (ready / active-with-timer / recharging), current weapon icon, partner status, minimap (`draw_minimap`) and full map overlay (`draw_full_map`, toggled by Tab/M), robot HP bar, and the keys/coins/fragments counters. Also implements the Enter-the-Gungeon-style minimap/map icon system (`map_icon`, `draw_map_icons`).

### `scripts/terminal_ui.gd` — `TemporalTerminal` (20.5 KB)
The entire menu system as one class. `show_screen(name)` tears down and rebuilds a `Control` tree per screen (`main`, `play`, `online`, `equipment`, `seed`, `options`), loading the matching background PNG from `assets/ui/`. Generic `panel()`/`label()`/`button()` helpers build styled/transparent `Control`s at literal pixel `Rect2`s measured against the supplied concept art. Screen-specific builders: `build_main`, `build_play` (solo/AI choice), `build_online` (host/join by IP), `build_equipment` (uniform/armor/robot picker, applies instantly on click via `choose()` → `apply_gear()`), `build_seed`, `build_options`.

## 5. Testing Strategy

All 7 files in `tests/` `extends SceneTree` and run headless via Godot's `--script` flag (no test framework/runner dependency). Two styles:
- **Pure-logic tests** (`simulation_test.gd`, `combat_regression_test.gd`, `enemies_test.gd`, `omega_test.gd`, `refuge_test.gd`) instantiate `Expedition`/`Sim` directly and call its methods, asserting on the resulting state — fast, no scene tree needed.
- **Integration tests** (`input_scene_test.gd`, `solo_robot_test.gd`) instantiate the full `main.tscn` scene, synthesize real `InputEventKey`/mouse events via `Input.parse_input_event`, and await physics frames — these exercise the actual UI callbacks and `_physics_process` loop end-to-end.

A separate PowerShell script (`tools/test_network.ps1`) launches two headless Godot processes with `--network-host-test` / `--network-client-test` flags (parsed in `main.gd:_ready`) to validate real ENet connection, remote movement and snapshot delivery between two OS processes.

## 6. Networking Architecture (single "part", so documented inline rather than as separate integration doc)

- **Topology:** direct IP, host-authoritative, exactly one guest (id 1 / P2). No lobby, relay, matchmaking, UPnP or NAT traversal.
- **Host → Client:** `receive_state(packet: PackedByteArray)`, `@rpc("authority","call_remote","reliable")`, sent every `0.05s` from `_physics_process`; payload is `var_to_bytes(sim.snapshot()).compress(FileAccess.COMPRESSION_DEFLATE)`.
- **Client → Host:** `submit_input(data: Dictionary)`, `@rpc("any_peer","call_remote","reliable")`; host whitelists exact key names/types before trusting it (`main.gd:193-200`) — the client's own `main.gd` never runs `sim.step()`, it just displays whatever snapshot arrived.
- **Equipment/robot RPCs:** `change_loadout`/`robot_action` let a guest request an action; the host validates via `sim.equip()`/`sim.summon_robot()`/`sim.toggle_fusion()` before applying — no direct guest-side mutation of `sim`.
- **Failure/recovery:** guest disconnect → host's `coop` flips back to `"ai"` and the AI takes over P2 (`peer_disconnected`); client-side failures show a status label and return to the menu.

## 7. Deployment / Distribution

None in this version. The game runs from source inside the Godot editor or via `Jogar.cmd` (which shells out to a locally-installed Godot executable). No `export_presets.cfg`, no CI/CD config, no packaging step exists yet (explicitly called out as a pending milestone in `README.md`).

---

_Generated using BMAD Method `document-project` workflow (exhaustive scan)_
