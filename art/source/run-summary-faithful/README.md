# Faithful run-summary masters

These masters were generated with the built-in OpenAI ImageGen tool on
2026-09-29. The approved concept at
`art/concept/resumo-pos-run-ux-v1.png` was supplied as the visual reference.
PixelLab remains the owner of the four loot illustrations in
`art/source/pixellab/run-summary/`; those files are copied by the deterministic
builder and were not regenerated here.

## Master shell prompt

> Recreate the approved 16:9 results screen as a production-ready, text-free
> background: cinematic retrofuturist docks behind a dense brass-and-dark-steel
> report machine. Preserve the large empty title chassis, three stat bays,
> parchment obituary card with empty portrait window, two right-hand metric
> panels, circular grade medallion and two bottom action frames. Match the
> reference materials, saturation, framing and visual weight. No text, letters,
> numbers, logos, portraits or fake statistics. Keep panels perspective-free for
> live Godot overlays. Target 1672x941.

Output: `summary_shell_master.png` (1672x941).

## Fish portrait prompt

> Create a square editorial dossier portrait of the reference's mutant abyssal
> fish: huge open jaws, needle teeth, glowing cyan eye and lure, ragged magenta
> fins and wet dark-teal scales. Premium hand-painted pixel-art, close-up rather
> than gameplay sprite, dark underwater vignette, no frame and no text.

Output: `portrait_fish_master.png` (1254x1254).

## Victory portrait prompt

> Create a square editorial portrait of a recovered brass containment device
> surrounding a brilliant cyan expedition nucleus. Match the reference's
> premium painted pixel-art, brass ornament and dockside lighting. Centered,
> heroic, no frame, no text and no fake values.

Output: `portrait_victory_master.png` (1254x1254).

The generated originals are preserved here. Runtime sizing and fallbacks are
owned by `tools/build_run_summary_assets.py`.
