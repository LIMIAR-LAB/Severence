"""Retratos de vitrine da tela de EQUIPAMENTO (personagem grande no meio).

Fonte: art/source/portraits-toriyama-v1.png — folha 3x2 gerada a partir de art/source/portraits-toriyama-prompt.txt
(homenagem ao traço de Akira Toriyama), fundo branco. Este script recorta cada figura, remove o branco com
bordas suaves e monta um cenário próprio para cada uma usando as ilustrações do jogo:

  Padrão    → cais noturno com holofotes (menu)          Ômega   → céu partido por raios e o monstro (menu)
  Mecânico  → oficina do Refúgio (refuge-reference)       Titan   → porto em guerra, navios e relâmpagos (adventure)
  Espião    → rua de Londres com garoa e névoa (online)   Spectre → céu cósmico dos tentáculos, tons violeta (menu)

Saída: assets/ui/portraits/<chave>.png (738x610). Uso: python tools/make_portraits.py
"""
from pathlib import Path
import math, random
import numpy as np
from PIL import Image, ImageFilter, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/source/portraits-toriyama-v1.png"
OUT = ROOT / "assets/ui/portraits"
W, H = 738, 610

# recortes na folha (x0, y0, x1, y1)
CELLS = {"o_padrao": (0, 0, 372, 388), "o_mecanico": (372, 0, 750, 390), "o_espiao": (750, 0, 1168, 392),
         "armor_omega": (0, 388, 372, 784), "titan": (372, 390, 750, 784), "spectre": (750, 392, 1168, 784)}

# cenário: (arquivo, recorte, desfoque, brilho, cor de contraluz, cor de tom, partículas)
SCENES = {
    "o_padrao": ("assets/ui/menu.png", (1070, 200, 1344, 520), 2.5, 0.75, (90, 220, 255), (0.85, 0.95, 1.1), "embers"),
    "o_mecanico": ("art/source/refuge-reference.png", (40, 60, 560, 390), 2.5, 0.72, (255, 160, 60), (1.12, 0.95, 0.8), "sparks"),
    "o_espiao": ("assets/ui/online.png", (0, 150, 360, 560), 2.5, 0.6, (230, 60, 70), (0.8, 0.85, 1.15), "rain"),
    "armor_omega": ("assets/ui/menu.png", (620, 0, 1190, 400), 1.8, 0.8, (110, 225, 255), (0.95, 1.0, 1.15), "energy"),
    "titan": ("assets/ui/adventure.png", (960, 160, 1344, 560), 2.5, 0.7, (255, 150, 60), (1.05, 1.0, 0.9), "embers"),
    "spectre": ("assets/ui/menu.png", (730, 0, 1160, 330), 2.0, 0.7, (170, 90, 255), (1.0, 0.8, 1.25), "spores"),
}

def cutout(box):
    im = Image.open(SRC).convert("RGB").crop(box)
    a = np.asarray(im).astype(np.int16)
    diff = (255 - a).sum(2)                       # 0 = branco puro
    bg = diff < 36
    h, w = bg.shape
    seen = np.zeros_like(bg)
    stack = [(y, 0) for y in range(h)] + [(y, w - 1) for y in range(h)] + [(0, x) for x in range(w)] + [(h - 1, x) for x in range(w)]
    while stack:
        y, x = stack.pop()
        if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or not bg[y, x]: continue
        seen[y, x] = True
        stack.extend(((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)))
    # buracos brancos fechados (entre pernas, braços, tentáculos) também são fundo, se forem grandes
    from scipy import ndimage
    lab, n = ndimage.label(bg & ~seen)
    sizes = ndimage.sum(np.ones_like(lab), lab, range(1, n + 1))
    for i, sz in enumerate(sizes, 1):
        if sz > 20: seen |= lab == i
    alpha = np.where(seen, 0, 255).astype(np.float32)
    # borda suave: pixels claros junto ao fundo ficam semitransparentes e perdem o "halo" branco
    near = np.asarray(Image.fromarray(seen.astype(np.uint8) * 255).filter(ImageFilter.MaxFilter(5))) > 0
    edge = near & ~seen
    k = np.clip(diff / 110.0, 0, 1)
    alpha[edge] = 255 * k[edge]
    rgb = a.astype(np.float32)
    ka = np.clip(alpha / 255.0, 0.05, 1)[..., None]
    rgb = np.where(edge[..., None], np.clip((rgb - 255 * (1 - ka)) / ka, 0, 255), rgb)   # remove o branco misturado
    out = Image.fromarray(np.dstack([rgb, alpha]).astype(np.uint8), "RGBA")
    return out.crop(out.getbbox())

