"""0.16: utilitários para recortar folhas de sprites geradas por IA com fundo magenta (#FF00FF).

A IA não respeita tamanhos exatos: cada folha é lida como imagem, o magenta vira transparente
(com tolerância e limpeza da franja rosada), as "ilhas" de cada peça são detectadas sozinhas e
cada peça é levada ao tamanho-alvo do jogo com NEAREST NEIGHBOR (pixel art, sem suavização).
Usado por tools/prepare_{workshop,market,chapel,cracked_walls,tentacle_gate,map_icons}.py.
Requer numpy, pillow e scipy.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/source"
PREVIEW_BG = (58, 62, 70)


def key_magenta(img: Image.Image, tol: int = 70, fringe: int = 2) -> np.ndarray:
    """RGBA com o magenta removido. tol = quanto o pixel pode fugir do magenta puro.
    A franja (pixels rosados colados no fundo) é apagada ou tem o rosa retirado (despill)."""
    a = np.asarray(img.convert("RGB")).astype(np.int16)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mag = np.minimum(r, b) - g                      # alto no magenta, ~0 em cores comuns
    bg = (mag > 255 - tol) | ((r > 200) & (b > 200) & (g < 90))
    alpha = np.where(bg, 0, 255).astype(np.uint8)
    # franja: até `fringe` px do fundo, pixels ainda puxados para o magenta somem
    near = ndimage.binary_dilation(bg, iterations=fringe) & ~bg
    pinkish = near & (mag > 55) & (r > g + 40) & (b > g + 40)
    alpha[pinkish] = 0
    # despill no resto da borda: tira o excesso de vermelho+azul em relação ao verde
    edge = ndimage.binary_dilation(alpha == 0, iterations=fringe) & (alpha > 0)
    out = a.copy()
    spill = np.clip(mag - 25, 0, None)
    for c in (0, 2):
        ch = out[..., c]
        ch[edge] = np.clip(ch[edge] - spill[edge] // 2, 0, 255)
    return np.dstack([out.clip(0, 255).astype(np.uint8), alpha])


def islands(rgba: np.ndarray, merge: int = 10, min_area: int = 400) -> list:
    """Caixas (x0, y0, x1, y1) de cada peça. `merge` junta partes próximas (faíscas, chamas, cordas)."""
    solid = rgba[..., 3] > 0
    grown = ndimage.binary_dilation(solid, iterations=merge)
    lab, _ = ndimage.label(grown)
    boxes = []
    for sl in ndimage.find_objects(lab):
        if sl is None: continue
        y0, y1, x0, x1 = sl[0].start, sl[0].stop, sl[1].start, sl[1].stop
        if solid[y0:y1, x0:x1].sum() < min_area: continue
        # encolhe de volta ao pixel sólido
        ys, xs = np.nonzero(solid[y0:y1, x0:x1])
        boxes.append((x0 + xs.min(), y0 + ys.min(), x0 + xs.max() + 1, y0 + ys.max() + 1))
    return boxes


def reading_order(boxes: list, row_tol: float = 0.5) -> list:
    """Ordena em linhas (de cima para baixo) e, dentro da linha, da esquerda para a direita."""
    boxes = sorted(boxes, key=lambda b: (b[1] + b[3]) / 2)
    rows, row = [], []
    for b in boxes:
        cy, h = (b[1] + b[3]) / 2, b[3] - b[1]
        if row:
            rcy = np.mean([(q[1] + q[3]) / 2 for q in row]); rh = np.mean([q[3] - q[1] for q in row])
            if abs(cy - rcy) > row_tol * max(h, rh):
                rows.append(row); row = []
        row.append(b)
    if row: rows.append(row)
    return [b for r in rows for b in sorted(r, key=lambda q: q[0])]


def fit(piece: Image.Image, size: tuple, mode: str = "contain", anchor: str = "bottom") -> Image.Image:
    """Leva a peça ao tamanho-alvo com NEAREST. contain = mantém a proporção dentro da caixa
    (sobra transparente, pés no chão); stretch = preenche exato (pisos); cover = preenche cortando."""
    w, h = size
    if mode == "stretch":
        return piece.resize((w, h), Image.NEAREST)
    s = min(w / piece.width, h / piece.height) if mode == "contain" else max(w / piece.width, h / piece.height)
    nw, nh = max(1, round(piece.width * s)), max(1, round(piece.height * s))
    small = piece.resize((nw, nh), Image.NEAREST)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = (w - nw) // 2
    y = (h - nh) if anchor == "bottom" else (h - nh) // 2
    out.alpha_composite(small, (x, y)) if mode == "contain" else out.paste(small.crop((-x, -y, -x + w, -y + h)))
    return out


def seamless_score(tile: Image.Image) -> float:
    """Diferença média entre bordas opostas (0 = fecha perfeito). Acima de ~40 a emenda aparece."""
    a = np.asarray(tile.convert("RGB")).astype(float)
    return float((np.abs(a[0] - a[-1]).mean() + np.abs(a[:, 0] - a[:, -1]).mean()) / 2)


def make_seamless(tile: Image.Image, band: int = 2) -> Image.Image:
    """Mescla `band` px das bordas opostas (média) para a repetição não mostrar costura."""
    a = np.asarray(tile.convert("RGBA")).astype(float)
    for i in range(band):
        w = 0.5 * (1 - i / band)
        top, bot = a[i].copy(), a[-1 - i].copy()
        a[i] = top * (1 - w) + bot * w; a[-1 - i] = bot * (1 - w) + top * w
        lef, rig = a[:, i].copy(), a[:, -1 - i].copy()
        a[:, i] = lef * (1 - w) + rig * w; a[:, -1 - i] = rig * (1 - w) + lef * w
    return Image.fromarray(a.round().astype(np.uint8), "RGBA")


def tile_3x3(tile: Image.Image) -> Image.Image:
    out = Image.new("RGBA", (tile.width * 3, tile.height * 3))
    for y in range(3):
        for x in range(3): out.paste(tile, (x * tile.width, y * tile.height))
    return out


def cut_sheet(sheet_name: str, names: list, merge: int = 10, min_area: int = 400, tol: int = 70) -> dict:
    """Recorta a folha e devolve {nome: Image RGBA recortada no tamanho original}. Confere a contagem."""
    rgba = key_magenta(Image.open(SRC / sheet_name), tol)
    boxes = reading_order(islands(rgba, merge, min_area))
    if len(boxes) != len(names):
        raise SystemExit(f"{sheet_name}: achei {len(boxes)} peças, esperava {len(names)}: {boxes}")
    img = Image.fromarray(rgba, "RGBA")
    return {n: img.crop(b) for n, b in zip(names, boxes)}


def _grid(cells: list, zoom: int, cols: int) -> Image.Image:
    cw = max(im.width for _, im in cells) * zoom + 24
    ch = max(im.height for _, im in cells) * zoom + 40
    rows = (len(cells) + cols - 1) // cols
    out = Image.new("RGBA", (cw * min(cols, len(cells)), ch * rows), PREVIEW_BG + (255,))
    d = ImageDraw.Draw(out)
    for i, (n, im) in enumerate(cells):
        x, y = (i % cols) * cw, (i // cols) * ch
        big = im.resize((im.width * zoom, im.height * zoom), Image.NEAREST)
        out.alpha_composite(big, (x + (cw - big.width) // 2, y + 8))
        d.text((x + 6, y + ch - 26), f"{n} {im.width}x{im.height}", fill=(230, 230, 220))
    return out


def preview(items: dict, path: Path, zoom: int = 2, cols: int = 5, extra: dict | None = None) -> None:
    """Prévia das peças prontas numa grade, sobre fundo neutro; pisos repetidos 3x3 numa faixa própria."""
    parts = [_grid(list(items.items()), zoom, cols)]
    if extra: parts.append(_grid(list(extra.items()), 1, 4))
    out = Image.new("RGBA", (max(p.width for p in parts), sum(p.height for p in parts)), PREVIEW_BG + (255,))
    y = 0
    for p in parts: out.alpha_composite(p, (0, y)); y += p.height
    path.parent.mkdir(parents=True, exist_ok=True)
    out.convert("RGB").save(path)


def run(sheet: str, out_dir: str, pieces: list, preview_name: str, merge: int = 10, min_area: int = 400,
        uniform: bool = False, seamless_fix: bool = True) -> dict:
    """pieces: [(nome, (w, h), modo)] na ordem de leitura da folha. modo: contain | stretch | floor.
    uniform = mesma escala para todas as peças (paredes, ícones): tijolos/traços do mesmo tamanho.
    Pisos ("floor") são esticados para o alvo, testados 3x3 e, se a emenda aparecer, mesclados 2 px."""
    raw = cut_sheet(sheet, [p[0] for p in pieces], merge, min_area)
    out = ROOT / out_dir
    out.mkdir(parents=True, exist_ok=True)
    scale = None
    if uniform:
        scale = min(min(sz[0] / raw[n].width, sz[1] / raw[n].height) for n, sz, _ in pieces)
    done, extra, report = {}, {}, []
    for name, size, mode in pieces:
        im = raw[name]
        if mode == "floor":
            tile = fit(im, size, "stretch")
            before = seamless_score(tile)
            if seamless_fix and before > 40:
                tile = make_seamless(tile)
            after = seamless_score(tile)
            report.append(f"{name}: emenda {before:.0f} -> {after:.0f}" + ("  (VISÍVEL)" if after > 40 else ""))
            extra[name + " 3x3"] = tile_3x3(tile)
        elif scale is not None:
            small = im.resize((max(1, round(im.width * scale)), max(1, round(im.height * scale))), Image.NEAREST)
            tile = Image.new("RGBA", size, (0, 0, 0, 0))
            tile.alpha_composite(small, ((size[0] - small.width) // 2, size[1] - small.height))
        else:
            tile = fit(im, size, "contain")
        tile.save(out / f"{name}.png")
        done[name] = tile
    preview(done, ROOT / "art" / preview_name, extra=extra)
    for line in report: print("  " + line)
    print(f"{sheet}: {len(done)} peças -> {out_dir}  (prévia art/{preview_name})")
    return done
