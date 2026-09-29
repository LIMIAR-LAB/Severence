"""Cenário 0.17 (Tarefa C) — variantes de parede, decals de chão e microbiomas novos.

Gera, com numpy+PIL, na mesma linguagem visual de make_props_hd.py
(contorno escuro, luz de cima-esquerda, rampas de cor):

  assets/environment/docks12/walls/{cult,abyssal,rail}/<tile>.png
      peles da fachada por ambiente (recolor + detalhe das peças docks12)
  assets/environment/docks12/decals/*.png
      manchas/rachaduras/algas/etc. planas, alpha, espalhadas por seed
  assets/environment/docks12/{depot,lighthouse,drydock,cellar,boss}/*.png
      pisos 64x64 e props dos microbiomas novos
  assets/environment/docks12/props/npc_fisherman.png
      pescador da sala de história (quest 0.17)

Uso: python tools/make_scenery_017.py   (prévia em art/scenery-017-preview.png)
"""
from pathlib import Path
import math, random
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/environment/docks12"
R = random.Random(17017)

class C:
    def __init__(s, w, h): s.w, s.h = w, h; s.a = np.zeros((h, w, 4), np.uint8)
    def px(s, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < s.w and 0 <= y < s.h: s.a[y, x] = c if len(c) == 4 else (*c, 255)
    def get(s, x, y): return tuple(s.a[int(y), int(x)]) if 0 <= x < s.w and 0 <= y < s.h else (0, 0, 0, 0)
    def rect(s, x0, y0, x1, y1, c):
        for y in range(int(y0), int(y1) + 1):
            for x in range(int(x0), int(x1) + 1): s.px(x, y, c)
    def ellipse(s, cx, cy, rx, ry, c, fill=True):
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                d = ((x - cx) / max(rx, .1)) ** 2 + ((y - cy) / max(ry, .1)) ** 2
                if (d <= 1 and fill) or (not fill and 0.75 <= d <= 1): s.px(x, y, c)
    def line(s, x0, y0, x1, y1, c):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1): s.px(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, c)
    def noise(s, amp, dens=1.0):
        for y in range(s.h):
            for x in range(s.w):
                if s.a[y, x, 3] and R.random() < dens:
                    k = R.randint(-amp, amp)
                    px = s.a[y, x].astype(int)
                    s.a[y, x, :3] = np.clip(px[:3] + k, 0, 255)
    def outline(s):
        op = s.a[..., 3] > 200
        g = op.copy(); g[1:] |= op[:-1]; g[:-1] |= op[1:]; g[:, 1:] |= op[:, :-1]; g[:, :-1] |= op[:, 1:]
        s.a[g & ~(s.a[..., 3] > 0)] = (20, 16, 26, 255)
    def save(s, path, outline=False):
        if outline: s.outline()
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.fromarray(s.a).save(path); print("wrote", path.relative_to(ROOT), (s.w, s.h))
        return s.a

def ramp(cols):
    """Interpola uma lista de cores em n tons."""
    return cols

def vramp(s, x0, y0, x1, y1, cols):
    for y in range(int(y0), int(y1) + 1):
        t = 0 if y1 == y0 else (y - y0) / (y1 - y0)
        s.rect(x0, y, x1, y, cols[min(len(cols) - 1, int(t * len(cols)))])

# ------------------------------------------------------------------ peles de parede
WALL_TILES = ["wall_cap_0", "wall_cap_1", "wall_cap_2", "wall_cap_3", "wall_cap_4",
              "brick_base", "brick_base2", "brick_damaged", "brick_hole", "brick_pipe", "brick_window",
              "wall_base_0", "wall_base_1", "wall_base_2", "wall_base_3", "wall_base_4",
              "wall_corner_0", "wall_corner_1", "side_cap"]

