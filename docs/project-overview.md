# Severence — Ecos do Tempo - Project Overview

**Date:** 2026-09-25
**Type:** game
**Architecture:** Monolithic single-player/co-op game client (client-authoritative host model for netplay)

## Executive Summary

"Severence — Ecos do Tempo" is a top-down (3/4 perspective) pixel-art action game built in **Godot 4.7.2** (GL Compatibility renderer). The player controls Marty through a hub area ("Refúgio • Fora do Tempo") and a fixed dungeon-style map ("Docas de 1941") fighting enemies, collecting keys/coins/fragments, piloting a mech ("Titan"), and using a drone companion ("Spectre") that can fuse with the player. The game supports solo play, an AI companion, local split-input co-op, and direct-IP online co-op (ENet, host-authoritative). This is version 0.11, a functional MVP prototype — not a finished campaign or final art pass.

## Project Classification

- **Repository Type:** Monolith (single Godot project, no client/server split)
- **Project Type(s):** game (detected via `project.godot`, `scenes/`, `scripts/`)
- **Primary Language(s):** GDScript (engine logic), Python (offline art/asset tooling, not runtime)
- **Architecture Pattern:** MVC-ish split — a serializable simulation model (`Expedition` in `scripts/simulation.gd`), a rendering/view layer (`DockView` in `scripts/world_view.gd`, `CombatHUD` in `scripts/combat_hud.gd`), and an app/controller layer (`scripts/main.gd`) that owns input, camera, persistence and networking. `scripts/terminal_ui.gd` implements all menu screens as one hand-built UI system drawn over supplied concept-art backgrounds.

## Technology Stack Summary

| Category | Technology | Version | Justification |
|---|---|---|---|
| Engine | Godot Engine | 4.7.2 (GL Compatibility) | `project.godot` `config/features=("4.7","GL Compatibility")` |
| Language | GDScript | Godot 4.x | All gameplay/UI/network code |
| Networking | Godot High-Level Multiplayer (ENet) | built-in | `scripts/main.gd` — UDP port 24871, host-authoritative snapshots |
| Persistence | JSON via `FileAccess` | built-in | `user://progress.json` (fragments/upgrades/clears), `user://settings.json` (prefs) |
| Art tooling (offline) | Python + Pillow + NumPy + OpenCV | n/a | `tools/*.py` — sprite sheet extraction/animation, never required at runtime |
| Audio | Synthesized WAV (NumPy) | n/a | `tools/make_support_assets.py` generates `assets/audio/*.wav` |

## Key Features

- **Two areas:** Hub ("Refúgio • Fora do Tempo", `Expedition.make_hub()`) and a large fixed dungeon map ("Docas de 1941", `scripts/docks_map.gd` + `Expedition.start_run()`), plus a standalone combat-testing "Arena" mode (`Expedition.start_arena()`).
- **Combat:** 3 selectable uniforms (Padrão/Mecânico/Espião) each with its own gun, melee tool, speed and damage-taken multiplier; a temporary "Armadura Ômega" power-up with its own 3-hit energy-sword combo, speed boost and damage reduction; 4 enemy types plus a 3-phase boss ("O Almirante das Profundezas").
- **Robots:** Pilotable mech "Titan" (own HP pool persists across embark/disembark, turbo boost) and drone "Spectre" (follows/shoots, or fuses with Marty to absorb damage and boost stats).
- **Progression:** Keys/coins/fragments per run; permanent upgrades and armor unlock persisted to `user://progress.json`; an optional 55s "defend the generator" side-challenge; a hidden secret room opened via melee on a cracked wall.
- **Multiplayer:** Solo, Solo+AI, local split-input co-op (keyboard+gamepad or two gamepads), and direct-IP online co-op over ENet (host runs the authoritative `Expedition` simulation; client sends inputs and receives compressed snapshots).
- **Menus:** Fully custom UI (`scripts/terminal_ui.gd`) drawn as real `Control` nodes layered over 4 supplied concept-art background images (`assets/ui/*.png`).

## Architecture Highlights

- **Simulation/View separation:** `Expedition` (`scripts/simulation.gd`, `extends RefCounted`) holds 100% of game state as plain `Array`/`Dictionary` values and is fully serializable via `snapshot()` / `apply_snapshot()` — this is what gets compressed and sent over the network, and what the automated tests instantiate directly (no scene tree needed).
- **Deterministic-ish replay:** each run seeds a `RandomNumberGenerator`; `start_run(seed)` with the same seed reproduces the same enemy layout (verified in `tests/simulation_test.gd`).
- **Fixed map, seeded variation:** the dungeon layout is hand-authored in `scripts/docks_map.gd` (rooms, corridors, obstacles, decor, spawn points) — the RNG only picks enemy *types* per spawn point and small position jitter, not room layout.
- **Custom 2D navigation:** an `AStar2D` grid is rebuilt on every `build_navigation()` call (hub/arena/run) from walkable floor rects; used both for AI pathing (`path_direction`) and validated by a test that a route exists from spawn to boss.
- **Host-authoritative netcode:** the host steps the real simulation and periodically (every 0.05s) sends a `var_to_bytes` + zlib-compressed snapshot via an `@rpc("authority")` call; the client sends raw input dictionaries via `@rpc("any_peer")`. No client prediction/reconciliation.
- **Hand-drawn UI over static art:** `terminal_ui.gd` treats supplied PNGs as decoration and overlays transparent real `Button`/`Label` controls at hand-measured pixel rectangles — there is no scene-based UI (`.tscn`) for menus.

## Development Overview

### Prerequisites

- Godot Engine `4.7.2` (stable, GL Compatibility build) — path used by this project: `C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\`
- No package manager, npm, or login/API key required to play.
- Optional (art regeneration only): Python 3 with `Pillow`, `numpy`, `opencv-python`.

### Getting Started

Run `Jogar.cmd` in the project root, or open `project.godot` in the Godot editor and press F5. No build step.

### Key Commands

- **Install:** none (open project in Godot)
- **Dev:** `Jogar.cmd` or Godot editor F5
- **Build:** none (not exported/packaged in this version)
- **Test:** `Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/<name>.gd` for each file in `tests/`

## Repository Structure

Single Godot project (monolith). Top-level: `scripts/` (all GDScript logic), `scenes/` (one scene, `main.tscn`, which instantiates everything else in code), `tests/` (7 headless GDScript test suites), `tools/` (11 offline Python art/asset scripts + 1 PowerShell network integration test), `assets/` (sprites, audio, UI backgrounds), `art/` (source references and previews), `docs/` (versioned design/changelog notes), `output/imagegen/` (raw AI-generated source images).

## Documentation Map

For detailed information, see:

- [index.md](./index.md) - Master documentation index
- [architecture.md](./architecture.md) - Detailed technical architecture
- [source-tree-analysis.md](./source-tree-analysis.md) - Directory structure
- [development-guide.md](./development-guide.md) - Development workflow
- [component-inventory.md](./component-inventory.md) - State management & component catalog
- [asset-inventory.md](./asset-inventory.md) - Art/audio asset catalog

---

_Generated using BMAD Method `document-project` workflow (exhaustive scan)_

