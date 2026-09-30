# Severence — Ecos do Tempo - Component & State Management Inventory

**Date:** 2026-09-25

`documentation-requirements.csv` flags `requires_state_management=true` for project type `game`. This project has no UI framework (Redux/MobX/etc.) — "state management" here means the custom `Expedition` state container and how the rendering/UI/network layers read and mutate it. This file documents that pattern plus the reusable UI-building "components" in `terminal_ui.gd`.

## State Container: `Expedition` (`scripts/simulation.gd`)

- **Single source of truth** for all gameplay state (see `architecture.md` §3 for the full field table). No other script keeps a duplicate copy of game state; `world_view.gd` and `combat_hud.gd` hold zero gameplay state and read `sim` fresh every `_draw()`.
- **Mutation is always through methods**, never direct field poking from outside (`main.gd`/`terminal_ui.gd` call `sim.equip()`, `sim.summon_robot()`, `sim.interact()`, etc.) — this keeps validation (e.g. "can't change uniform while armor is active") in one place.
- **Read access is direct** — `Dictionary`/`Array` fields are exposed as public `var`s and read directly by the view/HUD/network layers (`a.hp`, `sim.mech.hp`, `sim.actors[id]`), since GDScript has no reactive/observer system here; every consumer just re-reads on its own per-frame `_draw()`/`_process()`.
- **Snapshot/patch, not diffing:** the network layer doesn't diff state — it re-sends the *entire* `snapshot()` dictionary every 0.05s, compressed. There is no incremental/delta sync.
- **Per-actor sub-state:** each of the 2 `actors[]` dictionaries is a self-contained bag of ~25 fields (position, timers, loadout, robot/fusion flags) — effectively a "player state machine" encoded as timers-that-count-down-to-zero (`hurt`, `slash`, `dodge`, `jump`, `armor_time`, `armor_cd`, `summon_cd`, `combo_t`, `snare`, `fire_flash`, `transform`) rather than an explicit enum state machine. `step_actor()` decrements every timer once per frame (`scripts/simulation.gd:384`) then branches on which ones are still `> 0`.

## UI "Components" (`scripts/terminal_ui.gd`)

Since there's no scene-based UI, `terminal_ui.gd` implements 3 small reusable builder functions used by every screen — the closest equivalent to a component library:

| Builder | Signature | Purpose |
|---|---|---|
| `panel()` | `panel(parent, rect, bg, outline) -> Panel` | Styled rounded-rect background panel |
| `label()` | `label(parent, rect, caption, font_size, color) -> Label` | Positioned text |
| `button()` | `button(parent, rect, caption, callback, transparent) -> Button` | Styled or fully-transparent clickable region (transparent buttons are used as invisible hit-targets over the supplied concept-art PNGs) |

Screens (`build_main`, `build_play`, `build_online`, `build_equipment`, `build_seed`, `build_options`) are all "pages" composed purely from these 3 primitives plus one `TextureRect` background per screen. `show_screen(next)` is the router: it frees the previous page's `Control` subtree and rebuilds the requested one from scratch every time (no page caching/pooling).

**Equipment screen pattern (`build_equipment`):** clicking any option (`choose(key)`) immediately calls `apply_gear()` — there is no separate "confirm" step or "Apply" button; `refresh_gear()` re-renders the preview sprite, description panel, and selection highlight borders after every click. This "apply-on-click" pattern is called out explicitly in `docs/EQUIPAMENTO_0_9.md`.

## Component Reuse Across Uniform/Armor/Robot Choices

`OUTFIT_ROW` (`world_view.gd:23`) and the `UNIFORMS`/`ARMORS` dictionaries (`simulation.gd:63`) are the two tables every layer joins against by the same string keys (`"padrao" | "mecanico" | "espiao" | "omega"`), so adding a 4th uniform requires: one entry in `UNIFORMS`, one row in the `outfits.png` atlas + `OUTFIT_ROW` entry, and (if it needs a unique weapon) one entry in `weapon_of()`'s implicit mapping. No other file needs to change.

## Notes for AI-Assisted Development

- When adding new player-facing state, add the field to the `actor()` factory (`simulation.gd:55`) with a sensible default, and to `snapshot()`'s field list *only if* it isn't already covered by the `"actors"` bulk key (it is — actor fields don't need individual snapshot entries).
- When adding new global run state, you must add it explicitly to `snapshot()`'s `for name in [...]` list (`simulation.gd:875`) or it will silently not sync over the network / round-trip in tests.
- There is no persisted "settings schema version" for `settings.json` (unlike `progress.json`, which has `"version": 1`); `load_settings()` uses `.get(key, default)` defensively per-field instead.

---

_Generated using BMAD Method `document-project` workflow (exhaustive scan)_
