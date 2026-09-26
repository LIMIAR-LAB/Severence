"""0.16: assets visuais e sonoros de "juice" de combate (impacto, telegraph, dois
inimigos novos e badge de streak). Só numpy + pillow, sem rede — mesma convenção de
tools/make_support_assets.py. Reexecutar regenera tudo de forma determinística."""
from pathlib import Path
import wave
import numpy as np
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
EFFECTS = root / 'assets/effects'
ENEMIES = root / 'assets/enemies'
HUD = root / 'assets/ui/hud'
AUDIO = root / 'assets/audio'
for d in (EFFECTS, ENEMIES, HUD, AUDIO):
    d.mkdir(parents=True, exist_ok=True)

rng = np.random.default_rng(1941)

# Paleta do jogo: cyan escuro / dourado, sobre tons quase-pretos.
CYAN = (0x6a, 0xe6, 0xe6)
CYAN_LIGHT = (0xc9, 0xff, 0xff)
WHITE = (0xff, 0xff, 0xff)
GOLD = (0xff, 0xc9, 0x3a)
GOLD_DARK = (0xb8, 0x82, 0x12)
GOLD_LIGHT = (0xff, 0xef, 0xb0)
INK = (0x18, 0x16, 0x25)
RED = (0xe6, 0x3a, 0x3a)


def canvas(w, h):
    return Image.new('RGBA', (w, h), (0, 0, 0, 0))


def upscale(img: Image.Image, factor: int) -> Image.Image:
    return img.resize((img.width * factor, img.height * factor), Image.NEAREST)


def px(draw: ImageDraw.ImageDraw, x, y, color):
    draw.point((x, y), fill=color)


# ---------------------------------------------------------------------------
# 1) assets/effects/hit_sparks.png -- 4 quadros de impacto, 32x32 cada, cyan/branco
# ---------------------------------------------------------------------------

def make_hit_sparks():
    scale = 2
    base = 16  # 16x16 "pixels" de arte -> 32x32 final
    cx, cy = 8, 8
    frames = []

    def spark(core_r, ray_len, ray_w, alpha, ray_color):
        im = Image.new('RGBA', (base, base), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        dirs8 = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)]
        for i, (rdx, rdy) in enumerate(dirs8):
            diag = rdx != 0 and rdy != 0
            length = max(2, int(ray_len * (0.62 if diag else 1.0)))
            x2 = cx + rdx * length
            y2 = cy + rdy * length
            d.line((cx, cy, x2, y2), fill=(*ray_color, alpha), width=ray_w)
            # ponta mais clara
            d.line((cx + rdx * max(1, length - 1), cy + rdy * max(1, length - 1), x2, y2),
                   fill=(*CYAN_LIGHT, alpha), width=max(1, ray_w - 1))
        if core_r > 0:
            d.ellipse((cx - core_r, cy - core_r, cx + core_r, cy + core_r), fill=(*WHITE, 255))
        return im

    stages = [
        # (raio núcleo, comprimento raio, largura raio, alpha, cor do raio)
        (2, 3, 2, 255, CYAN_LIGHT),
        (3, 6, 2, 255, CYAN),
        (2, 7, 1, 190, CYAN),
        (0, 7, 1, 90, CYAN),
    ]
    for core_r, ray_len, ray_w, alpha, ray_color in stages:
        frames.append(upscale(spark(core_r, ray_len, ray_w, alpha, ray_color), scale))
    sheet = Image.new('RGBA', (32 * 4, 32), (0, 0, 0, 0))
    for i, fr in enumerate(frames):
        sheet.paste(fr, (i * 32, 0), fr)
    sheet.save(EFFECTS / 'hit_sparks.png')


# ---------------------------------------------------------------------------
# 2) assets/effects/oil_stain.png -- 3 variações de mancha de óleo, 48x32, opaca
# ---------------------------------------------------------------------------

