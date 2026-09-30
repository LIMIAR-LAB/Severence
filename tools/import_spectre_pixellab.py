"""Import PixelLab's eight-direction character sheets without changing the sources.

Run after downloading each character's ``/spritesheet`` ZIP to the paths below.
Each animation becomes its own transparent PNG with directions ordered like Marty.
"""

from __future__ import annotations

import io
import json
import zipfile
from pathlib import Path

from PIL import Image
from PIL import ImageFilter
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
DIRECTIONS = (
    "south", "south-east", "east", "north-east",
    "north", "north-west", "west", "south-west",
)
CHARACTERS = {
    "spectre": {
        "archive": ROOT / "art/source/characters/spectre/pixellab/spectre-pixellab-spritesheet.zip",
        "output": ROOT / "assets/characters/spectre/pixellab",
        "cell": 128,
    },
    "fusion": {
        "archive": ROOT / "art/source/characters/marty/spectre_fusion/pixellab/fusion-pixellab-spritesheet.zip",
        "output": ROOT / "assets/characters/marty/spectre_fusion/pixellab",
        "cell": 128,
    },
}

FRONT_CORRECTION = ROOT / "art/source/characters/marty/spectre_fusion/front-correction-source.png"
HEAD_SOURCE = ROOT / "art/source/characters/marty/spectre_fusion/symbiote-heads-v1.png"


def symbiote_heads() -> dict[str, Image.Image]:
    source = Image.open(HEAD_SOURCE).convert("RGBA")
    heads = {}
    for index, direction in enumerate(DIRECTIONS):
        # The reference is a 4 x 2 turn sheet in the same order as Marty.
        col, row = index % 4, index // 4
        left = round(col * source.width / 4)
        top = round(row * source.height / 2)
        right = round((col + 1) * source.width / 4)
        bottom = round((row + 1) * source.height / 2)
        tile = source.crop((left, top, right, bottom))
        alpha = np.asarray(tile)[:, :, 3]
        yy, xx = np.where(alpha > 64)
        if not yy.size:
            raise ValueError(f"Missing symbiote head: {direction}")
        tile = tile.crop((xx.min(), yy.min(), xx.max() + 1, yy.max() + 1))
        scale = min(40 / tile.width, 32 / tile.height)
        tile = tile.resize((round(tile.width * scale), round(tile.height * scale)), Image.Resampling.NEAREST)
        pixels = np.array(tile)
        pixels[pixels[:, :, 3] < 80] = (0, 0, 0, 0)
        heads[direction] = Image.fromarray(pixels, "RGBA")
    return heads


def hair_bounds(frame: Image.Image) -> tuple[int, int, int, int]:
    pixels = np.asarray(frame)
    r = pixels[:, :, 0].astype(np.int16)
    g = pixels[:, :, 1].astype(np.int16)
    b = pixels[:, :, 2].astype(np.int16)
    a = pixels[:, :, 3]
    hair = ((r > 24) & (r < 145) & (g > 12) & (g < 105)
            & (b < 110) & (r > g * 1.12) & (b < r * 0.86) & (a > 180))
    yy, xx = np.where(hair)
    if not yy.size:
        left, top, right, _ = frame.getbbox()
        return left, top, right, top + 20
    remaining = set(zip(xx.tolist(), yy.tolist()))
    best = []
    while remaining:
        seed = remaining.pop()
        component = [seed]
        pending = [seed]
        while pending:
            x, y = pending.pop()
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    neighbor = (x + dx, y + dy)
                    if neighbor in remaining:
                        remaining.remove(neighbor)
                        pending.append(neighbor)
                        component.append(neighbor)
        if len(component) > len(best):
            best = component
    return (min(x for x, _ in best), min(y for _, y in best),
            max(x for x, _ in best) + 1, max(y for _, y in best) + 1)


