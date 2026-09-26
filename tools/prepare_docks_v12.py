"""Recorta o cenário v1 das Docas (Higgsfield, set/2026) em tiles e props de jogo.

Entradas (art/source/):
  docks-tileset-v1.png      tábuas, cais de granito, água, parede de armazém, decalques
  docks-props-v1.png        props (fundo cinza liso) — usado no jogo
  docks-props-v2.png        variante guardada como referência (não recortada)
  docks-sala01-mockup-v1.png  mockup da Sala 01 (guia de composição)

Saídas (assets/environment/docks12/):
  tiles/*.png   tiles na escala nativa (1 px da folha = 1 px de mundo)
  props/*.png   props recortados sem fundo, pivô = centro da borda inferior
  fx/*.png      poças de luz (desenhadas em modo aditivo)
  art/docks-v12-preview.png  prévia de tudo

Uso: python tools/prepare_docks_v12.py   (requer numpy e pillow; nada mais)
"""
from pathlib import Path
from collections import deque
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/source"
OUT = ROOT / "assets/environment/docks12"

# ---------------------------------------------------------------- tiles
# Retângulos detectados na folha (x0, y0, x1, y1); o recorte tira 2 px de moldura.
PLANKS = [(16, 28, 90, 113), (99, 28, 173, 112), (182, 28, 256, 112), (265, 28, 339, 113),
          (348, 28, 422, 112), (431, 28, 504, 113), (513, 28, 588, 112)]
PLANK_NAMES = ["base", "knot", "nails", "crack", "light", "wet", "oil"]
PLANK_HOLE = (16, 124, 91, 270)
GRANITE = [(602, 26, 673, 135), (681, 26, 753, 135), (761, 26, 833, 135), (841, 26, 913, 135), (921, 26, 993, 135)]
GRANITE_NAMES = ["base", "moss", "cracked", "puddle", "yellow"]
QUAY_EDGE = [(602, 146, 673, 298), (681, 146, 753, 298), (761, 146, 833, 298), (841, 146, 913, 298)]
WATER = [(1010, 26, 1081, 103), (1091, 26, 1163, 103), (1173, 26, 1244, 103), (1254, 26, 1326, 103)]
FOAM = [(1010, 114, 1081, 180), (1091, 114, 1163, 180), (1173, 114, 1244, 180), (1254, 114, 1326, 180)]
WALL_CAP = [(17, 300, 121, 355), (132, 300, 225, 355), (235, 300, 312, 355), (323, 300, 395, 355), (407, 300, 481, 355)]
BRICK = [(17, 365, 121, 476), (132, 365, 225, 476), (235, 365, 313, 476), (323, 365, 395, 476), (406, 365, 481, 476), (491, 365, 586, 476)]
BRICK_NAMES = ["base", "damaged", "hole", "window", "pipe", "base2"]
WALL_BASE = [(17, 485, 122, 548), (132, 486, 225, 548), (235, 486, 312, 548), (323, 486, 395, 548), (407, 486, 481, 548)]
WALL_CORNER = [(17, 560, 107, 697), (119, 560, 202, 697)]
GRATE = (1055, 385, 1135, 467)
MANHOLE = (1208, 383, 1288, 465)
SYMBOLS = [(606, 503, 699, 622), (711, 503, 805, 622), (817, 503, 911, 622)]
PILING = (265, 123, 339, 269)   # tile com estaca: fica só a madeira (água removida)

