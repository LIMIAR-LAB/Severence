"""0.16: recorta art/source/tentacle_gate_sheet.png — poça de tentáculo ativa (dano) e selada (grade).
Saída: assets/environment/docks12/props/ + art/tentacle-gate-preview.png.
Uso: python3 tools/prepare_tentacle_gate.py  (numpy, pillow, scipy)"""
from sheet_cut import run

PIECES = [("tentacle_gate_active", (140, 100), "contain"), ("tentacle_gate_sealed", (140, 100), "contain")]

if __name__ == "__main__":
    run("tentacle_gate_sheet.png", "assets/environment/docks12/props", PIECES, "tentacle-gate-preview.png", uniform=True)
