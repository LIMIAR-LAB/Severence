"""Prepara a arte do Refúgio a partir de art/source/refuge-reference.png.

Saídas (assets/environment/refuge/):
  refuge_bg.png   — cenário limpo: Marty e Titan pintados removidos (o jogo desenha os reais).
  core_front.png  — recorte com alfa do Núcleo Temporal, desenhado na ordenação por Y
                    para que Marty passe atrás da gaiola giroscópica.

Requer: pip install opencv-python numpy
Uso: python tools/prepare_refuge.py
"""
from pathlib import Path
import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/source/refuge-reference.png"
OUT = ROOT / "assets/environment/refuge"
OUT.mkdir(parents=True, exist_ok=True)

im = cv2.imread(str(SRC)).astype(np.float32)
assert im.shape[:2] == (752, 1344), im.shape
out = im.copy()


def feather(h, w, pad=5, blur=9):
    m = np.zeros((h, w), np.float32)
    m[pad:-pad, pad:-pad] = 1
    return cv2.GaussianBlur(m, (blur, blur), 3)[..., None]


def clone(x0, y0, x1, y1, dx, dy=0):
    src = out[y0 + dy:y1 + dy, x0 + dx:x1 + dx].copy()
    m = feather(y1 - y0, x1 - x0)
    out[y0:y1, x0:x1] = src * m + out[y0:y1, x0:x1] * (1 - m)


# 1) Marty pintado ao lado do núcleo: clona o piso (e o cabo) logo à direita.
clone(708, 362, 760, 460, 46)
clone(748, 380, 772, 416, 22)  # fecha a emenda do cabo

# 2) Titan pintado no hangar: inpaint. O Titan jogável estaciona exatamente aqui.
mask = np.zeros(im.shape[:2], np.uint8)
cv2.fillPoly(mask, [np.array([(1105, 345), (1180, 340), (1215, 380), (1238, 420), (1238, 470), (1225, 480),
                              (1200, 470), (1200, 530), (1150, 540), (1140, 500), (1115, 510), (1085, 515),
                              (1072, 470), (1062, 450), (1035, 450), (1032, 400), (1085, 375)])], 255)
cv2.fillPoly(mask, [np.array([(1062, 495), (1122, 492), (1125, 528), (1062, 528)]),
                    np.array([(1150, 525), (1210, 522), (1212, 553), (1150, 553)])], 255)  # pés
mask = cv2.dilate(mask, np.ones((5, 5), np.uint8))
out8 = cv2.inpaint(out.astype(np.uint8), mask, 6, cv2.INPAINT_TELEA).astype(np.float32)
# Textura procedural de parede de chapas + piso de ladrilhos no lugar do borrão do inpaint.
rng = np.random.default_rng(1941)
H, W = im.shape[:2]
yy, xx = np.mgrid[0:H, 0:W]
wall = np.zeros((H, W, 3), np.float32) + np.array([49, 38, 38], np.float32)   # BGR ~ #262631
seam = (xx % 34 < 2)
wall[seam] = (26, 20, 22)
wall[(xx % 34 == 2)] = (66, 54, 54)
wall[(yy % 58 < 2)] = (30, 24, 26)
floor = np.zeros((H, W, 3), np.float32) + np.array([64, 55, 54], np.float32)   # ~ #2e303a
u = (xx + 2 * yy) % 56; v = (xx - 2 * yy) % 56
floor[(u < 2) | (v < 2)] = (34, 27, 28)
tex = np.where((yy < 420)[..., None], wall, floor)
tex += rng.normal(0, 4, tex.shape).astype(np.float32)
tex = np.clip(tex, 0, 255)
soft = cv2.GaussianBlur(mask.astype(np.float32) / 255, (11, 11), 3)[..., None]
out8 = (tex * soft + out8 * (1 - soft)).astype(np.uint8)
cv2.imwrite(str(OUT / "refuge_bg.png"), out8)


def cutout(name, x0, y0, x1, y1, polygon):
    crop = out8[y0:y1, x0:x1]
    alpha = np.zeros((y1 - y0, x1 - x0), np.uint8)
    cv2.fillPoly(alpha, [np.array([(x - x0, y - y0) for x, y in polygon])], 255)
    rgba = np.dstack([crop, alpha])
    cv2.imwrite(str(OUT / name), rgba)
    print(name, "offset", (x0, y0), "size", (x1 - x0, y1 - y0))


# Núcleo: gaiola + pedestal (offset 548,232 no jogo)
cutout("core_front.png", 548, 232, 716, 444, [
    (598, 236), (690, 236), (712, 262), (712, 350), (716, 380), (708, 430), (640, 442),
    (560, 430), (548, 385), (556, 350), (574, 330), (574, 262)])
print("ok")
