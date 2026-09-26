# Marty — Fraturas do Tempo Documentation Index

**Type:** Monolith (single Godot project)
**Primary Language:** GDScript (Godot 4.7.2)
**Architecture:** Simulation/View/Controller split — `Expedition` (rules) / `DockView`+`CombatHUD` (rendering) / `main.gd` (input, camera, save, netcode)
**Last Updated:** 2026-09-25

## Project Overview

A top-down pixel-art action game (v0.11 prototype): Marty fights through a fixed dungeon ("Docas de 1941") launched from a hub ("Refúgio • Fora do Tempo"), with a pilotable mech, a fusable drone companion, a temporary power-armor, solo/AI/local-coop/online-coop modes, and a run-based key/coin/fragment economy with persistent meta-progression. See `project-overview.md` for the full summary.

## Quick Reference

- **Tech Stack:** Godot 4.7.2 (GL Compatibility) · GDScript · built-in ENet multiplayer · JSON file persistence
- **Entry Point:** `scripts/main.gd` (attached to `scenes/main.tscn`, launched via `Jogar.cmd` or Godot editor F5)
- **Architecture Pattern:** Serializable state container (`Expedition`) read by stateless `_draw()`-based renderers; host-authoritative network snapshotting
- **Database:** none (in-memory `Dictionary`/`Array` state + flat JSON save files under `user://`)
- **Deployment:** none configured yet (run from source / Godot editor only)

## Generated Documentation

### Core Documentation

- [Project Overview](./project-overview.md) - Executive summary, tech stack, key features, architecture highlights
- [Architecture](./architecture.md) - Detailed technical architecture: layers, data model, component responsibilities, testing strategy, netcode
- [Source Tree Analysis](./source-tree-analysis.md) - Full annotated directory structure, entry points, file organization patterns
- [Component Inventory](./component-inventory.md) - State management pattern (`Expedition`) and UI component builders
- [Asset Inventory](./asset-inventory.md) - Full art/audio catalog by folder, with provenance notes
- [Development Guide](./development-guide.md) - Setup, run/test/capture commands, common development tasks

### Deep Dives

- [Enemy AI & Partner AI (Echo)](./deep-dive-ai.md) - Navigation graph, per-enemy attack patterns, Echo's decision priority order
- [Progression & Economy](./deep-dive-economy.md) - Currency sources, persistence tiers, chest/side-challenge state machines
- [Networking / Multiplayer](./deep-dive-networking.md) - Connection lifecycle, RPC protocol, host-authoritative validation, pause semantics
- [Boss Fight — O Almirante das Profundezas](./deep-dive-boss.md) - Stage machine, exact per-attack damage/speed/cadence, visual state machine

### Optional Documentation

None generated (no deployment config or `CONTRIBUTING.md` found in the repository — see `development-guide.md`'s "Contribution Guidelines" section for the informal conventions observed instead).

## Existing Documentation

These pre-existing files were **not modified** by this scan; they remain the authoritative version-by-version changelog and are cross-referenced from the generated docs above:

- [README.md](../README.md) - User-facing manual: how to play, controls, first-run walkthrough, network setup, art credits, current limits
- [docs/MVP_STATUS.md](./MVP_STATUS.md) - Snapshot of design decisions and what's implemented vs. pending as of 2026-09-25
- [docs/TITAN_0_12.md](./TITAN_0_12.md) - Titan mech v0.12: heavy cannon, arced bomb, diagonal-pose fix (cross-checked in `architecture.md` §4 and `deep-dive-boss.md`)
- [docs/CENARIO_0_12.md](./CENARIO_0_12.md) - Docks scenario v0.12: walls, fog of war, night lighting, Room 01 rebuild
- [docs/DOCAS_0_11.md](./DOCAS_0_11.md) - Dungeon map v0.11: rooms, difficulty tuning, armor timing
- [docs/EQUIPAMENTO_0_9.md](./EQUIPAMENTO_0_9.md) - Uniform/Armor/Robot system spec (source of truth for balance, cross-checked in `architecture.md`)
- [docs/SPRITES_0_6.md](./SPRITES_0_6.md) - Marty/enemy/boss sprite sheets, animation notes (v0.6–v0.8)
- [docs/REFUGIO_0_5.md](./REFUGIO_0_5.md) - Hub scene construction and points of interest
- [docs/ART_0_4.md](./ART_0_4.md) - v0.4 visual direction notes
- [docs/CHANGES_0_3.md](./CHANGES_0_3.md) - v0.3 changelog (menus, solo mode, robots)
- [docs/FIXES_0_2.md](./FIXES_0_2.md) - Post-playtest fixes after v0.1

## Getting Started

### Prerequisites

Godot Engine 4.7.2 (GL Compatibility build). No package manager, login, or API key needed to play.

### Setup

```bash
# Nothing to install — open the project directly.
```

### Run Locally

```bash
Jogar.cmd
# or: open project.godot in Godot 4.7.2 and press F5
```

### Run Tests

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

## For AI-Assisted Development

This documentation was generated specifically to enable AI agents to understand and extend this codebase.

### When Planning New Features:

**Balance/gameplay-rule changes (uniforms, armor, enemies, boss, robots):**
→ Reference: `architecture.md` §3–4, `component-inventory.md` — edit `scripts/simulation.gd` tables/methods, add a `tests/*.gd` assertion.

**Dungeon/hub layout changes:**
→ Reference: `architecture.md` §4 (`docks_map.gd`), `source-tree-analysis.md` "Notes for Development" — edit `scripts/docks_map.gd` or `Expedition.make_hub()`.

**Menu/UI changes:**
→ Reference: `architecture.md` §4 (`terminal_ui.gd`), `component-inventory.md` "UI Components" — add a `build_<screen>()` using the existing `panel()/label()/button()` primitives.

**Rendering/VFX changes:**
→ Reference: `architecture.md` §4 (`world_view.gd`, `combat_hud.gd`) — add a case to the relevant `_draw()`/`effects[]` match block.

**Networking changes:**
→ Reference: `architecture.md` §6 — follow the existing host-authoritative `@rpc` request/validate/apply pattern; never let a client mutate `sim` directly.

**Deployment/packaging:**
→ No existing config to reference; this is an acknowledged gap (see `README.md` "Limites desta entrega" and "Próximos marcos").

---

_Documentation generated by BMAD Method `document-project` workflow (exhaustive scan)_