def make_oil_stain():
    variants = []
    seeds = [7, 23, 91]
    for seed in seeds:
        r = np.random.default_rng(seed)
        base = 12  # 12x8 -> upscale x4 = 48x32
        im = Image.new('RGBA', (base, 8), (0, 0, 0, 0))
        cx, cy = base / 2.0 + r.uniform(-1, 1), 4 + r.uniform(-0.5, 0.5)
        rx = 4.6 + r.uniform(-0.6, 0.8)
        ry = 2.6 + r.uniform(-0.4, 0.5)
        for x in range(base):
            for y in range(8):
                nx, ny = (x - cx) / rx, (y - cy) / ry
                d = nx * nx + ny * ny
                if d <= 1.0:
                    edge = d > 0.72
                    dark = (0x0e, 0x14, 0x12) if not edge else (0x1c, 0x27, 0x24)
                    jitter = r.integers(-4, 5)
                    col = tuple(max(0, min(255, c + jitter)) for c in dark)
                    im.putpixel((x, y), (*col, 255))
        # brilho leve fora de centro
        for _ in range(3):
            gx = int(cx + r.uniform(-rx * 0.4, rx * 0.1))
            gy = int(cy + r.uniform(-ry * 0.4, ry * 0.1))
            if 0 <= gx < base and 0 <= gy < 8:
                px_col = im.getpixel((gx, gy))
                if px_col[3] > 0:
                    im.putpixel((gx, gy), (0x2c, 0x3a, 0x36, 255))
        variants.append(upscale(im, 4))
    sheet = Image.new('RGBA', (48 * 3, 32), (0, 0, 0, 0))
    for i, v in enumerate(variants):
        sheet.paste(v, (i * 48, 0), v)
    sheet.save(EFFECTS / 'oil_stain.png')


# ---------------------------------------------------------------------------
# 3) assets/effects/aoe_ring.png -- anel vermelho translúcido de telegraph, 96x96
# ---------------------------------------------------------------------------

def make_aoe_ring():
    size = 96
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cx = cy = size / 2.0
    outer = 47.0
    inner = 36.0
    dash_period = 14
    dash_on = 8
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx + 0.5, y - cy + 0.5
            dist = (dx * dx + dy * dy) ** 0.5
            if inner <= dist <= outer:
                t = (dist - inner) / (outer - inner)  # 0 na borda interna, 1 na externa
                ring_alpha = 235 * (1.0 - abs(t - 0.5) * 2.0) ** 0.6
                ang = (np.degrees(np.arctan2(dy, dx)) + 360) % 360
                dashed = (ang % dash_period) < dash_on
                alpha = ring_alpha if dashed else ring_alpha * 0.35
                col = (0xff, 0x55, 0x3a) if dashed else (0xb8, 0x2a, 0x22)
                im.putpixel((x, y), (*col, int(max(0, min(255, alpha)))))
            elif dist < inner:
                fill_alpha = 55 * (1.0 - dist / inner)
                im.putpixel((x, y), (*RED, int(max(0, fill_alpha))))
    im.save(EFFECTS / 'aoe_ring.png')


# ---------------------------------------------------------------------------
# 4/5) inimigos: bomber.png e guard.png -- grade 4x4 de 256x256 (igual warden.png)
#      linhas = direção (0 baixo, 1 esquerda, 2 direita, 3 cima) via feral_row()
#      colunas = quadros de animação (0 parado, 1-2 andando, 3 especial/aceso)
# ---------------------------------------------------------------------------

def blit_cell(sheet: Image.Image, art32: Image.Image, row: int, col: int, flip=False):
    cell = upscale(art32, 8)  # 32 -> 256
    if flip:
        cell = cell.transpose(Image.FLIP_LEFT_RIGHT)
    sheet.paste(cell, (col * 256, row * 256), cell)


