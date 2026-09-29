"""Monta os inimigos PixelLab em atlas previsíveis para o renderer Godot.

As fontes .zip são exportações do PixelLab guardadas em art/source/pixellab.
Cada atlas final tem 8 direções (linhas) × 5 poses (parado + 4 de movimento),
células 96×96 e pivô dos pés em (48, 92).
"""

from io import BytesIO
from pathlib import Path
from zipfile import ZipFile

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "source" / "pixellab"
TARGET = ROOT / "assets" / "enemies"
DIRECTIONS = (
    "south", "south-east", "east", "north-east",
    "north", "north-west", "west", "south-west",
)
CELL = 96
CONFIG = {
    "guard": "guard_walk_4_cardinal",
    "bomber": "bomber_run_4",
}


def frame(archive: ZipFile, name: str) -> Image.Image | None:
    try:
        return Image.open(BytesIO(archive.read(name))).convert("RGBA")
    except KeyError:
        return None


def place(canvas: Image.Image, art: Image.Image, column: int, row: int) -> None:
    # Corta só a transparência externa; mantém a proporção e o chão estável.
    box = art.getbbox()
    if box is None:
        return
    art = art.crop(box)
    ratio = min(84 / art.width, 84 / art.height)
    size = (max(1, round(art.width * ratio)), max(1, round(art.height * ratio)))
    art = art.resize(size, Image.Resampling.NEAREST)
    x = column * CELL + (CELL - art.width) // 2
    y = row * CELL + 92 - art.height
    canvas.alpha_composite(art, (x, y))


def build(kind: str, animation: str) -> None:
    with ZipFile(SOURCE / f"{kind}_v1.zip") as archive:
        atlas = Image.new("RGBA", (5 * CELL, 8 * CELL), (0, 0, 0, 0))
        animated = 0
        for row, direction in enumerate(DIRECTIONS):
            idle = frame(archive, f"Idle/rotations/{direction}.png")
            if idle is None:
                raise ValueError(f"{kind}: vista {direction} ausente")
            place(atlas, idle, 0, row)
            for index in range(4):
                path = f"Idle/animations/{animation}/{direction}/frame_{index:03}.png"
                pose = frame(archive, path)
                if pose is not None:
                    animated += 1
                place(atlas, pose if pose is not None else idle, index + 1, row)
        output = TARGET / f"{kind}_pixellab_v1.png"
        atlas.save(output)
        print(f"{kind}: {output.name} 480x768, {animated}/32 quadros animados")


if __name__ == "__main__":
    for enemy, motion in CONFIG.items():
        build(enemy, motion)
