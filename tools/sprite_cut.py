"""Utilitários de recorte para folhas com fundo cinza liso (Higgsfield)."""
import cv2
import numpy as np
from PIL import Image


def remove_gray_background(path, dilate=6, min_area=120):
    rgb = np.array(Image.open(path).convert("RGB")).astype(np.int16)
    mx, mn = rgb.max(2), rgb.min(2)
    # Fundo e sombras: cinza neutro de valor médio, conectado à borda/fundo.
    cand = ((mx - mn) < 14) & (mx > 78) & (mx < 160)
    n, lab, stats, _ = cv2.connectedComponentsWithStats(cand.astype(np.uint8), 4)
    bg = np.zeros_like(cand)
    for i in range(1, n):
        if stats[i, cv2.CC_STAT_AREA] > 4000:  # grandes regiões cinzas = fundo ou sombra ligada a ele
            bg |= lab == i
    # sombras isoladas (elipses sob os pés) também são cinza neutro mais escuro
    for i in range(1, n):
        x, y, w, h, a = stats[i]
        if a > 150 and w > 2.2 * h and mx[lab == i].mean() < 125:
            bg |= lab == i
    fg = ~bg
    fg = cv2.morphologyEx(fg.astype(np.uint8), cv2.MORPH_OPEN, np.ones((2, 2), np.uint8)).astype(bool)
    rgba = np.dstack([rgb.astype(np.uint8), (fg * 255).astype(np.uint8)])
    grown = cv2.dilate(fg.astype(np.uint8), np.ones((dilate, dilate), np.uint8))
    n, lab, stats, cent = cv2.connectedComponentsWithStats(grown, 8)
    boxes = []
    for i in range(1, n):
        x, y, w, h, a = stats[i]
        if a >= min_area:
            boxes.append((int(x), int(y), int(x + w), int(y + h)))
    return rgba, boxes


def rows_of(boxes, gap=30):
    boxes = sorted(boxes, key=lambda b: (b[1] + b[3]) / 2)
    rows = []
    for b in boxes:
        cy = (b[1] + b[3]) / 2
        if rows and abs(cy - rows[-1]["cy"]) < gap + (b[3] - b[1]) * 0.3:
            rows[-1]["b"].append(b); rows[-1]["cy"] = np.mean([(q[1] + q[3]) / 2 for q in rows[-1]["b"]])
        else:
            rows.append({"cy": cy, "b": [b]})
    return [sorted(r["b"], key=lambda q: q[0]) for r in rows]