# ---------------------------------------------------------------- props (folha v1, fundo ~113)
PROPS = {
    # linha 1
    "crate": (24, 42, 104, 128), "crate_2": (143, 20, 222, 134), "crate_3": (258, 8, 331, 136),
    "crate_broken": (357, 33, 452, 132), "crate_net": (476, 30, 574, 126), "crate_barnacles": (594, 33, 690, 130),
    "barrel": (729, 38, 806, 129), "barrel_oil": (850, 30, 917, 130), "barrel_toxic": (951, 25, 1021, 130),
    "barrel_explosive": (1056, 24, 1129, 130), "barrel_tipped": (1171, 38, 1285, 139),
    # linha 2
    "sandbags": (17, 175, 139, 264), "sandbags_corner": (150, 160, 276, 249), "sandbags_damaged": (287, 166, 405, 264),
    "bollard": (435, 176, 518, 263), "bollard_rope": (538, 176, 620, 257), "rope": (621, 182, 699, 253),
    "fish_basket": (707, 173, 793, 261), "lobster_trap": (808, 170, 929, 266), "wheelbarrow": (946, 160, 1073, 269),
    "anchor": (1073, 141, 1172, 262), "bench": (1192, 174, 1328, 270),
    # linha 3
    "lamp_post": (15, 262, 99, 430), "ship_lantern": (132, 302, 185, 407), "wall_lamp": (220, 316, 302, 397),
    "brazier": (321, 284, 392, 412), "brazier_f1": (423, 320, 482, 422), "brazier_f2": (491, 298, 550, 422),
    "brazier_f3": (551, 268, 620, 422), "container": (639, 305, 771, 432), "container_open": (777, 298, 929, 447),
    "rowboat": (947, 316, 1117, 432), "crane": (1119, 263, 1268, 449), "hook": (1283, 276, 1315, 412),
    # linha 4
    "phone_booth": (28, 443, 120, 586), "poster": (153, 433, 256, 588), "radio": (274, 467, 377, 582),
    "jerrycans": (405, 483, 528, 573), "medkit": (552, 486, 663, 577), "chest": (701, 482, 806, 578),
    "chest_open": (841, 462, 950, 580), "key": (972, 501, 1023, 557), "coin": (1054, 508, 1097, 551),
    "crystal": (1129, 491, 1174, 562), "iron_door": (1235, 453, 1325, 583),
    # linha 5
    "tentacle_pool_1": (17, 616, 167, 723), "tentacle_pool_2": (193, 626, 375, 726), "ritual_circle": (400, 592, 574, 731),
    "tentacle_planks": (592, 596, 759, 733), "debris_crate": (790, 604, 955, 732), "debris_barrel": (967, 618, 1135, 729),
    "debris_sandbags": (1148, 615, 1322, 733),
}
GLOW_PROPS = {"lamp_post", "ship_lantern", "wall_lamp"}


def load(name):
    return np.array(Image.open(SRC / name).convert("RGB")).astype(np.int16)


