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
PREVIEW = ROOT / "art/source/characters/marty/omega/pixellab/omega-actions-preview.png"
TARGET_CELL = 112
PREVIEW_SCALE = 2
PREVIEW_FRAMES = 8
DIRECTIONS = [
    "south", "south-east", "east", "north-east",
    "north", "north-west", "west", "south-west",
]

ACTION_NAMES = {
    "idle": ("Omega Idle 8-dir", 4),
    "run": ("Omega Run 8-dir", 8),
    "jump": ("Omega Jump 8-dir", 8),
    "evade": ("Omega Rift Dash 8-dir", 7),
    "melee": ("Omega Sword Swing Body 8-dir", 6),
    "hurt": ("Omega Hurt 8-dir", 6),
    "defeat": ("Omega Defeat 8-dir", 8),
}


def fail(message: str) -> None:
    raise SystemExit(message)


def find_export() -> tuple[Path, Path]:
    metadata_files = list(EXPORT.glob("*.json"))
    if len(metadata_files) != 1:
        fail(f"Esperado um JSON em {EXPORT}, encontrados: {len(metadata_files)}")
    metadata_path = metadata_files[0]
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        relative_image = Path(metadata["spritesheet"]["path"])
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        fail(f"Metadados invalidos em {metadata_path}: {error}")
    image_path = (EXPORT / relative_image).resolve()
    if image_path.parent != EXPORT.resolve():
        fail(f"Spritesheet deve estar diretamente em {EXPORT}: {relative_image}")
    if not image_path.is_file():
        fail(f"Spritesheet ausente: {image_path}")
    return metadata_path, image_path


def positive_int(value: object, label: str) -> int:
    try:
        number = int(value)
    except (TypeError, ValueError):
        fail(f"{label} deve ser um inteiro positivo")
    if number <= 0:
        fail(f"{label} deve ser um inteiro positivo")
    return number


def nonnegative_int(value: object, label: str) -> int:
    try:
        number = int(value)
    except (TypeError, ValueError):
        fail(f"{label} deve ser um inteiro nao negativo")
    if number < 0:
        fail(f"{label} deve ser um inteiro nao negativo")
    return number


def validate_cell(cell: Image.Image, label: str) -> None:
    alpha = cell.getchannel("A")
    minimum_alpha, maximum_alpha = alpha.getextrema()
    if maximum_alpha == 0:
        fail(f"{label}: celula vazia")
    if minimum_alpha > 0:
        fail(f"{label}: celula sem fundo transparente")
    bounds = alpha.getbbox()
    if bounds is None:
        fail(f"{label}: celula vazia")
    if bounds[0] == 0 or bounds[1] == 0 or bounds[2] == cell.width or bounds[3] == cell.height:
        fail(f"{label}: arte toca a borda e pode estar cortada")


