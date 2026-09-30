# Articulated enemy animation — work in progress

The user explicitly rejected the rigid-body simplification. The target is real
articulated animation with consistent anatomy, readable anticipation, impact,
recovery and a natural collapse.

`jobs.json` records PixelLab input references, generation IDs, returned frame
URLs and per-clip visual approval. A generated clip is never approved merely
because the job succeeded or a test passed.

Reviewed and integrated so far:

- Crawler: 16 generated walking poses in each of eight directions, plus 16
  attack poses and 20 death poses for south. Each sequence also stores its
  unchanged starting reference.
- Cultist south: 16 generated walking and attack poses, 20 natural falling
  poses, and the unchanged starting reference for each action.
- Attack/death in the other crawler directions and the remaining enemy
  sequences are not complete. Pending jobs are listed in `jobs.json`.

The crawler attack initially introduced pale fills on tentacles in frames 5–8
(zero-based). PixelLab's exact pixel workbench replaced those fills with the
existing purple palette without changing transparency, outlines or timing.
The corrected sheet and GIF are stored next to the untouched source frames;
`correction_tool_id` records the final tool artifact. Do not silently replace
the raw frames with corrected copies.

For directions whose attack or death clip is still in the PixelLab queue, the
renderer temporarily uses that direction's approved walking anatomy. This
avoids the old rigid rotation that visibly changed the creature's proportions;
the fallback is replaced automatically when a new clip passes visual review.

Import with `tools/import_enemy_motion.py`. Every frame retains its source
pixels. A single pivot taken from reference frame 0 and a single world scale
apply to the entire creature. Do not normalize each frame to its own bounding
box, stretch a lying corpse to standing height, or crop a moving limb. Death
frames receive a vertical translation only to keep their lowest opaque pixel
on the original floor; their pixels and scale stay unchanged.

`tools/review_enemy_motion.py` creates review sheets and animated GIFs.
`tests/enemy_motion_preview.gd` captures the actual Godot renderer, including
the attack state timeline. Tests check frame playback, directional selection,
fixed draw geometry, offspring scale and non-looping death. Visual review is
still required for anatomy, motion and unwanted generated marks.

The separate `fluid_crawl_v3` comparison job
`e6fe4a5c-be03-48d3-afa8-a6b909618099` was cancelled after the MiniMax walking
sequence passed review. Its unfinished candidate is not a game asset.
