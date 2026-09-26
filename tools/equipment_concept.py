"""Conceito da nova tela de EQUIPAMENTO (imagem estática para aprovação antes de implementar).

Usa os personagens da folha art/source/portraits-toriyama-v1.png (sem redesenhar ninguém) e os valores
reais do jogo (scripts/simulation.gd). Saída: art/concept/equipamento-v2-conceito.png (1344x752, 2x).
Uso: python tools/equipment_concept.py [padrao|mecanico|espiao|omega|titan|spectre]
"""
from pathlib import Path
import sys, math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import make_portraits as MP

S = 2                                   # desenha em 2x para ficar nítido
W, H = 1344 * S, 752 * S
OUT = ROOT / "art/concept"

FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf"
FONT_R = "/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed.ttf"
def font(size, bold=True): return ImageFont.truetype(FONT_B if bold else FONT_R, size * S)

CYAN = (84, 232, 245); CYAN_D = (20, 90, 104); GOLD = (232, 190, 110); BRASS = (150, 112, 60); BRASS_D = (74, 54, 30)
PANEL = (10, 30, 38); PANEL_2 = (14, 42, 52); INK = (6, 12, 16); TEXT = (226, 232, 220); DIM = (120, 150, 150)
ORANGE = (240, 138, 36); GREEN = (120, 210, 90); VIOLET = (170, 110, 255); RED = (230, 70, 80)

# valores reais do jogo (simulation.gd 0.13)
UNIFORMS = {
    "padrao": {"name": "PADRÃO", "sub": "equilibrado", "weapon": "BLASTER", "speed": 320, "melee": 26, "dmg": 16, "taken": 1.0, "dash": 0.6,
               "desc": "Equilibrado em tudo. Blaster de energia com cadência média."},
    "mecanico": {"name": "MECÂNICO", "sub": "+ força", "weapon": "ESCOPETA DE REBITE", "speed": 290, "melee": 46, "dmg": 54, "taken": 0.85, "dash": 0.7,
                 "desc": "Mais força e resistência. Chave inglesa pesada; mais lento."},
    "espiao": {"name": "ESPIÃO", "sub": "+ velocidade", "weapon": "SUBMETRALHADORA", "speed": 385, "melee": 20, "dmg": 7, "taken": 1.1, "dash": 0.35,
               "desc": "Rápido e discreto: inimigos só o notam de perto."},
}

def R(x, y, w, h): return (x * S, y * S, (x + w) * S, (y + h) * S)

def frame(d, box, sel=False, color=None, fill=PANEL):
    x0, y0, x1, y1 = box
    edge = color or (CYAN if sel else BRASS)
    d.rectangle(box, fill=INK)
    d.rectangle((x0 + 2 * S, y0 + 2 * S, x1 - 2 * S, y1 - 2 * S), fill=BRASS_D if not sel else CYAN_D)
    d.rectangle((x0 + 4 * S, y0 + 4 * S, x1 - 4 * S, y1 - 4 * S), fill=fill, outline=edge, width=2 * S)
    for (cx, cy) in [(x0 + 8 * S, y0 + 8 * S), (x1 - 8 * S, y0 + 8 * S), (x0 + 8 * S, y1 - 8 * S), (x1 - 8 * S, y1 - 8 * S)]:
        d.ellipse((cx - 3 * S, cy - 3 * S, cx + 3 * S, cy + 3 * S), fill=(200, 160, 90) if not sel else (180, 250, 255))

def glow_box(img, box, color, radius=14):
    g = Image.new("RGBA", img.size, (0, 0, 0, 0))
    ImageDraw.Draw(g).rectangle(box, outline=color + (200,), width=5 * S)
    g = g.filter(ImageFilter.GaussianBlur(radius))
    img.alpha_composite(g)

def text(d, xy, s, size=16, color=TEXT, bold=True, anchor="la"):
    d.text((xy[0] * S, xy[1] * S), s, font=font(size, bold), fill=color, anchor=anchor)

def tag(d, box, label, color, size=14):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=INK)
    d.rectangle((x0 + S, y0 + S, x1 - S, y1 - S), fill=tuple(int(c * 0.28) for c in color), outline=color, width=2 * S)
    d.text(((x0 + x1) / 2, (y0 + y1) / 2), label, font=font(size), fill=color, anchor="mm")

