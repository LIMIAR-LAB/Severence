"""0.16: tela inicial em vídeo (loop em pixel art enviado pelo usuário).

O vídeo já traz o painel do menu desenhado (logo, CONTINUAR, NOVA EXPEDIÇÃO, ONLINE, EXPEDIÇÃO DIRETA,
EQUIPAMENTO, OPÇÕES, SAIR, OFFLINE). No jogo ele toca em loop no fundo e os botões são Controls reais
por cima. Como o CONTINUAR vem "aceso" no vídeo, este script gera duas placas estáticas por botão:
  btn_N.png      estado normal (o CONTINUAR é refeito no estilo apagado dos outros)
  btn_N_sel.png  estado aceso (moldura ciana do CONTINUAR com o ícone e o texto do botão N em ciano)
As placas cobrem o botão do vídeo e o jogo troca uma pela outra no hover/foco.

Uso: python3 tools/make_title_screen.py <video.mp4>
Saída: assets/ui/title/title_loop.ogv (Theora 1344x752, 24 fps — o formato de vídeo do Godot) e as placas.
Precisa de ffmpeg com libtheora, numpy e pillow.
"""
from pathlib import Path
import subprocess, sys, tempfile
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/title"
SRC_W, SRC_H = 1920, 1088
CROP_Y = 7                      # 1088 -> 1074 (proporção 1344x752) e escala 0.7
K = 0.7
VF = f"crop=1920:1074:0:{CROP_Y},scale=1344:752:flags=lanczos"

# botões no vídeo original (px de 1920x1088): topo de cada placa; todas com 62 px de altura
TOPS = [388, 459, 530, 601, 672, 743, 814]
X0, X1 = 52, 488                # moldura do botão
PAD_X, PAD_T, PAD_B = 8, 7, 9   # margem das placas (brilho do CONTINUAR aceso e sombra)
IN_X0, IN_X1 = 80, 462          # miolo com ícone + texto (entre os rebites)
IN_T, IN_B = 8, 56              # miolo em y, relativo ao topo
CLEAN = (400, 460)              # faixa sem conteúdo nos botões, usada para apagar ícone e texto


def run(cmd):
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def median_frame(video: Path) -> np.ndarray:
    with tempfile.TemporaryDirectory() as tmp:
        run(["ffmpeg", "-y", "-i", str(video), "-vf", "fps=6", f"{tmp}/f_%03d.png"])
        frames = [np.asarray(Image.open(p).convert("RGB")) for p in sorted(Path(tmp).glob("f_*.png"))]
    return np.median(np.stack(frames), 0).astype(np.uint8)   # tira o ruído de compressão


def box(i):
    t = TOPS[i]
    return (X0 - PAD_X, t - PAD_T, X1 + PAD_X, t + 62 + PAD_B)


def erase_content(img: np.ndarray, top: int) -> np.ndarray:
    """Apaga ícone e texto repetindo uma faixa limpa do próprio botão."""
    out = img.copy()
    strip = img[top + IN_T:top + IN_B, CLEAN[0]:CLEAN[1]]
    x = IN_X0
    while x < IN_X1:
        w = min(strip.shape[1], IN_X1 - x)
        out[top + IN_T:top + IN_B, x:x + w] = strip[:, :w]
        x += w
    return out


def content_mask(img: np.ndarray, top: int, kind: str) -> np.ndarray:
    """Máscara do ícone + texto (dourado nos normais, ciano no CONTINUAR aceso)."""
    reg = img[top + IN_T:top + IN_B, IN_X0:IN_X1].astype(int)
    r, g, b = reg[..., 0], reg[..., 1], reg[..., 2]
    if kind == "gold": m = (r > 150) & (g > 110) & (r > b + 40)
    else: m = (b > 170) & (g > 150) & (b > r + 50)
    return m