def make_bomber():
    sheet = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    # arte base 32x32: criatura/barril instável com núcleo incandescente laranja
    outline = (0x14, 0x10, 0x0c)
    barrel_dark = (0x3a, 0x33, 0x28)
    barrel_mid = (0x55, 0x4a, 0x38)
    barrel_band = (0x22, 0x1e, 0x18)
    core_hot = (0xff, 0x9a, 0x2e)
    core_hotter = (0xff, 0xe0, 0x8a)
    leg = (0x2a, 0x24, 0x1c)

    def base_art(bob=0, glow=0, wobble=0, hot=False):
        im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        top = 6 + bob
        # pernas curtas instáveis
        d.rectangle((10 + wobble, 24, 13 + wobble, 28), fill=leg)
        d.rectangle((19 - wobble, 24, 22 - wobble, 28), fill=leg)
        # corpo tipo barril, levemente cônico
        d.rounded_rectangle((7, top, 24, top + 19), radius=3, fill=barrel_mid, outline=outline)
        d.rectangle((7, top + 5, 24, top + 6), fill=barrel_band)
        d.rectangle((7, top + 12, 24, top + 13), fill=barrel_band)
        for i in range(7, 24, 3):
            d.line((i, top + 1, i, top + 18), fill=barrel_dark)
        # rachaduras revelando o núcleo
        d.line((13, top + 7, 15, top + 11), fill=core_hot)
        d.line((19, top + 8, 17, top + 12), fill=core_hot)
        # núcleo incandescente pulsante
        core_r = 3 + glow
        cx, cy = 15, top + 10
        col_core = core_hotter if hot else core_hot
        d.ellipse((cx - core_r, cy - core_r, cx + core_r, cy + core_r), fill=(*col_core, 235))
        d.ellipse((cx - 1, cy - 1, cx + 1, cy + 1), fill=(*WHITE, 255))
        # tampa/boca superior
        d.ellipse((8, top - 3, 23, top + 3), fill=barrel_dark, outline=outline)
        return im

    idle = base_art(bob=0, glow=0)
    walk1 = base_art(bob=-1, glow=1, wobble=1)
    walk2 = base_art(bob=0, glow=0, wobble=-1)
    hot = base_art(bob=-1, glow=2, wobble=0, hot=True)

    for row in (0, 3):  # baixo e cima: mesma silhueta (visto de cima/baixo é simétrico)
        blit_cell(sheet, idle, row, 0)
        blit_cell(sheet, walk1, row, 1)
        blit_cell(sheet, walk2, row, 2)
        blit_cell(sheet, hot, row, 3)
    blit_cell(sheet, idle, 1, 0)
    blit_cell(sheet, walk1, 1, 1)
    blit_cell(sheet, walk2, 1, 2)
    blit_cell(sheet, hot, 1, 3)
    blit_cell(sheet, idle, 2, 0, flip=True)
    blit_cell(sheet, walk1, 2, 1, flip=True)
    blit_cell(sheet, walk2, 2, 2, flip=True)
    blit_cell(sheet, hot, 2, 3, flip=True)
    sheet.save(ENEMIES / 'bomber.png')


