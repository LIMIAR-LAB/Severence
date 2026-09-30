---
title: Refresh remaining dock monsters and requested game audio
type: feature
created: 2026-09-30
status: done
baseline_commit: b6fd2a7373ae196b7f1f2b9a9386d3da693431d9
context: []
---

## Intent

Replace the visibly rough legacy dock monsters, particularly the opening octopus,
with actual PixelLab generations. Deliver transparent pixel art with readable
silhouettes and directional movement consistent with the game's existing camera.
The user also requests weapon sounds, enemy sounds and background music through
Higgsfield. Its connected audio tool explicitly supports speech only, so alternate
audio production uses original local synthesis/composition, authorized by the
user's subsequent "sim". No external sampled music or speech is used.

## Boundaries & Constraints

Preserve existing unrelated edits to the menus, HUD, environment and Omega armor.
Keep enemy combat behavior, collision, health, encounter layout and multiplayer
state unchanged. Retain the small crawler variant and the established guard and
bomber assets. Do not cancel another task's PixelLab jobs. Store original exports
and generation metadata. Do not claim synthesized audio came from Higgsfield.
Do not overwrite legacy assets until replacements are inspected and validated.

## Code Map

- `scripts/world_view.gd`: texture loading, octant selection, enemy and corpse drawing.
- `tools/build_pixellab_enemies.py`: existing guard/bomber atlas import convention.
- `assets/enemies/docas_anim.png`: four legacy rows (cult, fish, crawler, brute).
- `scripts/main.gd`: existing shot playback and master volume.
- `scripts/simulation.gd`: enemy attack timers and existing combat effects.
- `tests/enemy_sprite_test.gd`: directional atlas checks.

## Tasks & Acceptance

- [x] Generate crawler, cult, fish and brute through PixelLab with clean alpha.
- [x] Store source exports and reproducible import tooling under art/source and tools.
- [x] Integrate directional art and available movement without mirroring views.
- [x] Ensure the small crawler stays proportionally small, including its corpse.
- [x] Replace corpse presentation so defeated enemies never revert to old sprites.
- [x] Inspect sprites against dark backgrounds for white matte and clipped extremities.
- [x] Validate Godot imports, directional cells, enemy behavior and renderer.
- [x] Resolve alternate audio provider with user; original local synthesis authorized.
- [x] Generate 23 weapon/enemy/action effects and two original looping music tracks.
- [x] Connect successful gameplay events to audio, bounded and synchronized online.
- [x] Integrate music transitions, pause ducking, global mute and voice limiting.
- [x] Complete final audio review and regression checks.

**Acceptance Criteria:**

- Given any legacy dock monster, when shown alive or defeated, then its new art
  is used without accidental white background pixels or directional mirroring.
- Given a crawler that splits, when its offspring appear, then both use the new
  octopus art at their smaller scale and retain existing behavior.
- Given movement across all octants, when selecting sprite frames, then each
  cell contains an aligned complete silhouette without frame-to-frame resizing.
- Given pending PixelLab jobs from other work, when generation is unavailable,
  then wait and retry without cancelling those jobs or creating duplicate requests.
- Given a real shot or attack, when it occurs, then the matching cue plays once;
  empty weapons click and sword swings never play firearm audio.
- Given repeated snapshots, save loading or pause, when state is consumed, then
  historical audio is not replayed. Audio must never consume the combat RNG.
- Given a room change or pause, when music changes, then it fades smoothly;
  volume zero must silence both music and effects.

## Verification

Use Pillow to validate source alpha, nonempty atlas cells and opaque near-white
pixels; inspect previews visually. Run Godot headless import and existing enemy
and combat tests. Use a dedicated in-engine monster showcase for visual review.

## Progress

- Initial four PixelLab requests rejected before submission: concurrency limit.
- Existing eight active jobs belong to the Omega armor task; left untouched.
- Higgsfield tool documentation confirms it cannot generate music or SFX.
- Saved local snapshots of modified integration files before this task's edits.
- Final movement coverage: crawler has generated south/east/north cycles, four
  movement frames each (reference excluded). All four creatures have eight idle
  views; remaining movements use their own view plus renderer bob. Requests for
  west and humanoid cycles were rejected by the shared concurrency limit. No
  generation jobs submitted by this task remain pending. Coverage is recorded in
  `art/source/pixellab/dock-monsters-v2/*-import.json`.
- All new cell borders are transparent. Crawler's small near-white regions are
  intentional eye highlights; the other three atlases contain no near-white pixels.
- Godot import, enemy_sprite_test, enemies_test and combat_framework_test passed.
- Captured the eight-direction gallery and a running arena; reviewed both.
- Three independent reviews identified two importer issues, both fixed: default
  CLI argument validation and detection of missing V3 frames. A deliberately
  truncated export is now rejected using the export metadata before atlas output.
- Audio now delivered through local synthesis: 23 mono WAV effects, 64-second
  refuge music and 51.2-second expedition music in stereo Ogg. Source generator,
  measurements and provenance are retained under tools and art/source/audio.
- Audio gameplay tests cover successful/dry shots, guard bursts, invulnerability,
  bounded queues, snapshot replacement and RNG preservation. Presentation tests
  cover deduplication, distance, mute, pause, music switching and saved-history reset.
- Existing combat, weapons, guard, Omega, Warden and save/load flow tests passed.
- Final review fixed distant same-key sounds suppressing nearby player feedback;
  regression verifies a local simultaneous shot still plays. All 25 asset hashes
  match the source manifest. Final audio and combat tests passed; startup reports
  no audio errors (unrelated in-progress chapel art emits legacy-fallback warnings).
- No external generation service or samples were used for the audio. All requested
  audio is integrated and works offline; no account or runtime Python is required.

## Suggested Review Order

- Review gameplay audio, fades, mute, distance and playback cleanup.
  [game_audio.gd](../../scripts/game_audio.gd)
- Inspect original audio measurements, hashes and production method.
  [audio manifest](../../art/source/audio/manifest.json)

- Inspect new monster visuals and exact animation coverage.
  [manifest.json](../../art/source/pixellab/dock-monsters-v2/manifest.json)
- Review enemy and corpse rendering while preserving existing combat behavior.
  [world_view.gd](../../scripts/world_view.gd)
- Rebuild all four atlases with fixed animation pivots and one scale per monster.
  [import_dock_monsters.py](../../tools/import_dock_monsters.py)
- Verify directional cells and small-crawler scale.
  [enemy_sprite_test.gd](../../tests/enemy_sprite_test.gd)
