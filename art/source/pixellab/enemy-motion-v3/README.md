# Articulated enemy animation — work in progress

The user explicitly rejected the rigid-body simplification. The target is real
articulated animation with consistent anatomy, readable anticipation, impact,
recovery and a natural collapse.

`jobs.json` records PixelLab input references, generation IDs, returned frame
URLs and per-clip visual approval. A generated clip is never approved merely
because the job succeeded or a test passed.

Reviewed and integrated so far:

- Crawler: walking in eight directions, attack in five, and death in four.
  Each sequence stores its unchanged starting reference.
- Cultist: walking, firing and death in all eight directions. The original
  template clips read as a gliding statue (the robe hides the footwork and the
  template attack never raised the gun), so they were superseded by v3 custom
  clips — see below. Its first north-east walking result was rejected for
  changing orientation; the approved retry is recorded separately in
  `jobs.json`.
- Other action directions and the remaining enemy sequences are not complete.
  Crawler death west has a pending job recorded in `jobs.json`; no further
  generation was requested after credits ran out.

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

Fish (`Severence fish v2`, character `9d0d295a-e53c-4955-a33d-063031fd95f3`,
group `479fa1a9-a72e-489e-b722-a1cb5fae4afd`): real generated clips for
south, east, north, west and south-east. `south-west` is a pixel-mirrored
copy of south-east (job_id `mirror:...`), matching how the character's own
static rotations pair SE/SW. `north-east` and `north-west` temporarily reuse
the approved north clip (`job_id` `reuse-north`) while their real jobs wait
in the account queue; replace them with generated clips when slots open.

Fish attack (group `9327fb5d-96b2-41c4-8c1f-856d2b6a6e4a`, template
`throw-object`): real 7-frame clips in all eight directions. The harpoon
leaves the hand during the throw — matching the separate harpoon bullet the
simulation fires — and returns on recovery. Template clips do not echo the
rotation frame, so `import_enemy_motion.py` prepends the walk clip's anchored
reference (`prepend_reference`) giving 8-cell atlases that start on the exact
same anatomy as the walk cycle.

Cultist v3 regeneration (character `c59afc82-116f-4396-954d-f1774c064b7b`):
the robe swallowed the template walk's footwork, so the cultist glided like a
statue, and the template attack never raised the gun. Replaced with v3 custom
clips:

- Walk (group `57dc3290-dd7e-4e2b-9bd5-a13dc5e1a4d9`, source `cult/walk2/`):
  "heavy stride, purple robe billowing, hem flapping" — 17 frames, 8 dirs.
- Attack (group `55f74686-7e76-4fd4-b893-d58959be1dd8`, source `cult/attack2/`):
  "aim, fire with recoil and muzzle flash, lower" — 9 frames, 8 dirs. The first
  north take repeated three stills and was rejected; the approved retry
  (`0802a5b4`, group `7295fd43`) keeps the flash readable from behind.
- Death (group `49be0825-9960-44d6-afa0-92d01081bae5`, source `cult/death2/`):
  "knees buckle, robe crumples, falls face-down" — 13 frames, 6 dirs; south and
  east keep their previously approved clips.

The superseded template jobs stay in `jobs.json` with `approved: false` and
`retry_of` links on the new entries; their raw sources remain under
`cult/walk/` and `cult/attack/` untouched. The importer nudges a clip
uniformly (never per frame) up to 4px when a sprawled death pose spills past
the cell, while frame 0 always keeps the canonical anchor so every clip
starts from identical anatomy.

Golem (`Severence golem`, character `96fdfaa0-4911-419b-9843-97fd84354bde`,
group `59ebd638-f199-4bf5-a0ce-141395cdd589`): the GOLEM-9 reward robot —
a Gundam-inspired heavy mecha that replaces Sentinela-7 as the capturable
machine in the Cranes. Real generated clips:

- Walk: 17 frames, all 8 directions.
- Attack: 13-frame heavy gatling burst in south, south-east, east,
  north-east, north, west; `north-west` and `south-west` are pixel-mirrored
  copies (`job_id` `mirror:...`). The west clip's frame 8 muzzle-flash tip
  spilled 9px past the cell; `corrected_sheet` (`attack/west_corrected.png`)
  trims only the flash edge pixels. `west`, `north-west` and `south-west`
  use `prepend_reference` so the atlas opens on the identical rotation
  anatomy as the walk.
- Death (group `e05b5752-24ba-45b9-8ba1-a136f1b89c35`, source
  `golem/death/`): 13-frame collapse — knees buckle, sparks burst from the
  chest, falls face-down — in south, south-east, east, north-east, north
  and west; `south-west` and `north-west` are pixel-mirrored copies
  (`job_id` `mirror:...`, `prepend_reference`). The first north-east take
  failed under server load; the approved retry is `f630c9ce`.

The golem's shoulder armor and gatling cannon sweep through the band the
head-width guard measures, so its jobs carry `skip_head_check`; anatomy is
verified visually instead.