def paint(dst: np.ndarray, top: int, mask: np.ndarray, light, shade, lum: np.ndarray) -> None:
    """Pinta o conteúdo com contorno escuro (como o texto original) e degradê de luz."""
    m_img = Image.fromarray((mask * 255).astype(np.uint8))
    outline = np.asarray(m_img.filter(ImageFilter.MaxFilter(5))) > 0
    reg = dst[top + IN_T:top + IN_B, IN_X0:IN_X1]
    reg[outline & ~mask] = (22, 18, 12)
    t = np.clip((lum - lum[mask].min()) / max(1, np.ptp(lum[mask])), 0, 1) if mask.any() else lum
    for c in range(3):
        ch = reg[..., c]
        ch[mask] = (shade[c] + (light[c] - shade[c]) * t[mask]).astype(np.uint8)


def to_design(img: np.ndarray, b) -> tuple:
    """Mesma transformação do vídeo (corte + escala) e recorte da placa no espaço 1344x752."""
    full = Image.fromarray(img).crop((0, CROP_Y, SRC_W, CROP_Y + 1074)).resize((1344, 752), Image.LANCZOS)
    x0, y0 = int(b[0] * K), int((b[1] - CROP_Y) * K)
    x1, y1 = int(round(b[2] * K)), int(round((b[3] - CROP_Y) * K))
    return full.crop((x0, y0, x1, y1)), (x0, y0, x1 - x0, y1 - y0)


def main(video: Path) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    run(["ffmpeg", "-y", "-i", str(video), "-vf", VF, "-c:v", "libtheora", "-q:v", "8", "-an", str(OUT / "title_loop.ogv")])
    med = median_frame(video)
    lum = med.astype(float).mean(2)
    gold_light, gold_shade = (255, 222, 150), (196, 142, 70)
    cyan_light, cyan_shade = (190, 250, 255), (40, 200, 235)
    c_top = TOPS[0]
    sel_base = erase_content(med, c_top)                # moldura ciana vazia
    rects = []
    for i, top in enumerate(TOPS):
        # normal
        if i == 0:
            # CONTINUAR apagado: placa da NOVA EXPEDIÇÃO sem conteúdo + ícone/texto do CONTINUAR em dourado
            normal = med.copy()
            src_top = TOPS[1]
            blank = erase_content(med, src_top)
            bx0, y0, bx1, y1 = box(0)
            dy = src_top - c_top
            normal[y0:y1, bx0:bx1] = blank[y0 + dy:y1 + dy, bx0:bx1]
            m = content_mask(med, c_top, "cyan")
            paint(normal, c_top, m, gold_light, gold_shade, lum[c_top + IN_T:c_top + IN_B, IN_X0:IN_X1])
        else:
            normal = med
        img, rect = to_design(normal, box(i))
        img.save(OUT / f"btn_{i}.png")
        # aceso: moldura do CONTINUAR com o conteúdo deste botão em ciano
        sel = med.copy()
        bx0, y0, bx1, y1 = box(i)
        dy = c_top - top
        sel[y0:y1, bx0:bx1] = sel_base[y0 + dy:y1 + dy, bx0:bx1]
        if i == 0: m = content_mask(med, c_top, "cyan"); l = lum[c_top + IN_T:c_top + IN_B, IN_X0:IN_X1]
        else: m = content_mask(med, top, "gold"); l = lum[top + IN_T:top + IN_B, IN_X0:IN_X1]
        paint(sel, top, m, cyan_light, cyan_shade, l)
        img, _ = to_design(sel, box(i))
        img.save(OUT / f"btn_{i}_sel.png")
        rects.append(rect)
    print("TITLE_BUTTONS := [" + ", ".join("Rect2(%d, %d, %d, %d)" % r for r in rects) + "]")
    Image.fromarray(med).crop((0, CROP_Y, SRC_W, CROP_Y + 1074)).resize((1344, 752), Image.LANCZOS).save(OUT / "title_still.png")
    print("wrote", OUT)


if __name__ == "__main__":
    if len(sys.argv) < 2: sys.exit("uso: python3 tools/make_title_screen.py <video.mp4>")
    main(Path(sys.argv[1]))
