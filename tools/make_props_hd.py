"""Props HD das Docas (0.15) — substitui os desenhos simples de assets/environment/docks/.

Pixel art feita à mão em código, no mesmo clima da folha docks12:
- contorno escuro de 1 px;
- luz vindo de cima e da esquerda;
- rampas de cor, rebites, desgaste, musgo e brilhos.

Mesmos nomes e tamanhos dos arquivos antigos, então o jogo usa sem mudar código.
Saída: assets/environment/docks/{pillar,generator,altar,pew,ammo,candles,puddle,crack,capsule,rug,stairs}.png
Uso:   python tools/make_props_hd.py   (prévia em art/props-hd-preview.png)
"""
from pathlib import Path
import math, random
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/environment/docks"
OUTLINE = (20, 16, 26, 255)
R = random.Random(1941)

class C:
    def __init__(s, w, h): s.w, s.h = w, h; s.a = np.zeros((h, w, 4), np.uint8)
    def px(s, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h: s.a[y, x] = c if len(c) == 4 else (*c, 255)
    def get(s, x, y): return tuple(s.a[int(y), int(x)]) if 0 <= x < s.w and 0 <= y < s.h else (0, 0, 0, 0)
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1): s.px(x, y, c)
    def vramp(s, x0, y0, x1, y1, ramp):
        for y in range(int(y0), int(y1) + 1):
            t = 0 if y1 == y0 else (y - y0) / (y1 - y0)
            s.rect(x0, y, x1, y, ramp[min(len(ramp) - 1, int(t * len(ramp)))])
    def hramp(s, x0, y0, x1, y1, ramp):
        for x in range(int(x0), int(x1) + 1):
            t = 0 if x1 == x0 else (x - x0) / (x1 - x0)
            s.rect(x, y0, x, y1, ramp[min(len(ramp) - 1, int(t * len(ramp)))])
    def cyl(s, x0, y0, x1, y1, ramp):
        """Cilindro vertical: claro à esquerda do centro, escuro nas bordas."""
        for x in range(int(x0), int(x1) + 1):
            t = (x - x0) / max(1, x1 - x0)
            k = 1 - abs(t - 0.35) / 0.65
            s.rect(x, y0, x, y1, ramp[min(len(ramp) - 1, max(0, int((1 - k) * len(ramp))))])
    def ellipse(s, cx, cy, rx, ry, c, fill=True):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                d = ((x - cx) / max(rx, .1)) ** 2 + ((y - cy) / max(ry, .1)) ** 2
                if (d <= 1 and fill) or (not fill and 0.78 <= d <= 1): s.px(x, y, c)
    def line(s, x0, y0, x1, y1, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1): s.px(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, c)
    def poly(s, pts, c):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)), int(max(ys)) + 1):
            xs = []
            for i in range(len(pts)):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % len(pts)]
                if (ya <= y < yb) or (yb <= y < ya): xs.append(xa + (y - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2): s.rect(round(xs[i]), y, round(xs[i + 1]), y, c)
    def speckle(s, x0, y0, x1, y1, colors, dens):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1):
                if s.get(x, y)[3] and R.random() < dens: s.px(x, y, R.choice(colors))
    def rivet(s, x, y, light=(214, 206, 186), dark=(60, 54, 58)):
        s.px(x, y, light); s.px(x + 1, y, (150, 142, 128)); s.px(x, y + 1, (150, 142, 128)); s.px(x + 1, y + 1, dark)
    def outline(s):
        op = s.a[..., 3] > 200
        g = op.copy(); g[1:] |= op[:-1]; g[:-1] |= op[1:]; g[:, 1:] |= op[:, :-1]; g[:, :-1] |= op[:, 1:]
        s.a[g & ~(s.a[..., 3] > 0)] = OUTLINE
    def save(s, name, outline=True):
        if outline: s.outline()
        Image.fromarray(s.a).save(OUT / name); print("wrote", name, (s.w, s.h))
        return Image.fromarray(s.a)

