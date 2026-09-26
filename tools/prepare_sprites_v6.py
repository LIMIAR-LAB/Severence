"""Recorta as folhas do conceito v1 (Higgsfield, fundo cinza) em atlas de jogo.

Entradas (art/source/):
  marty-outfits-v1.png    4 roupas × (frente, frente-3/4, lado, costas-3/4, costas, correndo)
  enemies-docas-v1.png    4 inimigos × (frente, costas, andando, atacando, morte, projétil)
  boss-almirante-v1.png   Almirante: parado, anel, espiral, carga, dano, fúria, derrota + projéteis

Saídas:
  assets/marty/outfits.png           4 linhas × 6 colunas, células 96×96, pés em (48, 92)
  assets/enemies/docas.png           4 linhas × 5 colunas, células 144×96, pés em (56, 92)
  assets/enemies/proj_*.png          projéteis dos inimigos (apontando para a direita)
  assets/boss/almirante_*.png        poses do chefe (pés no centro da borda inferior)
  assets/boss/proj_*.png             projéteis do chefe (apontando para a direita)

Uso: python tools/prepare_sprites_v6.py   (requer opencv-python, numpy, pillow)
"""
from pathlib import Path
import sys
import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from sprite_cut import remove_gray_background  # noqa: E402

SRC = ROOT / "art/source"


def shrink(rgba, scale):
    """Reduz com média pré-multiplicada e devolve alfa binário (bordas nítidas de pixel art)."""
    img = rgba.astype(np.float32) / 255.0
    a = img[..., 3:4]
    pre = np.concatenate([img[..., :3] * a, a], axis=2)
    h, w = rgba.shape[:2]
    size = (max(1, round(w * scale)), max(1, round(h * scale)))
    small = cv2.resize(pre, size, interpolation=cv2.INTER_AREA)
    alpha = small[..., 3:4]
    rgb = np.where(alpha > 1e-4, small[..., :3] / np.maximum(alpha, 1e-4), 0)
    out_a = (alpha > 0.42).astype(np.float32)
    out = np.concatenate([np.clip(rgb, 0, 1), out_a], axis=2)
    return (out * 255).astype(np.uint8)


def trim(rgba):
    ys, xs = np.nonzero(rgba[..., 3] > 0)
    if len(xs) == 0: return rgba, 0
    return rgba[ys.min():ys.max() + 1, xs.min():xs.max() + 1], xs.min()


def body_anchor_x(rgba):
    """x dos pés: média das colunas opacas no quarto inferior (ignora clarões e projéteis)."""
    a = rgba[..., 3] > 0
    ys = np.nonzero(a.any(1))[0]
    lower = a[int(ys.min() + (ys.max() - ys.min()) * 0.72):]
    xs = np.nonzero(lower)[1]
    return int(np.median(xs)) if len(xs) else rgba.shape[1] // 2


def paste_cell(atlas, sprite, col, row, cw, ch, ax, ay, anchor=None):
    sprite, _ = trim(sprite)
    sx = body_anchor_x(sprite) if anchor is None else anchor
    x = col * cw + ax - sx
    y = row * ch + ay - sprite.shape[0]
    # recorta o que exceder a célula
    x0, y0 = max(x, col * cw), max(y, row * ch)
    x1, y1 = min(x + sprite.shape[1], (col + 1) * cw), min(y + sprite.shape[0], (row + 1) * ch)
    if x1 <= x0 or y1 <= y0: return
    region = sprite[y0 - y:y1 - y, x0 - x:x1 - x]
    dst = atlas[y0:y1, x0:x1]
    m = region[..., 3:4] > 0
    atlas[y0:y1, x0:x1] = np.where(m, region, dst)


def save(arr, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr).save(path)
    print("wrote", path.relative_to(ROOT), arr.shape[1], "x", arr.shape[0])


# ───────────── Marty: 4 roupas ─────────────
rgba, boxes = remove_gray_background(SRC / "marty-outfits-v1.png")
rows = {0: [], 1: [], 2: [], 3: []}
for b in boxes:
    cy = (b[1] + b[3]) / 2
    rows[min(3, int(cy // 188))].append(b)
POSES = [0, 1, 2, 3, 4, 5]          # frente, frente-3/4, lado, costas-3/4, costas, correndo
OMEGA = [0, 1, 2, 3, 4, 6]          # Ômega tem uma 2ª vista de costas (capa); usa o dash como corrida
atlas = np.zeros((4 * 96, 6 * 96, 4), np.uint8)
for r in range(4):
    row = sorted(rows[r], key=lambda q: q[0])
    picks = OMEGA if r == 3 else POSES
    assert len(row) >= max(picks) + 1, (r, len(row))
    for c, idx in enumerate(picks):
        x0, y0, x1, y1 = row[idx]
        paste_cell(atlas, shrink(rgba[y0:y1, x0:x1], 0.45), c, r, 96, 96, 48, 92)
save(atlas, ROOT / "assets/marty/outfits.png")

# ───────────── Inimigos das Docas ─────────────
rgba, _ = remove_gray_background(SRC / "enemies-docas-v1.png")
COLS = [(0, 220), (220, 420), (420, 630), (630, 920), (920, 1160), (1160, 1344)]
ROWS = [(0, 200), (200, 390), (390, 552), (552, 752)]
atlas = np.zeros((4 * 96, 5 * 144, 4), np.uint8)
for r, (y0, y1) in enumerate(ROWS):
    for c in range(5):
        x0, x1 = COLS[c]
        cell = rgba[y0:y1, x0:x1]
        paste_cell(atlas, shrink(cell, 0.42), c, r, 144, 96, 56, 92)
save(atlas, ROOT / "assets/enemies/docas.png")
for name, (x0, y0, x1, y1), scale in [("magenta", (1205, 70, 1300, 155), 0.32), ("harpoon", (1165, 255, 1330, 345), 0.34),
                                      ("acid", (1190, 425, 1325, 530), 0.3), ("violet", (1262, 583, 1296, 616), 0.6)]:
    save(trim(shrink(rgba[y0:y1, x0:x1], scale))[0], ROOT / f"assets/enemies/proj_{name}.png")

# ───────────── O Almirante das Profundezas ─────────────
rgba, _ = remove_gray_background(SRC / "boss-almirante-v1.png")
for name, rect, scale in [("idle", (0, 0, 540, 652), 0.40), ("ring", (535, 0, 925, 338), 0.72),
                          ("spiral", (925, 0, 1344, 340), 0.66), ("charge", (522, 336, 728, 620), 0.88),
                          ("hurt", (728, 336, 915, 620), 0.88), ("fury", (912, 338, 1140, 628), 0.86),
                          ("defeat", (1136, 336, 1344, 628), 0.86)]:
    x0, y0, x1, y1 = rect
    save(trim(shrink(rgba[y0:y1, x0:x1], scale))[0], ROOT / f"assets/boss/almirante_{name}.png")
# Projéteis: todos salvos apontando para a direita (o jogo gira pela velocidade).
for name, rect, scale, flip in [("orb", (95, 664, 158, 727), 0.34, False), ("flame", (378, 654, 560, 738), 0.3, True),
                                ("cannon", (596, 660, 802, 732), 0.36, True), ("ink", (826, 656, 1036, 740), 0.24, True),
                                ("harpoon", (1062, 664, 1270, 730), 0.3, False)]:
    x0, y0, x1, y1 = rect
    sprite = trim(shrink(rgba[y0:y1, x0:x1], scale))[0]
    if flip: sprite = sprite[:, ::-1].copy()
    save(sprite, ROOT / f"assets/boss/proj_{name}.png")
