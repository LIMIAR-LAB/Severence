"""Arte em pixel art para as Docas de 1941 (mapa fixo 0.11) e a cápsula de extração.

Saídas em assets/environment/docks/:
  planks.png        piso de tábuas do cais (128×128, repete)
  wall_side.png     parede lateral de tijolos com capa de pedra (24×64, repete na vertical)
  container_red/blue/olive.png   contêineres (240×130: frente + tampo)
  pillar.png        base de guindaste de pedra/ferro (96×140)
  bollard.png       cabeço de amarração (34×40)
  generator.png     gerador elétrico (120×120)
  altar.png         altar do culto (210×120)   pew.png  banco (180×50)
  ammo.png          caixa de munição (70×52)   fishbox.png caixa de peixe (64×40)
  candles.png       velas (40×40)   puddle.png poça (120×50)   anchor.png âncora (60×70)
  capsule.png       cápsula de extração estilo "câmara de upgrade" (150×240)
  crack.png         rachadura de parede secreta (80×80)
Uso: python tools/make_docks_art.py
"""
from pathlib import Path
import random
from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parents[1] / "assets/environment/docks"
OUT.mkdir(parents=True, exist_ok=True)
K = (16, 14, 22, 255)
rnd = random.Random(1941)


def save(im, name):
    im.save(OUT / name); print("wrote", name, im.size)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c[:3]) + (255,)


# ── piso de tábuas
im = Image.new("RGBA", (128, 128)); d = ImageDraw.Draw(im)
base = (92, 66, 48)
for row in range(8):
    y = row * 16
    off = (row * 37) % 128
    for seg in range(3):
        x0 = (off + seg * 52) % 128
        c = shade(base, rnd.uniform(0.82, 1.1))
        for dx in range(52):
            x = (x0 + dx) % 128
            d.line([(x, y + 1), (x, y + 14)], fill=c)
        d.line([((x0) % 128, y), ((x0) % 128, y + 15)], fill=shade(base, 0.5))
    d.line([(0, y), (127, y)], fill=shade(base, 0.45))
    d.line([(0, y + 1), (127, y + 1)], fill=shade(base, 1.25))
    for _ in range(10):
        x = rnd.randrange(128); d.point((x, y + rnd.randrange(3, 13)), fill=shade(base, 0.65))
    for _ in range(2):
        x = rnd.randrange(4, 124); d.point((x, y + 4), fill=(40, 40, 44, 255)); d.point((x, y + 11), fill=(40, 40, 44, 255))
save(im, "planks.png")

# ── parede lateral
im = Image.new("RGBA", (24, 64)); d = ImageDraw.Draw(im)
d.rectangle([0, 0, 23, 63], fill=(60, 36, 34, 255))
for r in range(8):
    y = r * 8; off = 0 if r % 2 == 0 else 6
    for x in range(-12, 24, 12):
        c = shade((128, 70, 56), rnd.uniform(0.8, 1.1))
        d.rectangle([x + off + 1, y + 1, x + off + 10, y + 6], fill=c)
        d.line([(x + off + 1, y + 1), (x + off + 10, y + 1)], fill=shade(c, 1.25))
d.rectangle([0, 0, 3, 63], fill=(120, 116, 110, 255)); d.line([(0, 0), (0, 63)], fill=(170, 166, 158, 255))
d.rectangle([20, 0, 23, 63], fill=(40, 34, 36, 255))
save(im, "wall_side.png")


# ── contêineres
def container(name, col):
    im = Image.new("RGBA", (240, 130)); d = ImageDraw.Draw(im)
    top = shade(col, 1.2); front = col
    d.rectangle([2, 2, 237, 36], fill=K); d.rectangle([4, 4, 235, 34], fill=top)
    for x in range(10, 232, 14): d.line([(x, 6), (x, 32)], fill=shade(top, 0.85))
    d.rectangle([2, 36, 237, 127], fill=K); d.rectangle([4, 38, 235, 125], fill=front)
    for x in range(8, 232, 10):
        d.line([(x, 40), (x, 123)], fill=shade(front, 0.72)); d.line([(x + 1, 40), (x + 1, 123)], fill=shade(front, 1.12))
    d.rectangle([4, 38, 235, 43], fill=shade(front, 1.3)); d.rectangle([4, 119, 235, 125], fill=shade(front, 0.55))
    for x in (4, 231): d.rectangle([x, 38, x + 4, 125], fill=shade(front, 0.5))
    d.rectangle([96, 60, 144, 96], fill=shade(front, 0.62)); d.text((101, 70), "1941", fill=(230, 220, 200, 255))
    for _ in range(40):  # ferrugem
        x, y = rnd.randrange(6, 232), rnd.randrange(40, 122)
        d.point((x, y), fill=(122, 70, 40, 255))
    save(im, name)
