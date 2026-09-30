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
        "actions": {
            "hovering idle": "idle",
            "hovering travel": "run",
            "energy shot": "shoot",
            "evasive burst": "evade",
            "damage reaction": "hurt",
            "shutdown": "defeat",
        },
    },
    "fusion": {
        "archive": ROOT / "art/source/characters/marty/spectre_fusion/pixellab/fusion-pixellab-spritesheet.zip",
        "output": ROOT / "assets/characters/marty/spectre_fusion/pixellab",
        "cell": 128,
        "actions": {
            "fusion idle": "idle",
            "fusion run": "run",
            "fusion jump": "jump",
            "fusion evade": "evade",
            "fusion shoot": "shoot",
            "fusion melee": "melee",
            "fusion hurt": "hurt",
            "fusion defeat": "defeat",
        },
    },
}


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
    groups: dict[str, dict[str, dict]] = {}
    for row in rows:
        if row["type"] == "animation":
            groups.setdefault(row["animation"].lower(), {})[row["direction"]] = row

    output = config["output"]
    output.mkdir(parents=True, exist_ok=True)
    target_cell = config["cell"]
    counts: dict[str, int] = {}
    for pattern, action in config["actions"].items():
        found = [(name, directions) for name, directions in groups.items() if pattern in name]
        if len(found) > 1:
            raise ValueError(f"{key}/{action}: ambiguous animation: {[name for name, _ in found]}")
        if found:
            directions = found[0][1]
            if any(direction not in directions for direction in DIRECTIONS):
                print(f"{key}/{action}: waiting for all eight directions")
                continue
            frames = min(directions[direction]["frame_count"] for direction in DIRECTIONS)
            sheet = Image.new("RGBA", (frames * target_cell, 8 * target_cell))
            for row_index, direction in enumerate(DIRECTIONS):
                source_row = directions[direction]["row"]
                for frame in range(frames):
                    tile = copy_cell(source, source_cell, target_cell, frame, source_row)
                    sheet.alpha_composite(tile, (frame * target_cell, row_index * target_cell))
        elif action == "idle":
            rotation = next((row for row in rows if row["type"] == "rotations"), None)
            if rotation is None:
                continue
            frames = 1
            sheet = Image.new("RGBA", (target_cell, 8 * target_cell))
            for row_index, direction in enumerate(DIRECTIONS):
                source_column = rotation["directions"].index(direction)
                tile = copy_cell(source, source_cell, target_cell, source_column, rotation["row"])
                sheet.alpha_composite(tile, (0, row_index * target_cell))
        else:
            continue
        sheet.save(output / f"{action}.png", optimize=True)
        counts[action] = frames
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
