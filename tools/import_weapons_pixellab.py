"""Import approved PixelLab weapon sprites into the Godot weapon canvases."""

from pathlib import Path
from urllib.request import urlretrieve

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/source/weapons/pixellab"
TARGET = ROOT / "assets/weapons"
BASE_URL = "https://api.pixellab.ai/mcp/images/{}/download"

# Native canvas sizes and placement preserve the existing hand and muzzle anchors.
WEAPONS = {
    "pistol": ("8961da1a-8e96-4cc9-a5d3-dab6294aa967", (40, 18), (2, 0, 38, 17)),
    "shotgun": ("6c2a3cc8-9187-48dd-affa-e0e81d31edd8", (56, 18), (0, 1, 56, 16)),
    "smg": ("5c890c70-624c-4808-8f76-045b2c41b9d8", (52, 22), (0, 1, 52, 21)),
    "bazooka_v2": ("b2154ea4-ca54-4a15-9a3d-24459a5bc426", (96, 64), (3, 19, 91, 48)),
    "omega_sword": ("4167626e-f655-4b59-8aee-8e2c3108f369", (78, 20), (0, 0, 78, 19)),
}


def main() -> None:
    SOURCE.mkdir(parents=True, exist_ok=True)
    preview_rows = []
    for name, (job_id, canvas_size, box) in WEAPONS.items():
        raw = SOURCE / f"{name}.png"
        if not raw.exists():
            urlretrieve(BASE_URL.format(job_id), raw)
        image = Image.open(raw).convert("RGBA")
        bounds = image.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"PixelLab returned an empty sprite for {name}")
        weapon = image.crop(bounds)
        weapon = weapon.resize((box[2] - box[0], box[3] - box[1]), Image.Resampling.NEAREST)
        canvas = Image.new("RGBA", canvas_size)
        canvas.alpha_composite(weapon, box[:2])
        canvas.save(TARGET / f"{name}.png", optimize=True)
        preview_rows.append((name, canvas))
        print(f"{name}: source {image.size}, sprite {bounds}, canvas {canvas_size}")

    row_heights = [max(48, canvas.height * 4) + 24 for _, canvas in preview_rows]
    preview = Image.new("RGB", (600, sum(row_heights) + 16), (27, 32, 47))
    draw = ImageDraw.Draw(preview)
    y = 8
    for (name, canvas), row_height in zip(preview_rows, row_heights):
        draw.text((16, y + 8), name.replace("_", " ").upper(), fill=(239, 198, 113))
        scaled = canvas.resize((canvas.width * 4, canvas.height * 4), Image.Resampling.NEAREST)
        preview.paste(scaled, (170, y + 8), scaled)
        y += row_height
    preview.save(ROOT / "art/weapons-pixellab-preview.png", optimize=True)


if __name__ == "__main__":
    main()
