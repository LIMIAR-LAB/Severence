"""Armas v2 — pixel art maior e com sombreamento (substitui os desenhos de make_weapons.py).

Cada arma é montada por camadas com rampa de cor (luz em cima, sombra embaixo), detalhes
(rebites, frisos, gravações) e um contorno automático de 1px. Tudo aponta para a direita,
com a empunhadura perto da borda esquerda (o jogo gira pela mira).

Saídas (assets/weapons/): pistol.png, shotgun.png, smg.png, omega_sword.png, wrench.png, knife.png
Uso: python tools/make_weapons_v2.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

OUT = Path(__file__).resolve().parents[1] / "assets/weapons"
OUTLINE = (20, 16, 26, 255)


class Canvas:
    def __init__(self, w, h):
        self.a = np.zeros((h, w, 4), np.uint8)
        self.w, self.h = w, h

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h: self.a[y, x] = c if len(c) == 4 else (*c, 255)

    def rect(self, x0, y0, x1, y1, ramp):
        """Retângulo inclusivo com rampa vertical: ramp = [cor_topo, ..., cor_base]."""
        for y in range(y0, y1 + 1):
            t = 0 if y1 == y0 else (y - y0) / (y1 - y0)
            c = ramp[min(len(ramp) - 1, int(t * len(ramp)))]
            for x in range(x0, x1 + 1): self.px(x, y, c)

    def poly(self, pts, ramp):
        ys = [p[1] for p in pts]
        for y in range(min(ys), max(ys) + 1):
            xs = []
            n = len(pts)
            for i in range(n):
                (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
                if (y0 <= y < y1) or (y1 <= y < y0):
                    xs.append(x0 + (y - y0) * (x1 - x0) / (y1 - y0))
            xs.sort()
            t = (y - min(ys)) / max(1, max(ys) - min(ys))
            c = ramp[min(len(ramp) - 1, int(t * len(ramp)))]
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(round(xs[i])), int(round(xs[i + 1])) + 1): self.px(x, y, c)

    def hline(self, x0, x1, y, c):
        for x in range(x0, x1 + 1): self.px(x, y, c)

    def vline(self, x, y0, y1, c):
        for y in range(y0, y1 + 1): self.px(x, y, c)

    def outline(self):
        a = self.a
        op = a[..., 3] > 0
        grown = op.copy()
        grown[1:] |= op[:-1]; grown[:-1] |= op[1:]; grown[:, 1:] |= op[:, :-1]; grown[:, :-1] |= op[:, 1:]
        a[grown & ~op] = OUTLINE

    def save(self, name, glow=None):
        self.outline()
        if glow is not None:  # halo suave para armas de energia (fora do contorno)
            op = self.a[..., 3] > 0
            halo = op.copy()
            for _ in range(2):
                g = halo.copy(); g[1:] |= halo[:-1]; g[:-1] |= halo[1:]; g[:, 1:] |= halo[:, :-1]; g[:, :-1] |= halo[:, 1:]; halo = g
            self.a[halo & ~op] = (*glow, 70)
        Image.fromarray(self.a).save(OUT / name); print("wrote", name, (self.w, self.h))


# paletas
STEEL = [(196, 204, 220), (138, 148, 168), (96, 104, 124), (64, 70, 88)]
GUNMETAL = [(120, 128, 146), (78, 84, 100), (52, 56, 70), (36, 38, 50)]
WOOD = [(176, 112, 64), (140, 84, 46), (104, 60, 34), (74, 42, 26)]
GRIP = [(96, 70, 56), (70, 50, 42), (50, 36, 32)]
CYAN = [(200, 255, 255), (96, 232, 245), (40, 170, 200)]
GOLD = [(255, 222, 130), (220, 170, 70), (160, 112, 40)]
WHITE = [(255, 255, 255), (228, 232, 238), (180, 186, 198), (140, 146, 160)]
OLIVE = [(140, 150, 96), (106, 116, 70), (78, 86, 52)]
HI = (240, 246, 255)

# ── BLASTER (Padrão) 40×18 — pistola de energia do futuro, célula ciano e aletas
c = Canvas(40, 18)
c.poly([(4, 8), (11, 8), (12, 16), (6, 16), (4, 12)], GRIP)                     # cabo
for y in (10, 12, 14): c.hline(6, 10, y, (40, 30, 28))                          # ranhuras do cabo
c.rect(9, 11, 13, 12, GUNMETAL); c.px(11, 13, GUNMETAL[2]); c.px(12, 13, GUNMETAL[2])   # guarda-mato
c.rect(3, 3, 26, 9, STEEL)                                                     # corpo
c.hline(4, 25, 3, HI)
c.rect(26, 5, 36, 8, GUNMETAL)                                                 # cano
c.hline(26, 36, 5, GUNMETAL[0])
for x in (28, 31, 34): c.vline(x, 4, 9, GUNMETAL[3])                           # aletas
c.rect(37, 5, 38, 8, CYAN); c.px(38, 6, HI)                                    # boca emissora
c.rect(12, 5, 21, 7, CYAN); c.hline(13, 20, 5, HI); c.hline(12, 21, 8, (20, 90, 110))   # célula de energia
c.px(6, 5, (70, 76, 92)); c.px(6, 7, (70, 76, 92))                             # rebites
c.rect(4, 1, 8, 2, GUNMETAL)                                                   # mira traseira
c.save("pistol.png")

# ── ESCOPETA DE REBITE (Mecânico) 56×18 — cano duplo, coronha de madeira, rebites de latão
c = Canvas(56, 18)
c.poly([(1, 7), (14, 7), (14, 12), (6, 15), (1, 14)], WOOD)                   # coronha
for x in (4, 7, 10): c.px(x, 9, WOOD[3]); c.px(x + 1, 11, WOOD[3])             # veios da madeira
c.rect(14, 5, 24, 11, GUNMETAL)                                                # caixa da culatra
c.hline(15, 23, 5, GUNMETAL[0])
for x in (16, 22): c.px(x, 8, GOLD[0]); c.px(x, 9, GOLD[2])                    # rebites
c.rect(17, 12, 20, 13, GUNMETAL); c.px(18, 14, GUNMETAL[2])                   # gatilho
c.rect(24, 3, 53, 5, STEEL); c.hline(24, 53, 3, HI)                            # cano de cima
c.rect(24, 7, 53, 9, STEEL[1:]); c.hline(24, 53, 7, STEEL[0])                  # cano de baixo
c.hline(24, 53, 6, GUNMETAL[3])
c.rect(28, 10, 42, 12, WOOD)                                                   # telha (fore-end)
for x in (30, 34, 38): c.vline(x, 10, 12, WOOD[3])
c.rect(46, 2, 48, 10, GOLD); c.vline(46, 2, 10, GOLD[0])                       # abraçadeira de latão
c.px(54, 4, (30, 30, 36)); c.px(54, 8, (30, 30, 36))                           # bocas
c.save("shotgun.png")

# ── SUBMETRALHADORA DE TAMBOR (Espião) 52×22 — estilo 1941, tambor e empunhadura frontal
c = Canvas(52, 22)
c.poly([(1, 6), (10, 5), (10, 10), (3, 12), (1, 11)], WOOD)                    # coronha
c.rect(10, 4, 34, 9, GUNMETAL); c.hline(11, 33, 4, GUNMETAL[0])                # corpo
c.rect(34, 5, 48, 7, STEEL); c.hline(34, 48, 5, HI)                            # cano
for x in (37, 40, 43, 46): c.px(x, 6, (24, 24, 30))                            # compensador ranhurado
c.rect(49, 4, 50, 8, GUNMETAL)                                                 # massa de mira
c.rect(12, 2, 16, 3, GUNMETAL)                                                 # alça de mira
# tambor
cx, cy, r = 21, 14, 6
for y in range(cy - r, cy + r + 1):
    for x in range(cx - r, cx + r + 1):
        d2 = (x - cx) ** 2 + (y - cy) ** 2
        if d2 <= r * r:
            t = (y - (cy - r)) / (2 * r)
            col = GUNMETAL[min(3, int(t * 4))]
            if d2 <= 4: col = STEEL[0]
            elif d2 <= 9: col = GUNMETAL[2]
            c.px(x, y, col)
c.px(cx - 3, cy - 4, HI); c.px(cx - 4, cy - 3, HI)
c.rect(26, 10, 28, 12, GUNMETAL); c.px(27, 13, GUNMETAL[2])                   # gatilho
c.poly([(36, 8), (40, 8), (41, 16), (37, 16)], WOOD)                           # empunhadura frontal
for y in (10, 12, 14): c.hline(37, 40, y, WOOD[3])
c.save("smg.png")

# ── LÂMINA ÔMEGA (armadura) 78×20 — cabo branco e dourado, lâmina de energia com núcleo branco
c = Canvas(78, 20)
c.rect(2, 8, 14, 11, WHITE); c.hline(2, 14, 8, HI)                             # cabo
for x in (5, 8, 11): c.vline(x, 8, 11, GOLD[1])                                # fitas douradas
c.rect(0, 7, 2, 12, GOLD)                                                      # pomo
c.poly([(15, 3), (19, 5), (19, 14), (15, 16)], GOLD)                           # guarda
c.px(17, 9, CYAN[0]); c.px(17, 10, CYAN[1])                                    # gema da guarda
c.poly([(20, 6), (68, 7), (76, 9), (76, 10), (68, 12), (20, 13)], [(120, 240, 255), (70, 210, 240), (40, 160, 210)])
c.poly([(20, 8), (68, 8), (73, 9), (73, 10), (68, 11), (20, 11)], [(220, 255, 255), (170, 245, 255)])
c.hline(21, 66, 9, (255, 255, 255))                                            # fio branco
for x in range(24, 66, 7): c.px(x, 7, (200, 250, 255))                         # faíscas na borda
c.save("omega_sword.png", glow=(80, 230, 255))

# ── CHAVE INGLESA (golpe do Mecânico) 42×16
c = Canvas(42, 16)
c.rect(1, 6, 28, 9, STEEL); c.hline(1, 28, 6, HI)
c.rect(2, 6, 10, 9, [(150, 52, 44)]); c.hline(2, 10, 6, (200, 90, 70))           # empunhadura vermelha
c.poly([(28, 2), (40, 2), (40, 5), (34, 5), (34, 10), (40, 10), (40, 13), (28, 13)], STEEL)
c.hline(29, 39, 2, HI); c.px(31, 7, GUNMETAL[2]); c.px(31, 8, GUNMETAL[2])
c.save("wrench.png")

# ── FACA (golpe do Espião) 32×10
c = Canvas(32, 10)
c.rect(1, 4, 9, 6, GRIP); for_x = [3, 6]
for x in for_x: c.px(x, 5, GOLD[1])
c.rect(10, 2, 11, 8, GUNMETAL)
c.poly([(12, 3), (27, 4), (30, 5), (27, 6), (12, 7)], STEEL); c.hline(13, 27, 4, HI)
c.save("knife.png")
