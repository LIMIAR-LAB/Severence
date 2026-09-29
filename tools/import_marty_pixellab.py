"""Converte o spritesheet exportado pelo PixelLab em folhas do Godot.

O PixelLab exporta celulas 112x112 com o pivo no centro. O jogo usa celulas
96x96 com os pes em y=94. Recortar oito pixels de cada lateral preserva o
tamanho nativo do pixel art e o deslocamento de cada quadro da animacao.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = (
    ROOT
    / "art/source/characters/marty/padrao/pixellab/export-v2"
    / "Cocky_irreverent_young_a-Se_transformando_em.png"
)
OUTPUT = ROOT / "assets/characters/marty/padrao/pixellab"

SOURCE_CELL = 112
TARGET_CELL = 96
CROP_X = 8
CROP_Y = 0

# Cada acao ocupa oito linhas consecutivas, na ordem direcional do PixelLab.
ACTIONS = {
    "jump": (1, 9),
    "melee": (9, 6),
    "shoot": (17, 3),
    "idle": (25, 4),
    "defeat": (33, 7),
    "hurt": (41, 6),
    "evade": (49, 6),
    "run": (57, 8),
}


def export_action(source: Image.Image, name: str, first_row: int, frames: int) -> None:
    sheet = Image.new("RGBA", (frames * TARGET_CELL, 8 * TARGET_CELL))
    for direction in range(8):
        source_row = first_row + direction
        for frame in range(frames):
            left = frame * SOURCE_CELL + CROP_X
            top = source_row * SOURCE_CELL + CROP_Y
            cell = source.crop(
                (left, top, left + TARGET_CELL, top + TARGET_CELL)
            )
            sheet.paste(cell, (frame * TARGET_CELL, direction * TARGET_CELL))

    path = OUTPUT / f"{name}.png"
    sheet.save(path, optimize=True)
    print(f"{name}: {sheet.width}x{sheet.height} -> {path.relative_to(ROOT)}")


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGBA")
    for name, (first_row, frames) in ACTIONS.items():
        export_action(source, name, first_row, frames)


if __name__ == "__main__":
    main()
