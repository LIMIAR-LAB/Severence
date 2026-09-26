"""Retratos "de vitrine" da tela de EQUIPAMENTO (o personagem grande no meio).

Monta uma arte por skin, armadura e robô a partir das folhas em alta resolução (art/source, assets/mech),
num palco noturno das Docas tirado da ilustração do menu: contraluz na cor do equipamento, raios de luz,
plataforma hexagonal (a mesma da Cápsula Temporal), contorno luminoso, partículas e vinheta.

Saída: assets/ui/portraits/<chave>.png (738x610, o dobro da área de prévia)
Uso:   python tools/make_portraits.py
Para trocar por uma ilustração pintada, basta salvar outra imagem com o mesmo nome.
"""
from pathlib import Path
import math, random
import numpy as np
from PIL import Image, ImageFilter, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/portraits"
W, H = 738, 610   # 2× a área interna do painel de prévia (369×305)

def sheet_cell(path, box, key_bg=None, tol=24):
    im = Image.open(ROOT / path).convert("RGBA").crop(box)
    if key_bg is not None:
        a = np.asarray(im).copy()
        diff = np.abs(a[..., :3].astype(int) - np.array(key_bg)).sum(2)
        # remove o fundo por inundação a partir das bordas (não apaga cinzas dentro do personagem)
        bg = diff < tol
        seen = np.zeros_like(bg)
        stack = [(y, x) for y in range(a.shape[0]) for x in (0, a.shape[1] - 1)] + [(y, x) for x in range(a.shape[1]) for y in (0, a.shape[0] - 1)]
        while stack:
            y, x = stack.pop()
            if y < 0 or x < 0 or y >= a.shape[0] or x >= a.shape[1] or seen[y, x] or not bg[y, x]: continue
            seen[y, x] = True
            stack += [(y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)]
        a[seen, 3] = 0
        im = Image.fromarray(a)
    bb = im.getbbox()
    return im.crop(bb)

GRAY = (123, 123, 123)
SUBJECTS = {
    # chave: (recorte, cor principal, cor secundária, fundo do menu)
    "o_padrao": (lambda: sheet_cell("art/source/marty-outfits-v1.png", (228, 13, 390, 185), GRAY), (80, 230, 245), (255, 170, 80), "city"),
    "o_espiao": (lambda: sheet_cell("art/source/marty-outfits-v1.png", (228, 200, 390, 367), GRAY), (230, 60, 70), (120, 140, 255), "street"),
    "o_mecanico": (lambda: sheet_cell("art/source/marty-outfits-v1.png", (228, 379, 390, 547), GRAY), (255, 150, 50), (120, 230, 120), "fire"),
    "armor_omega": (lambda: sheet_cell("art/source/marty-outfits-v1.png", (15, 561, 196, 734), GRAY), (90, 230, 255), (255, 210, 110), "sky"),
    "titan": (lambda: Image.open(ROOT / "assets/mech/titan_v2.png").convert("RGBA").crop((880, 0, 1056, 176)).crop(Image.open(ROOT / "assets/mech/titan_v2.png").convert("RGBA").crop((880, 0, 1056, 176)).getbbox()), (70, 230, 240), (240, 140, 50), "docks"),
    "spectre": (lambda: sheet_cell("art/source/spectre-feral-source.png", (915, 0, 1222, 320)), (150, 80, 255), (60, 230, 240), "sky"),
}
BG_BOX = {"city": (1000, 300, 1344, 640), "street": (1060, 430, 1344, 720), "fire": (415, 250, 630, 520),
          "sky": (620, 0, 1180, 420), "docks": (1150, 250, 1344, 560)}

def stage(kind, main, rng):
    menu = Image.open(ROOT / "assets/ui/menu.png").convert("RGB")
    bg = menu.crop(BG_BOX[kind]).resize((W, H), Image.BICUBIC).filter(ImageFilter.GaussianBlur(7))
    bg = ImageEnhance.Brightness(bg).enhance(0.55)
    bg = ImageEnhance.Color(bg).enhance(0.8)
    a = np.asarray(bg).astype(float) / 255
    # tom da cor do equipamento + vinheta
    yy, xx = np.mgrid[0:H, 0:W]
    cx, cy = W / 2, H * 0.52
    r = np.sqrt(((xx - cx) / W) ** 2 + ((yy - cy) / H) ** 2)
    tint = np.array(main) / 255
    a = a * (0.75 + 0.25 * tint)
    glow = np.clip(1.0 - r / 0.42, 0, 1) ** 2
    a = a + glow[..., None] * tint * 0.55
    # raios de luz saindo de trás do personagem
    ang = np.arctan2(yy - H * 0.45, xx - cx)
    rays = (0.5 + 0.5 * np.cos(ang * 9 + 0.6)) ** 6 * np.clip(1 - r / 0.7, 0, 1)
    a = a + rays[..., None] * tint * 0.22
    vign = np.clip(1.25 - r * 1.4, 0, 1)
    a = a * vign[..., None]
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).convert("RGBA")

