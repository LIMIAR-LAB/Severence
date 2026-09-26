"""0.16: recorta art/source/map_icons_sheet.png — ícones do minimapa/mapa (48x48, legíveis em 24x24).
Saída: assets/ui/map_icons/ + art/map-icons-preview.png (inclui a versão 24x24 para conferir).
Uso: python3 tools/prepare_map_icons.py  (numpy, pillow, scipy)"""
from PIL import Image
from sheet_cut import run, preview, ROOT

PIECES = [("map_icon_boss", (48, 48), "contain"), ("map_icon_shop", (48, 48), "contain"), ("map_icon_challenge", (48, 48), "contain"),
          ("map_icon_chest", (48, 48), "contain"), ("map_icon_locked", (48, 48), "contain"), ("map_icon_exit", (48, 48), "contain")]

if __name__ == "__main__":
    done = run("map_icons_sheet.png", "assets/ui/map_icons", PIECES, "map-icons-preview.png", uniform=True)
    small = {n + " @24": im.resize((24, 24), Image.NEAREST) for n, im in done.items()}
    preview({**done, **small}, ROOT / "art/map-icons-preview.png", zoom=3, cols=6)
