# O Almirante das Profundezas — PixelLab remake

Generated on 2026-09-29 with PixelLab from the existing production idle sprite as the identity and style reference. The canonical object and every accepted state use a 256×256 transparent canvas.

## PixelLab assets

| Runtime pose | Source file | PixelLab object ID | Notes |
|---|---|---|---|
| `idle` | `idle.png` | `08ba3344-e1dd-4f22-9842-069e3226e3bf` | Canonical remake; low top-down front view |
| `ring` | `ring.png` | `84828029-0be4-4204-9018-32ce45c3db09`, reviewed as `a22d32ef-1d78-4aa3-8ae5-0559a8abca21` | Stage-one radial firing stance, shifted right 1 px to clear the canvas edge |
| `spiral` | `spiral.png` | `4090ec00-c09f-4f52-b00c-e932b5a3a2f1`, palette pass `b4e3ffea-c28e-4523-8f83-f9e8e596455b` | Native 208×208 radial composition, palette-matched without dithering, then nearest-neighbor fitted to a 224×224 safe area on the 256×256 runtime canvas |
| `charge` | `charge.png` | `2fbcada1-04e5-4f25-aae0-6d818d5d20e7` | Braced central cannon with violet charge core |
| `hurt` | `hurt.png` | `aa9f6e9d-4464-4eb0-918d-b61857bdb843` | Pale lavender hit flash and recoil |
| `fury` | `fury.png` | `52e40641-75b5-48bf-9838-369e8cd06925` | Hat removed, red-magenta eyes and ink aura |
| `defeat` | `defeat.png` | `b10b39b6-de8d-4294-88c0-37c2de0fd927`, reviewed as `05a45b46-0981-4657-a4ab-4d9bc4e6b0ec` | Collapsed, partially submerged silhouette, shifted down 6 px to preserve the live-pose waterline |

The three original rejected spiral attempts are preserved for provenance. `rejected-spiral-v1.png` remained upright; `rejected-spiral-v2.png` was radial but too large and overlapped the boss label/bar while rotating; `rejected-spiral-v3.png` ignored the requested safe bounds. The later native 176×176 candidate (`spiral-176.png`) was also rejected after review because it produced a visible scale drop in gameplay. `spiral-208-raw.png` and `spiral-208.png` retain the accepted generation before and after palette matching; `style-spiral-208.png` is its cropped style reference. The 224×224 and 240×240 raw candidates were retained for comparison but rejected because their generated silhouettes occupied less canvas than the accepted 208×208 candidate. `preview.png` is the accepted seven-pose contact sheet.

## Integration contract

- Accepted poses are copied unchanged to `assets/boss/almirante_<pose>.png`.
- Every accepted frame is RGBA, 256×256, with hard transparent edges and no partial-alpha pixels.
- Every grounded pose, including defeat, ends at y=246 (9 px bottom margin). The accepted spiral occupies x=25..226 and y=22..229 (202×208 visible pixels), eliminating the earlier scale pop while leaving enough radial clearance to avoid the fixed boss name and health bar throughout all 30 renderer rotation increments.
- Projectiles and combat logic are intentionally unchanged.
