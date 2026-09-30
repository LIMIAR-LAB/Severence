"""Converte o export PixelLab da Armadura Omega em folhas separadas do Godot.

O export usa celulas com margem e pivo central. A producao do jogo conserva uma
celula 112x112 para a silhueta mais larga da armadura e organiza as direcoes na
ordem padrao: sul, sudeste, leste, nordeste, norte, noroeste, oeste, sudoeste.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "art/source/characters/marty/omega/pixellab/export"
OUTPUT = ROOT / "assets/characters/marty/omega/pixellab"
TARGET_CELL = 112
DIRECTIONS = [
    "south", "south-east", "east", "north-east",
    "north", "north-west", "west", "south-west",
]

ACTION_NAMES = {
    "idle": "Omega Idle 8-dir",
    "run": "Omega Run 8-dir",
    "jump": "Omega Jump 8-dir",
    "evade": "Omega Rift Dash 8-dir",
    "melee": "Omega Sword Swing Body 8-dir",
    "hurt": "Omega Hurt 8-dir",
    "defeat": "Omega Defeat 8-dir",
}


def find_export() -> tuple[Path, Path]:
    metadata_files = list(EXPORT.glob("*.json"))
    if len(metadata_files) != 1:
        raise SystemExit(f"Esperado um JSON em {EXPORT}, encontrados: {len(metadata_files)}")
    metadata_path = metadata_files[0]
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    image_path = EXPORT / metadata["spritesheet"]["path"]
    if not image_path.exists():
        raise SystemExit(f"Spritesheet ausente: {image_path}")
    return metadata_path, image_path


def main() -> None:
    metadata_path, image_path = find_export()
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    sheet_info = metadata["spritesheet"]
    source_cell = int(sheet_info["cell_size"]["width"])
    if source_cell < TARGET_CELL:
        raise SystemExit(f"Celula PixelLab {source_cell}px menor que o alvo {TARGET_CELL}px")

    crop_x = (source_cell - TARGET_CELL) // 2
    crop_y = 0
    source = Image.open(image_path).convert("RGBA")
    rows = sheet_info["rows"]
    OUTPUT.mkdir(parents=True, exist_ok=True)

    for action, animation_name in ACTION_NAMES.items():
        animation_rows = {
            row["direction"]: row
            for row in rows
            if row.get("type") == "animation" and row.get("animation") == animation_name
        }
        missing = [direction for direction in DIRECTIONS if direction not in animation_rows]
        if missing:
            raise SystemExit(f"{animation_name}: direcoes ausentes: {', '.join(missing)}")

        frame_count = int(animation_rows[DIRECTIONS[0]]["frame_count"])
        output = Image.new("RGBA", (frame_count * TARGET_CELL, len(DIRECTIONS) * TARGET_CELL))
        for direction_index, direction in enumerate(DIRECTIONS):
            row = animation_rows[direction]
            if int(row["frame_count"]) != frame_count:
                raise SystemExit(f"{animation_name}: quantidade de quadros inconsistente")
            source_y = int(row["row"]) * source_cell + crop_y
            for frame in range(frame_count):
                source_x = frame * source_cell + crop_x
                cell = source.crop((
                    source_x,
                    source_y,
                    source_x + TARGET_CELL,
                    source_y + TARGET_CELL,
                ))
                output.alpha_composite(cell, (frame * TARGET_CELL, direction_index * TARGET_CELL))

        destination = OUTPUT / f"{action}.png"
        output.save(destination, optimize=True)
        print(f"{action}: {frame_count} quadros -> {destination.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