def make_guard():
    sheet = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    outline = (0x10, 0x12, 0x16)
    armor = (0x3c, 0x46, 0x52)
    armor_light = (0x5a, 0x68, 0x76)
    armor_dark = (0x24, 0x2b, 0x33)
    shield_metal = (0x8a, 0x97, 0xa2)
    shield_light = (0xc8, 0xd6, 0xdf)
    shield_rivet = (0x2a, 0x30, 0x36)
    visor = CYAN

    def body(step=0):
        im = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rectangle((12 + step, 25, 14 + step, 29), fill=armor_dark)
        d.rectangle((18 - step, 25, 20 - step, 29), fill=armor_dark)
        d.rounded_rectangle((10, 10, 22, 26), radius=3, fill=armor, outline=outline)
        d.rectangle((10, 15, 22, 16), fill=armor_light)
        d.ellipse((11, 4, 21, 13), fill=armor, outline=outline)
        d.rectangle((13, 7, 19, 9), fill=(*visor, 255))
        return im

    def with_frontal_shield(step=0):
        im = body(step)
        d = ImageDraw.Draw(im)
        # escudo grande frontal (visto de baixo/frente): cobre quase todo o corpo
        d.rounded_rectangle((5, 6, 26, 27), radius=4, fill=shield_metal, outline=outline)
        d.rounded_rectangle((7, 8, 24, 25), radius=3, outline=shield_light)
        d.line((15, 8, 15, 25), fill=shield_light)
        for ry in (11, 22):
            for rx in (9, 15, 21):
                d.ellipse((rx - 1, ry - 1, rx + 1, ry + 1), fill=shield_rivet)
        d.polygon([(15, 6), (18, 12), (12, 12)], fill=shield_light)
        return im

    def side_view(step=0, flip=False):
        # de lado o escudo é visto de perfil (fino): a proteção frontal não cobre as costas
        im = body(step)
        d = ImageDraw.Draw(im)
        x = 20 if not flip else 12
        d.rounded_rectangle((x - 2, 6, x + 2, 27), radius=1, fill=shield_metal, outline=outline)
        d.line((x, 9, x, 24), fill=shield_light)
        return im

    def back_view(step=0):
        im = body(step)
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((11, 10, 21, 24), radius=2, fill=armor_dark)
        d.rectangle((14, 4, 18, 7), fill=armor_dark)
        return im

    front_idle, front_walk1, front_walk2 = with_frontal_shield(0), with_frontal_shield(-1), with_frontal_shield(1)
    back_idle, back_walk1, back_walk2 = back_view(0), back_view(-1), back_view(1)
    left_idle, left_walk1, left_walk2 = side_view(0, False), side_view(-1, False), side_view(1, False)

    blit_cell(sheet, front_idle, 0, 0)
    blit_cell(sheet, front_walk1, 0, 1)
    blit_cell(sheet, front_walk2, 0, 2)
    blit_cell(sheet, front_idle, 0, 3)

    blit_cell(sheet, left_idle, 1, 0)
    blit_cell(sheet, left_walk1, 1, 1)
    blit_cell(sheet, left_walk2, 1, 2)
    blit_cell(sheet, left_idle, 1, 3)

    blit_cell(sheet, left_idle, 2, 0, flip=True)
    blit_cell(sheet, left_walk1, 2, 1, flip=True)
    blit_cell(sheet, left_walk2, 2, 2, flip=True)
    blit_cell(sheet, left_idle, 2, 3, flip=True)

    blit_cell(sheet, back_idle, 3, 0)
    blit_cell(sheet, back_walk1, 3, 1)
    blit_cell(sheet, back_walk2, 3, 2)
    blit_cell(sheet, back_idle, 3, 3)
    sheet.save(ENEMIES / 'guard.png')


# ---------------------------------------------------------------------------
# 6) assets/ui/hud/streak.png -- medalha dourada de multiplicador, 24x24
# ---------------------------------------------------------------------------

def make_streak():
    im = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy, r = 11.5, 10.5, 8
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(*GOLD_DARK, 255), outline=(*INK, 255))
    d.ellipse((cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2), fill=(*GOLD, 255))
    d.pieslice((cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2), 200, 300, fill=(*GOLD_LIGHT, 255))
    d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=(*GOLD_LIGHT, 255))
    # estrela simples no centro
    star = [(cx, cy - 3.4), (cx + 1, cy - 0.8), (cx + 3.4, cy - 0.8), (cx + 1.4, cy + 0.7),
            (cx + 2.2, cy + 3.2), (cx, cy + 1.6), (cx - 2.2, cy + 3.2), (cx - 1.4, cy + 0.7),
            (cx - 3.4, cy - 0.8), (cx - 1, cy - 0.8)]
    d.polygon(star, fill=(*INK, 255))
    # fitas penduradas
    d.polygon([(cx - 4, cy + r - 2), (cx - 1, cy + r - 2), (cx - 2.5, cy + r + 5)], fill=(*RED, 255))
    d.polygon([(cx + 1, cy + r - 2), (cx + 4, cy + r - 2), (cx + 2.5, cy + r + 5)], fill=(0x8a, 0x1f, 0x1f, 255))
    im.save(HUD / 'streak.png')


