"""Converte o export PixelLab da Armadura Omega em folhas separadas do Godot.

O export usa celulas com margem e pivo central. A producao do jogo conserva uma
celula 112x112 para a silhueta mais larga da armadura e organiza as direcoes na
ordem padrao: sul, sudeste, leste, nordeste, norte, noroeste, oeste, sudoeste.
"""

from __future__ import annotations

import json
import os
from pathlib import Path
import tempfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
EXPORT = ROOT / "art/source/characters/marty/omega/pixellab/export"
OUTPUT = ROOT / "assets/characters/marty/omega/pixellab"
PREVIEW = ROOT / "art/source/characters/marty/omega/pixellab/omega-actions-preview.png"
MELEE_SOURCE = ROOT / "art/source/characters/marty/omega/pixellab/melee-pixellab"
MELEE_MANIFEST = MELEE_SOURCE / "manifest.json"
TARGET_CELL = 112
APPROVED_CHARACTER_ID = "b41db246-47d5-4914-a111-a6bd644abc2b"
MAX_ALPHA_BOUNDS_OCCUPANCY = 0.95
HURT_WEST_OVERRIDE = {
    "animation": "Omega Hurt West Clean Retry 2",
    "animation_group_id": "6e1c87d3-73d4-4318-aeb3-7257cb8747a8",
    "direction": "west",
}
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

