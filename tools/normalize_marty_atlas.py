"""Gera o atlas jogável v2 do Marty mantendo a grade e as animações existentes.

O original preserva a arte-fonte. Este passo só normaliza escala e pivô para que
as três roupas pareçam o mesmo piloto e a Ômega permaneça maior, mas controlada.
"""
from pathlib import Path

from PIL import Image


CELL = 96
COLUMNS = 10
ROWS_PER_OUTFIT = 5
OUTFITS = ("padrao", "espiao", "mecanico", "omega")

# Escala do corpo em relação ao atlas legado. O centro e o contato dos pés são
# preservados em todas as poses; Ômega fica 16% maior para comunicar a armadura.
SCALE = {"padrao": 1.05, "espiao": 1.08, "mecanico": 1.00, "omega": 0.90}
FOOT_Y = 92


def place_cell(source: Image.Image, scale: float) -> Image.Image:
    """Escala uma célula inteira ao redor do pivô inferior, sem suavização."""
    alpha = source.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        return source.copy()
    left, top, right, bottom = bounds
    crop = source.crop(bounds)
    width = max(1, round(crop.width * scale))
    height = max(1, round(crop.height * scale))
    crop = crop.resize((width, height), Image.Resampling.NEAREST)
    destination = Image.new("RGBA", (CELL, CELL))
    x = round(CELL * 0.5 - crop.width * 0.5)
    y = FOOT_Y - crop.height
    destination.alpha_composite(crop, (x, y))
    return destination


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    source_path = root / "assets" / "marty" / "marty_anim.png"
    target_path = root / "assets" / "marty" / "marty_anim_v2.png"
    source = Image.open(source_path).convert("RGBA")
    expected = (CELL * COLUMNS, CELL * ROWS_PER_OUTFIT * len(OUTFITS))
    if source.size != expected:
        raise ValueError(f"Atlas inesperado: {source.size}; esperado {expected}.")

    output = Image.new("RGBA", source.size)
    for outfit_index, outfit in enumerate(OUTFITS):
        for view in range(ROWS_PER_OUTFIT):
            row = outfit_index * ROWS_PER_OUTFIT + view
            for column in range(COLUMNS):
                rect = (column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL)
                output.alpha_composite(place_cell(source.crop(rect), SCALE[outfit]), (rect[0], rect[1]))
    output.save(target_path)
    print(f"ATLAS_NORMALIZED {target_path.relative_to(root)} {output.size[0]}x{output.size[1]}")


if __name__ == "__main__":
    main()