def normalize_cell(source_cell: Image.Image, label: str) -> Image.Image:
    validate_cell(source_cell, label)
    bounds = source_cell.getchannel("A").getbbox()
    crop_x = max(0, (source_cell.width - TARGET_CELL) // 2)
    # O apoio dos pes e preservado pelo fundo da celula, sem redimensionar pixels.
    crop_y = max(0, source_cell.height - TARGET_CELL)
    normalized_width = min(source_cell.width, TARGET_CELL)
    normalized_height = min(source_cell.height, TARGET_CELL)
    crop_bounds = (
        crop_x,
        crop_y,
        crop_x + normalized_width,
        crop_y + normalized_height,
    )
    if bounds is None or not (
        bounds[0] >= crop_bounds[0]
        and bounds[1] >= crop_bounds[1]
        and bounds[2] <= crop_bounds[2]
        and bounds[3] <= crop_bounds[3]
    ):
        fail(f"{label}: arte nao cabe na normalizacao {TARGET_CELL}x{TARGET_CELL}")
    cropped = source_cell.crop(crop_bounds)
    cell = Image.new("RGBA", (TARGET_CELL, TARGET_CELL))
    destination_x = (TARGET_CELL - normalized_width) // 2
    destination_y = TARGET_CELL - normalized_height
    cell.alpha_composite(cropped, (destination_x, destination_y))
    validate_cell(cell, label)
    return cell


def distributed_frame_indices(source_count: int, target_count: int) -> list[int]:
    if target_count == 1:
        return [0]
    # Arredondamento inteiro e reproduzivel, sempre incluindo primeiro e ultimo.
    denominator = target_count - 1
    return [
        (index * (source_count - 1) + denominator // 2) // denominator
        for index in range(target_count)
    ]


def source_frame_indices(action: str, source_count: int, target_count: int) -> list[int]:
    # O lote idle do PixelLab inclui a rotacao de referencia como quadro zero,
    # seguida dos quatro quadros gerados. O contrato final usa somente a animacao.
    if action == "idle" and source_count == target_count + 1:
        return list(range(1, source_count))
    return distributed_frame_indices(source_count, target_count)


def build_preview(outputs: dict[str, Image.Image]) -> Image.Image:
    """Monta uma auditoria ampliada da vista sul das sete acoes."""
    preview_cell = TARGET_CELL * PREVIEW_SCALE
    preview = Image.new(
        "RGBA",
        (PREVIEW_FRAMES * preview_cell, len(ACTION_NAMES) * preview_cell),
        (20, 20, 29, 255),
    )
    for action_index, (action, (_animation_name, frame_count)) in enumerate(ACTION_NAMES.items()):
        sheet = outputs[action]
        for preview_frame in range(PREVIEW_FRAMES):
            source_frame = preview_frame % frame_count
            cell = sheet.crop((
                source_frame * TARGET_CELL,
                0,
                (source_frame + 1) * TARGET_CELL,
                TARGET_CELL,
            ))
            enlarged = cell.resize((preview_cell, preview_cell), Image.Resampling.NEAREST)
            preview.alpha_composite(enlarged, (preview_frame * preview_cell, action_index * preview_cell))
    return preview


def main() -> None:
    metadata_path, image_path = find_export()
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        sheet_info = metadata["spritesheet"]
        cell_info = sheet_info["cell_size"]
        declared_size = sheet_info["sheet_size"]
        rows = sheet_info["rows"]
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        fail(f"Metadados incompletos em {metadata_path}: {error}")
    if not isinstance(rows, list):
        fail("spritesheet.rows deve ser uma lista")

    if not isinstance(cell_info, dict) or not isinstance(declared_size, dict):
        fail("cell_size e sheet_size devem ser objetos")
    cell_width = positive_int(cell_info.get("width"), "cell_size.width")
    cell_height = positive_int(cell_info.get("height"), "cell_size.height")
    columns = positive_int(sheet_info.get("columns"), "spritesheet.columns")
    declared_width = positive_int(declared_size.get("width"), "sheet_size.width")
    declared_height = positive_int(declared_size.get("height"), "sheet_size.height")

    with Image.open(image_path) as opened_source:
        if opened_source.format != "PNG" or "A" not in opened_source.getbands():
            fail("Spritesheet deve ser PNG com canal alpha")
        source = opened_source.convert("RGBA")
    if source.size != (declared_width, declared_height):
        fail(
            f"Dimensao real {source.width}x{source.height} difere dos metadados "
            f"{declared_width}x{declared_height}"
        )
    if declared_width != columns * cell_width or declared_height % cell_height != 0:
        fail("Dimensoes da folha nao correspondem a columns e cell_size")
    if sheet_info.get("pivot") != "cell-center":
        fail("spritesheet.pivot deve ser cell-center")
    row_count = declared_height // cell_height
    outputs: dict[str, Image.Image] = {}

    for action, (animation_name, expected_frames) in ACTION_NAMES.items():
        matching_rows = [
            row for row in rows
            if isinstance(row, dict)
            and row.get("type") == "animation"
            and row.get("animation") == animation_name
        ]
        animation_rows: dict[str, dict] = {}
        for row in matching_rows:
            direction = row.get("direction")
            if direction in animation_rows:
                fail(f"{animation_name}: direcao duplicada: {direction}")
            animation_rows[direction] = row
        missing = [direction for direction in DIRECTIONS if direction not in animation_rows]
        if missing:
            fail(f"{animation_name}: direcoes ausentes: {', '.join(missing)}")
        unexpected = [direction for direction in animation_rows if direction not in DIRECTIONS]
        if unexpected:
            fail(f"{animation_name}: direcoes desconhecidas: {', '.join(map(str, unexpected))}")

        source_frame_count = positive_int(
            animation_rows[DIRECTIONS[0]].get("frame_count"),
            f"{animation_name}.frame_count",
        )
        if source_frame_count < expected_frames:
            fail(
                f"{animation_name}: minimo de {expected_frames} quadros, "
                f"encontrados {source_frame_count}"
            )
        if source_frame_count > columns:
            fail(f"{animation_name}: {source_frame_count} quadros excedem {columns} colunas")
        selected_frames = source_frame_indices(action, source_frame_count, expected_frames)
        output = Image.new("RGBA", (expected_frames * TARGET_CELL, len(DIRECTIONS) * TARGET_CELL))
        for direction_index, direction in enumerate(DIRECTIONS):
            row = animation_rows[direction]
            if positive_int(row.get("frame_count"), f"{animation_name}/{direction}.frame_count") != source_frame_count:
                fail(f"{animation_name}: quantidade de quadros inconsistente")
            row_index = nonnegative_int(row.get("row"), f"{animation_name}/{direction}.row")
            if row_index >= row_count:
                fail(f"{animation_name}/{direction}: linha {row_index} fora da folha")
            normalized_cells: list[Image.Image] = []
            for source_frame in range(source_frame_count):
                label = f"{animation_name}/{direction}/quadro {source_frame}"
                cell_left = source_frame * cell_width
                cell_top = row_index * cell_height
                source_cell = source.crop((
                    cell_left,
                    cell_top,
                    cell_left + cell_width,
                    cell_top + cell_height,
                ))
                normalized_cells.append(normalize_cell(source_cell, label))
            for target_frame, source_frame in enumerate(selected_frames):
                cell = normalized_cells[source_frame]
                output.alpha_composite(cell, (target_frame * TARGET_CELL, direction_index * TARGET_CELL))
        outputs[action] = output

    OUTPUT.mkdir(parents=True, exist_ok=True)
    for action, output in outputs.items():
        destination = OUTPUT / f"{action}.png"
        output.save(destination, optimize=True)
        print(
            f"{action}: {output.width // TARGET_CELL} quadros -> "
            f"{destination.relative_to(ROOT)}"
        )
    preview = build_preview(outputs)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    preview.save(PREVIEW, optimize=True)
    print(f"preview: {preview.width}x{preview.height} -> {PREVIEW.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
