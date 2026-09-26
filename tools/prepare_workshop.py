"""0.16: recorta art/source/workshop_sheet.png (fundo magenta) para a Sala 05 • Oficina.
Saída: assets/environment/docks12/workshop/ + prévia art/workshop-preview.png.
Uso: python3 tools/prepare_workshop.py  (numpy, pillow, scipy)"""
from sheet_cut import run

PIECES = [  # ordem de leitura da folha (linhas de cima para baixo, esquerda -> direita)
    ("workshop_floor_riveted", (64, 64), "floor"), ("workshop_floor_oil", (64, 64), "floor"),
    ("workshop_floor_grate", (64, 64), "floor"), ("workshop_floor_worn", (64, 64), "floor"),
    ("workshop_bench", (96, 64), "contain"), ("workshop_tool_rack", (64, 96), "contain"),
    ("workshop_hoist", (48, 96), "contain"), ("workshop_oil_puddle", (64, 32), "contain"),
    ("workshop_welder", (64, 64), "contain"), ("workshop_parts", (64, 64), "contain")]

if __name__ == "__main__":
    run("workshop_sheet.png", "assets/environment/docks12/workshop", PIECES, "workshop-preview.png")
