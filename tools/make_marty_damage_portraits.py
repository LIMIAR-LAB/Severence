"""DOOM-style damage tiers for the HUD portrait.

Paints bruises, cuts, a swollen-shut black eye and a nosebleed onto copies of
the authored Marty portrait cell — the source art is never modified. Also adds
a cracked-visor variant for the armored Omega portrait. Output is a 6-cell
sheet read by combat_hud.gd:

  cells 0-3: marty healthy -> worst (<= half a heart)
  cell 4:    omega healthy
  cell 5:    omega, cracked visor (heavy damage)
"""
from pathlib import Path
import random

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / 'assets/ui/hud/marty_omega_portraits_v1.png'
OUT = ROOT / 'assets/ui/hud/marty_omega_portraits_v2.png'
CELL = 991

BRUISE = np.array([96, 56, 104], dtype=float)      # roxo do hematoma
BRUISE_DARK = np.array([54, 30, 66], dtype=float)
BLOOD = np.array([158, 26, 26], dtype=float)
BLOOD_DARK = np.array([96, 14, 14], dtype=float)
SKIN = np.array([244, 176, 128], dtype=float)      # amostrada na bochecha


def jitter_blob(arr, cx, cy, rx, ry, color, strength, seed, feather=0.45):
    """Blend pixels inside a noisy ellipse toward `color` (alpha = falloff*strength)."""

    noise = np.zeros((arr.shape[0], arr.shape[1]), dtype=float)
    x0, x1 = max(0, int(cx - rx * 1.6)), min(arr.shape[1], int(cx + rx * 1.6))
    y0, y1 = max(0, int(cy - ry * 1.6)), min(arr.shape[0], int(cy + ry * 1.6))
    for y in range(y0, y1):
        for x in range(x0, x1):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            if d <= 1.0:
                noise[y, x] = max(noise[y, x], 1.0 - d)
    # borda irregular: multiplica por ruído determinístico por célula de 8px
    for y in range(y0, y1):
        for x in range(x0, x1):
            if noise[y, x] <= 0:
                continue
            n = random.Random((x // 8) * 7349 + (y // 8) * 1511 + seed).random()
            f = noise[y, x] * (0.55 + 0.45 * n)
            if f > feather * 0.4:
                a = min(1.0, f * strength)
                px = arr[y, x].astype(float)
                if px[3] > 0:
                    arr[y, x] = np.concatenate([px[:3] * (1 - a) + color * a, px[3:4]])


def paint_polyline(arr, pts, width, color, seed):
    """Linha dentada grossa — cortes, sangue escorrido, trincas."""
    rng = random.Random(seed)
    h, w = arr.shape[:2]
    for i in range(len(pts) - 1):
        (x0, y0), (x1, y1) = pts[i], pts[i + 1]
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for s in range(steps + 1):
            t = s / steps
            x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
            wobble = (rng.random() - 0.5) * 3
            r = width * (0.7 + 0.6 * rng.random())
            for dy in range(-int(r), int(r) + 1):
                for dx in range(-int(r), int(r) + 1):
                    px, py = int(x + dx + wobble), int(y + dy)
                    if 0 <= px < w and 0 <= py < h and dx * dx + dy * dy <= r * r:
                        if arr[py, px, 3] > 0:
                            arr[py, px, :3] = color


def fill_ellipse(arr, cx, cy, rx, ry, color):
    h, w = arr.shape[:2]
    for y in range(max(0, int(cy - ry)), min(h, int(cy + ry))):
        for x in range(max(0, int(cx - rx)), min(w, int(cx + rx))):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and arr[y, x, 3] > 0:
                arr[y, x, :3] = color


def bruise_eye(arr, closed=False):
    # Halo roxo ao redor do olho esquerdo (cx~515, cy~430 na célula)
    jitter_blob(arr, 515, 425, 130, 95, BRUISE, 1.0, seed=11)
    jitter_blob(arr, 500, 415, 85, 65, BRUISE_DARK, 1.0, seed=12)
    if closed:
        # Olho inchado fechado: pele + sombra + linha escura da pálpebra
        fill_ellipse(arr, 515, 428, 66, 50, SKIN * np.array([0.92, 0.82, 0.86]))
        jitter_blob(arr, 515, 420, 90, 70, BRUISE_DARK, 0.9, seed=13)
        paint_polyline(arr, [(468, 445), (500, 453), (550, 450)], 7, np.array([52, 24, 40]), 14)
        paint_polyline(arr, [(486, 470), (528, 478)], 5, np.array([70, 30, 52]), 15)


def nosebleed(arr, heavy):
    base = [(648, 496), (652, 524), (644, 552), (652, 585)]
    paint_polyline(arr, base, 9, BLOOD_DARK, 21)
    paint_polyline(arr, base, 5, BLOOD, 22)
    if heavy:
        drip = [(668, 500), (674, 540), (664, 590), (672, 640)]
        paint_polyline(arr, drip, 8, BLOOD_DARK, 23)
        paint_polyline(arr, drip, 4, BLOOD, 24)
        jitter_blob(arr, 658, 505, 34, 18, BLOOD_DARK, 0.85, seed=25)


def bloodshot(arr):
    # Cantos vermelhos nos olhos — olho esquerdo e direito
    for cx, cy, rx in [(480, 428, 16), (700, 438, 14)]:
        jitter_blob(arr, cx, cy, rx, 34, np.array([200, 60, 52]), 0.75, seed=int(cx))


def forehead_cut(arr):
    # Corte na testa escorrendo entre os olhos — o golpe "final" do tier crítico
    cut = [(575, 330), (585, 355), (578, 382)]
    paint_polyline(arr, cut, 5, BLOOD_DARK, 55)
    paint_polyline(arr, cut, 2.5, BLOOD, 56)
    drip = [(580, 385), (572, 415), (578, 440)]
    paint_polyline(arr, drip, 4, BLOOD_DARK, 57)
    paint_polyline(arr, drip, 2, BLOOD, 58)


def cheek_cut(arr):
    paint_polyline(arr, [(438, 470), (462, 478)], 3, BLOOD_DARK, 31)
    paint_polyline(arr, [(440, 471), (460, 477)], 1.6, BLOOD, 32)
    jitter_blob(arr, 450, 474, 20, 12, np.array([160, 70, 60]), 0.4, seed=33)


def omega_crack(arr):
    # Trinca grossa atravessando o visor ciano (~x440-700, y320-500) — larga o
    # bastante pra ler a 82px — + o lado esquerdo do visor apagando, como se o
    # brilho estivesse morrendo.
    dead = np.array([18, 40, 54], dtype=float)
    jitter_blob(arr, 500, 400, 88, 92, dead, 0.9, seed=40)
    jitter_blob(arr, 470, 380, 50, 55, np.array([8, 18, 28], dtype=float), 0.95, seed=46)
    crack = [(610, 315), (575, 355), (595, 385), (560, 425), (575, 470)]
    paint_polyline(arr, crack, 9, np.array([8, 20, 30]), 41)
    paint_polyline(arr, [(575, 355), (530, 375)], 6, np.array([8, 20, 30]), 42)
    paint_polyline(arr, [(595, 385), (645, 405)], 5, np.array([8, 20, 30]), 43)
    # Fresta de ciano sobrevivente ao longo da trinca — vidro trincado brilhando
    paint_polyline(arr, [(612, 318), (578, 356), (597, 386)], 2.5, np.array([140, 235, 250]), 45)


def main():
    sheet = Image.open(SRC).convert('RGBA')
    marty = sheet.crop((0, 0, CELL, 793))
    omega = sheet.crop((992, 0, 1983, 793))

    cells = [marty.copy()]
    for tier in (1, 2, 3):
        arr = np.array(marty)
        if tier >= 1:
            cheek_cut(arr)
            jitter_blob(arr, 520, 445, 105, 66, BRUISE, 0.55, seed=51)
        if tier >= 2:
            bloodshot(arr)
            nosebleed(arr, heavy=False)
            jitter_blob(arr, 515, 425, 115, 80, BRUISE, 0.7, seed=52)
        if tier >= 3:
            bruise_eye(arr, closed=True)
            nosebleed(arr, heavy=True)
            forehead_cut(arr)
            cheek_cut_extra = [(428, 500), (454, 510)]
            paint_polyline(arr, cheek_cut_extra, 5, BLOOD_DARK, 53)
        cells.append(Image.fromarray(arr))

    cells.append(omega.copy())
    cracked = np.array(omega)
    omega_crack(cracked)
    cells.append(Image.fromarray(cracked))

    out = Image.new('RGBA', (CELL * 6, 793), (0, 0, 0, 0))
    for i, cell in enumerate(cells):
        out.paste(cell, (i * CELL, 0))
    out.save(OUT)
    print('wrote', OUT, out.size)


if __name__ == '__main__':
    main()