def recolor(name, mul, speck=None, streaks=0, glyphs=False):
    src = np.array(Image.open(BASE / "tiles" / (name + ".png")).convert("RGBA")).astype(np.float32)
    a = src.copy()
    lum = a[..., :3].mean(-1, keepdims=True)
    a[..., :3] = np.clip(a[..., :3] * np.array(mul), 0, 255)
    out = a.astype(np.uint8)
    h, w = out.shape[:2]
    if speck:   # cracas/musgo: pontos claros/escuros por cima
        for _ in range(int(w * h * speck[1])):
            x, y = R.randrange(w), R.randrange(h)
            if out[y, x, 3] > 0: out[y, x, :3] = speck[0]
    if streaks:  # infiltração: listras verticais escuras descendo do topo
        for _ in range(streaks):
            x = R.randrange(w); ln = R.randrange(h // 3, h)
            for y in range(ln):
                if out[y, x, 3] > 0:
                    out[y, x, :3] = (out[y, x, :3] * 0.72).astype(np.uint8)
    if glyphs and "brick" in name:   # runas do culto gravadas no tijolo
        for _ in range(2):
            x0, y0 = R.randrange(8, max(9, w - 24)), R.randrange(8, max(9, h - 20))
            for k in range(6):
                x, y = x0 + k * 3, y0 + (k % 3) * 4
                if out[y, x, 3] > 0: out[y, x, :3] = (96, 190, 150)
    return Image.fromarray(out)

def wall_sets():
    sets = {
        # culto: pedra fria escura arroxeada, runas verdes esmaecidas
        "cult": ((0.60, 0.55, 0.74), {"speck": ((70, 60, 92), 0.03), "glyphs": True}),
        # abissal: pedra molhada azul-esverdeada, cracas, infiltração
        "abyssal": ((0.52, 0.66, 0.70), {"speck": ((150, 170, 160), 0.02), "streaks": 4}),
        # rail: concreto/ferro de obra — dessaturado e mais claro
        "rail": ((0.88, 0.86, 0.84), {"speck": ((90, 88, 96), 0.02)}),
    }
    for sname, (mul, fx) in sets.items():
        for t in WALL_TILES:
            img = recolor(t, mul, speck=fx.get("speck"), streaks=fx.get("streaks", 0), glyphs=fx.get("glyphs", False))
            out = BASE / "walls" / sname / (t + ".png")
            out.parent.mkdir(parents=True, exist_ok=True)
            img.save(out)
        print("wall set", sname)

# ------------------------------------------------------------------ decals de chão (alpha, planos)
def decal_stain(name, cols, n=5, w=96, h=64):
    s = C(w, h)
    for i in range(n):
        cx, cy = R.uniform(w * .25, w * .75), R.uniform(h * .25, h * .75)
        rx, ry = R.uniform(10, w * .3), R.uniform(6, h * .3)
        c = cols[i % len(cols)]
        s.ellipse(cx, cy, rx, ry, (*c, R.randint(50, 90)))
    return s

def decal_crack(name, w=96, h=64, branches=3):
    s = C(w, h)
    for i in range(branches):
        x, y = R.uniform(8, w * .5), R.uniform(h * .4, h * .6)
        ang = R.uniform(0, TAU)
        for step in range(R.randint(10, 22)):
            x += math.cos(ang) * R.uniform(2, 5); y += math.sin(ang) * R.uniform(1.5, 4)
            ang += R.uniform(-0.7, 0.7)
            s.px(x, y, (18, 16, 20, 190)); s.px(x, y + 1, (18, 16, 20, 120))
    return s

def decal_scorch(w=80, h=56):
    s = C(w, h)
    yy, xx = np.mgrid[0:h, 0:w]
    d = np.sqrt(((xx - w / 2) / (w / 2)) ** 2 + ((yy - h / 2) / (h / 2)) ** 2)
    s.a[..., 3] = np.clip((1 - d) * 160, 0, 255).astype(np.uint8)
    s.a[..., :3] = 16
    return s

def decal_algae(w=96, h=64):
    s = C(w, h)
    for i in range(8):
        cx, cy = R.uniform(8, w - 8), R.uniform(8, h - 8)
        s.ellipse(cx, cy, R.uniform(3, 12), R.uniform(2, 6), (40 + R.randint(0, 30), 80 + R.randint(0, 40), 50, R.randint(60, 110)))
    return s

def decal_fishbones(w=64, h=32):
    s = C(w, h)
    bone = (205, 200, 185, 220)
    s.line(10, h // 2, w - 16, h // 2, bone)
    for i in range(5):
        x = 14 + i * 8
        s.line(x, h // 2, x - 4, h // 2 - 7, bone); s.line(x, h // 2, x - 4, h // 2 + 7, bone)
    s.ellipse(w - 12, h // 2, 6, 5, bone)
    s.px(w - 13, h // 2 - 1, (20, 16, 26, 255))
    return s

def decal_glyph(w=96, h=96):
    """Runa de giz do culto: círculo, olho e tentáculos."""
    s = C(w, h)
    chalk = (140, 220, 180, 200)
    s.ellipse(w / 2, h / 2, 34, 22, chalk, fill=False)
    s.ellipse(w / 2, h / 2, 8, 6, chalk, fill=False)
    for k in range(6):
        a = k * TAU / 6 + 0.4
        x0, y0 = w / 2 + math.cos(a) * 34, h / 2 + math.sin(a) * 22
        s.line(x0, y0, x0 + math.cos(a) * 16, y0 + math.sin(a) * 12 + 4, (*chalk[:3], 150))
    return s

def decal_planks_loose(w=96, h=48):
    s = C(w, h)
    wood = [(150, 100, 60, 230), (120, 76, 44, 230), (96, 60, 36, 230)]
    for i, (x, y, ang) in enumerate([(10, 12, 0.12), (36, 20, -0.2), (60, 8, 0.3)]):
        L, W = R.randint(24, 40), 9
        ca, sa = math.cos(ang), math.sin(ang)
        for dx in range(L):
            for dy in range(W):
                s.px(x + dx * ca - dy * sa, y + dx * sa + dy * ca, wood[(dy + i) % 3])
    return s

TAU = math.tau

def decals():
    out = BASE / "decals"
    decal_stain("x", [(16, 14, 18), (24, 20, 26)]).save(out / "stain_oil.png")
    decal_stain("x", [(20, 34, 48), (16, 28, 40)], n=6).save(out / "stain_water.png")
    decal_crack("x").save(out / "crack_a.png")
    decal_crack("x", w=128, h=80, branches=5).save(out / "crack_b.png")
    decal_scorch().save(out / "scorch.png")
    decal_algae().save(out / "algae.png")
    decal_fishbones().save(out / "fishbones.png")
    decal_glyph().save(out / "glyph_chalk.png")
    decal_planks_loose().save(out / "planks_loose.png")
    decal_stain("x", [(90, 60, 30), (70, 48, 26)], n=4).save(out / "rust_stain.png")

# ------------------------------------------------------------------ pisos de microbioma (64x64)
def concrete(cols, joint=(40, 40, 44), rivets=True):
    s = C(64, 64)
    vramp(s, 0, 0, 63, 63, cols)
    s.rect(0, 0, 63, 1, joint); s.rect(0, 62, 63, 63, joint)
    s.rect(0, 0, 1, 63, joint); s.rect(62, 0, 63, 63, joint)
    if rivets:
        for x in (10, 54):
            for y in (10, 54):
                s.px(x, y, tuple(min(255, v + 40) for v in joint)); s.px(x + 1, y + 1, (30, 30, 34))
    s.noise(14)
    return s

def planks(cols, gap=(30, 22, 18)):
    s = C(64, 64)
    for b in range(4):
        y0, y1 = b * 16, b * 16 + 15
        vramp(s, 0, y0, 63, y1, cols)
        s.rect(0, y1, 63, y1, gap)
        for x in range(4, 60, 14):
            if R.random() < 0.6: s.line(x, y0 + 3, x + R.randint(4, 12), y0 + R.randint(3, 10), (cols[2][0] - 12, cols[2][1] - 12, cols[2][2] - 12))
    s.noise(12)
    return s

def floor_depot():
    d = BASE / "depot"
    concrete([(120, 120, 126), (104, 104, 110), (88, 88, 96)]).save(d / "depot_floor_a.png")
    concrete([(96, 96, 104), (82, 82, 90), (70, 70, 78)]).save(d / "depot_floor_b.png")
    s = concrete([(110, 110, 118), (96, 96, 104), (80, 80, 88)])
    s.ellipse(34, 34, 20, 12, (14, 14, 18, 160)); s.ellipse(30, 30, 8, 5, (40, 40, 48, 120))
    s.save(d / "depot_floor_oil.png")
    s = concrete([(112, 112, 120), (98, 98, 106), (84, 84, 92)])
    for k in range(-64, 128, 16):   # faixa de advertência diagonal no rodapé
        for i in range(6):
            for x in range(int(k + i * 8), int(k + i * 8 + 8)):
                y = 52 + i
                s.px(x, y, (190, 160, 40) if (x - k) // 8 % 2 == 0 else (40, 40, 44))
    s.save(d / "depot_floor_stripe.png")

def floor_lighthouse():
    d = BASE / "lighthouse"
    concrete([(150, 146, 138), (132, 128, 122), (114, 110, 106)], joint=(70, 66, 62)).save(d / "light_floor_a.png")
    s = concrete([(146, 142, 134), (128, 124, 118), (110, 106, 102)], joint=(70, 66, 62))
    s.ellipse(32, 32, 24, 24, (88, 84, 80), fill=False)
    for k in range(8):
        a = k * TAU / 8
        s.line(32 + math.cos(a) * 18, 32 + math.sin(a) * 18, 32 + math.cos(a) * 26, 32 + math.sin(a) * 26, (84, 80, 76))
        s.px(32 + math.cos(a) * 24, 32 + math.sin(a) * 24, (60, 56, 54))
    s.ellipse(32, 32, 6, 6, (88, 84, 80), fill=False)
    s.save(d / "light_floor_gear.png")
    s = concrete([(140, 136, 128), (124, 120, 114), (106, 102, 98)], joint=(70, 66, 62))
    s.rect(0, 28, 63, 30, (58, 52, 48)); s.rect(0, 34, 63, 36, (58, 52, 48))
    s.rect(0, 29, 63, 29, (110, 100, 88)); s.rect(0, 34, 63, 34, (110, 100, 88))
    for x in range(4, 64, 12): s.rect(x, 27, x + 3, 37, (66, 52, 40))
    s.save(d / "light_floor_rail.png")

def floor_drydock():
    d = BASE / "drydock"
    concrete([(96, 100, 110), (82, 86, 96), (68, 72, 82)], joint=(44, 46, 54)).save(d / "dock_floor_steel.png")
    s = concrete([(100, 96, 90), (86, 82, 78), (72, 68, 66)], joint=(48, 44, 42))
    for _ in range(7):
        s.ellipse(R.uniform(6, 58), R.uniform(6, 58), R.uniform(2, 7), R.uniform(1, 4), (110, 70, 40, R.randint(90, 140)))
    s.save(d / "dock_floor_rust.png")
    s = concrete([(92, 96, 104), (80, 84, 92), (68, 70, 78)], joint=(44, 46, 54))
    s.rect(0, 6, 63, 18, (34, 30, 30)); s.rect(0, 8, 63, 16, (50, 40, 34))   # sombra da costela do navio
    s.save(d / "dock_floor_rib.png")

def floor_cellar():
    d = BASE / "cellar"
    dark = [(96, 70, 46), (80, 58, 38), (64, 46, 30), (50, 36, 24)]
    s = planks(dark)
    for _ in range(14):
        x, y = R.randrange(64), R.randrange(64)
        s.px(x, y, (120, 160, 190)); s.px(x + 1, y, (90, 130, 160))
    s.save(d / "cellar_floor_wet.png")
    s = planks(dark)
    for _ in range(6):
        s.ellipse(R.uniform(8, 56), R.uniform(8, 56), R.uniform(3, 9), R.uniform(2, 4), (52, 88, 50, 150))
    s.save(d / "cellar_floor_moss.png")
    s = planks(dark)
    s.rect(18, 20, 44, 40, (14, 16, 22)); s.rect(20, 22, 42, 38, (8, 10, 16))
    for x in range(18, 45): s.px(x, 20, (30, 22, 16)); s.px(x, 40, (30, 22, 16))
    s.save(d / "cellar_floor_broken.png")

def floor_boss():
    d = BASE / "boss"
    basalt = [(64, 60, 78), (52, 48, 66), (42, 38, 54)]
    s = concrete(basalt, joint=(26, 24, 36), rivets=False)
    s.save(d / "boss_floor_stone.png")
    s = concrete(basalt, joint=(26, 24, 36), rivets=False)
    s.ellipse(32, 32, 20, 20, (26, 22, 40), fill=False)
    s.ellipse(32, 32, 14, 14, (60, 200, 190, 60))
    for k in range(5):   # glifo de tentáculo entalhado, brilho esverdeado
        a = k * TAU / 5 - PI / 2
        x0, y0 = 32 + math.cos(a) * 8, 32 + math.sin(a) * 8
        s.line(x0, y0, x0 + math.cos(a + 0.5) * 14, y0 + math.sin(a + 0.5) * 14, (70, 190, 170))
        s.line(x0 + math.cos(a + 0.5) * 14, y0 + math.sin(a + 0.5) * 14,
               x0 + math.cos(a + 1.1) * 18, y0 + math.sin(a + 1.1) * 18, (50, 150, 135))
    s.save(d / "boss_floor_glyph.png")
    s = concrete(basalt, joint=(26, 24, 36), rivets=False)
    s.line(8, 10, 30, 34, (16, 14, 26)); s.line(30, 34, 52, 30, (16, 14, 26))
    s.line(30, 34, 38, 56, (16, 14, 26)); s.line(30, 34, 20, 44, (20, 18, 30))
    s.save(d / "boss_floor_crack.png")

PI = math.pi

# ------------------------------------------------------------------ props novos
def prop_depot_shells():
    s = C(64, 40)
    for i, (x, y) in enumerate([(10, 30), (24, 32), (38, 30), (52, 32), (17, 20), (31, 22), (45, 20), (24, 10), (38, 12)]):
        s.rect(x - 5, y - 8, x + 5, y, (140, 120, 60) if i % 2 else (170, 150, 75))
        s.rect(x - 5, y - 8, x - 3, y, (190, 170, 95)); s.rect(x - 5, y - 4, x + 5, y - 2, (70, 60, 40))
        s.ellipse(x, y - 8, 5, 2.5, (60, 50, 34))
    s.save(BASE / "depot/depot_shells.png", outline=True)

def prop_depot_sign():
    s = C(48, 72)
    s.rect(21, 30, 26, 66, (70, 64, 58)); s.rect(21, 30, 23, 66, (110, 104, 96))
    for i in range(18):   # triângulo de advertência
        w = i
        s.rect(24 - w / 2, 8 + i, 24 + w / 2, 8 + i, (200, 170, 50))
    s.rect(23, 14, 25, 22, (30, 28, 30)); s.rect(23, 25, 25, 26, (30, 28, 30))
    s.save(BASE / "depot/depot_sign.png", outline=True)

def prop_dock_scaffold():
    s = C(96, 96)
    iron = (88, 82, 78); light = (130, 124, 116)
    for x in (8, 48, 88):
        s.rect(x - 2, 8, x + 2, 92, iron); s.rect(x - 2, 8, x, 92, light)
    for y in (16, 50, 84):
        s.rect(8, y, 88, y + 3, iron); s.rect(8, y, 88, y + 1, light)
    s.line(10, 18, 46, 48, iron); s.line(88, 18, 50, 48, iron)
    s.rect(6, 4, 90, 10, (110, 90, 60)); s.rect(6, 4, 90, 6, (140, 116, 78))
    s.save(BASE / "drydock/dock_scaffold.png", outline=True)

def prop_dock_chain():
    s = C(64, 32)
    for i in range(9):
        x = 6 + i * 6
        s.ellipse(x, 16 + (i % 3) * 4, 6, 3.5, (70, 72, 80), fill=False)
        s.ellipse(x, 16 + (i % 3) * 4, 5, 2.5, (110, 114, 124), fill=False)
    s.save(BASE / "drydock/dock_chain.png", outline=True)

def prop_cellar_float():
    s = C(64, 32)
    s.rect(6, 14, 40, 22, (110, 76, 46)); s.rect(6, 14, 40, 16, (140, 98, 60))
    s.line(10, 15, 36, 15, (90, 60, 36))
    s.rect(46, 8, 54, 26, (60, 90, 70)); s.rect(48, 6, 52, 10, (80, 110, 90))
    s.ellipse(48, 20, 4, 6, (40, 60, 48))
    s.save(BASE / "cellar/cellar_float.png", outline=True)

def prop_boss_skull_pile():
    s = C(64, 48)
    bone = (200, 192, 170); shade = (150, 142, 124)
    for x, y, r in [(18, 36, 9), (38, 38, 8), (28, 26, 9), (48, 30, 7), (12, 28, 6)]:
        s.ellipse(x, y - r * 0.7, r, r * 0.85, bone)
        s.rect(x - r * 0.6, y - 2, x + r * 0.6, y + 2, shade)
        s.px(x - r * 0.35, y - r * 0.75, (20, 16, 26)); s.px(x + r * 0.2, y - r * 0.75, (20, 16, 26))
        s.px(x - r * 0.15, y - r * 0.15, (20, 16, 26))
    s.save(BASE / "boss/boss_skull_pile.png", outline=True)

def prop_light_gear():
    s = C(80, 80)
    s.ellipse(40, 40, 30, 30, (120, 108, 92))
    s.ellipse(40, 40, 26, 26, (150, 136, 116))
    for k in range(10):
        a = k * TAU / 10
        x, y = 40 + math.cos(a) * 32, 40 + math.sin(a) * 32
        s.ellipse(x, y, 5, 5, (120, 108, 92)); s.ellipse(x - 1, y - 1, 4, 4, (150, 136, 116))
    s.ellipse(40, 40, 12, 12, (70, 62, 56)); s.ellipse(40, 40, 9, 9, (96, 88, 78))
    s.ellipse(40, 40, 3, 3, (40, 36, 34))
    s.save(BASE / "lighthouse/light_gear.png", outline=True)

def prop_npc_fisherman():
    """Pescador velho de capa de chuva — sprite do NPC da sala de história."""
    s = C(56, 92)
    skin = (196, 160, 128); coat = (58, 84, 88); coat_l = (76, 108, 112); dark = (34, 48, 52)
    s.rect(18, 30, 38, 78, dark)                    # capa (sombras)
    vramp(s, 20, 30, 36, 78, [coat_l, coat, dark])  # capa
    s.rect(19, 30, 21, 78, coat_l); s.rect(35, 30, 37, 78, dark)
    s.line(22, 42, 34, 42, dark); s.line(22, 56, 34, 56, dark)
    s.ellipse(28, 20, 11, 10, skin)                 # rosto
    s.rect(18, 10, 38, 16, (70, 84, 90))            # chapéu de chuva
    s.rect(14, 15, 42, 18, (60, 74, 80))
    s.px(24, 22, (20, 16, 26)); s.px(31, 22, (20, 16, 26))
    s.line(24, 28, 33, 29, (220, 220, 215))         # barba clara
    s.rect(40, 34, 46, 60, (90, 70, 40))            # lanterna na mão
    s.rect(41, 38, 45, 52, (230, 190, 90)); s.ellipse(43, 45, 3, 5, (255, 230, 140))
    s.rect(24, 78, 27, 86, (40, 34, 30)); s.rect(30, 78, 33, 86, (40, 34, 30))  # botas
    s.save(BASE / "props/npc_fisherman.png", outline=True)

# ------------------------------------------------------------------ prévia
def preview():
    thumbs = []
    for sub in ["depot", "lighthouse", "drydock", "cellar", "boss", "decals"]:
        d = BASE / sub
        for f in sorted(d.glob("*.png")): thumbs.append((sub + "/" + f.stem, f))
    cols = 8
    rows = math.ceil(len(thumbs) / cols)
    sheet = Image.new("RGBA", (cols * 100, rows * 116 + 20), (24, 22, 30, 255))
    from PIL import ImageDraw
    dr = ImageDraw.Draw(sheet)
    for i, (name, f) in enumerate(thumbs):
        img = Image.open(f).convert("RGBA")
        img.thumbnail((88, 88), Image.NEAREST)
        x, y = (i % cols) * 100 + 6, (i // cols) * 116 + 6
        sheet.paste(img, (x, y), img)
        dr.text((x, y + 92), name[:16], fill=(200, 190, 170, 255))
    p = ROOT / "art/scenery-017-preview.png"; sheet.save(p); print("preview", p)

if __name__ == "__main__":
    wall_sets()
    decals()
    floor_depot(); floor_lighthouse(); floor_drydock(); floor_cellar(); floor_boss()
    prop_depot_shells(); prop_depot_sign(); prop_dock_scaffold(); prop_dock_chain()
    prop_cellar_float(); prop_boss_skull_pile(); prop_light_gear(); prop_npc_fisherman()
    preview()
    print("OK — scenery 0.17")