def keycap(d, x, y, k, label):
    d.rounded_rectangle(R(x, y, 26, 26), radius=5 * S, fill=(30, 40, 46), outline=(150, 170, 170), width=2 * S)
    text(d, (x + 13, y + 13), k, 14, TEXT, anchor="mm")
    text(d, (x + 34, y + 13), label, 13, (190, 200, 196), False, anchor="lm")
    return x + 40 + int(font(13, False).getlength(label) / S) + 20

def paste_fit(img, fig, box, anchor="bottom", pad=6):
    x0, y0, x1, y1 = box
    bw, bh = x1 - x0 - 2 * pad * S, y1 - y0 - 2 * pad * S
    f = min(bw / fig.width, bh / fig.height)
    fg = fig.resize((max(1, int(fig.width * f)), max(1, int(fig.height * f))), Image.LANCZOS)
    px = x0 + (x1 - x0 - fg.width) // 2
    py = y1 - pad * S - fg.height if anchor == "bottom" else y0 + (y1 - y0 - fg.height) // 2
    img.alpha_composite(fg, (px, py))

def bust(fig, top=0.0, bottom=0.55):
    """Recorte do busto (cabeça e ombros) para os cartões."""
    return fig.crop((0, int(fig.height * top), fig.width, int(fig.height * bottom)))

