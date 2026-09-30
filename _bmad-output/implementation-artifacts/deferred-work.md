# Deferred Work

## Enemy spawn data cleanup

- `scripts/docks_map.gd` and `tools/build_docks_map.py` still emit an unused `GROUPS` table and describe spawn classes as seed-sampled, while runtime currently consumes the fixed class stored in each `SPAWNS` entry.
- `docs/architecture.md`, `docs/CENARIO_0_13.md`, and `README.md` contain older statements that the seed changes enemy types; reconcile these with the current fixed-class behavior and correct the stale room-count description in `docs/architecture.md`.

## Boss capture HUD layout

- The top-center reload panel overlaps the right side of `O ALMIRANTE DAS PROFUNDEZAS` in boss arena captures. This predates the PixelLab sprite replacement and needs a focused HUD-layout adjustment rather than an asset edit.
- The `--capture-boss` helper still places Marty at obsolete arena coordinates unless `--at=4200,1350` is also supplied; update the default capture position when the current `main.gd` work is stable.

## Save validation feedback

- `has_saved_game()` only checks whether the save file exists. A malformed, truncated, or externally removed save can therefore leave Continue enabled while `load_game()` rejects it without title-screen feedback. Add validation and a visible recovery message in a focused save-resilience change.

## Generated audio fixture recovery

- `tests/game_audio_test.gd` currently reports 30 failures because `assets/audio/generated/*.wav` is absent or has no usable Godot imports in a clean checkout. This predates the Equipment visual change; restore or regenerate the tracked audio fixtures in a focused audio task so the complete suite can return to green.
