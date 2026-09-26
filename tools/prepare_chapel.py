"""0.16: recorta art/source/chapel_sheet.png (fundo magenta) para a Sala 10 • Capela do Culto.
Saída: assets/environment/docks12/chapel/ + prévia art/chapel-preview.png.
Uso: python3 tools/prepare_chapel.py  (numpy, pillow, scipy)"""
from sheet_cut import run

PIECES = [
    ("chapel_floor_eye", (64, 64), "floor"), ("chapel_floor_spiral", (64, 64), "floor"),
    ("chapel_stained_glass", (64, 96), "contain"), ("chapel_candles", (48, 64), "contain"),
    ("chapel_banner", (64, 128), "contain"), ("chapel_offering_bowl", (64, 64), "contain")]

if __name__ == "__main__":
    run("chapel_sheet.png", "assets/environment/docks12/chapel", PIECES, "chapel-preview.png", merge=14)
