"""0.16: retratos do palco da tela de EQUIPAMENTO v3 (layout art/concept/equipamento-v3-mockup.png).

Fontes (arte do usuário, sem redesenhar ninguém):
  art/source/portraits-anime-v1.png   folha 3x2: padrão, mecânico, espião / ômega, titan, almirante
  art/concept/equipamento-v3-mockup.png  o palco do padrão (arte larga do mockup)
O Spectre não está na folha: o retrato usa o sprite do jogo (spectre_octopus_v2) sobre a tempestade roxa
do painel do Almirante, até existir uma arte própria.

Saída: assets/ui/portraits_v3/{o_padrao,o_mecanico,o_espiao,armor_omega,titan,spectre,almirante}.png
em 1100x704 (proporção do palco, 1.5625). O jogo mostra com filtro linear e KEEP_ASPECT_COVERED.
Uso: python3 tools/make_portraits_v3.py
"""
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "art/source/portraits-anime-v1.png"
MOCKUP = ROOT / "art/concept/equipamento-v3-mockup.png"
OUT = ROOT / "assets/ui/portraits_v3"
W, H = 1100, 704

# arte de cada painel da folha (sem moldura e sem a placa com o nome), em px da folha 1024x687
COLS = [(8, 329), (352, 675), (694, 1016)]
ROWS = [(16, 300), (360, 646)]
CELLS = {
    "o_padrao": (0, 0), "o_mecanico": (1, 0), "o_espiao": (2, 0),
    "armor_omega": (0, 1), "titan": (1, 1), "almirante": (2, 1),
}
# foco horizontal de cada personagem dentro do painel (0..1) — o recorte largo centra nele
FOCUS = {"o_padrao": 0.5, "o_mecanico": 0.45, "o_espiao": 0.55, "armor_omega": 0.5, "titan": 0.55, "almirante": 0.5}


def cover(img: Image.Image, w: int, h: int, fx: float = 0.5, fy: float = 0.5) -> Image.Image:
    f = max(w / img.width, h / img.height)
    big = img.resize((max(w, round(img.width * f)), max(h, round(img.height * f))), Image.LANCZOS)
    x = round((big.width - w) * fx); y = round((big.height - h) * fy)
    return big.crop((x, y, x + w, y + h))


def widen(panel: Image.Image, focus: float) -> Image.Image:
    """Painel quase quadrado -> palco largo: a arte inteira na altura, laterais com a própria arte desfocada."""
    back = cover(panel, W, H, focus, 0.5).filter(ImageFilter.GaussianBlur(18))
    back = ImageEnhance.Brightness(back).enhance(0.55)
    fh = H
    fw = round(panel.width * fh / panel.height)
    fore = panel.resize((fw, fh), Image.LANCZOS)
    fore = ImageEnhance.Sharpness(fore).enhance(1.35)
    x0 = round(W * focus - fw / 2); x0 = max(0, min(W - fw, x0))
    # máscara com bordas laterais esfumadas (as laterais somem no fundo desfocado)
    mask = Image.new("L", (fw, fh), 255)
    d = ImageDraw.Draw(mask)
    feather = 90
    for i in range(feather):
        a = round(255 * i / feather)
        d.line((i, 0, i, fh), fill=a); d.line((fw - 1 - i, 0, fw - 1 - i, fh), fill=a)
    out = back.copy(); out.paste(fore, (x0, 0), mask)
    return out


def vignette(img: Image.Image) -> Image.Image:
    v = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(v)
    for i in range(60):
        d.rectangle((i, i, img.width - 1 - i, img.height - 1 - i), outline=round(120 * (1 - i / 60)))
    shade = Image.new("RGB", img.size, (4, 10, 14))
    return Image.composite(shade, img, v)


def spectre(storm: Image.Image) -> Image.Image:
    sheet = Image.open(ROOT / "assets/mech/spectre_octopus_v2.png").convert("RGBA")
    fig = sheet.crop((0, 0, 128, 128))
    fig = fig.crop(fig.getbbox())
    fig = fig.resize((fig.width * 5, fig.height * 5), Image.NEAREST)   # pixel art: só nearest
    bg = cover(storm, W, H, 0.5, 0.5).filter(ImageFilter.GaussianBlur(10))
    bg = ImageEnhance.Brightness(bg).enhance(0.5).convert("RGBA")
    # brilho ciano atrás do Spectre
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((W / 2 - 260, H / 2 - 230, W / 2 + 260, H / 2 + 230), fill=(70, 200, 240, 110))
    bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(70)))
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse((W / 2 - 200, H - 150, W / 2 + 200, H - 90), fill=(0, 0, 0, 170))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(14)))
    x = (W - fig.width) // 2; y = H - 120 - fig.height
    halo = Image.new("RGBA", fig.size, (120, 90, 255, 0)); halo.putalpha(fig.split()[3].filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(16)).point(lambda a: a * 0.6))
    bg.alpha_composite(halo, (x, y)); bg.alpha_composite(fig, (x, y))
    return bg.convert("RGB")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(SHEET).convert("RGB")
    panels = {}
    for key, (c, r) in CELLS.items():
        (x0, x1), (y0, y1) = COLS[c], ROWS[r]
        panels[key] = sheet.crop((x0, y0, x1, y1))
    for key, panel in panels.items():
        img = widen(panel, FOCUS[key])
        if key == "o_padrao":
            # o mockup já traz o padrão numa arte larga: usa o miolo (sem o título e as setas do mockup)
            mock = Image.open(MOCKUP).convert("RGB").crop((300, 92, 740, 356))
            img = ImageEnhance.Sharpness(cover(mock, W, H, 0.45, 0.3)).enhance(1.3)
        vignette(img).save(OUT / f"{key}.png")
        print("wrote", OUT / f"{key}.png")
    vignette(spectre(panels["almirante"])).save(OUT / "spectre.png")
    print("wrote", OUT / "spectre.png")


if __name__ == "__main__":
    main()