STONE = [(186, 180, 170), (156, 150, 142), (126, 120, 116), (98, 94, 94), (72, 70, 74)]
BRICK = [(176, 92, 70), (146, 72, 56), (116, 56, 46), (86, 42, 38)]
IRON = [(150, 156, 170), (110, 116, 130), (78, 82, 96), (52, 56, 68)]
WOOD = [(170, 112, 66), (140, 88, 50), (110, 66, 38), (80, 48, 30)]
GOLD = [(255, 224, 140), (226, 176, 74), (170, 120, 44)]
MOSS = [(92, 132, 64), (70, 108, 50), (54, 84, 40)]
CYAN = [(210, 255, 255), (110, 235, 245), (40, 170, 200)]
PURPLE = [(128, 82, 160), (98, 58, 128), (70, 40, 96), (48, 26, 66)]
GREEN_GLOW = [(200, 255, 190), (110, 240, 120), (50, 170, 70)]
OLIVE = [(132, 142, 84), (104, 114, 64), (80, 88, 48), (58, 64, 36)]
out = {}

# ── PILAR 96×140: coluna de granito com plinto, faixas de ferro, capitel e musgo
c = C(96, 140)
c.vramp(4, 120, 91, 136, STONE[1:])                          # plinto
c.rect(4, 120, 91, 121, STONE[0])
c.vramp(10, 112, 85, 120, STONE)                             # degrau
c.cyl(16, 22, 79, 112, STONE)                                # fuste
for y in range(28, 110, 12):                                 # juntas das pedras
    c.line(17, y, 78, y, STONE[4])
    off = 0 if (y // 12) % 2 else 16
    for x in range(20 + off, 78, 32): c.line(x, y + 1, x, y + 11, STONE[4])
for yb in (40, 88):                                          # faixas de ferro com rebites
    c.cyl(14, yb, 81, yb + 5, IRON)
    for x in range(18, 80, 10): c.rivet(x, yb + 2)
c.vramp(8, 8, 87, 22, STONE)                                 # capitel
c.vramp(12, 2, 83, 8, STONE[:3])
c.rect(8, 21, 87, 22, STONE[4])
for x in range(14, 84, 8): c.rect(x, 10, x + 3, 16, STONE[3])  # frisos
c.speckle(16, 22, 79, 112, [STONE[3], STONE[2]], 0.03)
c.line(60, 50, 66, 62, STONE[4]); c.line(66, 62, 63, 72, STONE[4])   # rachadura
for x in range(8, 88):                                       # musgo na base
    h = int(3 + 3 * math.sin(x * 0.7) + R.random() * 3)
    for y in range(120 - h, 121):
        if R.random() < 0.7: c.px(x, y, R.choice(MOSS))
c.speckle(4, 120, 91, 136, [MOSS[1], STONE[4]], 0.06)
out["pillar"] = c.save("pillar.png")

# ── GERADOR 120×120: dínamo industrial com bobinas de cobre, painel, canos e esfera Tesla
c = C(120, 120)
c.vramp(4, 100, 115, 116, IRON[1:])                          # base
for x in range(6, 114, 12): c.poly([(x, 104), (x + 6, 104), (x + 2, 112), (x - 4, 112)], (230, 180, 40))   # listras de perigo
c.rect(4, 100, 115, 101, IRON[0])
c.cyl(14, 44, 106, 100, [(112, 128, 110), (92, 108, 92), (72, 86, 74), (54, 64, 56), (40, 48, 42)])    # tambor
for x in range(20, 104, 7): c.line(x, 46, x, 98, (40, 48, 42))                                       # nervuras
for yc in (56, 78):                                          # bobinas de cobre
    c.cyl(10, yc, 110, yc + 8, [(250, 190, 120), (214, 140, 70), (170, 100, 50), (120, 70, 40)])
    for x in range(12, 110, 3): c.px(x, yc + 4, (120, 70, 40))
c.vramp(24, 30, 96, 44, IRON)                                # tampa
for x in range(28, 94, 11): c.rivet(x, 36)
c.rect(84, 60, 104, 76, (28, 30, 36)); c.rect(85, 61, 103, 75, (48, 52, 60))                       # painel
c.ellipse(90, 67, 4, 4, (230, 226, 210)); c.line(90, 67, 92, 64, (200, 40, 40))                     # manômetro
c.ellipse(99, 67, 3, 3, (230, 226, 210)); c.line(99, 67, 97, 65, (200, 40, 40))
c.px(88, 73, (90, 255, 120)); c.px(92, 73, (255, 190, 60)); c.px(96, 73, (255, 70, 60))
for (x0, x1) in ((6, 14), (106, 114)):                       # canos laterais
    c.cyl(x0, 36, x1, 100, IRON)
    c.rect(x0 - 1, 50, x1 + 1, 53, IRON[3]); c.rect(x0 - 1, 84, x1 + 1, 87, IRON[3])
c.ellipse(60, 18, 22, 16, (30, 60, 80, 170))                 # cúpula de vidro
c.ellipse(60, 18, 13, 11, CYAN[2]); c.ellipse(60, 17, 9, 8, CYAN[1]); c.ellipse(58, 15, 4, 3, CYAN[0])
for k in range(5):                                           # raios dentro da cúpula
    a = k * 1.25; c.line(60, 18, 60 + math.cos(a) * 18, 18 + math.sin(a) * 13, (170, 250, 255))
c.ellipse(60, 18, 22, 16, (150, 220, 240), fill=False)
c.px(50, 8, (255, 255, 255)); c.px(51, 8, (255, 255, 255)); c.px(50, 9, (255, 255, 255))
c.vramp(38, 30, 82, 34, GOLD)                                # anel de latão
c.line(14, 100, 2, 118, (30, 30, 34)); c.line(106, 100, 118, 119, (30, 30, 34))                     # cabos
out["generator"] = c.save("generator.png")

# ── ALTAR 210×120: pedra entalhada, pano roxo com borda dourada e olho do culto, velas e oferendas
c = C(210, 120)
c.vramp(6, 40, 203, 116, STONE)                              # bloco
c.vramp(0, 30, 209, 42, STONE[:3])                           # tampo
c.rect(0, 41, 209, 42, STONE[4])
for x in range(12, 200, 22): c.rect(x, 100, x + 12, 112, STONE[3])   # entalhes da base
c.speckle(6, 44, 203, 116, [STONE[3], STONE[2]], 0.03)
c.poly([(52, 34), (158, 34), (150, 108), (60, 108)], PURPLE[1])      # pano
c.vramp(56, 36, 154, 106, PURPLE)
for y in range(40, 104, 6): c.line(60 + (y - 40) // 8, y, 150 - (y - 40) // 8, y, PURPLE[3])   # dobras
c.poly([(60, 100), (150, 100), (144, 110), (66, 110)], GOLD[1]); c.line(60, 100, 150, 100, GOLD[0])  # franja
for x in range(64, 148, 5): c.line(x, 110, x, 114, GOLD[2])
c.ellipse(105, 66, 18, 11, GREEN_GLOW[2]); c.ellipse(105, 66, 14, 8, (20, 40, 26)); c.ellipse(105, 66, 6, 6, GREEN_GLOW[1]); c.ellipse(105, 66, 2, 2, (10, 20, 12))
for a in range(8):                                           # raios do olho
    t = a * math.pi / 4; c.line(105 + math.cos(t) * 22, 66 + math.sin(t) * 14, 105 + math.cos(t) * 27, 66 + math.sin(t) * 17, GREEN_GLOW[1])
for cx, h in ((18, 22), (30, 14), (178, 18), (192, 26)):     # velas
    c.cyl(cx - 3, 30 - h, cx + 3, 30, [(246, 238, 214), (222, 212, 186), (190, 178, 150)])
    c.px(cx - 3, 31 - h + 4, (246, 238, 214)); c.px(cx + 3, 30 - h + 7, (222, 212, 186))    # pingos
    c.ellipse(cx, 30 - h - 4, 2, 3, (255, 200, 80)); c.px(cx, 30 - h - 5, (255, 250, 210))
c.ellipse(76, 26, 8, 5, (240, 232, 214)); c.ellipse(76, 25, 4, 2, (200, 190, 170))                 # concha
c.vramp(128, 16, 140, 30, GOLD); c.rect(126, 14, 142, 16, GOLD[0])                                  # cálice
c.rect(150, 20, 166, 30, (90, 40, 40)); c.rect(151, 21, 165, 22, (130, 60, 55))                     # livro
out["altar"] = c.save("altar.png")

# ── BANCO 180×50: banco de igreja de madeira (encosto + assento), com pontas entalhadas
c = C(180, 50)
c.vramp(8, 4, 171, 22, WOOD)                                 # encosto
for x in range(8, 171, 26): c.line(x, 5, x, 21, WOOD[3])
c.rect(8, 4, 171, 5, WOOD[0])
c.vramp(4, 24, 175, 38, WOOD)                                # assento
for y in (29, 34): c.line(5, y, 174, y, WOOD[3])
c.rect(4, 24, 175, 25, (196, 140, 88))
for x0 in (0, 170):                                          # cabeceiras entalhadas
    c.vramp(x0, 0, x0 + 9, 46, [(120, 76, 44), (96, 58, 34), (72, 42, 26)])
    c.ellipse(x0 + 4.5, 4, 5, 4, (140, 90, 52))
    c.rect(x0 + 3, 12, x0 + 6, 40, (72, 42, 26))
for x in (40, 90, 140): c.rect(x, 38, x + 5, 46, WOOD[3])   # pés
c.speckle(8, 4, 171, 38, [WOOD[3], WOOD[2]], 0.04)
for x in range(20, 170, 30): c.px(x, 31, (200, 200, 190)); c.px(x + 12, 36, (200, 200, 190))       # pregos
out["pew"] = c.save("pew.png")

# ── MUNIÇÃO 70×52: caixote militar oliva com alças, estêncil e cartuchos de latão
c = C(70, 52)
c.vramp(3, 14, 66, 50, OLIVE)
c.vramp(1, 8, 68, 16, [(150, 160, 96), (124, 134, 76), (98, 108, 60)])     # tampa
for x in (10, 58): c.rect(x, 8, x + 3, 50, OLIVE[3])        # cintas
c.rect(24, 24, 46, 40, OLIVE[2])                             # estêncil
for (x, y) in [(27, 28), (28, 28), (29, 28), (27, 29), (29, 30), (27, 31), (28, 31), (29, 31),   # ".303"
               (32, 31), (35, 28), (36, 28), (37, 28), (35, 29), (37, 29), (35, 30), (37, 30), (35, 31), (36, 31), (37, 31),
               (40, 28), (41, 28), (42, 28), (42, 29), (41, 30), (42, 30), (42, 31), (40, 31), (41, 31)]:
    c.px(x, y, (220, 214, 170))
c.rect(26, 35, 44, 36, (220, 214, 170))
for x in (6, 62): c.rect(x - 3, 28, x + 3, 30, IRON[1]); c.rect(x - 3, 30, x + 3, 30, IRON[3])      # alças
for i, x in enumerate(range(20, 50, 6)):                     # cartuchos saindo
    c.vramp(x, 1 + (i % 2) * 2, x + 3, 9, GOLD); c.rect(x, 1 + (i % 2) * 2, x + 3, 2 + (i % 2) * 2, (120, 70, 40))
c.speckle(3, 14, 66, 50, [OLIVE[3], OLIVE[0]], 0.05)
for x, y in ((5, 16), (64, 16), (5, 46), (64, 46)): c.rivet(x, y)
out["ammo"] = c.save("ammo.png")

# ── VELAS 40×40: grupo de velas derretidas sobre um prato
c = C(40, 40)
c.ellipse(20, 34, 18, 5, IRON[2]); c.ellipse(20, 33, 16, 4, IRON[1])
for cx, h, w in ((10, 14, 3), (20, 22, 4), (29, 10, 3), (16, 8, 2), (25, 17, 3)):
    c.cyl(cx - w, 33 - h, cx + w, 33, [(248, 242, 222), (228, 216, 190), (196, 182, 156)])
    c.px(cx - w, 33 - h + 3, (248, 242, 222)); c.px(cx + w, 33 - h + 5, (228, 216, 190)); c.px(cx + w, 33 - h + 6, (228, 216, 190))
    c.line(cx, 33 - h, cx, 33 - h - 1, (40, 30, 30))
    c.ellipse(cx, 33 - h - 4, 1.6, 3, (255, 170, 60)); c.px(cx, 33 - h - 4, (255, 246, 200))
out["candles"] = c.save("candles.png")

# ── POÇA 120×50: água rasa irregular com reflexo e ondinhas (semitransparente, sem contorno)
c = C(120, 50)
for y in range(50):
    for x in range(120):
        d = ((x - 60) / 58) ** 2 + ((y - 25) / 22) ** 2
        wob = 0.12 * math.sin(x * 0.21 + y * 0.4) + 0.08 * math.sin(x * 0.09)
        if d < 0.85 + wob: c.px(x, y, (22, 40, 64, 170))
        if d < 0.55 + wob: c.px(x, y, (30, 54, 84, 180))
for y, x0, x1 in ((16, 34, 62), (22, 50, 86), (30, 30, 48), (34, 66, 90)):
    c.line(x0, y, x1, y, (120, 160, 200, 200))
c.line(40, 18, 52, 18, (220, 236, 255, 230)); c.px(72, 23, (220, 236, 255, 230)); c.px(73, 23, (220, 236, 255, 230))
out["puddle"] = c.save("puddle.png", outline=False)

# ── RACHADURA 80×80: parede rachada com luz fria vazando (pista da sala secreta)
c = C(80, 80)
pts = [(40, 2), (36, 16), (44, 28), (38, 40), (46, 54), (40, 66), (43, 78)]
for (xa, ya), (xb, yb) in zip(pts, pts[1:]):
    for w in (2, 1, 0):
        col = [(60, 200, 220, 110), (140, 240, 255, 200), (230, 255, 255, 255)][2 - w]
        for o in range(-w, w + 1): c.line(xa + o, ya, xb + o, yb, col)
for (xa, ya, xb, yb) in ((38, 40, 22, 46), (44, 28, 60, 22), (46, 54, 64, 60), (36, 16, 24, 10)):
    c.line(xa, ya, xb, yb, (120, 230, 250, 200))
for i in range(14):
    x, y = R.uniform(24, 60), R.uniform(62, 78)
    c.rect(x, y, x + R.choice([1, 2, 3]), y + R.choice([1, 2]), R.choice([(120, 110, 104), (90, 86, 84), (150, 142, 132)]))
out["crack"] = c.save("crack.png", outline=False)

# ── TAPETE 140×330: passadeira vermelha com borda dourada e padrão do culto
c = C(140, 330)
c.rect(0, 0, 139, 329, (70, 20, 28, 230))
c.rect(6, 6, 133, 323, (120, 30, 40, 235))
for y in range(10, 322, 2): c.px(8 + (y // 2) % 2, y, (150, 44, 52, 235)); c.px(131 - (y // 2) % 2, y, (150, 44, 52, 235))
for (x0, y0, x1, y1) in ((12, 12, 127, 12), (12, 317, 127, 317), (12, 12, 12, 317), (127, 12, 127, 317)):
    c.line(x0, y0, x1, y1, (210, 160, 70, 255)); c.line(x0 + (1 if x0 == x1 else 0), y0 + (1 if y0 == y1 else 0), x1 + (1 if x0 == x1 else 0), y1 + (1 if y0 == y1 else 0), (150, 100, 40, 255))
for cy in range(50, 300, 60):                                # losangos com o olho
    c.poly([(70, cy - 22), (98, cy), (70, cy + 22), (42, cy)], (160, 50, 58, 240))
    c.poly([(70, cy - 16), (90, cy), (70, cy + 16), (50, cy)], (90, 24, 34, 240))
    c.ellipse(70, cy, 7, 4, (210, 160, 70)); c.ellipse(70, cy, 2, 2, (40, 12, 16))
for x in range(4, 136, 4): c.line(x, 0, x, -3, (210, 160, 70)); c.line(x, 329, x, 332, (210, 160, 70))
out["rug"] = c.save("rug.png", outline=False)

# ── DEGRAUS 64×64 (azulejo das rampas do balcão): pedra com degraus e borda gasta
c = C(64, 64)
for i in range(4):
    x0 = i * 16
    c.hramp(x0, 0, x0 + 15, 63, [STONE[1], STONE[0], STONE[1], STONE[2], STONE[3]])
    c.line(x0 + 15, 0, x0 + 15, 63, STONE[4]); c.line(x0, 0, x0, 63, (200, 194, 184))
c.speckle(0, 0, 63, 63, [STONE[3], MOSS[2]], 0.02)
out["stairs"] = c.save("stairs.png", outline=False)

# ── CÁPSULA 150×240: câmara de extração com hexágonos laranja da Cápsula Temporal
c = C(150, 240)
c.vramp(8, 196, 141, 236, IRON)                              # base
c.poly([(20, 196), (130, 196), (144, 216), (130, 236), (20, 236), (6, 216)], IRON[1])
c.poly([(28, 202), (122, 202), (132, 216), (122, 230), (28, 230), (18, 216)], (40, 44, 54))
c.poly([(40, 208), (110, 208), (116, 216), (110, 224), (40, 224), (34, 216)], (240, 138, 36))    # hexágono laranja
c.poly([(46, 211), (104, 211), (108, 216), (104, 221), (46, 221), (42, 216)], (120, 60, 20))
for x, y in ((14, 216), (136, 216), (28, 232), (122, 232)): c.rivet(x, y)
for x0, x1 in ((12, 30), (120, 138)):                        # colunas laterais
    c.cyl(x0, 50, x1, 196, [(236, 240, 246), (206, 212, 222), (170, 178, 192), (130, 138, 152)])
    for y in range(62, 190, 16): c.rect(x0 + 5, y, x1 - 5, y + 6, CYAN[1]); c.rect(x0 + 6, y + 1, x1 - 6, y + 2, CYAN[0])
c.vramp(30, 50, 120, 196, [(40, 80, 100), (34, 70, 90), (28, 60, 80), (24, 50, 70)])            # vidro
c.rect(44, 56, 50, 190, (150, 210, 230)); c.rect(98, 60, 101, 186, (90, 150, 180))
c.ellipse(75, 44, 66, 40, (220, 226, 236)); c.rect(9, 44, 141, 56, (200, 206, 216))            # cúpula
c.ellipse(75, 40, 58, 32, (238, 242, 248)); c.ellipse(60, 26, 18, 8, (255, 255, 255))
for x in range(14, 138, 12): c.rivet(x, 52)
c.ellipse(75, 20, 12, 10, IRON[3]); c.ellipse(75, 20, 9, 8, CYAN[2]); c.ellipse(75, 19, 6, 5, CYAN[1]); c.ellipse(73, 17, 2, 2, CYAN[0])
c.rect(8, 56, 142, 60, (240, 138, 36)); c.rect(8, 57, 142, 57, (255, 190, 110))                 # faixa laranja
c.rect(36, 188, 114, 194, CYAN[1]); c.rect(40, 189, 110, 190, CYAN[0])                           # anel de luz no chão
out["capsule"] = c.save("capsule.png")

# prévia
names = list(out)
W = sum(out[n].width * 2 + 16 for n in names); H = max(out[n].height * 2 for n in names) + 8
prev = Image.new("RGBA", (W, H), (38, 36, 48, 255)); x = 8
for n in names:
    im = out[n].resize((out[n].width * 2, out[n].height * 2), Image.NEAREST); prev.alpha_composite(im, (x, 4)); x += im.width + 16
prev.save(ROOT / "art/props-hd-preview.png")
