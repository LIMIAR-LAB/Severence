"""Desenha as armas do Marty em pixel art (apontando para a direita, empunhadura na borda esquerda).

Saídas em assets/weapons/: pistol.png, shotgun.png, smg.png, flash.png, flash_cyan.png
O jogo gira a arma pela mira, espelha na vertical quando mira para a esquerda,
aplica recuo e desenha o clarão na ponta do cano.
Uso: python tools/make_weapons.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets/weapons"
OUT.mkdir(parents=True, exist_ok=True)
K = (18, 16, 24, 255)  # contorno


def canvas(w, h):
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)


def box(d, x0, y0, x1, y1, fill, hi=None):
    d.rectangle([x0 - 1, y0 - 1, x1 + 1, y1 + 1], fill=K)
    d.rectangle([x0, y0, x1, y1], fill=fill)
    if hi: d.line([x0, y0, x1, y0], fill=hi)


def finish(im, name):
    # contorno único ao redor (remove sobreposição de contornos internos)
    im.save(OUT / name); print("wrote", name, im.size)


# Pistola blaster (Padrão) — 26×12
im, d = canvas(26, 12)
box(d, 2, 6, 6, 10, (70, 58, 52, 255), (110, 92, 80, 255))        # cabo
box(d, 3, 3, 18, 6, (58, 64, 78, 255), (140, 150, 168, 255))      # corpo
box(d, 18, 4, 23, 5, (40, 44, 54, 255), (110, 118, 132, 255))     # cano
d.rectangle([9, 4, 14, 5], fill=(102, 229, 237, 255))             # célula de energia
d.point((23, 4), fill=(170, 250, 255, 255))
finish(im, "pistol.png")

# Escopeta de cano duplo — 40×12
im, d = canvas(40, 12)
box(d, 1, 5, 10, 9, (122, 74, 42, 255), (165, 103, 58, 255))      # coronha
box(d, 10, 4, 18, 7, (96, 60, 36, 255), (140, 90, 52, 255))       # guarda-mão
box(d, 16, 2, 37, 3, (46, 50, 58, 255), (120, 128, 142, 255))     # cano de cima
box(d, 16, 5, 37, 6, (38, 42, 50, 255), (96, 104, 118, 255))      # cano de baixo
d.rectangle([13, 8, 14, 10], fill=K)                              # gatilho
finish(im, "shotgun.png")

# Submetralhadora de tambor — 36×16
im, d = canvas(36, 16)
box(d, 1, 5, 8, 8, (122, 74, 42, 255), (165, 103, 58, 255))       # coronha
box(d, 8, 3, 25, 7, (60, 64, 72, 255), (130, 138, 150, 255))      # corpo
box(d, 25, 4, 33, 5, (40, 44, 52, 255), (110, 118, 130, 255))     # cano
for x in (27, 29, 31): d.point((x, 5), fill=K)                    # ventilação
d.ellipse([12, 7, 20, 15], fill=K); d.ellipse([13, 8, 19, 14], fill=(74, 78, 88, 255))  # tambor
d.ellipse([15, 10, 17, 12], fill=(140, 146, 158, 255))
box(d, 22, 8, 24, 11, (122, 74, 42, 255))                         # empunhadura dianteira
finish(im, "smg.png")

# Clarões (estrela de 4 pontas)
for name, core, glow in [("flash.png", (255, 250, 220, 255), (255, 190, 70, 230)),
                         ("flash_cyan.png", (230, 255, 255, 255), (80, 230, 245, 230))]:
    im, d = canvas(18, 18)
    d.polygon([(0, 9), (9, 6), (18, 9), (9, 12)], fill=glow)
    d.polygon([(9, 0), (12, 9), (9, 18), (6, 9)], fill=glow)
    d.ellipse([5, 5, 13, 13], fill=glow); d.ellipse([7, 7, 11, 11], fill=core)
    finish(im, name)

# Canhão de Plasma Ômega (exclusivo da armadura) — 44×18
im, d = canvas(44, 18)
box(d, 2, 5, 12, 13, (214, 214, 206, 255), (250, 250, 244, 255))       # manopla
box(d, 10, 3, 30, 12, (232, 232, 226, 255), (255, 255, 255, 255))      # corpo branco
d.rectangle([10, 10, 30, 12], fill=(170, 170, 176, 255))              # sombra inferior
box(d, 28, 5, 40, 10, (58, 62, 76, 255), (120, 128, 148, 255))        # cano grafite
d.rectangle([12, 3, 30, 4], fill=(214, 172, 74, 255))                 # friso dourado
d.rectangle([14, 6, 24, 9], fill=(40, 200, 220, 255))                 # núcleo
d.rectangle([16, 7, 22, 8], fill=(200, 255, 255, 255))
for x in (32, 35, 38): d.rectangle([x, 6, x, 9], fill=(102, 229, 237, 255))  # bobinas
d.rectangle([40, 6, 41, 9], fill=(170, 250, 255, 255))
finish(im, "omega.png")

# Projéteis do Marty (apontando para a direita)
def bolt(name, w, h, core, glow, tail):
    im, d = canvas(w, h)
    cy = h // 2
    d.ellipse([w * 0.35, 0, w - 1, h - 1], fill=glow)
    d.rectangle([0, cy - 1, w * 0.7, cy], fill=tail)
    d.ellipse([w * 0.55, cy - h * 0.25, w - 2, cy + h * 0.25], fill=core)
    finish(im, name)
bolt("b_pistol.png", 16, 7, (230, 255, 255, 255), (80, 230, 245, 200), (80, 230, 245, 120))
bolt("b_smg.png", 14, 5, (255, 245, 210, 255), (255, 190, 80, 200), (255, 190, 80, 110))
bolt("b_pellet.png", 8, 6, (255, 240, 200, 255), (255, 170, 70, 210), (255, 170, 70, 90))
bolt("b_omega.png", 30, 14, (255, 255, 255, 255), (90, 235, 255, 210), (60, 200, 255, 140))

# ───── Lâmina Ômega (espada de energia, exclusiva da armadura) — 60×14, empunhadura à esquerda
im, d = canvas(60, 14)
box(d, 1, 5, 9, 8, (230, 230, 222, 255), (255, 255, 255, 255))         # cabo branco
d.rectangle([3, 6, 7, 7], fill=(214, 172, 74, 255))                   # fita dourada
box(d, 10, 2, 13, 11, (214, 172, 74, 255), (255, 220, 130, 255))      # guarda dourada
d.polygon([(14, 3), (54, 5), (59, 7), (54, 9), (14, 10)], fill=(60, 210, 240, 200))   # lâmina (brilho)
d.polygon([(14, 5), (54, 6), (57, 7), (54, 8), (14, 8)], fill=(210, 255, 255, 255))   # núcleo
d.line([(15, 6), (52, 6)], fill=(255, 255, 255, 255))
finish(im, "omega_sword.png")

# Onda crescente (3º golpe do combo) apontando para a direita — 34×48
im, d = canvas(34, 48)
d.pieslice([-30, 0, 32, 47], -70, 70, fill=(70, 220, 250, 170))
d.pieslice([-38, 5, 22, 42], -70, 70, fill=(0, 0, 0, 0))
d.arc([-30, 0, 32, 47], -65, 65, fill=(230, 255, 255, 255), width=3)
finish(im, "b_wave.png")

# Rastro do golpe (smear) — 3 quadros 112×112, arco de 150° para a direita, centro no meio
frames = Image.new("RGBA", (112 * 3, 112), (0, 0, 0, 0))
for i, (width, alpha) in enumerate([(10, 150), (18, 230), (12, 120)]):
    fr, fd = canvas(112, 112)
    for k in range(width):
        a = int(alpha * (1 - k / width))
        col = (200, 255, 255, a) if k < 4 else (70, 220, 250, a)
        fd.arc([6 + k, 6 + k, 106 - k, 106 - k], -75 + i * 10, 75 - i * 10 + (20 if i == 1 else 0), fill=col, width=2)
    frames.alpha_composite(fr, (112 * i, 0))
frames.save(OUT / "sword_smear.png"); print("wrote sword_smear.png", frames.size)

# Faca do Espião e chave inglesa do Mecânico (golpes corpo a corpo dos uniformes)
im, d = canvas(24, 8)
box(d, 1, 3, 7, 5, (60, 40, 30, 255)); d.polygon([(8, 2), (22, 4), (8, 6)], fill=(200, 205, 215, 255)); d.line([(9, 3), (20, 4)], fill=(250, 250, 255, 255))
finish(im, "knife.png")
im, d = canvas(34, 14)
box(d, 1, 5, 24, 8, (120, 124, 134, 255), (190, 194, 204, 255))
d.ellipse([22, 1, 33, 12], fill=K); d.ellipse([23, 2, 32, 11], fill=(150, 154, 164, 255)); d.rectangle([28, 4, 33, 9], fill=(0, 0, 0, 0))
finish(im, "wrench.png")
