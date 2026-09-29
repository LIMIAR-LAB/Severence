"""Desembarque artístico (0.18) — peças grandes de pixel art para a Sala 01.

Mantém a intenção da referência pintada (cargueiro avariado, abrigo militar, luz
âmbar, cais irregular) mas em pixel art coerente com o resto do jogo (contorno
escuro, luz de cima-esquerda, filtro NEAREST) em vez de uma pintura única —
evita a costura visual com a sala vizinha (tiles) e reaproveita o pipeline de
tools/make_scenery_017.py.

Saída: assets/environment/docks12/entry/{shipwreck,bunker}.png
Uso:   python tools/make_entry_018.py   (prévia em art/entry-018-preview.png)
"""
from pathlib import Path
import math, random
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/environment/docks12/entry"
R = random.Random(1938)
TAU = math.tau

class C:
    def __init__(s, w, h): s.w, s.h = w, h; s.a = np.zeros((h, w, 4), np.uint8)
    def px(s, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h: s.a[y, x] = c if len(c) == 4 else (*c, 255)
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1): s.px(x, y, c)
    def vramp(s, x0, y0, x1, y1, cols):
        for y in range(int(y0), int(y1) + 1):
            t = 0 if y1 == y0 else (y - y0) / (y1 - y0)
            s.rect(x0, y, x1, y, cols[min(len(cols) - 1, int(t * len(cols)))])
    def hramp(s, x0, y0, x1, y1, cols):
        for x in range(int(x0), int(x1) + 1):
            t = 0 if x1 == x0 else (x - x0) / (x1 - x0)
            s.rect(x, y0, x, y1, cols[min(len(cols) - 1, int(t * len(cols)))])
    def ellipse(s, cx, cy, rx, ry, c, fill=True):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                d = ((x - cx) / max(rx, .1)) ** 2 + ((y - cy) / max(ry, .1)) ** 2
                if (d <= 1 and fill) or (not fill and 0.72 <= d <= 1): s.px(x, y, c)
    def line(s, x0, y0, x1, y1, c, w=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            x, y = x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n
            for ww in range(w): s.px(x, y + ww - w // 2, c)
    def poly(s, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % len(pts)]
                if (ya <= y < yb) or (yb <= y < ya): xs.append(xa + (y - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2): s.rect(round(xs[i]), y, round(xs[i + 1]), y, c)
    def noise(s, amp, dens=1.0):
        for y in range(s.h):
            for x in range(s.w):
                if s.a[y, x, 3] and R.random() < dens:
                    px = s.a[y, x].astype(int)
                    s.a[y, x, :3] = np.clip(px[:3] + R.randint(-amp, amp), 0, 255)
    def rivet(s, x, y, light=(214, 206, 186), dark=(60, 54, 58)):
        s.px(x, y, light); s.px(x + 1, y, (150, 142, 128)); s.px(x, y + 1, (150, 142, 128)); s.px(x + 1, y + 1, dark)
    def outline(s):
        op = s.a[..., 3] > 200
        g = op.copy(); g[1:] |= op[:-1]; g[:-1] |= op[1:]; g[:, 1:] |= op[:, :-1]; g[:, :-1] |= op[:, 1:]
        s.a[g & ~(s.a[..., 3] > 0)] = (18, 14, 22, 255)
    def save(s, path, outline=True):
        if outline: s.outline()
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(s.a).save(path); print("wrote", path.relative_to(ROOT), (s.w, s.h))

HULL = [(64, 58, 56), (48, 44, 44), (36, 32, 34), (24, 22, 24)]
HULL_RUST = (94, 60, 40)
DECK = [(112, 100, 86), (92, 82, 70), (72, 64, 56)]
IRON = [(150, 148, 156), (110, 108, 118), (78, 78, 90)]
SAND = [(150, 122, 78), (124, 100, 62), (98, 78, 48)]
WOOD = [(140, 92, 54), (112, 72, 42), (86, 54, 32)]

def shipwreck():
    """Cargueiro avariado, visto de cima, atracado verticalmente ao longo do cais."""
    w, h = 280, 720
    s = C(w, h)
    cx = w * 0.52
    # casco: silhueta afunilada nas pontas (proa ao norte, popa ao sul), com uma leve inclinação
    for y in range(40, h - 30):
        t = (y - 40) / (h - 70)
        taper = math.sin(min(1.0, t) * math.pi) ** 0.35   # afina bem só perto das pontas
        half = (58 + 30 * taper)
        lean = math.sin(t * 3.1) * 4  # avaria: casco não é uma linha reta
        x0, x1 = cx - half + lean, cx + half + lean
        s.hramp(x0, y, x1, y, HULL)
        s.px(x0, y, (14, 12, 14)); s.px(x1, y, (10, 9, 10))
    # boca de proa/popa arredondada
    s.ellipse(cx, 42, 60, 22, HULL[1])
    s.ellipse(cx, h - 32, 56, 22, HULL[2])
    # avaria: rombo aberto no meio do casco com ferrugem escorrendo
    bx, by = cx + 34, h * 0.42
    s.ellipse(bx, by, 22, 34, (10, 8, 9))
    s.ellipse(bx - 2, by - 4, 16, 26, (28, 18, 14))
    for i in range(10):
        yy = by + R.uniform(-30, 34)
        s.line(bx + R.uniform(-14, 18), yy, bx + R.uniform(-10, 22), yy + R.uniform(14, 40), HULL_RUST)
    # convés central mais claro, com escotilhas
    s.vramp(cx - 34, 120, cx + 34, h - 110, DECK)
    for hy in range(190, h - 170, 92):
        s.rect(cx - 22, hy, cx + 22, hy + 46, DECK[2])
        s.rect(cx - 20, hy + 2, cx + 20, hy + 44, DECK[1])
        for rx in range(int(cx - 18), int(cx + 18), 8): s.rivet(rx, hy + 4)
    # chaminé tombada + fumaça parada (avaria)
    fx, fy = cx - 6, h * 0.34
    s.rect(fx - 14, fy - 70, fx + 20, fy, (70, 46, 40))
    s.rect(fx - 14, fy - 72, fx + 20, fy - 66, (150, 60, 40))
    s.line(fx + 4, fy - 70, fx + 46, fy - 118, (52, 50, 56), 10)
    for i in range(3):
        s.ellipse(fx + 40 + i * 14, fy - 130 - i * 10, 16 + i * 4, 12 + i * 3, (60, 58, 64, 90))
    # ponte de comando na popa, com janelas âmbar (as únicas luzes vivas do navio)
    by2 = h - 96
    s.rect(cx - 30, by2, cx + 30, by2 + 58, IRON[1])
    s.rect(cx - 30, by2, cx + 30, by2 + 10, IRON[0])
    for wx in range(-20, 24, 16):
        s.rect(cx + wx, by2 + 18, cx + wx + 10, by2 + 30, (255, 200, 110))
        s.rect(cx + wx + 1, by2 + 19, cx + wx + 9, by2 + 29, (255, 235, 180))
    # mastro/guincho na proa
    s.line(cx, 70, cx, 30, IRON[1], 4)
    s.line(cx - 26, 46, cx + 26, 46, IRON[1], 3)
    # amarras: cabos saindo do costado direito em direção ao cais (à direita da imagem)
    for ay in (170, 340, 520):
        s.line(cx + 60, ay, w - 6, ay + 26, (40, 34, 28), 3)
        s.line(cx + 60, ay, w - 6, ay + 26, (78, 66, 50), 1)
    # avaria/ferrugem espalhada e musgo salgado na linha da água
    s.noise(10, 0.4)
    for i in range(60):
        yy = R.uniform(40, h - 30)
        t = (yy - 40) / (h - 70)
        half = 58 + 30 * math.sin(min(1.0, t) * math.pi) ** 0.35
        xx = cx + R.uniform(-half, half)
        if s.a[int(yy), int(min(w - 1, max(0, xx))), 3]:
            s.px(xx, yy, R.choice([HULL_RUST, (52, 66, 46)]))
    s.save(OUT / "shipwreck.png")

def bunker():
    """Abrigo militar de sacos de areia e madeira, embutido na fachada do Desembarque."""
    w, h = 150, 130
    s = C(w, h)
    # parapeito de sacos de areia em fileiras (visto de cima-frente, como o resto dos props)
    rows = [(14, 96, 6), (10, 74, 5), (18, 52, 5)]
    for x0, y0, n in rows:
        for i in range(n):
            cx = x0 + i * 24
            s.ellipse(cx, y0, 13, 9, SAND[i % 3])
            s.ellipse(cx - 3, y0 - 3, 6, 4, SAND[0])
            s.line(cx - 10, y0, cx + 10, y0, (60, 48, 30))
    # postes de madeira de reforço nas laterais
    for x in (8, w - 16):
        s.rect(x, 20, x + 8, 118, WOOD[1]); s.rect(x, 20, x + 3, 118, WOOD[0])
    # placa de aviso militar pendurada
    s.rect(w * 0.5 - 16, 4, w * 0.5 + 16, 26, (40, 40, 30))
    s.rect(w * 0.5 - 14, 6, w * 0.5 + 14, 24, (60, 62, 44))
    for i in range(3): s.line(w * 0.5 - 10, 10 + i * 5, w * 0.5 + 10, 10 + i * 5, (30, 30, 22))
    # lanterna de vigia no topo (ponto de luz âmbar)
    s.rect(w * 0.5 - 3, 0, w * 0.5 + 3, 8, (30, 26, 22))
    s.ellipse(w * 0.5, 2, 5, 5, (255, 205, 120))
    s.noise(8, 0.3)
    s.save(OUT / "bunker.png")

def preview():
    thumbs = [("shipwreck", OUT / "shipwreck.png"), ("bunker", OUT / "bunker.png")]
    sheet = Image.new("RGBA", (620, 760), (20, 18, 26, 255))
    x = 10
    for name, f in thumbs:
        img = Image.open(f).convert("RGBA")
        sheet.paste(img, (x, 10), img)
        x += img.width + 20
    p = ROOT / "art/entry-018-preview.png"; sheet.save(p); print("preview", p)

if __name__ == "__main__":
    shipwreck()
    bunker()
    preview()
    print("OK — entry 0.18")
