"""0.16: arte do palco da tela de EQUIPAMENTO v3 (layout art/concept/equipamento-v3-mockup.png).

Fonte: art/source/portraits-v4/{chave}.png — cartas 1024x1024 em pixel art enviadas pelo usuário
(padrão, mecânico, espião, ômega, titan, spectre, almirante), com moldura de latão e placa com o nome.
Aqui só se tira a moldura e a placa e se adapta ao formato do palco; ninguém é redesenhado.

Saída: assets/ui/portraits_v3/{o_padrao,o_mecanico,o_espiao,armor_omega,titan,spectre,almirante}.png
em 1100x704 (proporção do palco, 1.5625): a carta inteira na altura e as laterais preenchidas com a
própria arte desfocada. O jogo mostra com KEEP_ASPECT_COVERED.
Uso: python3 tools/make_portraits_v3.py
"""
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/source/portraits-v4"
OUT = ROOT / "assets/ui/portraits_v3"
W, H = 1100, 704
KEYS = ["o_padrao", "o_mecanico", "o_espiao", "armor_omega", "titan", "spectre", "almirante"]
# miolo da carta sem a moldura (laterais ~30 px, cantoneiras no topo) e sem a placa do nome (y > ~860)
INNER = (34, 72, 990, 848)


def cover(img: Image.Image, w: int, h: int, fx: float = 0.5, fy: float = 0.5) -> Image.Image:
    f = max(w / img.width, h / img.height)
    big = img.resize((max(w, round(img.width * f)), max(h, round(img.height * f))), Image.LANCZOS)
    x = round((big.width - w) * fx); y = round((big.height - h) * fy)
    return big.crop((x, y, x + w, y + h))


def widen(art: Image.Image) -> Image.Image:
    """Arte quase quadrada -> palco largo: a arte inteira na altura, laterais com a própria arte desfocada."""
    back = cover(art, W, H).filter(ImageFilter.GaussianBlur(16))
    back = ImageEnhance.Brightness(back).enhance(0.5)
    fw = round(art.width * H / art.height)
    fore = art.resize((fw, H), Image.LANCZOS)
    x0 = (W - fw) // 2
    mask = Image.new("L", (fw, H), 255)
    d = ImageDraw.Draw(mask)
    feather = 70
    for i in range(feather):
        a = round(255 * i / feather)
        d.line((i, 0, i, H), fill=a); d.line((fw - 1 - i, 0, fw - 1 - i, H), fill=a)
    out = back.copy(); out.paste(fore, (x0, 0), mask)
    return out


def vignette(img: Image.Image) -> Image.Image:
    v = Image.new("L", img.size, 0)
    d = ImageDraw.Draw(v)
    for i in range(50):
        d.rectangle((i, i, img.width - 1 - i, img.height - 1 - i), outline=round(110 * (1 - i / 50)))
    return Image.composite(Image.new("RGB", img.size, (4, 10, 14)), img, v)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for key in KEYS:
        art = Image.open(SRC / f"{key}.png").convert("RGB").crop(INNER)
        vignette(widen(art)).save(OUT / f"{key}.png")
        print("wrote", OUT / f"{key}.png")


if __name__ == "__main__":
    main()