APPROVED_ANIMATION_GROUPS = {
    "idle": "3aa75c6b-8378-42d9-af3a-9ba796bcfac4",
    "run": "de4daf12-95f8-47cb-b436-d050f07f9472",
    "jump": "b5ae32c6-55fa-4cf3-a0ec-4117ba842baf",
    "evade": "7f0a6eb1-4af4-4696-80f0-8c7fdde0a7e5",
    "hurt": "b4a66c18-db45-412a-923f-dc7c77cec2ba",
    "defeat": "6a92b77d-1235-4e6a-a166-d7514931b27c",
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
    histogram = alpha.histogram()
    nonzero_alpha = sum(histogram[1:])
    bounds_area = (bounds[2] - bounds[0]) * (bounds[3] - bounds[1])
    occupancy = nonzero_alpha / bounds_area
    if occupancy >= MAX_ALPHA_BOUNDS_OCCUPANCY:
        fail(
            f"{label}: matte retangular opaco detectado "
            f"({occupancy:.1%} do bounding box preenchido)"
        )
    if bounds[0] == 0 or bounds[1] == 0 or bounds[2] == cell.width or bounds[3] == cell.height:
        fail(f"{label}: arte toca a borda e pode estar cortada")


def crop_window_start(
    source_size: int,
    content_start: int,
    content_end: int,
    desired_start: int,
    label: str,
) -> int:
    """Escolhe janela TARGET_CELL com pelo menos 1 px transparente nas bordas."""
    if source_size <= TARGET_CELL:
        return 0
    minimum_start = max(0, content_end - TARGET_CELL + 1)
    maximum_start = min(source_size - TARGET_CELL, content_start - 1)
    if minimum_start > maximum_start:
        fail(f"{label}: arte nao cabe em {TARGET_CELL}px com margem transparente")
    return max(minimum_start, min(desired_start, maximum_start))


def normalize_cell(source_cell: Image.Image, label: str, preserve_source_y: bool = False) -> Image.Image:
    validate_cell(source_cell, label)
    bounds = source_cell.getchannel("A").getbbox()
    if bounds is None:
        fail(f"{label}: celula vazia")
    crop_x = crop_window_start(
        source_cell.width,
        bounds[0],
        bounds[2],
        max(0, (source_cell.width - TARGET_CELL) // 2),
        label,
    )
    # Prefere a janela apoiada no fundo; move-a apenas o minimo necessario para
    # preservar alpha transparente nas quatro bordas do quadro final.
    crop_y = crop_window_start(
        source_cell.height,
        bounds[1],
        bounds[3],
        max(0, source_cell.height - TARGET_CELL),
        label,
    )
    normalized_width = min(source_cell.width, TARGET_CELL)
    normalized_height = min(source_cell.height, TARGET_CELL)
    crop_bounds = (
        crop_x,
        crop_y,
        crop_x + normalized_width,
        crop_y + normalized_height,
    )
    if not (
        bounds[0] >= crop_bounds[0]
        and bounds[1] >= crop_bounds[1]
        and bounds[2] <= crop_bounds[2]
        and bounds[3] <= crop_bounds[3]
    ):
        fail(f"{label}: arte nao cabe na normalizacao {TARGET_CELL}x{TARGET_CELL}")
    cropped = source_cell.crop(crop_bounds)
    cell = Image.new("RGBA", (TARGET_CELL, TARGET_CELL))
    destination_x = (TARGET_CELL - normalized_width) // 2
    # Os frames loose do melee usam o mesmo canvas PixelLab 96x96 da referência;
    # preservar y=0 mantém a linha dos pés compatível com as ações exportadas.
    destination_y = 0 if preserve_source_y and source_cell.height <= TARGET_CELL else TARGET_CELL - normalized_height
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


def load_loose_melee() -> Image.Image | None:
    """Carrega quadros PixelLab aprovados individualmente quando há manifesto."""
    if not MELEE_MANIFEST.exists():
        return None
    try:
        manifest = json.loads(MELEE_MANIFEST.read_text(encoding="utf-8"))
        directions = manifest["directions"]
    except (json.JSONDecodeError, KeyError, TypeError) as error:
        fail(f"Manifesto melee invalido em {MELEE_MANIFEST}: {error}")
    if not isinstance(directions, dict):
        fail("melee-pixellab/manifest.json: directions deve ser um objeto")
    if manifest.get("character_id") != APPROVED_CHARACTER_ID:
        fail(
            "melee-pixellab/manifest.json: character_id deve ser "
            f"{APPROVED_CHARACTER_ID}"
        )
    if not isinstance(manifest.get("generator"), str) or not manifest["generator"].strip():
        fail("melee-pixellab/manifest.json: generator/proveniencia obrigatorio")
    if set(directions) != set(DIRECTIONS):
        missing = [direction for direction in DIRECTIONS if direction not in directions]
        unexpected = [direction for direction in directions if direction not in DIRECTIONS]
        fail(
            "melee-pixellab/manifest.json: direcoes invalidas; "
            f"ausentes={missing}, desconhecidas={unexpected}"
        )

    output = Image.new("RGBA", (ACTION_NAMES["melee"][1] * TARGET_CELL, len(DIRECTIONS) * TARGET_CELL))
    source_root = MELEE_SOURCE.resolve()
    for direction_index, direction in enumerate(DIRECTIONS):
        entry = directions[direction]
        if not isinstance(entry, dict):
            fail(f"melee/{direction}: entrada deve ser um objeto")
        job_id = entry.get("job_id")
        source_indices = entry.get("selected_source_indices")
        frames = entry.get("frames")
        if not isinstance(job_id, str) or not job_id.strip():
            fail(f"melee/{direction}: job_id PixelLab obrigatorio")
        if not isinstance(frames, list) or len(frames) != ACTION_NAMES["melee"][1]:
            fail(f"melee/{direction}: esperado exatamente 6 caminhos de quadros")
        if (
            not isinstance(source_indices, list)
            or len(source_indices) != ACTION_NAMES["melee"][1]
            or any(not isinstance(index, int) or index < 0 for index in source_indices)
        ):
            fail(f"melee/{direction}: esperado exatamente 6 indices PixelLab nao negativos")
        if len(set(map(str, frames))) != len(frames):
            fail(f"melee/{direction}: caminhos de quadros duplicados")

        frame_hashes: set[bytes] = set()
        for frame_index, relative_frame in enumerate(frames):
            if not isinstance(relative_frame, str) or not relative_frame:
                fail(f"melee/{direction}/quadro {frame_index}: caminho invalido")
            frame_path = (MELEE_SOURCE / relative_frame).resolve()
            if not frame_path.is_relative_to(source_root):
                fail(f"melee/{direction}/quadro {frame_index}: caminho fora de {MELEE_SOURCE}")
            if not frame_path.is_file():
                fail(f"melee/{direction}/quadro {frame_index}: PNG ausente: {frame_path}")
            with Image.open(frame_path) as opened_frame:
                if opened_frame.format != "PNG" or "A" not in opened_frame.getbands():
                    fail(f"melee/{direction}/quadro {frame_index}: deve ser PNG com alpha")
                if opened_frame.size != (96, 96):
                    fail(
                        f"melee/{direction}/quadro {frame_index}: esperado 96x96, "
                        f"encontrado {opened_frame.width}x{opened_frame.height}"
                    )
                source_frame = opened_frame.convert("RGBA")
            label = f"melee/{direction}/quadro {frame_index} (job {job_id})"
            cell = normalize_cell(source_frame, label, preserve_source_y=True)
            frame_hashes.add(cell.tobytes())
            output.alpha_composite(cell, (frame_index * TARGET_CELL, direction_index * TARGET_CELL))
        if len(frame_hashes) <= 1:
            fail(f"melee/{direction}: os seis quadros nao possuem movimento real")
    return output


def build_preview(outputs: dict[str, Image.Image]) -> Image.Image:
    """Empilha as sete folhas completas para auditoria de todas as direcoes."""
    preview = Image.new(
        "RGBA",
        (max(output.width for output in outputs.values()), len(ACTION_NAMES) * len(DIRECTIONS) * TARGET_CELL),
        (20, 20, 29, 255),
    )
    for action_index, action in enumerate(ACTION_NAMES):
        preview.alpha_composite(outputs[action], (0, action_index * len(DIRECTIONS) * TARGET_CELL))
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
    character = metadata.get("character")
    if not isinstance(character, dict) or character.get("id") != APPROVED_CHARACTER_ID:
        fail(f"Export deve pertencer ao personagem aprovado {APPROVED_CHARACTER_ID}")

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
    loose_melee = load_loose_melee()

    for action, (animation_name, expected_frames) in ACTION_NAMES.items():
        if action == "melee" and loose_melee is not None:
            outputs[action] = loose_melee
            continue
        matching_rows = [
            row for row in rows
            if isinstance(row, dict)
            and row.get("type") == "animation"
            and row.get("animation") == animation_name
        ]
        if action == "hurt":
            # O west original retornou matte cinza e ainda aparece duplicado no
            # export. Somente o retry PixelLab aprovado pode preencher a linha.
            matching_rows = [row for row in matching_rows if row.get("direction") != "west"]
            override_rows = [
                row for row in rows
                if isinstance(row, dict)
                and row.get("type") == "animation"
                and all(row.get(key) == value for key, value in HURT_WEST_OVERRIDE.items())
            ]
            if len(override_rows) != 1:
                fail(
                    "Omega Hurt west: esperado exatamente um override PixelLab "
                    f"{HURT_WEST_OVERRIDE}, encontrados {len(override_rows)}"
                )
            matching_rows.append(override_rows[0])
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
            expected_group = (
                HURT_WEST_OVERRIDE["animation_group_id"]
                if action == "hurt" and direction == "west"
                else APPROVED_ANIMATION_GROUPS.get(action)
            )
            if expected_group is not None and row.get("animation_group_id") != expected_group:
                fail(
                    f"{animation_name}/{direction}: grupo PixelLab deve ser "
                    f"{expected_group}, encontrado {row.get('animation_group_id')}"
                )
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

    preview = build_preview(outputs)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    destinations = {OUTPUT / f"{action}.png": output for action, output in outputs.items()}
    destinations[PREVIEW] = preview
    # Codifica e reabre o conjunto inteiro antes de tocar nos assets publicados.
    # Durante a promocao, qualquer erro recuperavel restaura todos os arquivos
    # anteriores para evitar uma mistura de geracoes.
    with tempfile.TemporaryDirectory(prefix=".omega-import-", dir=OUTPUT.parent) as staging_name:
        staging = Path(staging_name)
        staged_files: dict[Path, Path] = {}
        for index, (destination, image) in enumerate(destinations.items()):
            staged = staging / f"new-{index}.png"
            image.save(staged, optimize=True)
            with Image.open(staged) as verification:
                if verification.format != "PNG" or verification.size != image.size:
                    fail(f"Falha ao verificar artefato temporario de {destination}")
            staged_files[destination] = staged
        backups: dict[Path, Path] = {}
        promoted: list[Path] = []
        try:
            for index, (destination, staged) in enumerate(staged_files.items()):
                backup = staging / f"old-{index}.png"
                if destination.exists():
                    os.replace(destination, backup)
                    backups[destination] = backup
                os.replace(staged, destination)
                promoted.append(destination)
        except OSError:
            for destination in reversed(promoted):
                if destination.exists():
                    destination.unlink()
                backup = backups.get(destination)
                if backup is not None and backup.exists():
                    os.replace(backup, destination)
            for destination, backup in backups.items():
                if destination not in promoted and backup.exists():
                    os.replace(backup, destination)
            raise
    for action, output in outputs.items():
        destination = OUTPUT / f"{action}.png"
        print(
            f"{action}: {output.width // TARGET_CELL} quadros -> "
            f"{destination.relative_to(ROOT)}"
        )
    print(f"preview: {preview.width}x{preview.height} -> {PREVIEW.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