def backdrop():
    # parede de metal escura com canos e rebites (clima da oficina do Refúgio)
    a = np.zeros((H, W, 3), np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    a[...] = np.array([8, 16, 22]) / 255
    a += ((np.sin(xx / (46 * S)) > 0.96) * 0.05)[..., None] * np.array([0.3, 0.5, 0.5])
    a += (((yy // (24 * S)) % 2) * 0.012)[..., None]
    r = np.sqrt(((xx - W / 2) / W) ** 2 + ((yy - H * 0.45) / H) ** 2)
    a += (np.clip(0.55 - r, 0, 1) * 0.12)[..., None] * np.array([0.3, 0.8, 0.9])
    img = Image.fromarray((np.clip(a, 0, 1) * 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(img)
    for y in (140, 470, 640):
        d.rectangle(R(0, y, 1344, 10), fill=(22, 30, 34)); d.rectangle(R(0, y, 1344, 2), fill=(60, 72, 74))
    return img

def stage(key, sel_fig_key, box_w, box_h):
    """Cena do personagem (mesmo cenário dos retratos, no formato do palco)."""
    MP.W, MP.H = box_w, box_h
    rng = random.Random(7)
    sc = MP.scene(sel_fig_key, rng)
    MP.particles(sc, MP.SCENES[sel_fig_key][6], MP.SCENES[sel_fig_key][4], rng, False)
    fig = MP.cutout(MP.CELLS[sel_fig_key])
    th = int(box_h * 0.84)
    f = th / fig.height
    fig = fig.resize((int(fig.width * f), th), Image.LANCZOS)
    sh = Image.new("RGBA", sc.size); ImageDraw.Draw(sh).ellipse((box_w / 2 - fig.width * 0.45, box_h - 70 * S, box_w / 2 + fig.width * 0.45, box_h - 18 * S), fill=(0, 0, 0, 170))
    sc.alpha_composite(sh.filter(ImageFilter.GaussianBlur(10 * S)))
    al = fig.split()[3]
    gl = Image.new("RGBA", fig.size, MP.SCENES[sel_fig_key][4] + (0,))
    gl.putalpha(al.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(12 * S)).point(lambda v: int(v * 0.7)))
    pos = ((box_w - fig.width) // 2, box_h - fig.height - 30 * S)
    sc.alpha_composite(gl, pos); sc.alpha_composite(fig, pos)
    MP.particles(sc, MP.SCENES[sel_fig_key][6], MP.SCENES[sel_fig_key][4], rng, True)
    # faixa escura embaixo para a placa com o nome
    fade = Image.new("RGBA", sc.size)
    fd = ImageDraw.Draw(fade)
    for i in range(90 * S):
        fd.line((0, box_h - i, box_w, box_h - i), fill=(4, 10, 14, int(220 * (1 - i / (90 * S)))))
    sc.alpha_composite(fade)
    return sc

def bar(d, x, y, w, v, vmax, color):
    d.rectangle(R(x, y, w, 10), fill=(20, 32, 38), outline=(40, 60, 66), width=S)
    n = 12; seg = (w - 4) / n
    fill = round(n * min(1, v / vmax))
    for i in range(n):
        c = color if i < fill else (26, 44, 50)
        d.rectangle(R(x + 2 + i * seg, y + 2, seg - 2, 6), fill=c)

def heart(d, x, y, s, color):
    d.polygon([(x * S, (y + s * 0.3) * S), ((x + s * 0.5) * S, (y + s) * S), ((x + s) * S, (y + s * 0.3) * S),
               ((x + s * 0.75) * S, y * S), ((x + s * 0.5) * S, (y + s * 0.2) * S), ((x + s * 0.25) * S, y * S)], fill=color)

def build(selected="padrao"):
    cuts = {k: MP.cutout(b) for k, b in MP.CELLS.items()}
    img = backdrop()
    d = ImageDraw.Draw(img)
    key = "armor_omega" if selected == "omega" else (selected if selected in ("titan", "spectre") else "o_" + selected)
    u = UNIFORMS.get(selected if selected in UNIFORMS else "padrao")

    # ── topo: título e abas de jogador
    frame(d, R(16, 12, 1312, 44), fill=(8, 22, 28))
    text(d, (34, 34), "EQUIPAMENTO", 22, GOLD, anchor="lm")
    text(d, (226, 34), "DOCAS DE 1941  •  escolha antes de ir ao Refúgio", 13, DIM, False, anchor="lm")
    tag(d, R(1090, 20, 110, 28), "◀ MARTY ▶", CYAN, 13); tag(d, R(1208, 20, 104, 28), "ECHO (P2)", DIM, 13)

    # ── coluna esquerda: uniforme + armadura
    frame(d, R(16, 64, 340, 376))
    text(d, (36, 92), "UNIFORME", 18, GOLD, anchor="lm"); text(d, (324, 92), "skin • sempre ativa", 11, DIM, False, anchor="rm")
    for i, (k, uu) in enumerate(UNIFORMS.items()):
        y = 110 + i * 100
        sel = k == (selected if selected in UNIFORMS else "padrao")
        box = R(28, y, 316, 90)
        if sel: glow_box(img, box, CYAN, 10 * S); d = ImageDraw.Draw(img)
        frame(d, box, sel, fill=PANEL_2 if sel else PANEL)
        paste_fit(img, bust(cuts["o_" + k], 0.0, 0.5), R(36, y + 6, 96, 78), "center", 2)
        d = ImageDraw.Draw(img)
        text(d, (140, y + 30), f"{i + 1}. {uu['name']}", 17, CYAN if sel else TEXT, anchor="lm")
        text(d, (140, y + 54), uu["sub"], 13, GREEN if "força" in uu["sub"] else (VIOLET if "veloc" in uu["sub"] else CYAN), False, anchor="lm")
        text(d, (140, y + 74), uu["weapon"], 11, DIM, anchor="lm")
    # armadura
    frame(d, R(16, 448, 340, 180))
    text(d, (36, 476), "ARMADURA", 18, GOLD, anchor="lm"); text(d, (324, 476), "R • 5s / recarga 60s", 11, DIM, False, anchor="rm")
    slots = [("ÔMEGA", "armor_omega", True), ("BLOQUEADA", None, False), ("BLOQUEADA", None, False)]
    for i, (lab, ck, on) in enumerate(slots):
        box = R(28 + i * 104, 494, 96, 122)
        frame(d, box, on and selected == "omega" or (on and i == 0), fill=PANEL_2 if on else (8, 18, 22))
        if ck:
            paste_fit(img, bust(cuts[ck], 0.02, 0.62), R(32 + i * 104, 500, 88, 90), "center", 2); d = ImageDraw.Draw(img)
            text(d, (76 + i * 104, 602), lab, 12, CYAN, anchor="mm")
        else:
            text(d, (76 + i * 104, 548), "?", 40, (60, 80, 86), anchor="mm")
            text(d, (76 + i * 104, 602), lab, 10, (70, 90, 96), anchor="mm")

    # ── centro: palco com o personagem em cena
    sx, sy, sw, sh = 356, 64, 632, 460
    frame(d, R(sx, sy, sw, sh), True, fill=INK)
    st = stage(selected, key, (sw - 12) * S, (sh - 12) * S)
    img.alpha_composite(st, ((sx + 6) * S, (sy + 6) * S))
    d = ImageDraw.Draw(img)
    for (cx, cy) in [(sx + 14, sy + 14), (sx + sw - 14, sy + 14), (sx + 14, sy + sh - 14), (sx + sw - 14, sy + sh - 14)]:
        d.rectangle(R(cx - 10, cy - 2, 20, 4), fill=CYAN); d.rectangle(R(cx - 2, cy - 10, 4, 20), fill=CYAN)
    title = {"titan": "TITAN-01 • ROBÔ PILOTÁVEL", "spectre": "SPECTRE • COMPANHEIRO FERAL", "omega": "MARTY • ARMADURA ÔMEGA"}.get(selected, f"MARTY • UNIFORME {u['name']}")
    text(d, (sx + sw / 2, sy + sh - 62), title, 24, (255, 255, 255), anchor="mm")
    text(d, (sx + sw / 2, sy + sh - 32), f"ARMA: {u['weapon']}   |   ARMADURA: ÔMEGA (R)   |   ROBÔ: TITAN", 13, CYAN, anchor="mm")
    # setas de troca rápida (LB / RB)
    for side, s in ((-1, "◀"), (1, "▶")):
        cx = sx + sw / 2 + side * (sw / 2 - 30)
        d.ellipse(R(cx - 18, sy + sh / 2 - 18, 36, 36), fill=(6, 20, 26), outline=CYAN, width=2 * S)
        text(d, (cx, sy + sh / 2), s, 16, CYAN, anchor="mm")
        text(d, (cx, sy + sh / 2 + 30), "LB" if side < 0 else "RB", 10, DIM, anchor="mm")

    # ── coluna direita: status + descrições
    rx = 1004
    frame(d, R(rx, 64, 324, 260))
    text(d, (rx + 20, 92), "STATUS", 18, GOLD, anchor="lm"); text(d, (rx + 304, 92), "uniforme atual", 11, DIM, False, anchor="rm")
    rows = [("CORAÇÕES", None), ("VELOCIDADE", (u["speed"], 430, CYAN)), ("GOLPE", (u["melee"], 50, ORANGE)),
            ("DANO / TIRO", (u["dmg"], 60, GOLD)), ("DEFESA", (2.0 - u["taken"], 1.2, GREEN)), ("DASH", (1.0 / u["dash"], 3.0, VIOLET))]
    for i, (lab, val) in enumerate(rows):
        y = 112 + i * 34
        text(d, (rx + 20, y + 10), lab, 13, TEXT, anchor="lm")
        if val is None:
            for h in range(3): heart(d, rx + 150 + h * 26, y + 1, 20, (232, 60, 70))
            text(d, (rx + 304, y + 10), "3", 14, TEXT, anchor="rm")
        else:
            v, vmax, c = val
            bar(d, rx + 124, y + 5, 132, v, vmax, c)
            shown = {"DEFESA": f"{int((1 - u['taken']) * 100):+d}%", "DASH": f"{u['dash']:.2f}s"}.get(lab, str(v))
            text(d, (rx + 304, y + 10), shown, 13, c, anchor="rm")
    frame(d, R(rx, 332, 324, 240))
    info = [(key if key != "titan" else "o_padrao", f"UNIFORME {u['name']}", CYAN, u["desc"]),
            ("armor_omega", "ARMADURA ÔMEGA", ORANGE, "Lâmina de energia, 3 corações de escudo e +velocidade por 5s."),
            ("titan", "COMPANHEIRO • TITAN", GREEN, "C invoca, E pilota. Canhão, bomba (R) e turbo (Shift).")]
    for i, (ck, t, c, body) in enumerate(info):
        y = 344 + i * 76
        d.rectangle(R(rx + 16, y, 60, 68), fill=(6, 18, 24), outline=(40, 70, 76), width=S)
        paste_fit(img, bust(cuts[ck], 0.0, 0.6) if ck != "titan" else cuts[ck], R(rx + 18, y + 2, 56, 64), "center", 2); d = ImageDraw.Draw(img)
        text(d, (rx + 88, y + 10), t, 13, c, anchor="lm")
        words, line, ly = body.split(), "", y + 30
        for w in words:
            test = (line + " " + w).strip()
            if font(12, False).getlength(test) / S > 222: text(d, (rx + 88, ly), line, 12, (200, 208, 204), False, anchor="lm"); line, ly = w, ly + 17
            else: line = test
        text(d, (rx + 88, ly), line, 12, (200, 208, 204), False, anchor="lm")
        if i < 2: d.line(R(rx + 16, y + 72, 292, 0)[:2] + R(rx + 308, y + 72, 0, 0)[:2], fill=(40, 60, 66), width=S)

    # ── faixa de baixo: robôs + botões
    frame(d, R(356, 532, 632, 152))
    tag(d, R(372, 544, 96, 26), "ROBÔ", GOLD, 15)
    text(d, (480, 557), "C invoca / recolhe • só um por vez", 11, DIM, False, anchor="lm")
    robots = [("TITAN", "titan", "PILOTAR  (E)", GREEN, True), ("SPECTRE", "spectre", "FUNDIR  (G)", VIOLET, False), ("BLOQUEADO", None, "", DIM, False)]
    for i, (lab, ck, act, c, sel) in enumerate(robots):
        bx = 372 + i * 204
        box = R(bx, 578, 192, 96)
        if sel: glow_box(img, box, CYAN, 8 * S); d = ImageDraw.Draw(img)
        frame(d, box, sel, fill=PANEL_2 if ck else (8, 18, 22))
        if ck:
            paste_fit(img, cuts[ck], R(bx + 6, 582, 84, 88), "center", 2); d = ImageDraw.Draw(img)
            text(d, (bx + 96, 604), lab, 16, TEXT if not sel else CYAN, anchor="lm")
            tag(d, R(bx + 96, 626, 86, 24), act, c, 11)
        else:
            text(d, (bx + 96, 622), "?", 38, (60, 80, 86), anchor="mm")
    # botões
    frame(d, R(rx, 636, 324, 48), False, fill=(40, 20, 8)); text(d, (rx + 162, 660), "⚔  INICIAR ARENA", 18, ORANGE, anchor="mm")
    glow_box(img, R(rx, 580, 324, 50), CYAN, 10 * S); d = ImageDraw.Draw(img)
    frame(d, R(rx, 580, 324, 50), True, fill=(8, 44, 54)); text(d, (rx + 162, 605), "IR AO REFÚGIO  ▶", 20, CYAN, anchor="mm")
    # a coluna direita encolhe para caber os botões
    # ── rodapé: atalhos de teclado e controle
    frame(d, R(16, 694, 1312, 46), fill=(6, 16, 20))
    x = 34
    for k, lab in [("R", "vestir armadura"), ("C", "invocar/recolher robô"), ("E", "pilotar Titan"), ("G", "fundir Spectre")]:
        x = keycap(d, x, 704, k, lab)
    text(d, (744, 717), "CONTROLE", 12, DIM, anchor="lm")
    x = 820
    for k, lab, c in [("A", "selecionar", GREEN), ("B", "voltar", RED), ("LB", "", GOLD), ("RB", "trocar", GOLD), ("✚", "navegar", TEXT)]:
        wbtn = 26 if len(k) == 1 else 34
        d.ellipse(R(x, 704, wbtn, 26), fill=(30, 40, 46), outline=c, width=2 * S) if len(k) == 1 else d.rounded_rectangle(R(x, 706, wbtn, 22), radius=6 * S, fill=(30, 40, 46), outline=c, width=2 * S)
        text(d, (x + wbtn / 2, 717), k, 12, c, anchor="mm")
        if lab: text(d, (x + wbtn + 8, 717), lab, 13, (190, 200, 196), False, anchor="lm"); x += wbtn + 16 + int(font(13, False).getlength(lab) / S) + 10
        else: x += wbtn + 6
    frame(d, R(16, 636, 324, 48), False, fill=(20, 16, 12)); text(d, (178, 660), "◀  VOLTAR", 18, GOLD, anchor="mm")

    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / f"equipamento-v2-conceito-{selected}.png"
    img.convert("RGB").save(path)
    print("wrote", path)
    return path




# ───────────────────────────────────────── fundo da tela real (só a moldura estática)
def build_background():
    """assets/ui/equipment_v2.png: painéis, títulos e rodapé. O conteúdo (sprites, números, seleção) é desenhado no jogo."""
    img = backdrop()
    d = ImageDraw.Draw(img)
    frame(d, R(16, 12, 1312, 44), fill=(8, 22, 28))
    text(d, (34, 34), "EQUIPAMENTO", 22, GOLD, anchor="lm")
    text(d, (226, 34), "DOCAS DE 1941  •  escolha antes de ir ao Refúgio", 13, DIM, False, anchor="lm")
    frame(d, R(16, 64, 340, 376))
    text(d, (36, 92), "UNIFORME", 18, GOLD, anchor="lm"); text(d, (324, 92), "skin • sempre ativa", 11, DIM, False, anchor="rm")
    for i in range(3): frame(d, R(28, 110 + i * 100, 316, 90))
    frame(d, R(16, 448, 340, 180))
    text(d, (36, 476), "ARMADURA", 18, GOLD, anchor="lm"); text(d, (324, 476), "R • 5s / recarga 60s", 11, DIM, False, anchor="rm")
    # vaga 1: armadura lendária (moldura dourada)
    gold_box = R(28, 494, 96, 122)
    glow_box(img, gold_box, (255, 200, 80), 8 * S); d = ImageDraw.Draw(img)
    frame(d, gold_box, color=(255, 205, 90), fill=(46, 34, 12))
    for i in (1, 2):
        frame(d, R(28 + i * 104, 494, 96, 122), fill=(8, 18, 22))
        text(d, (76 + i * 104, 548), "?", 40, (60, 80, 86), anchor="mm")
        text(d, (76 + i * 104, 602), "BLOQUEADA", 10, (70, 90, 96), anchor="mm")
    sx, sy, sw, sh = 356, 64, 632, 460
    frame(d, R(sx, sy, sw, sh), True, fill=INK)
    for (cx, cy) in [(sx + 14, sy + 14), (sx + sw - 14, sy + 14), (sx + 14, sy + sh - 14), (sx + sw - 14, sy + sh - 14)]:
        d.rectangle(R(cx - 10, cy - 2, 20, 4), fill=CYAN); d.rectangle(R(cx - 2, cy - 10, 4, 20), fill=CYAN)
    rx = 1004
    frame(d, R(rx, 64, 324, 260))
    text(d, (rx + 20, 92), "STATUS", 18, GOLD, anchor="lm"); text(d, (rx + 304, 92), "uniforme atual", 11, DIM, False, anchor="rm")
    for i, lab in enumerate(["CORAÇÕES", "VELOCIDADE", "GOLPE", "DANO / TIRO", "DEFESA", "DASH"]):
        text(d, (rx + 20, 122 + i * 34), lab, 13, TEXT, anchor="lm")
    frame(d, R(rx, 332, 324, 240))
    for i in range(3):
        y = 344 + i * 76
        d.rectangle(R(rx + 16, y, 60, 68), fill=(6, 18, 24), outline=(40, 70, 76), width=S)
        if i < 2: d.line(R(rx + 16, y + 72, 292, 0)[:2] + R(rx + 308, y + 72, 0, 0)[:2], fill=(40, 60, 66), width=S)
    frame(d, R(356, 532, 632, 152))
    tag(d, R(372, 544, 96, 26), "ROBÔ", GOLD, 15)
    text(d, (480, 557), "C invoca / recolhe • só um por vez", 11, DIM, False, anchor="lm")
    for i in range(3):
        frame(d, R(372 + i * 204, 578, 192, 96), fill=PANEL_2 if i < 2 else (8, 18, 22))
    text(d, (372 + 2 * 204 + 96, 626), "?", 38, (60, 80, 86), anchor="mm")
    frame(d, R(16, 694, 1312, 46), fill=(6, 16, 20))
    x = 34
    for k, lab in [("R", "vestir armadura"), ("C", "invocar/recolher robô"), ("E", "pilotar Titan"), ("G", "fundir Spectre")]:
        x = keycap(d, x, 704, k, lab)
    text(d, (744, 717), "CONTROLE", 12, DIM, anchor="lm")
    x = 820
    for k, lab, c in [("A", "selecionar", GREEN), ("B", "voltar", RED), ("LB", "", GOLD), ("RB", "trocar", GOLD), ("✚", "navegar", TEXT)]:
        wbtn = 26 if len(k) == 1 else 34
        if len(k) == 1: d.ellipse(R(x, 704, wbtn, 26), fill=(30, 40, 46), outline=c, width=2 * S)
        else: d.rounded_rectangle(R(x, 706, wbtn, 22), radius=6 * S, fill=(30, 40, 46), outline=c, width=2 * S)
        text(d, (x + wbtn / 2, 717), k, 12, c, anchor="mm")
        if lab: text(d, (x + wbtn + 8, 717), lab, 13, (190, 200, 196), False, anchor="lm"); x += wbtn + 16 + int(font(13, False).getlength(lab) / S) + 10
        else: x += wbtn + 6
    out = ROOT / "assets/ui/equipment_v2.png"
    img.convert("RGB").resize((1344, 752), Image.LANCZOS).save(out)
    print("wrote", out)

if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) > 1 else "padrao"
    if arg == "bg": build_background()
    else: build(arg)
