"""Gera ciclos de caminhada, tiro e salto a partir das poses paradas (animação por recorte).

As folhas do conceito têm UMA pose por direção. Este script separa as pernas do corpo
(quarto inferior da silhueta), divide em perna esquerda/direita e aplica:
  - vistas de frente/costas/3-4: passo alternado (uma perna sobe e dobra, a outra apoia);
  - vista de lado: tesoura (perna da frente avança, a de trás recua), com cisalhamento que
    começa zero no quadril — sem buracos entre corpo e perna;
  - balanço do corpo (−1/−2 px) nos quadros de passada;
  - tiro: recuo de 2 px para trás e leve achatamento;
  - salto: pernas encolhidas.

Entradas: assets/marty/outfits.png (4×6, 96×96) e assets/enemies/docas.png (4×5, 144×96)
Saídas:
  assets/marty/marty_anim.png   linhas = roupa*5 + vista (frente, frente-3/4, lado, costas-3/4, costas)
                                colunas = parado, passo1..passo4, tiro, salto, golpe1..golpe3 (96×96, pés em 48,92)
  assets/enemies/docas_anim.png linhas = inimigo (cult, fish, crawler, brute)
                                colunas = frente, costas, passo1..passo4, ataque, morte (144×96, pés em 56,92)
Uso: python tools/animate_sprites.py
"""
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def opaque_bounds(cell):
    a = cell[..., 3] > 0
    ys, xs = np.nonzero(a)
    return ys.min(), ys.max(), xs.min(), xs.max()


def split_legs(cell, ax, leg_frac=0.25):
    top, bottom, _, _ = opaque_bounds(cell)
    hip = int(bottom - (bottom - top) * leg_frac)
    return hip, bottom


def shift_rows(layer, hip, bottom, dx_max, dy_max, mask_cols):
    """Desloca linhas da região das pernas; deslocamento cresce do quadril (0) até o pé (máx)."""
    out = np.zeros_like(layer)
    out[:hip] = layer[:hip]
    h, w = layer.shape[:2]
    span = max(1, bottom - hip)
    for y in range(hip, h):
        t = min(1.0, (y - hip) / span)
        dx = int(round(dx_max * t)); dy = int(round(dy_max * t))
        row = layer[y].copy()
        row[~mask_cols] = 0
        ny = y - dy
        if not (0 <= ny < h): continue
        shifted = np.zeros_like(row)
        if dx >= 0: shifted[dx:] = row[:w - dx] if dx else row
        else: shifted[:dx] = row[-dx:]
        m = shifted[:, 3] > 0
        out[ny][m] = shifted[m]
    return out


def compose(cell, ax, left, right, body_dy=0, order="left_first"):
    """left/right = (dx, dy) para cada perna. Retorna nova célula."""
    hip, bottom = split_legs(cell, ax)
    w = cell.shape[1]
    cols = np.arange(w)
    lmask, rmask = cols < ax, cols >= ax
    body = cell.copy(); body[hip:] = 0
    legs_l = shift_rows(cell, hip, bottom, left[0], left[1], lmask); legs_l[:hip] = 0
    legs_r = shift_rows(cell, hip, bottom, right[0], right[1], rmask); legs_r[:hip] = 0
    out = np.zeros_like(cell)
    first, second = (legs_l, legs_r) if order == "left_first" else (legs_r, legs_l)
    for layer in (first, second):
        m = layer[..., 3] > 0; out[m] = layer[m]
    if body_dy:
        body = np.roll(body, body_dy, axis=0)
        if body_dy < 0: body[body_dy:] = 0
    m = body[..., 3] > 0; out[m] = body[m]
    return out


def walk_frames(cell, ax, side):
    if side:
        # tesoura: perna direita (frente, para quem olha para a direita) avança
        return [compose(cell, ax, (-6, 0), (6, 2), 0, "left_first"),
                compose(cell, ax, (-2, 0), (2, 0), 0),
                compose(cell, ax, (6, 2), (-6, 0), 0, "right_first"),
                compose(cell, ax, (2, 0), (-2, 0), 0)]
    # o balanço do corpo é aplicado no jogo (desloca o sprite inteiro), sem cortar os braços
    return [compose(cell, ax, (0, 6), (0, 0), 0),
            compose(cell, ax, (0, 2), (0, 2), 0),
            compose(cell, ax, (0, 0), (0, 6), 0),
            compose(cell, ax, (0, 2), (0, 2), 0)]


