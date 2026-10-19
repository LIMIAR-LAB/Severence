# Omega upright flight

Approved body source: PixelLab state `465590a4-dc1f-474b-af69-7384493b2184`, derived from the existing approved compact Omega `036c6e2f-d296-478d-acd5-c3597bdbc3e3`. `state.json` records the eight rotation URLs. These are dedicated palms-down flight poses, not reused idle frames.

`rotations/` preserves native 96px originals. `approved-anchors.json` contains the two palm and two sole nozzle positions in original coordinates, ordered left/far palm, right/near palm, first sole, second sole. The runtime packer adds eight transparent pixels on every side, yielding the existing 112px cell at the existing 124px draw size. It does not rescale or repaint the sprites. Run `python tools/import_omega_flight.py` to reproduce the runtime body atlas and metadata.

The body is one stable flight pose per direction. `scripts/omega_flight.gd` animates the four cyan jets and a slight vertical hover, and eases the lift/exhaust over 0.14 seconds at landing. Near palms render in front of the cape; far palms can be naturally occluded in side/rear views. All nozzles point down independently of aim. The normal action pose takes over during combat, damage, teleport, transformation or mounting. This module does not write simulation state or extend the existing jump.

The first generated animation group `a23e37d5-be87-4eb9-a964-3cc62f3b77f9` is preserved under `raw/` and `*-review.png` but rejected: several directions turned their torso or raised a hand. None of those frames enters the runtime atlas.

Evidence: `output/omega-flight/eight-directions.png`, `runtime-0.png` through `runtime-7.png`, and `flight-and-landing.gif`. Captures use the real DockView and Expedition without the application/save lifecycle. `review.json` records the test results. This was a renderer capture and automated verification, not a manual playtest.