container("container_red.png", (150, 48, 40, 255))
container("container_blue.png", (46, 78, 128, 255))
container("container_olive.png", (92, 100, 56, 255))

# ── base de guindaste (pilar)
im = Image.new("RGBA", (96, 140)); d = ImageDraw.Draw(im)
d.rectangle([4, 20, 91, 136], fill=K); d.rectangle([6, 22, 89, 134], fill=(98, 98, 104, 255))
for y in range(26, 132, 14):
    for x in range(8, 88, 20):
        c = shade((110, 110, 118), rnd.uniform(0.85, 1.12)); d.rectangle([x + (y // 14 % 2) * 8, y, x + 17 + (y // 14 % 2) * 8, y + 11], fill=c)
d.rectangle([0, 2, 95, 26], fill=K); d.rectangle([2, 4, 93, 24], fill=(150, 118, 52, 255))
for x in range(6, 90, 12): d.rectangle([x, 8, x + 6, 20], fill=(30, 28, 30, 255))
d.rectangle([2, 4, 93, 7], fill=(206, 170, 90, 255))
for x in (12, 84): d.ellipse([x - 4, 110, x + 4, 118], fill=(60, 60, 64, 255))
save(im, "pillar.png")

# ── cabeço de amarração
im = Image.new("RGBA", (34, 40)); d = ImageDraw.Draw(im)
d.ellipse([2, 26, 31, 38], fill=(0, 0, 0, 90))
d.rectangle([7, 8, 26, 32], fill=K); d.rectangle([9, 10, 24, 31], fill=(58, 60, 70, 255)); d.rectangle([9, 10, 12, 31], fill=(98, 102, 116, 255))
d.ellipse([3, 2, 30, 14], fill=K); d.ellipse([5, 3, 28, 12], fill=(72, 74, 86, 255)); d.ellipse([9, 4, 20, 8], fill=(130, 134, 148, 255))
save(im, "bollard.png")

# ── gerador
im = Image.new("RGBA", (120, 120)); d = ImageDraw.Draw(im)
d.rectangle([6, 30, 113, 116], fill=K); d.rectangle([8, 32, 111, 114], fill=(66, 80, 70, 255))
d.rectangle([0, 14, 119, 34], fill=K); d.rectangle([2, 16, 117, 32], fill=(92, 110, 96, 255))
for x in range(14, 106, 12): d.rectangle([x, 44, x + 6, 100], fill=(40, 48, 44, 255))
d.ellipse([40, 0, 80, 30], fill=K); d.ellipse([43, 3, 77, 27], fill=(40, 200, 220, 255)); d.ellipse([52, 9, 68, 21], fill=(210, 255, 255, 255))
d.rectangle([8, 104, 111, 114], fill=(214, 172, 60, 255))
for x in range(8, 111, 16): d.polygon([(x, 114), (x + 8, 104), (x + 16, 104), (x + 8, 114)], fill=(30, 30, 30, 255))
save(im, "generator.png")

# ── altar e banco
im = Image.new("RGBA", (210, 120)); d = ImageDraw.Draw(im)
d.rectangle([4, 40, 205, 116], fill=K); d.rectangle([6, 42, 203, 114], fill=(70, 50, 76, 255))
d.rectangle([0, 26, 209, 44], fill=K); d.rectangle([2, 28, 207, 42], fill=(110, 80, 120, 255))
d.rectangle([60, 60, 150, 100], fill=(40, 26, 44, 255))
d.ellipse([88, 64, 122, 96], outline=(120, 230, 100, 255), width=3); d.ellipse([100, 76, 110, 86], fill=(120, 230, 100, 255))
for x in (16, 40, 170, 194):
    d.rectangle([x - 3, 12, x + 3, 28], fill=(236, 226, 196, 255)); d.polygon([(x, 2), (x - 3, 10), (x + 3, 10)], fill=(255, 200, 90, 255))
save(im, "altar.png")
im = Image.new("RGBA", (180, 50)); d = ImageDraw.Draw(im)
d.rectangle([2, 4, 177, 46], fill=K); d.rectangle([4, 6, 175, 20], fill=(104, 70, 46, 255)); d.rectangle([4, 22, 175, 44], fill=(80, 52, 34, 255))
d.line([(4, 6), (175, 6)], fill=(150, 104, 70, 255))
save(im, "pew.png")

# ── caixa de munição, caixa de peixe
im = Image.new("RGBA", (70, 52)); d = ImageDraw.Draw(im)
d.rectangle([2, 2, 67, 49], fill=K); d.rectangle([4, 4, 65, 16], fill=(96, 106, 62, 255)); d.rectangle([4, 18, 65, 47], fill=(74, 84, 46, 255))
d.text((14, 24), "AMMO", fill=(230, 220, 160, 255)); d.line([(4, 4), (65, 4)], fill=(140, 150, 96, 255))
save(im, "ammo.png")
im = Image.new("RGBA", (64, 40)); d = ImageDraw.Draw(im)
d.rectangle([2, 8, 61, 37], fill=K); d.rectangle([4, 10, 59, 35], fill=(120, 96, 70, 255))
for x in range(8, 56, 10): d.ellipse([x, 2, x + 14, 12], fill=(150, 170, 176, 255)); d.point((x + 3, 6), fill=K)
save(im, "fishbox.png")

# ── velas, poça, âncora, rachadura
im = Image.new("RGBA", (40, 40)); d = ImageDraw.Draw(im)
for x, h in [(6, 18), (16, 26), (27, 14), (33, 20)]:
    d.rectangle([x, 38 - h, x + 4, 38], fill=(236, 226, 196, 255)); d.ellipse([x - 1, 30 - h, x + 5, 38 - h], fill=(255, 190, 70, 255))
save(im, "candles.png")
im = Image.new("RGBA", (120, 50)); d = ImageDraw.Draw(im)
d.ellipse([2, 6, 117, 46], fill=(30, 50, 70, 150)); d.ellipse([20, 14, 70, 26], fill=(120, 160, 190, 90))
save(im, "puddle.png")
im = Image.new("RGBA", (60, 70)); d = ImageDraw.Draw(im)
d.rectangle([27, 8, 33, 60], fill=(60, 62, 70, 255)); d.ellipse([22, 0, 38, 14], outline=(60, 62, 70, 255), width=4)
d.arc([4, 30, 56, 68], 0, 180, fill=(60, 62, 70, 255), width=6); d.rectangle([14, 18, 46, 22], fill=(60, 62, 70, 255))
save(im, "anchor.png")
im = Image.new("RGBA", (80, 80)); d = ImageDraw.Draw(im)
pts = [(40, 0), (34, 18), (44, 30), (30, 48), (40, 62), (36, 80)]
d.line(pts, fill=(20, 14, 16, 255), width=4); d.line([(34, 18), (18, 26)], fill=(20, 14, 16, 255), width=3); d.line([(44, 30), (62, 36)], fill=(20, 14, 16, 255), width=3)
d.line(pts, fill=(150, 120, 100, 255), width=1)
save(im, "crack.png")

# ── Cápsula de extração (câmara de upgrade) 150×240
im = Image.new("RGBA", (150, 240)); d = ImageDraw.Draw(im)
# base octogonal com degraus
d.polygon([(10, 200), (30, 184), (120, 184), (140, 200), (140, 222), (120, 236), (30, 236), (10, 222)], fill=K)
d.polygon([(13, 201), (32, 187), (118, 187), (137, 201), (137, 220), (118, 233), (32, 233), (13, 220)], fill=(200, 204, 214, 255))
d.polygon([(13, 212), (137, 212), (137, 220), (118, 233), (32, 233), (13, 220)], fill=(140, 146, 160, 255))
d.rectangle([40, 190, 110, 200], fill=(40, 200, 230, 255)); d.rectangle([48, 192, 102, 197], fill=(210, 255, 255, 255))
for x in (22, 128): d.rectangle([x - 3, 204, x + 3, 210], fill=(214, 172, 74, 255))
# pilares laterais
for x0 in (14, 118):
    d.rectangle([x0, 44, x0 + 18, 190], fill=K); d.rectangle([x0 + 2, 46, x0 + 16, 188], fill=(226, 228, 234, 255))
    d.rectangle([x0 + 2, 46, x0 + 5, 188], fill=(255, 255, 255, 255)); d.rectangle([x0 + 12, 46, x0 + 16, 188], fill=(160, 164, 178, 255))
    for y in range(64, 180, 22): d.rectangle([x0 + 6, y, x0 + 12, y + 8], fill=(40, 200, 230, 255))
# tubo de vidro
d.rectangle([34, 52, 116, 186], fill=(20, 60, 80, 255))
d.rectangle([36, 54, 114, 184], fill=(40, 120, 150, 150))
d.rectangle([42, 58, 50, 180], fill=(170, 240, 255, 150)); d.rectangle([96, 58, 100, 180], fill=(120, 220, 240, 110))
# topo / cúpula
d.pieslice([10, 6, 140, 90], 180, 360, fill=K); d.pieslice([13, 9, 137, 87], 180, 360, fill=(226, 228, 234, 255))
d.rectangle([10, 46, 140, 56], fill=K); d.rectangle([12, 48, 138, 54], fill=(214, 172, 74, 255))
d.ellipse([62, 16, 88, 40], fill=K); d.ellipse([65, 19, 85, 37], fill=(40, 200, 230, 255)); d.ellipse([70, 23, 80, 32], fill=(230, 255, 255, 255))
d.arc([18, 14, 132, 84], 200, 250, fill=(255, 255, 255, 255), width=3)
save(im, "capsule.png")
