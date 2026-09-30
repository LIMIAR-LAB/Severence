# Severence — Ecos do Tempo - Asset Inventory

**Date:** 2026-09-25

`documentation-requirements.csv` flags `requires_asset_inventory=true` for project type `game`. This catalogs everything under `assets/` (loaded at runtime) plus `art/`/`output/` (source material, not loaded at runtime).

## Runtime Assets — `assets/` (loaded via `load()` in `world_view.gd`, `combat_hud.gd`, `main.gd`)

| Subfolder | Files | Formats | Approx. size | Notes |
|---|---|---|---|---|
| `assets/marty/` | 6 PNG (+6 `.import`) | PNG sprite atlases | ~1.09 MB | `marty.png`/`actions.png` (v1, superseded), `marty-v2.png`/`actions-v2.png` (v0.4), `outfits.png` (v0.6, 4 uniforms × 6 poses, 96×96 cells), `marty_anim.png` (v0.7, animated walk/shoot/jump/melee, largest file at 341 KB) |
| `assets/mech/` | 3 PNG | PNG sprite atlases | ~636 KB | `titan.png` (v1), `titan_v2.png` (v0.10, 8-direction + visor + heavy-step anim), `spectre.png` (drone) |
| `assets/enemies/` | 2 PNG atlases + 4 projectile PNGs | PNG | ~316 KB | `docas.png` (v1 static poses), `docas_anim.png` (v0.7 animated, 4 enemy types × 5 views), `proj_{acid,harpoon,magenta,violet}.png` |
| `assets/boss/` | 7 pose PNGs + 5 projectile PNGs | PNG | ~646 KB | "O Almirante das Profundezas": idle/ring/spiral/charge/hurt/fury/defeat poses + proj_{cannon,flame,harpoon,ink,orb} |
| `assets/weapons/` | 14 PNG | PNG | ~87 KB | 4 hand weapons (pistol/shotgun/smg/omega + omega_sword), melee tools (wrench/knife), muzzle flashes (flash/flash_cyan), sword smear/trail, 4 projectile sprites (`b_*`) |
| `assets/environment/` | `cobble.png` + `docks/` (38 items) + `reference/` (15 items) + `refuge/` (2 items) | PNG | varies | Dungeon props (crates/containers/pillars/altar/pew/etc.), original reference crops, and the 2-file hub background (`refuge_bg.png` + `core_front.png` overlay) |
| `assets/ui/` | 4 PNG | PNG (large, full-screen concept art) | ~5.4 MB total | `menu.png` (1.56 MB), `adventure.png` (1.43 MB), `online.png` (1.27 MB), `equipment.png` (1.17 MB) — the 4 user-supplied menu background illustrations that `terminal_ui.gd` overlays real controls onto |
| `assets/audio/` | 4 WAV | WAV, mono 22050 Hz | ~24 KB total | `shot`, `heavy`, `jump`, `hit` — all synthesized (`tools/make_support_assets.py`), not recorded/licensed audio. **No music in this version.** |

Every `.png`/`.wav` above has a matching Godot `.import` sidecar (not counted separately; auto-generated, engine-managed).

## Source / Reference Material — not loaded at runtime

| Location | Contents |
|---|---|
| `art/source/` (14 items) | Raw AI-generated concept sheets (`marty-atlas-v1.png`, `marty-outfits-v1.png`, `enemies-docas-v1.png`/`v2`, `boss-almirante-v1.png`, `mech-atlas-v1.png`, `refuge-reference.png`, `docks-reference.png`) plus their `*-prompt.txt` generation prompts. |
| `art/` (root) | `marty-titan-preview.png`, `marty-v2-preview.png`, `sprites-v06-preview.png` (composited previews for human review), `walk-v07-preview.gif` (animation preview) |
| `output/imagegen/` (8 items) | Raw generator output before any `prepare_*.py` cropping/cleanup is applied |
| `Claude outputs/` (1 item) | Stray duplicate of `walk-v07-preview.gif` — appears to be leftover from an external tool session, not referenced by any script or doc |

## Provenance / Licensing Note (from `README.md`)

- Character/enemy/boss/environment source art was generated via the OpenAI API (`gpt_image_2_5`) and Higgsfield, using user-supplied reference images as prompts — explicitly **not** extracted from any existing commercial game or ROM (README calls out Enter the Gungeon / Metal Warriors by name as *not* used as asset sources, only as stylistic reference).
- Terrain placeholder texture and all 4 SFX are **originally generated** by `tools/make_support_assets.py` (procedural + synthesized), not sourced externally.
- The 4 `assets/ui/*.png` backgrounds are the literal user-provided menu concept screens; `terminal_ui.gd` builds real interactive controls on top rather than redrawing them.

## Total Footprint (order of magnitude)

`assets/` ≈ 8–9 MB (dominated by the 4 UI background PNGs and `marty_anim.png`/`docas_anim.png`). `art/` adds roughly another 1.6 MB of preview images. No 3D models, shaders, or video assets in the runtime asset set.

---

_Generated using BMAD Method `document-project` workflow (exhaustive scan)_
