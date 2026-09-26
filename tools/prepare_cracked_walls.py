"""0.16: recorta art/source/cracked_walls_sheet.png — fachadas rachadas (atalhos destrutíveis).
Linha de cima: rachadas A (diagonal), B (canto com vergalhão), C (queimada); de baixo: as versões _open.
Mesma escala para as 6 (tijolos iguais). Saída: assets/environment/docks12/tiles/ + art/cracked-walls-preview.png.
Uso: python3 tools/prepare_cracked_walls.py  (numpy, pillow, scipy)"""
from sheet_cut import run

PIECES = [("wall_crack_a", (128, 216), "contain"), ("wall_crack_b", (128, 216), "contain"), ("wall_crack_c", (128, 216), "contain"),
          ("wall_crack_a_open", (128, 216), "contain"), ("wall_crack_b_open", (128, 216), "contain"), ("wall_crack_c_open", (128, 216), "contain")]

if __name__ == "__main__":
    run("cracked_walls_sheet.png", "assets/environment/docks12/tiles", PIECES, "cracked-walls-preview.png", uniform=True)
