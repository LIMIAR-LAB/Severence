"""Prepare PixelLab room plates; keep originals and remove only export margins."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/source/pixellab/rooms-v1"
TARGET = ROOT / "assets/environment/docks12/rooms_pixellab"

def prepare():
    TARGET.mkdir(parents=True, exist_ok=True)
    corridor = ROOT / "art/source/pixellab/corridors-v1/corridor.png"
    if corridor.exists():
        deck = Image.open(corridor).convert("RGB")
        deck.save(TARGET / "corridor.png")
        deck.transpose(Image.Transpose.ROTATE_90).save(TARGET / "corridor_vertical.png")
    manifest = json.loads((SOURCE / "manifest.json").read_text(encoding="utf-8"))
    for entry in manifest["rooms"]:
        source = SOURCE / (entry["id"] + ".png")
        if not source.exists():
            continue
        image = Image.open(source).convert("RGB")
        pixels = np.asarray(image)
        content = np.min(pixels, axis=2) < 235
        rows = content[content.any(axis=1)]
        cols = content[:, content.any(axis=0)]
        left = int(np.quantile(rows.argmax(axis=1), .95))
        right = image.width - int(np.quantile(rows[:, ::-1].argmax(axis=1), .95))
        top = int(np.quantile(cols.argmax(axis=0), .95))
        bottom = image.height - int(np.quantile(cols[::-1].argmax(axis=0), .95))
        # Bound the crop to the outer margin, never trim room composition.
        if left > image.width * .1 or top > image.height * .1:
            raise ValueError(f"Unexpected export margin: {source.name}")
        crop = [left, top, right, bottom]
        image.crop(crop).save(TARGET / source.name)
        entry["source_size"] = list(image.size)
        entry["crop"] = crop
        print(entry["id"], crop)
    (SOURCE / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

if __name__ == "__main__":
    prepare()
