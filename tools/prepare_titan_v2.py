"""Titan v2: viseira no cockpit, 8 direções e passada pesada.

Fonte: art/source/mech-atlas-v1.png (4 vistas × parado/passada, fundo magenta).
- Cockpit: a cavidade aberta (onde aparecia o boneco do piloto) vira uma VISEIRA de vidro.
  Duas versões: vazia (vidro escuro) e pilotada (faixa ciano acesa) — o jogo não desenha mais piloto.
- Diagonais: geradas girando em perspectiva as vistas de frente e de costas (lado distante comprimido
  e sombreado), para os 8 rumos sem precisar de uma folha nova.
- Passada: 4 quadros por vista (pé sobe/desce com peso); o jogo soma o balanço e a pisada.

Saída: assets/mech/titan_v2.png — linhas = vista (frente, frente-3/4, lado, costas-3/4, costas; olhando
para a direita), colunas 0-4 = parado + passo1..4 (vazio), 5-9 = o mesmo pilotado. Células 176×176, pés em (88, 170).
Uso: python tools/prepare_titan_v2.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
src_code = (ROOT / "tools/animate_sprites.py").read_text(encoding="utf-8")
exec(src_code.split("# ───────── Marty")[0])  # reaproveita split_legs / compose / opaque_bounds

im = np.array(Image.open(ROOT / "art/source/mech-atlas-v1.png").convert("RGBA")).astype(int)
r, g, b = im[..., 0], im[..., 1], im[..., 2]
im[((r > 150) & (b > 150) & (g < 110)) | ((r > 140) & (b > 110) & (g < 100)), 3] = 0
im = im.astype(np.uint8)
CW, CH = 384, 512


def cell(col, row):
    return im[row * CH:(row + 1) * CH, col * CW:(col + 1) * CW].copy()


# regiões do cockpit (coordenadas da célula-fonte, referência: topo do corpo em REF_TOP)
REF_TOP = 76
CANOPY = {
    "front": [((164, 84, 266, 160), (104, 124))],
    "side": [((116, 76, 176, 108), None), ((156, 106, 234, 152), (118, 136))],
    "back": [((114, 80, 222, 114), None)],
}


def paint_visor(c, view, piloted):
    top = opaque_bounds(c)[0]
    dy = top - REF_TOP
    out = c.copy()
    for (x0, y0, x1, y1), band in CANOPY[view]:
        y0 += dy; y1 += dy
        reg = out[y0:y1, x0:x1].astype(int)
        rr, gg, bb = reg[..., 0], reg[..., 1], reg[..., 2]
        v = reg[..., :3].max(2)
        cavity = (reg[..., 3] > 0) & ((v < 100) | ((rr > gg + 18) & (v < 190)))
        h = y1 - y0
        ys = np.arange(h)[:, None] / max(1, h - 1)
        glass = np.zeros(reg.shape[:2] + (3,))
        glass[..., 0] = 18 + 22 * ys; glass[..., 1] = 38 + 40 * ys; glass[..., 2] = 52 + 45 * ys
        if piloted: glass = glass * 0.6 + np.array([40, 150, 170]) * 0.4
        xs = np.arange(x1 - x0)[None, :]
        streak = np.abs((xs - (x1 - x0) * 0.25) - ys * (x1 - x0) * 0.5) < 3
        glass[streak & cavity] = [150, 210, 225] if piloted else [90, 130, 150]
        if band:
            by0, by1 = band[0] + dy - y0, band[1] + dy - y0
            rows = np.zeros(h, bool); rows[max(0, by0):max(0, by1)] = True
            m = rows[:, None] & cavity
            glass[m] = [110, 240, 250] if piloted else [30, 64, 78]
            core = np.zeros(h, bool); core[(by0 + by1) // 2:(by0 + by1) // 2 + 2] = True
            glass[core[:, None] & cavity] = [235, 255, 255] if piloted else [45, 90, 105]
        reg[..., :3] = np.where(cavity[..., None], glass, reg[..., :3])
        out[y0:y1, x0:x1] = reg.clip(0, 255).astype(np.uint8)
    return out


def turn(c, near_right=True, squeeze=0.55):
    """Giro de 3/4: metade distante comprimida e escurecida; resultado mais estreito."""
    top, bottom, left, right = opaque_bounds(c)
    cx = (left + right) // 2
    h, w = c.shape[:2]
    out = np.zeros_like(c)
    far_w = int((cx - left) * squeeze)
    new_cx = cx
    for x in range(w):
        # mapeia x de destino -> x de origem
        if x < new_cx:
            d = new_cx - x
            sx = cx - d / squeeze if d <= far_w else -1
            shade = 0.84
        else:
            sx = x; shade = 1.0
        sx = int(round(sx))
        if 0 <= sx < w:
            col = c[:, sx].astype(float)
            col[:, :3] *= shade
            out[:, x] = col.clip(0, 255).astype(np.uint8)
    if not near_right: out = out[:, ::-1].copy()
    return out


def fit(c, scale=0.47):
    """Reduz e posiciona na célula 176×176 com pés em (88,170)."""
    img = Image.fromarray(c)
    bb = img.getbbox(); img = img.crop(bb)
    img = img.resize((max(1, round(img.width * scale)), max(1, round(img.height * scale))), Image.LANCZOS)
    a = np.array(img); a[..., 3] = np.where(a[..., 3] > 110, 255, 0)
    ai = a.astype(int)
    fringe = (ai[..., 0] - ai[..., 1] > 30) & (ai[..., 2] - ai[..., 1] > 30)   # resto do fundo magenta
    a[fringe, 3] = 0
    img = Image.fromarray(a)
    arr = np.array(img)
    lower = arr[int(arr.shape[0] * 0.75):, :, 3] > 0
    xs = np.nonzero(lower)[1]
    ax = int(np.median(xs)) if len(xs) else img.width // 2
    canvas = Image.new("RGBA", (176, 176), (0, 0, 0, 0))
    canvas.alpha_composite(img, (88 - ax, 170 - img.height))
    return np.array(canvas)


views = {}
for piloted in (False, True):
    fr_i = paint_visor(cell(0, 0), "front", piloted); fr_s = paint_visor(cell(0, 1), "front", piloted)
    sd_i = paint_visor(cell(2, 0), "side", piloted); sd_s = paint_visor(cell(2, 1), "side", piloted)
    bk_i = paint_visor(cell(3, 0), "back", piloted); bk_s = paint_visor(cell(3, 1), "back", piloted)
    views[piloted] = [
        (fit(fr_i), fit(fr_s), False),
        (fit(turn(fr_i)), fit(turn(fr_s)), False),
        (fit(sd_i), fit(sd_s), True),
        (fit(turn(bk_i, near_right=False)), fit(turn(bk_s, near_right=False)), False),
        (fit(bk_i), fit(bk_s), False),
    ]

out = np.zeros((5 * 176, 10 * 176, 4), np.uint8)
for piloted in (False, True):
    for v, (idle, stride, side) in enumerate(views[piloted]):
        if side:
            frames = [idle, stride, compose(idle, 88, (0, 3), (0, 3)), stride]
        else:
            frames = [compose(idle, 88, (0, 10), (0, 0)), compose(idle, 88, (0, 2), (0, 2)),
                      compose(idle, 88, (0, 0), (0, 10)), compose(idle, 88, (0, 2), (0, 2))]
        for c, f in enumerate([idle] + frames):
            col = c + (5 if piloted else 0)
            out[v * 176:(v + 1) * 176, col * 176:(col + 1) * 176] = f
Image.fromarray(out).save(ROOT / "assets/mech/titan_v2.png")
print("wrote assets/mech/titan_v2.png", out.shape[1], "x", out.shape[0])
