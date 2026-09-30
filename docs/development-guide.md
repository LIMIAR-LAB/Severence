# Severence — Ecos do Tempo - Development Guide

**Date:** 2026-09-25

## Prerequisites

- **Godot Engine 4.7.2** (stable, GL Compatibility build). This project hard-codes the path `C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe` in `Jogar.cmd` and `Godot_v4.7.2-stable_win64_console.exe` (same folder) in test/validation commands — update these paths if Godot is installed elsewhere.
- **No Node/npm, no login, no API key** required to play or develop.
- **Optional, only for regenerating art:** Python 3 with `Pillow`, `numpy`; `prepare_refuge.py` and `prepare_sprites_v6.py` additionally need `opencv-python`.

## Environment Setup

Nothing to install for the game itself. If you want to regenerate art:

```powershell
pip install pillow numpy opencv-python
```

## Local Development

### Run the game

```powershell
# Option A — double-click / shell:
Jogar.cmd

# Option B — Godot editor:
# open project.godot in Godot 4.7.2, press F5
```

### Run all headless tests

```powershell
$godot = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path . --script tests/simulation_test.gd
& $godot --headless --path . --script tests/combat_regression_test.gd
& $godot --headless --path . --script tests/enemies_test.gd
& $godot --headless --path . --script tests/omega_test.gd
& $godot --headless --path . --script tests/refuge_test.gd
& $godot --headless --path . --script tests/input_scene_test.gd
& $godot --headless --path . --script tests/solo_robot_test.gd
```

Each suite prints `PASS: <description>` per check and a final `... N failures` line, then exits with code `1` if any check failed (suitable for CI gating even though no CI is currently configured).

### Network integration test (2 local processes)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_network.ps1
```

Launches one headless Godot with `-- --network-host-test` and one with `-- --network-client-test`, waits up to 15s each, and asserts on their stdout/stderr logs (`test-output/network-*.log`) for a successful connection, remote movement, and at least one received snapshot, with zero engine `ERROR`/`WARNING` lines.

### Developer screenshot captures

```powershell
$godotWin = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
& $godotWin --path . -- --capture             # hub screenshot → test-output/refugio.png
& $godotWin --path . -- --capture-run         # dungeon screenshot → test-output/gameplay.png
& $godotWin --path . -- --capture-arena       # arena screenshot → test-output/arena-v06.png
& $godotWin --path . -- --capture-boss --boss-hp=0.5   # boss arena, boss at 50% HP
& $godotWin --path . -- --capture-ui-play     # menu screen screenshot → test-output/ui-play.png
```

These open a real (temporary) window, render one frame at a chosen tick, save a PNG under `test-output/`, print `CAPTURE_SAVED <path>`, and quit. See `scripts/main.gd:_ready()`/`capture()` for the full flag list (`--capture-docks-v04`, `--capture-ui-<page>` for `main/play/online/equipment/options`, `--outfit=`, `--armor`, `--transform-demo`, `--hub-pos=x,y`, `--boss-hp=`, `--open-chest`, `--demo-walk`, `--visit-all`).

### Regenerate art (optional, not required to play)

```powershell
python tools/prepare_sprites_v6.py     # cuts v1 concept sheets into game atlases
python tools/erase_painted_guns.py     # must run before animate_sprites.py
python tools/animate_sprites.py        # derives walk/shoot/jump frame variants
python tools/make_weapons.py           # procedural weapon/flash sprites
python tools/make_support_assets.py    # procedural floor texture + synthesized SFX
python tools/prepare_refuge.py         # hub background cleanup (needs opencv-python)
```

## Testing Approach

- **Style A — pure logic** (`simulation_test.gd`, `combat_regression_test.gd`, `enemies_test.gd`, `omega_test.gd`, `refuge_test.gd`): instantiate `Expedition`/`Sim` directly (`Sim.new()`), no scene tree, synchronous `_init()`. Fastest; prefer this style for new rules/balance tests.
- **Style B — scene integration** (`input_scene_test.gd`, `solo_robot_test.gd`): instantiate `res://scenes/main.tscn`, await physics frames, synthesize real `InputEventKey`/`InputEventMouseButton` via `Input.parse_input_event`. Use only when the thing under test genuinely depends on `main.gd`'s `_physics_process` loop, UI callbacks, or camera/HUD wiring.
- **No mocking framework** — tests call real methods on a real (but headless, isolated) `Expedition`/scene instance and assert on resulting field values.
- **No code coverage tooling configured.**

## Common Development Tasks

| Task | Where |
|---|---|
| Add/rebalance a uniform or the armor | `scripts/simulation.gd` — `UNIFORMS` / `ARMORS` consts (~line 63) |
| Add/rebalance an enemy type | `scripts/simulation.gd` — `spawn_enemy()` HP table + `step_enemies()` `match e.kind` attack block |
| Change boss phases/attacks | `scripts/simulation.gd` — `step_boss()` |
| Edit dungeon layout (rooms/obstacles/spawns/chests) | `scripts/docks_map.gd` |
| Edit hub layout/points of interest | `scripts/simulation.gd` — `make_hub()`, `HUB_POINTS` |
| Add a new menu screen | `scripts/terminal_ui.gd` — add a `build_<name>()` and a case in `show_screen()`'s `match` |
| Add a new HUD element | `scripts/combat_hud.gd` — `_draw()` |
| Add a new world VFX kind | `scripts/world_view.gd` — `effects[]` handling inside `draw_entities()`, plus wherever the effect is appended in `simulation.gd` |
| Add a new `--capture-*` dev flag | `scripts/main.gd` — `_ready()` arg parsing + `capture()` path selection |
| Add a networked action | Add validation in `Expedition`, then a host-authoritative `@rpc` pair in `main.gd` following the `request_robot_action`/`robot_action` pattern |

## Deployment / CI

Not applicable in this version — no export presets, no CI/CD pipeline, no packaging step. See `README.md` "Limites desta entrega" for the acknowledged gap (Windows packaging is a listed next milestone).

## Contribution Guidelines

No `CONTRIBUTING.md` exists. Informal conventions observed in the codebase:
- Comments and UI copy are written in **Brazilian Portuguese**; keep new user-facing strings and design-rationale comments consistent with that.
- Prefer dense, single-line GDScript statements chained with `;` for small state updates (matches the existing style in `simulation.gd`/`main.gd`), but do not sacrifice readability for very branchy logic (see `step_boss()` for the accepted level of match-statement complexity).
- Every new gameplay rule should get a corresponding assertion in the closest matching `tests/*.gd` file before being considered done — this project relies entirely on these headless suites, there is no manual QA checklist.

---

_Generated using BMAD Method `document-project` workflow (exhaustive scan)_