def scene(key, rng):
    path, box, blur, bright, glowc, tone, _ = SCENES[key]
    bg = Image.open(ROOT / path).convert("RGB").crop(box)
    # preenche 738x610 mantendo proporção (corta o excesso)
    s = max(W / bg.width, H / bg.height)
    bg = bg.resize((math.ceil(bg.width * s), math.ceil(bg.height * s)), Image.LANCZOS)
    bg = bg.crop(((bg.width - W) // 2, (bg.height - H) // 2, (bg.width - W) // 2 + W, (bg.height - H) // 2 + H))
    bg = bg.filter(ImageFilter.GaussianBlur(blur))
    bg = ImageEnhance.Brightness(bg).enhance(bright)
    a = np.asarray(bg).astype(np.float32) / 255 * np.array(tone)
    yy, xx = np.mgrid[0:H, 0:W]
    cx, cy = W / 2, H * 0.48
    r = np.sqrt(((xx - cx) / W) ** 2 + ((yy - cy) / H) ** 2)
    g = np.array(glowc) / 255
    a += (np.clip(1 - r / 0.45, 0, 1) ** 2)[..., None] * g * 0.5            # contraluz
    ang = np.arctan2(yy - H * 0.42, xx - cx)
    a += ((0.5 + 0.5 * np.cos(ang * 7 + 0.4)) ** 8 * np.clip(1 - r / 0.75, 0, 1))[..., None] * g * 0.16   # raios
    a *= np.clip(1.3 - r * 1.35, 0, 1)[..., None]                               # vinheta
    # névoa no chão
    fog = np.clip((yy - H * 0.7) / (H * 0.3), 0, 1) ** 1.5
    a = a * (1 - fog[..., None] * 0.35) + fog[..., None] * np.array([0.1, 0.12, 0.18]) * 0.6
    return Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).convert("RGBA")

def particles(img, kind, glowc, rng, front):
    d = ImageDraw.Draw(img, "RGBA")
    n = {"rain": 140, "sparks": 40, "embers": 45, "energy": 55, "spores": 50}[kind] // (2 if front else 1)
    for _ in range(n):
        x = rng.uniform(0, W); y = rng.uniform(0, H)
        a = int(rng.uniform(70, 200) * (1.0 if front else 0.6))
        if kind == "rain":
            d.line((x, y, x - 4, y + 18), fill=(190, 205, 255, a // 2), width=1)
        elif kind == "sparks":
            l = rng.uniform(4, 10); ang = rng.uniform(-2.6, -0.5)
            d.line((x, y, x + math.cos(ang) * l, y + math.sin(ang) * l), fill=(255, 200, 90, a), width=2)
        elif kind == "embers":
            s = rng.choice([2, 3, 3, 4]); d.ellipse((x, y, x + s, y + s), fill=(255, 150 + rng.randint(0, 80), 60, a))
        elif kind == "energy":
            s = rng.choice([2, 3, 4]); c = glowc if rng.random() < 0.7 else (255, 215, 120)
            d.rectangle((x, y, x + s, y + s), fill=c + (a,))
        elif kind == "spores":
            s = rng.uniform(2, 5); d.ellipse((x, y, x + s, y + s), fill=(190, 140, 255, a) if rng.random() < 0.7 else (90, 230, 240, a))

def make(key):
    rng = random.Random(sum(map(ord, key)))
    fig = cutout(CELLS[key])
    target_h = 545
    f = min(target_h / fig.height, (W - 40) / fig.width)
    fig = fig.resize((int(fig.width * f), int(fig.height * f)), Image.LANCZOS)
    img = scene(key, rng)
    particles(img, SCENES[key][6], SCENES[key][4], rng, False)
    pos = ((W - fig.width) // 2, H - fig.height - 22)
    # sombra de contato sob a plataforma e brilho de contorno na cor do personagem
    sh = Image.new("RGBA", (W, H)); ImageDraw.Draw(sh).ellipse((W / 2 - fig.width * 0.42, H - 60, W / 2 + fig.width * 0.42, H - 8), fill=(0, 0, 0, 170))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(10)))
    al = fig.split()[3]
    glow = Image.new("RGBA", fig.size, SCENES[key][4] + (0,))
    glow.putalpha(al.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(10)).point(lambda v: int(v * 0.75)))
    layer = Image.new("RGBA", (W, H)); layer.paste(glow, pos, glow); img = Image.alpha_composite(img, layer)
    layer = Image.new("RGBA", (W, H)); layer.paste(fig, pos, fig); img = Image.alpha_composite(img, layer)
    particles(img, SCENES[key][6], SCENES[key][4], rng, True)
    ImageDraw.Draw(img, "RGBA").rectangle((0, 0, W - 1, H - 1), outline=SCENES[key][4] + (110,), width=2)
    img.convert("RGB").save(OUT / f"{key}.png")
    print("wrote", key, fig.size)

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for k in CELLS: make(k)
