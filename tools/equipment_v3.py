"""0.16: fundo estático da tela de EQUIPAMENTO v3 (layout do mockup art/concept/equipamento-v3-mockup.png).

Molduras de metal escovado com friso de bronze e rebites, miolo azul-petróleo com trilhas de circuito,
palco com borda ciano. Tudo que muda (sprites, textos vivos, seleção, status) é Control no jogo
(scripts/terminal_ui.gd, build_equipment). As caixas daqui e as de terminal_ui.gd usam as MESMAS
coordenadas (espaço de desenho 1344x752) — mexeu numa, mexa na outra.

Saída: assets/ui/equipment_v3.png (1344x752). Uso: python3 tools/equipment_v3.py
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
S = 2                                   # desenha em 2x e reduz (bordas limpas)
W, H = 1344 * S, 752 * S

FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
FONT_R = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf"
def font(size, bold=True): return ImageFont.truetype(FONT_B if bold else FONT_R, size * S)

CYAN = (84, 232, 245); GOLD = (232, 190, 110); BRASS = (176, 132, 70); BRASS_L = (226, 184, 110)
INK = (5, 10, 14); FILL = (12, 32, 40); FILL_D = (8, 20, 26); TEXT = (226, 232, 220); DIM = (120, 150, 150)
GREEN = (120, 210, 90); RED = (230, 70, 80)

# ── layout (px no espaço 1344x752) — espelhado em terminal_ui.gd
HEADER = (16, 14, 1312, 42)
UNIFORM = (16, 66, 302, 374); UNIFORM_CARDS = [(29, 113 + i * 101, 277, 86) for i in range(3)]
ARMOR = (16, 452, 302, 172); ARMOR_CARDS = [(28 + i * 96, 496, 86, 118) for i in range(3)]
BACK = (16, 634, 302, 48)
STAGE = (322, 66, 704, 456)
ROBOT = (322, 532, 704, 150); ROBOT_TAG = (338, 544, 100, 24)
ROBOT_CARDS = [(338, 580, 250, 90), (602, 580, 250, 90), (866, 580, 146, 90)]
STATUS = (1042, 66, 286, 258)
INFO = (1042, 334, 286, 238)
REFUGE = (1042, 582, 286, 48); ARENA = (1042, 636, 286, 46)
FOOTER = (16, 694, 1312, 44)


def R(x, y, w, h): return (x * S, y * S, (x + w) * S, (y + h) * S)


def text(d, xy, s, size=16, color=TEXT, bold=True, anchor="la"):
    d.text((xy[0] * S, xy[1] * S), s, font=font(size, bold), fill=color, anchor=anchor)


def metal_strip(w, h):
    """Metal escovado: degradê vertical claro→escuro com riscos horizontais finos."""
    y = np.linspace(0, 1, h)[:, None]
    base = np.array([168, 176, 182]) * (1 - y[..., None]) + np.array([66, 72, 78]) * y[..., None]
    rng = np.random.default_rng(1941)
    streaks = rng.normal(0, 7, (h, 1, 1)) + rng.normal(0, 3, (h, w, 1))
    a = np.clip(np.broadcast_to(base, (h, w, 3)) + streaks, 0, 255).astype(np.uint8)
    return Image.fromarray(a, "RGB").convert("RGBA")


def rivet(d, cx, cy, r=3):
    d.ellipse((cx - r * S, cy - r * S, cx + r * S, cy + r * S), fill=(60, 44, 20))
    d.ellipse((cx - (r - 1) * S, cy - (r - 1) * S, cx + (r - 1) * S, cy + (r - 1) * S), fill=BRASS_L)
    d.point((cx - S, cy - S), fill=(255, 240, 200))


def plate(img, box, fill=FILL, band=9, edge=None):
    """Painel grande: moldura de metal escovado + friso de bronze + rebites; miolo escuro."""
    x, y, w, h = box
    d = ImageDraw.Draw(img)
    d.rectangle(R(x - 2, y - 2, w + 4, h + 4), fill=INK)
    img.alpha_composite(metal_strip(w * S, h * S), (x * S, y * S))
    d = ImageDraw.Draw(img)
    d.rectangle(R(x, y, w, h), outline=(30, 34, 38), width=S)
    d.rectangle(R(x + band - 2, y + band - 2, w - 2 * band + 4, h - 2 * band + 4), fill=(40, 30, 16))
    d.rectangle(R(x + band - 1, y + band - 1, w - 2 * band + 2, h - 2 * band + 2), outline=edge or BRASS, width=S)
    # miolo com leve degradê
    inner = Image.new("RGBA", ((w - 2 * band) * S, (h - 2 * band) * S))
    ia = np.zeros((inner.height, inner.width, 4), np.uint8)
    t = np.linspace(0, 1, inner.height)[:, None]
    for c in range(3): ia[..., c] = (fill[c] * (1.12 - 0.3 * t)).clip(0, 255).astype(np.uint8)
    ia[..., 3] = 255
    img.alpha_composite(Image.fromarray(ia, "RGBA"), ((x + band) * S, (y + band) * S))
    d = ImageDraw.Draw(img)
    for cx, cy in [(x + 4, y + 4), (x + w - 4, y + 4), (x + 4, y + h - 4), (x + w - 4, y + h - 4)]:
        rivet(d, cx * S, cy * S, 3)
    return d


def slot(img, box, fill=FILL, edge=BRASS, locked=False):
    """Cartão interno: borda de bronze fina, cantoneiras e miolo escuro."""
    x, y, w, h = box
    d = ImageDraw.Draw(img)
    d.rectangle(R(x, y, w, h), fill=INK)
    d.rectangle(R(x + 2, y + 2, w - 4, h - 4), fill=FILL_D if locked else fill, outline=edge, width=2 * S)
    for cx, cy in [(x + 5, y + 5), (x + w - 5, y + 5), (x + 5, y + h - 5), (x + w - 5, y + h - 5)]:
        rivet(d, cx * S, cy * S, 2)
    if locked:
        text(d, (x + w / 2, y + h / 2 - 6), "?", 36, (58, 78, 84), anchor="mm")
    return d


def circuit(img, x, y, w, h, seed):
    """Trilhas de circuito ciano, fracas, no canto de um painel."""
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rng = np.random.default_rng(seed)
    for i in range(5):
        yy = y + 6 + i * (h - 12) / 4
        xx = x + rng.integers(0, max(1, w // 3))
        pts = [(xx, yy)]
        run = rng.integers(w // 4, w // 2)
        pts.append((xx + run, yy))
        step = rng.choice([-1, 1]) * rng.integers(4, 10)
        pts.append((xx + run + abs(step), yy + step))
        pts.append((min(x + w, xx + run + abs(step) + rng.integers(20, 80)), yy + step))
        d.line([(px * S, py * S) for px, py in pts], fill=(84, 232, 245, 70), width=S)
        ex, ey = pts[-1]
        d.ellipse(R(ex - 2, ey - 2, 4, 4), outline=(84, 232, 245, 120), width=S)
    img.alpha_composite(layer)


def glow(img, box, color, radius=10):
    x, y, w, h = box
    g = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).rectangle(R(x, y, w, h), outline=color + (210,), width=4 * S)
    img.alpha_composite(g.filter(ImageFilter.GaussianBlur(radius * S)))


def backdrop():
    yy, xx = np.mgrid[0:H, 0:W]
    a = np.zeros((H, W, 3), np.float32) + np.array([9, 15, 20]) / 255
    a += (((xx // (224 * S)) % 2) * 0.012)[..., None]                       # chapas
    a += ((xx % (224 * S) < 2 * S) * 0.05)[..., None] * np.array([0.5, 0.6, 0.6])   # emendas
    r = np.sqrt(((xx - W / 2) / W) ** 2 + ((yy - H * 0.45) / H) ** 2)
    a += (np.clip(0.55 - r, 0, 1) * 0.10)[..., None] * np.array([0.3, 0.8, 0.9])
    img = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(img)
    for y in (60, 446, 628, 688):                                             # canos atrás dos painéis
        d.rectangle(R(0, y, 1344, 6), fill=(24, 32, 36)); d.rectangle(R(0, y, 1344, 1), fill=(64, 76, 78))
    return img


def keycap(d, x, y, k, label):
    d.rounded_rectangle(R(x, y, 26, 26), radius=5 * S, fill=(30, 40, 46), outline=(150, 170, 170), width=2 * S)
    text(d, (x + 13, y + 13), k, 14, TEXT, anchor="mm")
    text(d, (x + 34, y + 13), label, 13, (190, 200, 196), False, anchor="lm")
    return x + 40 + int(font(13, False).getlength(label) / S) + 20


def build():
    img = backdrop()
    # topo
    d = plate(img, HEADER, fill=(8, 22, 28), band=5)
    text(d, (34, 35), "EQUIPAMENTO", 22, GOLD, anchor="lm")
    text(d, (212, 35), "DOCAS DE 1941  •  escolha antes de ir ao Refúgio", 13, DIM, False, anchor="lm")
    # uniforme
    d = plate(img, UNIFORM)
    text(d, (36, 94), "UNIFORME", 18, GOLD, anchor="lm"); text(d, (304, 94), "skin • sempre ativa", 11, DIM, False, anchor="rm")
    circuit(img, 30, 412, 270, 20, 3)
    for b in UNIFORM_CARDS: slot(img, b)
    # armadura: 1ª vaga lendária (dourada), 2 bloqueadas
    d = plate(img, ARMOR)
    text(d, (36, 478), "ARMADURA", 18, GOLD, anchor="lm"); text(d, (304, 478), "R • 5s / recarga 60s", 11, DIM, False, anchor="rm")
    glow(img, ARMOR_CARDS[0], (255, 200, 80), 6)
    slot(img, ARMOR_CARDS[0], fill=(52, 38, 12), edge=(255, 205, 90))
    for b in ARMOR_CARDS[1:]:
        d = slot(img, b, locked=True)
        text(d, (b[0] + b[2] / 2, b[1] + b[3] - 12), "BLOQUEADA", 9, (70, 90, 96), anchor="mm")
    # voltar (o botão real fica por cima, transparente)
    plate(img, BACK, fill=(22, 18, 12), band=5)
    # palco
    glow(img, STAGE, CYAN, 8)
    d = plate(img, STAGE, fill=INK, edge=CYAN)
    sx, sy, sw, sh = STAGE
    d.rectangle(R(sx + 6, sy + 6, sw - 12, sh - 12), outline=CYAN, width=2 * S)
    for cx, cy, dx, dy in [(sx + 10, sy + 10, 1, 1), (sx + sw - 10, sy + 10, -1, 1), (sx + 10, sy + sh - 10, 1, -1), (sx + sw - 10, sy + sh - 10, -1, -1)]:
        d.line([((cx) * S, (cy + dy * 18) * S), (cx * S, cy * S), ((cx + dx * 18) * S, cy * S)], fill=(180, 250, 255), width=3 * S)
    # robôs (Titan, Spectre, vaga bloqueada)
    d = plate(img, ROBOT)
    tx, ty, tw, th = ROBOT_TAG
    d.rectangle(R(tx, ty, tw, th), fill=(46, 34, 14), outline=GOLD, width=2 * S)
    text(d, (tx + tw / 2, ty + th / 2), "ROBÔ", 15, GOLD, anchor="mm")
    text(d, (450, 556), "C invoca / recolhe • só um por vez", 11, DIM, False, anchor="lm")
    circuit(img, 760, 540, 250, 30, 11)
    slot(img, ROBOT_CARDS[0]); slot(img, ROBOT_CARDS[1]); slot(img, ROBOT_CARDS[2], locked=True)
    # status + descrições
    d = plate(img, STATUS)
    text(d, (1062, 94), "STATUS", 18, GOLD, anchor="lm")
    d = plate(img, INFO)
    for i in range(3):
        y = 348 + i * 74
        d.rectangle(R(1056, y, 60, 66), fill=(6, 18, 24), outline=(44, 74, 80), width=S)
        if i < 2: d.line((1056 * S, (y + 70) * S, 1314 * S, (y + 70) * S), fill=(40, 60, 66), width=S)
    # botões (os reais ficam por cima)
    plate(img, REFUGE, fill=(8, 40, 50), band=5, edge=CYAN)
    plate(img, ARENA, fill=(30, 18, 10), band=5)
    # rodapé
    d = plate(img, FOOTER, fill=(6, 16, 20), band=5)
    x = 34
    for k, lab in [("R", "vestir armadura"), ("C", "invocar/recolher robô"), ("E", "pilotar Titan"), ("G", "fundir Spectre")]:
        x = keycap(d, x, 703, k, lab)
    text(d, (744, 716), "CONTROLE", 12, DIM, anchor="lm")
    x = 820
    for k, lab, c in [("A", "selecionar", GREEN), ("B", "voltar", RED), ("LB", "", GOLD), ("RB", "trocar", GOLD), ("✚", "navegar", TEXT)]:
        wb = 26 if len(k) == 1 else 34
        if len(k) == 1: d.ellipse(R(x, 703, wb, 26), fill=(30, 40, 46), outline=c, width=2 * S)
        else: d.rounded_rectangle(R(x, 705, wb, 22), radius=6 * S, fill=(30, 40, 46), outline=c, width=2 * S)
        text(d, (x + wb / 2, 716), k, 12, c, anchor="mm")
        if lab: text(d, (x + wb + 8, 716), lab, 13, (190, 200, 196), False, anchor="lm"); x += wb + 16 + int(font(13, False).getlength(lab) / S) + 10
        else: x += wb + 6
    out = ROOT / "assets/ui/equipment_v3.png"
    img.convert("RGB").resize((1344, 752), Image.LANCZOS).save(out)
    print("wrote", out)


if __name__ == "__main__":
    build()
