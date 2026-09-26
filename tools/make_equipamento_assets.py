"""0.17: recortes da tela de EQUIPAMENTO modular (artes do usuário, montadas em camadas pelo jogo).

Fontes (art/source/equipamento/):
  equip_moldura_original.png  moldura 1344x752 com painéis, títulos e botões (slots vazios)
  equip_icones.png            folha de ícones 3x4 sobre fundo cinza
  card_*.png                  cards 1:1 (1024x1024) da vitrine

Saída (assets/ui/equipamento/):
  equip_moldura.png   a moldura sem os destaques ciano "pintados" (1ª linha de UNIFORME e aba MARTY) —
                      seleção e foco são desenhados pelo jogo por cima
  equip_icones.png    a folha original (referência)
  icones/*.png        um arquivo por ícone, fundo cinza removido (transparente), já no tamanho do slot
  cards/*.png         cards da vitrine em 360x360 (mostrados 1:1 no espaço 1344x752, filtro Nearest)

Uso: python3 tools/make_equipamento_assets.py
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/source/equipamento"
OUT = ROOT / "assets/ui/equipamento"

# grade da folha de ícones (caixas medidas na folha 1344x752)
SHEET = {
    "icon_uniforme_padrao": (344, 10, 523, 188), "icon_uniforme_mecanico": (581, 9, 763, 187), "icon_uniforme_espiao": (822, 9, 1000, 188),
    "icon_armadura_omega": (344, 201, 524, 369), "icon_armadura_omega_bloqueada": (581, 201, 763, 369), "icon_slot_vazio": (822, 203, 1000, 368),
    "icon_robo_titan": (344, 386, 523, 552), "icon_robo_spectre": (581, 387, 763, 551), "icon_robo_titan_bloqueado": (822, 386, 1000, 552),
    "icon_cadeado": (368, 584, 498, 709), "frame_selecao": (589, 570, 755, 724), "frame_lendario": (829, 568, 992, 723),
}
UNIFORM_ICON = 72     # altura dos ícones de uniforme (slot ~84x74)
BIG_ICON = 84         # armadura e robô (slots ~88x94)
FRAME = 84            # molduras de seleção (usadas como NinePatch)
CARD = 360
# áreas de texto da moldura (x0, y0, x1, y1) — sem as linhas-guia
TEXT_AREAS = [(138, 140, 346, 212), (138, 230, 346, 300), (138, 318, 346, 392),
              (52, 590, 352, 646), (716, 546, 930, 642), (992, 472, 1302, 640)]


def cut_background(img: Image.Image, fill_interior: bool = False) -> Image.Image:
    """Tira o cinza de fundo por preenchimento a partir da borda (não apaga cinza de dentro do ícone)."""
    a = np.asarray(img.convert("RGB")).astype(int)
    gray = np.abs(a - np.array([128, 128, 128])).sum(2) < 40
    lab, _ = ndimage.label(gray)
    edge = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(edge))
    if fill_interior:   # molduras: o miolo azul-marinho também vira transparente
        navy = (a[..., 2] > a[..., 0] + 8) & (a.sum(2) < 170)
        lab2, _ = ndimage.label(navy)
        c = lab2[a.shape[0] // 2, a.shape[1] // 2]
        if c: bg |= lab2 == c
    alpha = np.where(bg, 0, 255).astype(np.uint8)
    alpha = np.asarray(Image.fromarray(alpha).filter(ImageFilter.MinFilter(3)))
    rgba = np.dstack([a.astype(np.uint8), alpha])
    return Image.fromarray(rgba, "RGBA")


def fit(img: Image.Image, h: int) -> Image.Image:
    w = round(img.width * h / img.height)
    return img.resize((w, h), Image.LANCZOS)


def locked(icon: Image.Image, lock: Image.Image) -> Image.Image:
    """Versão bloqueada no estilo da folha: silhueta escura azulada + cadeado no canto."""
    rgb = icon.convert("RGB")
    g = ImageEnhance.Brightness(ImageEnhance.Color(rgb).enhance(0.0)).enhance(0.38)
    tint = Image.new("RGB", rgb.size, (22, 30, 58))
    out = Image.blend(g, tint, 0.35).convert("RGBA"); out.putalpha(icon.split()[3])
    lk = fit(lock, max(12, icon.height // 3))
    out.alpha_composite(lk, (icon.width - lk.width - 3, icon.height - lk.height - 3))
    return out


def neutral_moldura() -> Image.Image:
    m = np.asarray(Image.open(SRC / "equip_moldura_original.png").convert("RGB")).copy()
    # 1ª linha de UNIFORME vem acesa (ciano): copia a 3ª linha, que tem o mesmo desenho apagado
    m[126:221, 38:362] = m[307:402, 38:362]
    # aba MARTY acesa: ciano -> cinza-aço (mesmo tom da aba ECHO)
    tab = m[14:74, 862:1082].astype(int)
    cyan = (tab[..., 2] > tab[..., 0] + 40) & (tab[..., 1] > tab[..., 0] + 30)
    lum = tab.mean(2)
    gray = np.stack([lum * 0.92, lum * 0.95, lum * 1.0], 2)
    tab[cyan] = gray[cyan].clip(0, 255)
    m[14:74, 862:1082] = tab.astype(np.uint8)
    # linhas-guia das áreas de texto: o jogo escreve por cima, então some com elas (repete a faixa de cima)
    for x0, y0, x1, y1 in TEXT_AREAS:
        area = m[y0:y1, x0:x1].astype(int)
        lum = area.mean(axis=(1, 2))
        base = np.median(lum)
        for r in range(area.shape[0]):
            if lum[r] > base + 10: m[y0 + r, x0:x1] = m[y0 + r - 3, x0:x1]
    return Image.fromarray(m)


def main() -> None:
    (OUT / "icones").mkdir(parents=True, exist_ok=True); (OUT / "cards").mkdir(parents=True, exist_ok=True)
    neutral_moldura().save(OUT / "equip_moldura.png")
    sheet = Image.open(SRC / "equip_icones.png").convert("RGB")
    sheet.save(OUT / "equip_icones.png")
    raw = {k: cut_background(sheet.crop(b), k.startswith("frame_")) for k, b in SHEET.items()}
    lock = raw["icon_cadeado"]
    for k, img in raw.items():
        h = UNIFORM_ICON if k.startswith("icon_uniforme") else (FRAME if k.startswith("frame_") else BIG_ICON)
        if k == "icon_cadeado": h = 56
        fit(img, h).save(OUT / "icones" / f"{k}.png")
    # itens sem versão bloqueada na folha: gerada no mesmo estilo
    for k in ["icon_uniforme_mecanico", "icon_uniforme_espiao", "icon_robo_spectre"]:
        h = UNIFORM_ICON if k.startswith("icon_uniforme") else BIG_ICON
        base = "icon_robo_spectre" if k == "icon_robo_spectre" else k
        name = base.replace("icon_robo_spectre", "icon_robo_spectre_bloqueado") if k == "icon_robo_spectre" else k + "_bloqueado"
        locked(fit(raw[k], h), lock).save(OUT / "icones" / f"{name}.png")
    for card in sorted(SRC.glob("card_*.png")):
        Image.open(card).convert("RGB").resize((CARD, CARD), Image.LANCZOS).save(OUT / "cards" / card.name)
    print("wrote", OUT)


if __name__ == "__main__":
    main()