def recoil(cell, ax, back_dx):
    hip, bottom = split_legs(cell, ax)
    out = cell.copy()
    body = cell.copy(); body[hip:] = 0
    out[:hip] = 0
    body = np.roll(body, back_dx, axis=1)
    body = np.roll(body, 1, axis=0)  # leve agachada
    m = body[..., 3] > 0; out[m] = body[m]
    return out


def lean(cell, ax, dx_head, squash=0):
    """Inclina o tronco (cisalhamento: pés parados, cabeça desloca dx_head) e achata `squash` px."""
    top, bottom, _, _ = opaque_bounds(cell)
    out = np.zeros_like(cell)
    h, w = cell.shape[:2]
    span = max(1, bottom - top)
    for y in range(h):
        t = (bottom - y) / span
        if t < 0: continue
        dx = int(round(dx_head * min(1.0, t)))
        dy = int(round(squash * min(1.0, t)))
        ny = y + dy
        if not (0 <= ny < h): continue
        row = cell[y]
        shifted = np.zeros_like(row)
        if dx >= 0: shifted[dx:] = row[:w - dx] if dx else row
        else: shifted[:dx] = row[-dx:]
        m = shifted[:, 3] > 0
        out[ny][m] = shifted[m]
    return out


def attack_frames(cell, ax, view):
    """Golpe: preparo (inclina para trás), corte (avança) e finalização."""
    if view in (1, 2):   # frente-3/4 e lado olham para a direita
        return [lean(cell, ax, -4, 1), lean(cell, ax, 6, 2), lean(cell, ax, 3, 1)]
    if view == 3:
        return [lean(cell, ax, -3, 1), lean(cell, ax, 5, 2), lean(cell, ax, 2, 1)]
    return [lean(cell, ax, 0, -2), lean(cell, ax, 0, 3), lean(cell, ax, 0, 1)]   # frente/costas: estica e agacha


def tuck(cell, ax):
    return compose(cell, ax, (1, 7), (-1, 7), 0)


# ───────── Marty ─────────
src = np.array(Image.open(ROOT / "assets/marty/outfits.png").convert("RGBA"))
C = 96
out = np.zeros((4 * 5 * C, 10 * C, 4), np.uint8)
for o in range(4):
    run = src[o * C:(o + 1) * C, 5 * C:6 * C]
    for v in range(5):
        cell = src[o * C:(o + 1) * C, v * C:(v + 1) * C]
        side = v == 2
        frames = [cell] + walk_frames(cell, 48, side)
        frames.append(recoil(cell, 48, -2 if v in (1, 2) else 0))
        frames.append(run if side else tuck(cell, 48))
        frames += attack_frames(cell, 48, v)
        r = o * 5 + v
        for c, f in enumerate(frames):
            out[r * C:(r + 1) * C, c * C:(c + 1) * C] = f
Image.fromarray(out).save(ROOT / "assets/marty/marty_anim.png")
print("wrote assets/marty/marty_anim.png", out.shape[1], "x", out.shape[0])

# ───────── Inimigos ─────────
src = np.array(Image.open(ROOT / "assets/enemies/docas.png").convert("RGBA"))
W, H = 144, 96
out = np.zeros((4 * H, 8 * W, 4), np.uint8)
for r in range(4):
    cells = [src[r * H:(r + 1) * H, c * W:(c + 1) * W] for c in range(5)]
    walk = walk_frames(cells[2], 56, True) if r != 2 else walk_frames(cells[2], 56, False)
    frames = [cells[0], cells[1]] + walk + [cells[3], cells[4]]
    for c, f in enumerate(frames):
        out[r * H:(r + 1) * H, c * W:(c + 1) * W] = f
Image.fromarray(out).save(ROOT / "assets/enemies/docas_anim.png")
print("wrote assets/enemies/docas_anim.png", out.shape[1], "x", out.shape[0])
