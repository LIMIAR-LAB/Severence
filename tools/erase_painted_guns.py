"""Remove as pistolas pintadas nas mãos do Marty (o jogo desenha a arma real, que gira com a mira).

Atua só dentro de caixas manuais por pose e só em pixels cinza-metal ou de contorno escuro;
pele, luvas ciano, roupa e a chave inglesa do Mecânico ficam. A Ômega não tem arma de mão.
Roda sobre assets/marty/outfits.png (in-place) antes de tools/animate_sprites.py.
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
C = 96
BOXES = {  # (roupa, vista): (x0, y0, x1, y1) relativos à célula 96×96
    (0, 0): (65, 66, 78, 86), (0, 1): (64, 66, 78, 86), (0, 2): (58, 66, 73, 84), (0, 3): (55, 67, 69, 86), (0, 5): (70, 60, 91, 74),
    (1, 0): (21, 66, 36, 86), (1, 1): (27, 66, 40, 88), (1, 2): (59, 66, 72, 86), (1, 3): (57, 68, 73, 88), (1, 5): (70, 58, 91, 74),
    (2, 0): (59, 65, 74, 86), (2, 1): (60, 66, 75, 86), (2, 2): (56, 54, 70, 68), (2, 3): (58, 66, 71, 88), (2, 5): (66, 56, 86, 70),
}
path = ROOT / "assets/marty/outfits.png"
a = np.array(Image.open(path).convert("RGBA"))
removed = 0
for (o, v), (x0, y0, x1, y1) in BOXES.items():
    cell = a[o * C + y0:o * C + y1, v * C + x0:v * C + x1]
    rgb = cell[..., :3].astype(int); mx, mn = rgb.max(2), rgb.min(2)
    metal = ((mx - mn) < 34) & (mx > 55)
    outline = mx < 62
    kill = (cell[..., 3] > 0) & (metal | outline)
    removed += int(kill.sum())
    cell[kill] = 0
Image.fromarray(a).save(path)
print("pixels de arma pintada removidos:", removed)
