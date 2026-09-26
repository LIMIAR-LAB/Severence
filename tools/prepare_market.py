"""0.16: recorta art/source/market_sheet.png (fundo magenta) para a Sala 04 • Mercado de Peixe.
Saída: assets/environment/docks12/market/ + prévia art/market-preview.png.
Uso: python3 tools/prepare_market.py  (numpy, pillow, scipy)"""
from sheet_cut import run

PIECES = [
    ("market_floor_scales", (64, 64), "floor"), ("market_floor_puddle", (64, 64), "floor"), ("market_floor_seaweed", (64, 64), "floor"),
    ("market_stall", (128, 96), "contain"), ("market_net", (96, 64), "contain"), ("market_baskets", (64, 64), "contain"),
    ("market_ice_barrel", (64, 64), "contain"), ("market_rowboat", (96, 48), "contain"), ("market_lanterns", (96, 32), "contain")]

if __name__ == "__main__":
    run("market_sheet.png", "assets/environment/docks12/market", PIECES, "market-preview.png")
