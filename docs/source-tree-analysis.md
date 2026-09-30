# Severence — Ecos do Tempo - Source Tree Analysis

**Date:** 2026-09-25

## Overview

Single-part Godot 4.7.2 project. All runtime logic lives in 6 GDScript files under `scripts/`; there are no subfolders inside `scripts/` and no additional engine scenes besides the single empty root `scenes/main.tscn`. Tests, offline art tools, and generated docs are cleanly separated at the project root.

## Complete Directory Structure

```
Jogo Steam/
├── project.godot                 # Engine config: viewport 1280x800, GL Compatibility renderer, main scene
├── Jogar.cmd                      # Double-click launcher, calls local Godot_v4.7.2 executable
├── README.md                      # User-facing manual (PT-BR): controls, flow, network, art credits, limits
├── .gitignore
├── scenes/
│   └── main.tscn                  # Empty root Node2D; scripts/main.gd builds everything else in code
├── scripts/                       # All runtime GDScript (no subfolders)
│   ├── simulation.gd              # Expedition (RefCounted) — game state + rules, network-serializable
│   ├── docks_map.gd               # DocksMap (RefCounted) — static hand-authored dungeon layout data
│   ├── main.gd                    # App controller — input, camera, save, ENet networking, dev capture flags
│   ├── world_view.gd              # DockView (Node2D) — world/sprite/VFX rendering (_draw)
│   ├── combat_hud.gd              # CombatHUD (Control) — HUD/minimap/map overlay rendering (_draw)
│   └── terminal_ui.gd             # TemporalTerminal (Control) — every menu screen, built in code
├── tests/                         # 7 headless GDScript test suites (extends SceneTree)
│   ├── simulation_test.gd         # Core rules: mech seat, damage, seeded runs, chests, shop, nav, revive
│   ├── combat_regression_test.gd  # Bullet freeze/dash/turn/animation/arena-wave regressions
│   ├── enemies_test.gd            # Per-enemy attack patterns + 3-phase boss
│   ├── omega_test.gd              # Armor transformation, sword combo, chest, Titan turbo
│   ├── refuge_test.gd             # Hub walkability/reachability of every point of interest
│   ├── input_scene_test.gd        # Full-scene real keyboard/mouse input → gameplay effect
│   └── solo_robot_test.gd         # Solo-mode UI flow + robot/Spectre fusion edge cases
├── tools/                         # Offline art/asset generation (Python) — never imported at runtime
│   ├── prepare_art.py             # v1 atlas: background-key removal + grid re-detection (Marty/Titan)
│   ├── prepare_marty_v2.py        # Registers approved v2 Marty sheet from output/imagegen/
│   ├── prepare_reference_assets.py# Crops reusable pieces from user-supplied docks reference art
│   ├── prepare_refuge.py          # Cleans hub background + extracts Temporal Core overlay (needs cv2)
│   ├── prepare_sprites_v6.py      # Cuts v1-concept sheets: outfits, enemies, boss + projectiles
│   ├── sprite_cut.py              # Shared gray-background removal utility (used by v6 prep)
│   ├── erase_painted_guns.py      # Removes painted-on pistols so the real weapon sprite can render
│   ├── animate_sprites.py         # Derives walk/shoot/jump animation frames by leg-cutting poses
│   ├── make_weapons.py            # Procedurally draws pistol/shotgun/smg + muzzle flash sprites
│   ├── make_support_assets.py     # Procedural floor texture + 4 synthesized WAV sound effects
│   └── test_network.ps1           # Spawns 2 headless Godot processes to validate ENet integration
├── assets/                        # Runtime-loaded art/audio (see asset-inventory.md)
│   ├── marty/  mech/  enemies/  boss/  weapons/  ui/  environment/  audio/
├── art/                           # Source references, prompts, and PNG/GIF previews (not loaded at runtime)
│   └── source/                    # Raw AI-generated concept sheets + prompt .txt files
├── output/imagegen/               # Raw generator output before prepare_*.py processing
├── docs/                          # Versioned design/changelog notes (this file's sibling set)
├── test-output/                   # Screenshot captures written by --capture* dev flags (gitignored likely)
└── Claude outputs/                # Stray external-tool output (1 duplicate preview GIF)
```

## Critical Directories

### `scripts/`

All gameplay, rendering, UI and networking code for the entire game.

