"""0.15: transforma as linhas 3 e 4 do atlas do Titan em vistas de COSTAS.

O atlas v3 gerado por IA veio com as linhas 3 (costas-3/4) e 4 (costas) mostrando
o rosto: viseira acesa e núcleo ciano no peito. No jogo, olhar/andar para cima
com o Titan parecia "não mudar o sprite". Este passo apaga a viseira e o núcleo
(inpaint na cor da blindagem), deixando só os tanques laranja, que passam a ler
como mochila. Os jatos do boost (parte de baixo) são preservados.

Uso: python tools/titan_back_view.py   (roda também no fim de clean_titan_atlas.py)
É idempotente: rodar de novo não altera um atlas já corrigido.
"""

from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ATLAS = ROOT / "assets" / "mech" / "titan_v3_clean.png"
CELL = 176
COLS = 10
BACK_ROWS = (3, 4)


def _components(mask: np.ndarray):
    n, _, stats, centers = cv2.connectedComponentsWithStats(mask.astype(np.uint8), 8)
    return [(stats[i], centers[i]) for i in range(1, n)]


def back_view(cell: np.ndarray) -> np.ndarray:
    rgb = cell[:, :, :3].astype(int)
    alpha = cell[:, :, 3]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    lum = rgb.sum(-1) / 3
    solid = cv2.erode((alpha > 200).astype(np.uint8), np.ones((5, 5), np.uint8))
    cyan = (b > 130) & (g > 120) & (b - r > 35) & (alpha > 0)
    cyan[112:] = False  # jatos do boost ficam embaixo: não mexer
    mask = np.zeros(alpha.shape, np.uint8)
    for (x, y, w, h, area), (cx, cy) in _components(cyan):
        if area < 4:
            mask[y:y + h, x:x + w] |= cyan[y:y + h, x:x + w].astype(np.uint8)
        elif 70 <= cy < 104 and 40 < cx < 140 and area > 40:  # núcleo do peito
            cv2.circle(mask, (int(cx), int(cy)), int(max(w, h) * 0.5) + 5, 1, -1)
    head = cyan.copy()
    head[70:] = False
    ys, xs = np.nonzero(head)
    if len(ys):  # viseira: olhos + faixa escura em volta
        box = np.zeros_like(mask)
        box[max(0, ys.min() - 7):ys.max() + 8, max(0, xs.min() - 12):xs.max() + 13] = 1
        mask |= ((box == 1) & ((lum < 95) | head)).astype(np.uint8)
    mask = cv2.dilate(mask, np.ones((3, 3), np.uint8), 1) & solid
    if not mask.any():
        return cell
    base = cell[:, :, :3].copy()
    armor = np.median(cell[(alpha > 200) & (lum > 60) & (lum < 150)][:, :3], axis=0).astype(np.uint8)
    base[alpha < 200] = armor  # evita que o inpaint puxe preto do fundo transparente
    bgr = cv2.cvtColor(base, cv2.COLOR_RGB2BGR)
    filled = cv2.cvtColor(cv2.inpaint(bgr, mask * 255, 7, cv2.INPAINT_TELEA), cv2.COLOR_BGR2RGB).astype(float)
    filled += np.random.default_rng(1).normal(0, 4, filled.shape)  # textura leve
    filled = np.clip(filled, 0, 255).astype(np.uint8)
    out = cell.copy()
    out[:, :, :3] = np.where(mask[..., None] > 0, filled, cell[:, :, :3])
    return out


def main() -> None:
    atlas = np.array(Image.open(ATLAS).convert("RGBA"))
    for row in BACK_ROWS:
        for col in range(COLS):
            y, x = row * CELL, col * CELL
            atlas[y:y + CELL, x:x + CELL] = back_view(atlas[y:y + CELL, x:x + CELL])
    Image.fromarray(atlas).save(ATLAS, optimize=True)
    print(f"Vistas de costas do Titan aplicadas em {ATLAS}")


if __name__ == "__main__":
    main()