def save(arr, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(arr.astype(np.uint8)).save(path)


def crop(a, box, trim=2):
    x0, y0, x1, y1 = box
    return a[y0 + trim:y1 - trim, x0 + trim:x1 - trim]


def fixed(a, box, w, h):
    """Recorte de tamanho fixo (tiles do mesmo tipo precisam ter o mesmo tamanho para ladrilhar)."""
    x0, y0 = box[0] + 2, box[1] + 2
    return a[y0:y0 + h, x0:x0 + w]


def rgba(rgb, alpha):
    return np.dstack([rgb, alpha]).astype(np.uint8)


def flood_from_border(candidate):
    """Marca os pixels candidatos ligados à borda do recorte (fundo), sem tocar no interior."""
    h, w = candidate.shape
    seen = np.zeros_like(candidate, dtype=bool)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            if candidate[y, x] and not seen[y, x]: seen[y, x] = True; q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if candidate[y, x] and not seen[y, x]: seen[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            yy, xx = y + dy, x + dx
            if 0 <= yy < h and 0 <= xx < w and candidate[yy, xx] and not seen[yy, xx]:
                seen[yy, xx] = True; q.append((yy, xx))
    return seen


def cut_prop(sheet, box, bg, glow=False):
    part = crop(sheet, box, 0)
    rgb = part.astype(int)
    L = rgb.mean(-1)
    chroma = rgb.max(-1) - rgb.min(-1)
    cand = (chroma <= 10) & (L >= bg - 34) & (L <= bg + 10)   # fundo + sombra suave
    if glow:   # halo laranja da luz: fundo tingido, ainda longe de preto/branco
        warm = (rgb[..., 0] >= rgb[..., 1]) & (rgb[..., 1] >= rgb[..., 2]) & (L >= bg - 20) & (L <= 175) & (chroma <= 110)
        cand |= warm
    bgmask = flood_from_border(cand)
    alpha = np.where(bgmask, 0, 255)
    # remove ilhas minúsculas (poeira do fundo)
    ys, xs = np.nonzero(alpha)
    if len(ys) == 0: return None
    out = rgba(part, alpha)[ys.min():ys.max() + 1, xs.min():xs.max() + 1]
    return out


def key_water(tile):
    rgb = tile.astype(int)
    water = (rgb[..., 2] > rgb[..., 0] + 12) & (rgb[..., 2] >= rgb[..., 1])
    alpha = np.where(water, 0, 255)
    ys, xs = np.nonzero(alpha)
    return rgba(tile, alpha)[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def key_green(tile):
    rgb = tile.astype(int)
    g = (rgb[..., 1] > rgb[..., 0] + 35) & (rgb[..., 1] > rgb[..., 2] + 20)
    alpha = np.where(g, 255, 0)
    ys, xs = np.nonzero(alpha)
    return rgba(tile, alpha)[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def circle_mask(tile):
    h, w = tile.shape[:2]
    yy, xx = np.mgrid[:h, :w]
    r = min(h, w) / 2 - 1
    alpha = np.where((yy - h / 2 + 0.5) ** 2 + (xx - w / 2 + 0.5) ** 2 <= r * r, 255, 0)
    return rgba(tile, alpha)


def recolor(path, hue, sat_k, val_k):
    """Troca o azul do contêiner por outra cor (só os pixels azulados; madeira e metal ficam)."""
    im = Image.open(path).convert("RGBA")
    hsv = np.array(im.convert("RGB").convert("HSV")).astype(np.float32)
    a = np.array(im)[..., 3]
    h, sv, v = hsv[..., 0] / 255.0, hsv[..., 1], hsv[..., 2]
    blue = (h > 0.5) & (h < 0.75) & (sv > 50)
    hsv[..., 0] = np.where(blue, hue * 255, hsv[..., 0])
    hsv[..., 1] = np.where(blue, np.clip(sv * sat_k, 0, 255), sv)
    hsv[..., 2] = np.where(blue, np.clip(v * val_k, 0, 255), v)
    rgb = Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB")
    return Image.fromarray(np.dstack([np.array(rgb), a]).astype(np.uint8), "RGBA")


def light_pool(w, h, color, power=1.8):
    yy, xx = np.mgrid[:h, :w]
    d = np.sqrt(((xx - w / 2 + 0.5) / (w / 2)) ** 2 + ((yy - h / 2 + 0.5) / (h / 2)) ** 2)
    k = np.clip(1 - d, 0, 1) ** power
    rgb = np.zeros((h, w, 3)) + np.array(color)
    return rgba(rgb, k * 255)


def main():
    tiles = load("docks-tileset-v1.png")
    sheet = load("docks-props-v1.png")
    T, P = OUT / "tiles", OUT / "props"
    made = []
    for box, name in zip(PLANKS, PLANK_NAMES): save(fixed(tiles, box, 68, 78), T / f"planks_{name}.png"); made.append(T / f"planks_{name}.png")
    hole = fixed(tiles, PLANK_HOLE, 68, 78)
    save(hole, T / "planks_hole.png"); made.append(T / "planks_hole.png")
    for box, name in zip(GRANITE, GRANITE_NAMES): save(fixed(tiles, box, 66, 103), T / f"granite_{name}.png"); made.append(T / f"granite_{name}.png")
    for i, box in enumerate(QUAY_EDGE): save(fixed(tiles, box, 66, 148)[58:], T / f"quay_edge_{i}.png"); made.append(T / f"quay_edge_{i}.png")
    for i, box in enumerate(WATER): save(fixed(tiles, box, 66, 72), T / f"water_{i}.png"); made.append(T / f"water_{i}.png")
    for i, box in enumerate(FOAM): save(fixed(tiles, box, 66, 60), T / f"foam_{i}.png"); made.append(T / f"foam_{i}.png")
    for i, box in enumerate(WALL_CAP): save(crop(tiles, box), T / f"wall_cap_{i}.png"); made.append(T / f"wall_cap_{i}.png")
    for box, name in zip(BRICK, BRICK_NAMES): save(crop(tiles, box), T / f"brick_{name}.png"); made.append(T / f"brick_{name}.png")
    for i, box in enumerate(WALL_BASE): save(crop(tiles, box), T / f"wall_base_{i}.png"); made.append(T / f"wall_base_{i}.png")
    for i, box in enumerate(WALL_CORNER): save(crop(tiles, box), T / f"wall_corner_{i}.png"); made.append(T / f"wall_corner_{i}.png")
    save(rgba(crop(tiles, GRATE, 0), np.full(crop(tiles, GRATE, 0).shape[:2], 255)), T / "grate.png"); made.append(T / "grate.png")
    save(circle_mask(crop(tiles, MANHOLE, 0)), T / "manhole.png"); made.append(T / "manhole.png")
    for i, box in enumerate(SYMBOLS): save(key_green(crop(tiles, box)), T / f"symbol_{i}.png"); made.append(T / f"symbol_{i}.png")
    save(key_water(crop(tiles, PILING)[30:, 12:46]), T / "piling.png"); made.append(T / "piling.png")
    # topo da parede visto de cima, girado para as paredes laterais (faixa vertical)
    cap = crop(tiles, WALL_CAP[0])[:34]
    save(np.rot90(cap, 1).copy(), T / "side_cap.png"); made.append(T / "side_cap.png")

    bg = int(np.median(sheet[:6, :].reshape(-1, 3).mean(-1)))
    for name, box in PROPS.items():
        cut = cut_prop(sheet, box, bg, name in GLOW_PROPS)
        if cut is None: print("vazio:", name); continue
        save(cut, P / f"{name}.png"); made.append(P / f"{name}.png")

    # contêineres recoloridos (a folha só tem o azul)
    for name in ("container", "container_open"):
        for color, hue, sat, val in (("red", 0.0, 1.0, 0.95), ("olive", 0.16, 0.65, 0.85)):
            out = recolor(P / f"{name}.png", hue, sat, val)
            out.save(P / f"{name}_{color}.png"); made.append(P / f"{name}_{color}.png")

    FX = OUT / "fx"
    save(light_pool(320, 180, (255, 150, 60)), FX / "light_amber.png")
    save(light_pool(160, 160, (120, 255, 150), 2.2), FX / "light_green.png")
    save(light_pool(256, 256, (255, 255, 255), 1.4), FX / "soft_circle.png")
    made += [FX / "light_amber.png", FX / "light_green.png", FX / "soft_circle.png"]

    # prévia: tudo sobre fundo xadrez
    ims = [Image.open(p).convert("RGBA") for p in made]
    W, x, y, row_h, pos = 1600, 10, 10, 0, []
    for im in ims:
        if x + im.width + 10 > W: x = 10; y += row_h + 22; row_h = 0
        pos.append((x, y)); x += im.width + 10; row_h = max(row_h, im.height)
    H = y + row_h + 30
    prev = Image.new("RGBA", (W, H), (40, 40, 48, 255))
    d = ImageDraw.Draw(prev)
    for im, (px, py), p in zip(ims, pos, made):
        d.rectangle((px - 1, py - 1, px + im.width, py + im.height), outline=(70, 70, 80))
        prev.alpha_composite(im, (px, py))
        d.text((px, py + im.height + 2), p.stem[:14], fill=(200, 200, 200))
    (ROOT / "art").mkdir(exist_ok=True)
    prev.save(ROOT / "art/docks-v12-preview.png")
    print(len(made), "arquivos em", OUT)


if __name__ == "__main__":
    main()