**Purpose:** Single source of runtime logic; matches `documentation-requirements.csv` `critical_directories` pattern `Scripts/;scripts/` for project type `game`.
**Contains:** 6 `.gd` files (~183 KB total) + their Godot-generated `.uid` sidecar files.
**Entry Points:** `main.gd` (attached to `scenes/main.tscn`'s root node, run via `run/main_scene` in `project.godot`).
**Integration:** `main.gd` composes `simulation.gd`, `world_view.gd`, `combat_hud.gd`, `terminal_ui.gd` by direct instantiation (`preload(...).new()`), not via the scene tree/editor.

### `scenes/`

**Purpose:** Godot scene files. Deliberately minimal — the whole UI and world are built in GDScript, not the Godot scene editor.
**Contains:** exactly one file, `main.tscn` (163 bytes — an essentially empty root node).

### `tests/`

**Purpose:** Regression safety net for the simulation, combat, enemies/boss, hub navigation, armor system, and real input-driven gameplay.
**Contains:** 7 `SceneTree`-based suites, run individually via Godot's `--headless --script` flag; no external test runner/framework.
**Entry Points:** each file's `_init()` or `_initialize()`/`run()` (async ones need a scene, so use `_initialize` + `await`).

### `tools/`

**Purpose:** One-shot, reproducible art/audio generation from source concept images. Not part of the shipped game and not referenced by any `.gd` file.
**Contains:** 10 Python scripts (Pillow/NumPy, some also OpenCV) + 1 PowerShell integration-test script.

### `assets/`

**Purpose:** All textures/audio actually `load()`-ed by `world_view.gd`, `combat_hud.gd`, and `main.gd` at runtime.
**Contains:** see `asset-inventory.md` for the full breakdown by subfolder.

## Entry Points

- **Main Entry:** `scripts/main.gd` (`_ready()`), attached to `scenes/main.tscn`, launched via `project.godot`'s `run/main_scene`.
- **Additional:**
  - `Jogar.cmd`: shells out to a hard-coded local Godot 4.7.2 executable path with the project folder — the actual "run the game" entry point for the end user on Windows.
  - `tests/*.gd`: each is an independent entry point when run with `--script`.
  - `tools/*.py`: each is an independent CLI entry point (`python tools/<name>.py`), not wired to any build system.

## File Organization Patterns

- **No subfolders inside `scripts/`** — flat, one class per file, each with an explicit `class_name` (`Expedition`, `DocksMap`, `DockView`, `CombatHUD`, `TemporalTerminal`) except `main.gd` which is the anonymous scene-attached script.
- **Data-as-code:** dungeon layout (`docks_map.gd`), uniform/armor stats (`simulation.gd` `UNIFORMS`/`ARMORS` consts), and enemy stats (`spawn_enemy`'s inline `Dictionary` literal) are all plain GDScript constants/literals rather than `.tres`/`.json` resource files — there is no separate data layer to keep in sync.
- **`.uid` sidecars:** every `.gd` file has a matching Godot 4.4+ `.uid` file (stable script identity across renames); these are engine-managed, never hand-edited.
- **`.import` sidecars:** every `.png`/`.wav` under `assets/` and `art/` has a matching Godot `.import` file (auto-generated import settings); do not hand-edit.
- **Versioned prose docs, not changelogs-as-code:** `docs/*.md` are named by feature+version (e.g. `SPRITES_0_6.md`, `DOCAS_0_11.md`, `EQUIPAMENTO_0_9.md`) rather than a single running `CHANGELOG.md`.

## Key File Types

### GDScript source
- **Pattern:** `scripts/*.gd`
- **Purpose:** All runtime behavior.
- **Examples:** `simulation.gd`, `main.gd`, `world_view.gd`, `combat_hud.gd`, `terminal_ui.gd`, `docks_map.gd`

### GDScript tests
- **Pattern:** `tests/*_test.gd`
- **Purpose:** Headless regression checks (`extends SceneTree`).
- **Examples:** `simulation_test.gd`, `enemies_test.gd`, `omega_test.gd`

### Offline art/audio tooling
- **Pattern:** `tools/*.py`, `tools/*.ps1`
- **Purpose:** Reproducible asset generation and one network integration test; never imported by the game.
- **Examples:** `prepare_sprites_v6.py`, `animate_sprites.py`, `make_support_assets.py`, `test_network.ps1`

### Engine resource sidecars
- **Pattern:** `*.uid`, `*.import`
- **Purpose:** Godot-managed metadata; do not hand-edit.

## Asset Locations

See `asset-inventory.md` for the full catalog. Summary:

- **Character/enemy/boss sprites:** `assets/marty/`, `assets/enemies/`, `assets/boss/`, `assets/mech/` (12 PNG atlases)
- **Weapons/projectiles/VFX:** `assets/weapons/` (14 PNGs)
- **Environment (dungeon + hub):** `assets/environment/` (docks/, reference/, refuge/ subfolders, ~56 files)
- **UI backgrounds:** `assets/ui/` (4 large concept-art PNGs, ~1.2–1.5 MB each)
- **Audio:** `assets/audio/` (4 synthesized WAV SFX; no music in this version)
- **Source/reference (not loaded at runtime):** `art/source/` (14 files: prompts + AI-generated concept sheets), `output/imagegen/` (raw generator output)

## Configuration Files

- **`project.godot`**: Godot engine/project configuration (viewport size, renderer, main scene, animation compatibility flag).
- **`.gitignore`**: standard exclusions.
- **`user://settings.json` / `user://progress.json`** (runtime-written, not in repo): player preferences and cross-run progress, in the Godot user-data directory, not the project folder.

## Notes for Development

- Because `Expedition` is a plain `RefCounted` with no `_process`, all pure-logic tests can `Sim.new()` and call methods directly with zero scene-tree/engine overhead — prefer this style for new gameplay tests over the slower `input_scene_test.gd`/`solo_robot_test.gd` scene-based style.
- `UNIFORMS`/`ARMORS`/enemy-stat dictionaries in `simulation.gd` are the single source of truth for balance; the HUD (`combat_hud.gd`) and world renderer (`world_view.gd`) both read from `sim.uniform_of()`/`sim.ARMORS[...]` rather than duplicating numbers.
- Dungeon geometry changes go in `docks_map.gd` only; `Expedition.start_run()` just copies `DocksMap` consts into instance state, so editing room/obstacle/spawn coordinates there is safe and test-covered (`simulation_test.gd`, `refuge_test.gd` cover reachability-style invariants for the hub; there is no equivalent exhaustive reachability test yet for the dungeon).
- Any new developer `--capture-*` flags should follow the existing pattern in `main.gd:_ready()` (parse from `OS.get_cmdline_user_args()`, set `screenshot_mode = true`, call the appropriate `start_*`).

---

_Generated using BMAD Method `document-project` workflow (exhaustive scan)_