def hex_platform(img, main, sec):
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = W / 2, H * 0.86
    def hexpts(rx, ry, dy=0):
        return [(cx + rx * math.cos(math.pi / 3 * k), cy + dy + ry * math.sin(math.pi / 3 * k)) for k in range(6)]
    d.polygon(hexpts(200, 52, 14), fill=(10, 8, 14, 200))                 # lateral escura
    d.polygon(hexpts(200, 52), fill=(40, 34, 44, 255), outline=(240, 138, 36, 255))
    d.polygon(hexpts(178, 44), fill=(26, 22, 30, 255))
    d.polygon(hexpts(140, 35), outline=main + (230,))
    d.polygon(hexpts(100, 25), outline=main + (140,))
    # rebites laranja da cápsula
    for (x, y) in hexpts(190, 48): d.ellipse((x - 4, y - 3, x + 4, y + 3), fill=(255, 180, 90, 255))
    return img

def rim(sprite, scale, main, sec):
    big = sprite.resize((sprite.width * scale, sprite.height * scale), Image.NEAREST)
    alpha = big.split()[3]
    glow = Image.new("RGBA", big.size, main + (0,))
    g = alpha.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(9))
    glow.putalpha(g.point(lambda v: int(v * 0.9)))
    edge = Image.new("RGBA", big.size, main + (0,))
    e = alpha.filter(ImageFilter.MaxFilter(5))
    e = Image.fromarray(np.clip(np.asarray(e).astype(int) - np.asarray(alpha).astype(int), 0, 255).astype(np.uint8))
    edge.putalpha(e)
    return big, glow, edge

def particles(img, main, sec, rng):
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(46):
        x = rng.uniform(20, W - 20); y = rng.uniform(40, H * 0.85)
        s = rng.choice([2, 2, 3, 4]); c = main if rng.random() < 0.65 else sec
        a = int(rng.uniform(90, 230))
        d.rectangle((x, y, x + s, y + s), fill=c + (a,))
        if rng.random() < 0.25: d.rectangle((x - s, y + s / 2 - 0.5, x + 2 * s, y + s / 2 + 0.5), fill=c + (a // 2,))

def make(key):
    get, main, sec, bgk = SUBJECTS[key]
    rng = random.Random(hash(key) & 0xffff)
    sprite = get()
    target_h = 440 if key not in ("titan", "spectre") else 420
    scale = max(1, round(target_h / sprite.height)) if key != "spectre" else 1
    if key == "spectre":   # arte já é grande e pintada: redimensiona suave
        f = 470 / sprite.width
        sprite = sprite.resize((int(sprite.width * f), int(sprite.height * f)), Image.LANCZOS); scale = 1
    img = stage(bgk, main, rng)
    img = hex_platform(img, main, sec)
    big, glow, edge = rim(sprite, scale, main, sec)
    foot = (int(W / 2 - big.width / 2), int(H * 0.86 - big.height + 8))
    # sombra no chão
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0)); ImageDraw.Draw(sh).ellipse((W / 2 - big.width * 0.38, H * 0.86 - 16, W / 2 + big.width * 0.38, H * 0.86 + 16), fill=(0, 0, 0, 150))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(6)))
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0)); layer.paste(glow, foot, glow); img = Image.alpha_composite(img, layer)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0)); layer.paste(big, foot, big); img = Image.alpha_composite(img, layer)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0)); layer.paste(edge, foot, edge); img = Image.alpha_composite(img, layer)
    particles(img, main, sec, rng)
    # faixa de luz no topo e moldura fina
    d = ImageDraw.Draw(img, "RGBA")
    d.rectangle((0, 0, W - 1, H - 1), outline=main + (120,), width=2)
    img.convert("RGB").save(OUT / f"{key}.png")
    print("wrote", key, big.size)

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for k in SUBJECTS: make(k)
