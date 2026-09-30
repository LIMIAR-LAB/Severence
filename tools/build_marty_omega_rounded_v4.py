"""Build an eight-direction Omega motion proof from the approved PixelLab rotations.

The source rotations stay intact. Motion here is pixel-exact (nearest-neighbour)
so every action retains the same armor, faceplate and silhouette while the
PixelLab animation jobs are being reviewed.
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/source/characters/marty/omega/pixellab/rounded-v4/export/Omega_Compacta_Samurai_F-Idle.png"
OUTPUT = ROOT / "art/source/characters/marty/omega/pixellab/rounded-v4/generated"
AI_FRAMES = ROOT / "art/source/characters/marty/omega/pixellab/rounded-v4/ai-frames"
CELL = 112
SOURCE_CELL = 96
FRAMES = {"idle": 4, "run": 8, "jump": 8, "evade": 7, "melee": 6, "hurt": 6, "defeat": 8}
DIRECTIONS = ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]
MELEE_SELECTIONS = {
    "south": [1, 2, 3, 4, 5, 6],
    "south-east": [1, 2, 3, 2, 1, 0],
    "east": [1, 2, 3, 4, 5, 6],
    "north-east": [0, 1, 1, 1, 1, 0],
    "north": [1, 2, 3, 4, 5, 6],
    "north-west": [0, 1, 1, 6, 6, 0],
    "west": [1, 2, 3, 4, 5, 6],
    "south-west": [1, 2, 3, 4, 5, 6],
}


def ai_frame(action: str, direction: str, index: int) -> Image.Image | None:
    path = AI_FRAMES / action / direction / f"{index}.png"
    if not path.is_file():
        return None
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
    if image.size not in [(CELL, CELL), (CELL + 4, CELL + 4)]:
        raise ValueError(f"Invalid PixelLab frame size: {path}: {image.size}")
    if image.size != (CELL, CELL):
        margin = (image.width - CELL) // 2
        image = image.crop((margin, margin, margin + CELL, margin + CELL))
    bounds = image.getchannel("A").getbbox()
    if bounds is None or bounds[0] <= 0 or bounds[1] <= 0 or bounds[2] >= CELL or bounds[3] >= CELL:
        raise ValueError(f"Empty or clipped PixelLab frame: {path}: {bounds}")
    return image


def shift_cell(image: Image.Image, x: int = 0, y: int = 0) -> Image.Image:
    shifted = Image.new("RGBA", (CELL, CELL))
    shifted.alpha_composite(image, (x, y))
    return shifted


def validate_cell(image: Image.Image, label: str) -> None:
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError(f"Empty Omega frame: {label}")
    if bounds[0] <= 0 or bounds[1] <= 0 or bounds[2] >= CELL or bounds[3] >= CELL:
        raise ValueError(f"Clipped Omega frame: {label}: {bounds}")
    width, height = bounds[2] - bounds[0], bounds[3] - bounds[1]
    if width > 82 or height > 90:
        raise ValueError(f"Omega silhouette drift or weapon baked into frame: {label}: {width}x{height}")
    filled = sum(alpha.histogram()[1:])
    if filled / (width * height) >= 0.95:
        raise ValueError(f"Opaque rectangular matte in Omega frame: {label}")


def center_frame(sprite: Image.Image, x: int = 0, y: int = 0) -> Image.Image:
    canvas = Image.new("RGBA", (CELL, CELL))
    canvas.alpha_composite(sprite, ((CELL - SOURCE_CELL) // 2 + x, (CELL - SOURCE_CELL) // 2 + y))
    return canvas


def frame(sprite: Image.Image, action: str, index: int, direction: int) -> Image.Image:
    direction_name = DIRECTIONS[direction]
    if action == "idle":
        generated = ai_frame("idle", direction_name, index + 1)
        if generated is None:
            raise FileNotFoundError(f"Missing approved idle frame: {direction_name}/{index + 1}")
        return generated
    if action == "run":
        # Glide with the actual cape/jet movement from the PixelLab hover loop.
        # The separate run generation introduced footfalls, so it is rejected.
        generated = ai_frame("idle", direction_name, index % 4 + 1)
        if generated is None:
            raise FileNotFoundError(f"Missing approved glide frame: {direction_name}/{index % 4 + 1}")
        return shift_cell(generated, [0, 1, 2, 1, 0, -1, -2, -1][index], [-2, -3, -4, -3, -2, -1, -2, -3][index])
    if action == "jump":
        return center_frame(sprite, 0, [0, -3, -7, -10, -10, -7, -3, 0][index])
    if action == "evade":
        sx, sy = [(0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1)][direction]
        distance = [-4, -2, 1, 5, 7, 3, 0][index]
        return center_frame(sprite, sx * distance, sy * distance - [1, 2, 4, 5, 4, 2, 1][index])
    if action == "melee":
        # The east PixelLab pass hallucinated a cyan weapon. Mirroring the
        # clean west body motion preserves the armor and avoids a second blade.
        if direction_name == "east":
            west = ai_frame("melee", "west", MELEE_SELECTIONS[direction_name][index])
            generated = ImageOps.mirror(west) if west is not None else None
        else:
            generated = ai_frame("melee", direction_name, MELEE_SELECTIONS[direction_name][index])
        if generated is None:
            raise FileNotFoundError(f"Missing approved melee frame: {direction_name}/{index}")
        if direction_name in ("north-east", "north-west"):
            angle = [0, -3, -5, 6, 3, 0][index] * (1 if direction_name == "north-east" else -1)
            generated = generated.rotate(angle, Image.Resampling.NEAREST, expand=False)
            generated = shift_cell(generated, [0, -1, -2, 2, 1, 0][index], [-1, -2, -3, -2, -1, 0][index])
        return generated
    if action == "hurt":
        return center_frame(sprite, [0, -2, -4, -3, -1, 0][index], [0, -1, -2, -1, 0, 0][index])
    # Collapse without revealing the person under the suit.
    height = [96, 91, 83, 73, 62, 53, 46, 42][index]
    collapsed = sprite.resize((SOURCE_CELL, height), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (CELL, CELL))
    canvas.alpha_composite(collapsed, (8, 104 - height))
    return canvas


def main() -> None:
    with Image.open(SOURCE) as opened:
        source = opened.convert("RGBA")
    assert source.size == (SOURCE_CELL * 8, SOURCE_CELL), source.size
    OUTPUT.mkdir(parents=True, exist_ok=True)
    preview = Image.new("RGB", (4 * 288, 2 * 336), (23, 25, 38))
    preview_draw = ImageDraw.Draw(preview)
    labels = ["Frente", "Diagonal frente D", "Direita", "Diagonal costas D", "Costas", "Diagonal costas E", "Esquerda", "Diagonal frente E"]
    for direction, label in enumerate(labels):
        sprite = source.crop((direction * SOURCE_CELL, 0, (direction + 1) * SOURCE_CELL, SOURCE_CELL))
        enlarged = sprite.resize((288, 288), Image.Resampling.NEAREST)
        x, y = direction % 4 * 288, direction // 4 * 336
        preview.paste(enlarged, (x, y), enlarged)
        preview_draw.text((x + 10, y + 294), label, fill=(233, 237, 246))
    preview.save(OUTPUT.parent / "omega-rounded-v4-eight-directions-preview.png", optimize=True)
    sheets: dict[str, Image.Image] = {}
    for action, count in FRAMES.items():
        sheet = Image.new("RGBA", (CELL * count, CELL * 8))
        for direction in range(8):
            sprite = source.crop((direction * SOURCE_CELL, 0, (direction + 1) * SOURCE_CELL, SOURCE_CELL))
            for index in range(count):
                cell = frame(sprite, action, index, direction)
                validate_cell(cell, f"{action}/{DIRECTIONS[direction]}/{index}")
                sheet.alpha_composite(cell, (index * CELL, direction * CELL))
        sheet.save(OUTPUT / f"{action}.png", optimize=True)
        sheets[action] = sheet
        print(f"{action}: {sheet.width}x{sheet.height}")
    picks = {"idle": [0, 1, 3], "run": [0, 3, 6], "evade": [0, 3, 6], "melee": [0, 3, 5]}
    overview = Image.new("RGBA", (112 + CELL * 12, 36 + CELL * 8), (22, 24, 36, 255))
    labels = ImageDraw.Draw(overview)
    for action_index, (action, frames) in enumerate(picks.items()):
        labels.text((112 + action_index * CELL * 3 + 7, 10), action.upper(), fill=(232, 237, 246))
        for row, direction_name in enumerate(DIRECTIONS):
            labels.text((7, 36 + row * CELL + 47), direction_name, fill=(183, 199, 224))
            for column, frame_index in enumerate(frames):
                cell = sheets[action].crop((frame_index * CELL, row * CELL, (frame_index + 1) * CELL, (row + 1) * CELL))
                overview.alpha_composite(cell, (112 + (action_index * 3 + column) * CELL, 36 + row * CELL))
    overview.save(OUTPUT.parent / "omega-rounded-v4-actions-final-preview.png", optimize=True)


if __name__ == "__main__":
    main()