def replace_fusion_head(frame: Image.Image, head: Image.Image,
                        direction: str, action: str, frame_index: int) -> Image.Image:
    left, top, right, bottom = hair_bounds(frame)
    is_back = direction in ("north-east", "north", "north-west")
    is_side = direction in ("east", "west")
    extra_bottom = 5 if is_back else (10 if is_side else 15)
    pixels = np.array(frame)
    pixels[max(0, top - 4):min(128, bottom + extra_bottom),
           max(0, left - 8):min(128, right + 9), :] = 0
    clean = Image.fromarray(pixels, "RGBA")
    head_x = (left + right) // 2 + (3 if direction in ("east", "south-east") else (-3 if direction in ("west", "south-west") else 0))
    head_bottom = bottom + extra_bottom - (2 if is_back else 0)
    if action == "evade" and frame_index in (2, 3, 4):
        head = head.rotate(-45 if direction not in ("west", "south-west", "north-west") else 45,
                           resample=Image.Resampling.NEAREST, expand=True)
    elif action == "defeat" and frame_index >= 4:
        head = head.rotate(-65 if direction not in ("west", "south-west", "north-west") else 65,
                           resample=Image.Resampling.NEAREST, expand=True)
    clean.alpha_composite(head, (head_x - head.width // 2, head_bottom - head.height))
    return clean


def corrected_fusion_front(target_cell: int) -> Image.Image | None:
    if not FRONT_CORRECTION.exists():
        return None
    source = Image.open(FRONT_CORRECTION).convert("RGBA")
    pixels = np.asarray(source)
    occupied = np.where(pixels[:, :, 3] > 128)
    if not occupied[0].size:
        return None
    left, right = occupied[1].min(), occupied[1].max() + 1
    top, bottom = occupied[0].min(), occupied[0].max() + 1
    sprite = source.crop((left, top, right, bottom))
    width = round(sprite.width * 70 / sprite.height)
    sprite = sprite.resize((width, 70), Image.Resampling.NEAREST)
    clean_pixels = np.array(sprite)
    clean_pixels[clean_pixels[:, :, 3] < 96] = (0, 0, 0, 0)
    clean = Image.fromarray(clean_pixels, "RGBA")
    result = Image.new("RGBA", (target_cell, target_cell))
    result.alpha_composite(clean, ((target_cell - width) // 2, target_cell - 6 - clean.height))
    return result


def spectre_motion_sheet(source: Image.Image, source_cell: int,
                         target_cell: int, rotation: dict, action: str) -> Image.Image:
    frames = {"idle": 4, "run": 6, "shoot": 4}[action]
    sheet = Image.new("RGBA", (frames * target_cell, 8 * target_cell))
    for row_index, direction in enumerate(DIRECTIONS):
        source_column = rotation["directions"].index(direction)
        base = copy_cell(source, source_cell, target_cell, source_column, rotation["row"])
        for frame in range(frames):
            cell = Image.new("RGBA", (target_cell, target_cell))
            if action == "idle":
                offset = (0, (0, -1, -2, -1)[frame])
            elif action == "run":
                offset = ((0, 1, 1, 0, -1, -1)[frame], (0, -2, -3, -2, 0, 1)[frame])
            else:
                offset = ((0, -1, -2, 0)[frame], (0, 1, 1, 0)[frame])
            cell.alpha_composite(base, offset)
            if action == "shoot" and frame in (1, 2):
                pixels = np.array(cell)
                cyan = ((pixels[:, :, 2] > pixels[:, :, 0] * 1.25)
                        & (pixels[:, :, 1] > pixels[:, :, 0] * 1.25)
                        & (pixels[:, :, 3] > 150))
                pixels[cyan, :3] = np.minimum(255, pixels[cyan, :3].astype(np.int16) + 30)
                cell = Image.fromarray(pixels, "RGBA")
            sheet.alpha_composite(cell, (frame * target_cell, row_index * target_cell))
    return sheet


def fusion_tentacle_layer(base: Image.Image) -> Image.Image:
    pixels = np.array(base)
    head_left, head_top, head_right, head_bottom = hair_bounds(base)
    pixels[max(0, head_top - 5):min(base.height, head_bottom + 17),
           max(0, head_left - 9):min(base.width, head_right + 10), :] = 0
    height, width = pixels.shape[:2]
    y, x = np.indices((height, width))
    r = pixels[:, :, 0].astype(np.int16)
    g = pixels[:, :, 1].astype(np.int16)
    b = pixels[:, :, 2].astype(np.int16)
    purple = ((r > g * 1.12) & (b > g * 1.18) & (b > r * 0.78)
              & (pixels[:, :, 3] > 110)
              & ((x < width * 0.42) | (x > width * 0.58) | (y < height * 0.42)))
    mask = Image.fromarray((purple * 255).astype(np.uint8), "L").filter(ImageFilter.MaxFilter(5))
    pixels[:, :, 3] = np.minimum(pixels[:, :, 3], np.asarray(mask))
    return Image.fromarray(pixels, "RGBA")


def colorize_fusion_body(frame: Image.Image) -> Image.Image:
    pixels = np.array(frame)
    bbox = frame.getbbox()
    if bbox is None:
        return frame
    y = np.indices(pixels.shape[:2])[0]
    r = pixels[:, :, 0].astype(np.int16)
    g = pixels[:, :, 1].astype(np.int16)
    b = pixels[:, :, 2].astype(np.int16)
    skin = (r > 145) & (g > 85) & (r > g * 1.08) & (g > b * 0.8)
    cyan = (b > r * 1.2) & (g > r * 1.2)
    body = (pixels[:, :, 3] > 80) & (y > bbox[1] + 21) & ~skin & ~cyan
    pixels[body, 0] = np.clip(r[body] * 0.65 + 10, 0, 255).astype(np.uint8)
    pixels[body, 1] = np.clip(g[body] * 0.60 + 3, 0, 255).astype(np.uint8)
    pixels[body, 2] = np.clip(b[body] * 0.85 + 28, 0, 255).astype(np.uint8)
    return Image.fromarray(pixels, "RGBA")


def fusion_action_sheets(source: Image.Image, source_cell: int,
                         target_cell: int, rotation: dict,
                         output: Path) -> dict[str, int]:
    marty_root = ROOT / "assets/characters/marty/padrao/pixellab"
    heads = symbiote_heads()
    bases = {}
    tentacles = {}
    for direction in DIRECTIONS:
        column = rotation["directions"].index(direction)
        base = copy_cell(source, source_cell, target_cell, column, rotation["row"])
        if direction == "south":
            base = corrected_fusion_front(target_cell) or base
        bases[direction] = base
        tentacles[direction] = fusion_tentacle_layer(base)
    counts = {}
    for action in ("idle", "run", "jump", "evade", "shoot", "melee", "hurt", "defeat"):
        marty = Image.open(marty_root / f"{action}.png").convert("RGBA")
        frames = marty.width // 96
        sheet = Image.new("RGBA", (frames * target_cell, 8 * target_cell))
        for row_index, direction in enumerate(DIRECTIONS):
            for frame in range(frames):
                body = copy_cell(marty, 96, target_cell, frame, row_index)
                body = colorize_fusion_body(body)
                body = replace_fusion_head(body, heads[direction], direction, action, frame)
                cell = Image.new("RGBA", (target_cell, target_cell))
                cell.alpha_composite(tentacles[direction])
                cell.alpha_composite(body)
                sheet.alpha_composite(cell, (frame * target_cell, row_index * target_cell))
        sheet.save(output / f"{action}.png", optimize=True)
        counts[action] = frames
    return counts


def copy_cell(source: Image.Image, source_cell: int, target_cell: int,
              source_column: int, source_row: int) -> Image.Image:
    tile = source.crop((source_column * source_cell, source_row * source_cell,
                        (source_column + 1) * source_cell, (source_row + 1) * source_cell))
    used = tile.getbbox()
    result = Image.new("RGBA", (target_cell, target_cell))
    if used is None:
        return result
    tile = tile.crop(used)
    # Keep the actor's scale and common ground contact. PixelLab centres each
    # cell, whereas the game anchors every pose to the bottom of the frame.
    scale = min(1.0, (target_cell - 12) / max(tile.width, tile.height))
    if scale < 1.0:
        tile = tile.resize((round(tile.width * scale), round(tile.height * scale)), Image.Resampling.NEAREST)
    result.alpha_composite(tile, ((target_cell - tile.width) // 2,
                                  target_cell - 6 - tile.height))
    return result


def import_character(key: str, config: dict) -> None:
    archive = config["archive"]
    if not archive.exists():
        print(f"{key}: source archive missing: {archive}")
        return
    with zipfile.ZipFile(archive) as bundle:
        png_name = next(name for name in bundle.namelist() if name.endswith(".png"))
        json_name = next(name for name in bundle.namelist() if name.endswith(".json"))
        source = Image.open(io.BytesIO(bundle.read(png_name))).convert("RGBA")
        data = json.loads(bundle.read(json_name))
    layout = data["spritesheet"]
    source_cell = layout["cell_size"]["width"]
    assert source_cell == layout["cell_size"]["height"]
    assert source.width % source_cell == 0 and source.height % source_cell == 0
    rows = layout["rows"]
    rotation = next((row for row in rows if row["type"] == "rotations"), None)
    assert rotation is not None
    output = config["output"]
    output.mkdir(parents=True, exist_ok=True)
    target_cell = config["cell"]
    counts: dict[str, int] = {}
    if key == "spectre":
        # Hovering and recoil need tiny physical changes. The AI animation
        # added floating glyphs and stretched tentacles, so use the approved
        # eight rotations as a stable base for these three gameplay actions.
        for action, frames in (("idle", 4), ("run", 6), ("shoot", 4)):
            sheet = spectre_motion_sheet(source, source_cell, target_cell, rotation, action)
            sheet.save(output / f"{action}.png", optimize=True)
            counts[action] = frames
    elif key == "fusion":
        counts = fusion_action_sheets(source, source_cell, target_cell, rotation, output)
    else:
        raise ValueError(key)
    (output / "manifest.json").write_text(json.dumps({
        "character_id": data["character"]["id"],
        "cell": target_cell,
        "directions": DIRECTIONS,
        "frames": counts,
    }, indent=2) + "\n", encoding="utf-8")
    print(f"{key}: {counts}")


if __name__ == "__main__":
    for character, settings in CHARACTERS.items():
        import_character(character, settings)
