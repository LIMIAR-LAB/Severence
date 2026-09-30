"""Desenha o armamento temporário das Docas em pixels rígidos (0.21)."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
image = Image.new("RGBA", (32, 14))
d = ImageDraw.Draw(image)
dark, edge, olive, brass, cyan = "#10151b", "#252c2b", "#52614d", "#c49553", "#4be4f0"
d.rectangle((1, 4, 28, 10), fill=dark)
d.rectangle((3, 5, 27, 9), fill=olive)
d.rectangle((0, 3, 5, 11), fill=edge, outline=dark)
d.rectangle((1, 4, 3, 10), fill=brass)
d.rectangle((6, 4, 8, 10), fill=brass)
d.rectangle((20, 4, 22, 10), fill=brass)
d.rectangle((24, 2, 28, 4), fill=edge)
d.rectangle((26, 3, 31, 11), fill=dark)
d.rectangle((27, 4, 30, 10), fill="#758276")
d.rectangle((28, 5, 29, 9), fill=cyan)
d.polygon([(13, 10), (18, 10), (19, 13), (15, 13)], fill=dark)
d.rectangle((15, 10, 17, 12), fill=brass)
d.rectangle((10, 3, 14, 4), fill=edge)
image.resize((64, 28), Image.Resampling.NEAREST).save(root / "assets/weapons/bazooka.png")