# ---------------------------------------------------------------------------
# 7) audio sintetizado (mesma técnica de tools/make_support_assets.py)
# ---------------------------------------------------------------------------

SR = 22050


def save_wav(name, signal):
    signal = np.clip(signal, -1.0, 1.0)
    with wave.open(str(AUDIO / f'{name}.wav'), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(SR)
        out.writeframes((signal * 32767).astype('<i2').tobytes())


def make_audio():
    g = np.random.default_rng(1941)

    # explosão: estrondo grave + ruído, decaimento longo
    dur = 0.55
    t = np.arange(int(SR * dur)) / SR
    rumble = np.sin(2 * np.pi * 55 * t) * 0.6 + np.sin(2 * np.pi * 38 * t) * 0.4
    noise = g.uniform(-1, 1, len(t))
    sig = rumble * 0.5 + noise * 0.7
    sig *= np.exp(-t / dur * 3.2)
    save_wav('explosion', sig)

    # slash: whoosh curto e agudo com glide descendente + leve ruído
    dur = 0.16
    t = np.arange(int(SR * dur)) / SR
    freq = 1400 * np.exp(-t / dur * 2.2) + 300
    phase = 2 * np.pi * np.cumsum(freq) / SR
    sig = np.sin(phase) * 0.7 + g.uniform(-1, 1, len(t)) * 0.25
    sig *= np.exp(-t / dur * 6)
    save_wav('slash', sig)

    # dash: rajada de ar filtrada, sobe de tom rapidamente
    dur = 0.22
    t = np.arange(int(SR * dur)) / SR
    noise = g.uniform(-1, 1, len(t))
    # filtro passa-baixa simples (média móvel) para dar textura de "vento"
    kernel = np.ones(18) / 18
    wind = np.convolve(noise, kernel, mode='same')
    freq_mod = np.sin(2 * np.pi * (200 + t / dur * 500) * t) * 0.35
    sig = wind * 0.8 + freq_mod
    sig *= np.exp(-t / dur * 2.5) * (t / dur * 4).clip(0, 1)
    save_wav('dash', sig)

    # pickup: bipe curto ascendente, alegre
    dur = 0.18
    t = np.arange(int(SR * dur)) / SR
    freq = 520 + t / dur * 680
    phase = 2 * np.pi * np.cumsum(freq) / SR
    sig = (np.sin(phase) * 0.7 + np.sin(phase * 2) * 0.25)
    sig *= np.exp(-t / dur * 3.5)
    save_wav('pickup', sig)

    # enemy_die: "poof" descendente com ruído, mais curto que a explosão
    dur = 0.28
    t = np.arange(int(SR * dur)) / SR
    freq = 260 * np.exp(-t / dur * 3.0) + 60
    phase = 2 * np.pi * np.cumsum(freq) / SR
    tone = np.sin(phase) * 0.5
    noise = g.uniform(-1, 1, len(t)) * 0.5
    sig = tone + noise
    sig *= np.exp(-t / dur * 4.5)
    save_wav('enemy_die', sig)

    # fuel_alarm: 3 bipes curtos e urgentes repetidos (padrão de alarme)
    beep_dur = 0.09
    gap_dur = 0.07
    beep_t = np.arange(int(SR * beep_dur)) / SR
    beep = np.sign(np.sin(2 * np.pi * 880 * beep_t)) * 0.5  # onda quadrada, mais "elétrica"
    beep *= np.exp(-beep_t / beep_dur * 1.2)
    gap = np.zeros(int(SR * gap_dur))
    sig = np.concatenate([beep, gap] * 3)
    save_wav('fuel_alarm', sig)


if __name__ == '__main__':
    make_hit_sparks()
    make_oil_stain()
    make_aoe_ring()
    make_bomber()
    make_guard()
    make_streak()
    make_audio()
    print('OK: assets de combat juice gerados.')
