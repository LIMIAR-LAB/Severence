"""Pack the generated eight-direction attack/death sheets into Godot cells."""

from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/source/enemy-actions-ai"
TARGET = ROOT / "assets/enemies"
KINDS = ("cult", "crawler", "fish", "brute")
CELL = (160, 128)


def row_cuts(alpha: np.ndarray) -> list[int]:
    height = alpha.shape[0]
    occupancy = (alpha > 96).sum(axis=1)
    cuts = [0]
    for row in range(1, 8):
        expected = round(row * height / 8)
        lo, hi = expected - 42, expected + 42
        quiet = np.where(occupancy[lo:hi] < 3)[0] + lo
        if quiet.size:
            cuts.append(int(quiet[np.argmin(abs(quiet - expected))]))
        else:
            cuts.append(int(np.argmin(occupancy[lo:hi]) + lo))
    return cuts + [height]


def pack(kind: str) -> None:
    image = Image.open(SOURCE / f"{kind}.png").convert("RGBA")
    if image.size != (992, 1586):
        raise ValueError(f"{kind}: unexpected generated sheet size {image.size}")
    cuts = row_cuts(np.asarray(image)[:, :, 3])
    sprites = []
    for row in range(8):
        for col, (left, right) in enumerate(((0, 520), (520, image.width))):
            block = image.crop((left, cuts[row], right, cuts[row + 1]))
            alpha = np.asarray(block)[:, :, 3]
            ys, xs = np.where(alpha > 64)
            if not len(xs):
                raise ValueError(f"{kind}: empty row {row}, column {col}")
            sprite = block.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1))
            sprites.append(sprite)

    # One scale per kind keeps pose changes from resizing the monster.
    ratio = min(1.0, 150 / max(s.width for s in sprites), 108 / max(s.height for s in sprites))
    atlas = Image.new("RGBA", (CELL[0] * 2, CELL[1] * 8))
    for row in range(8):
        for col in range(2):
            sprite = sprites[row * 2 + col]
            sprite = sprite.resize((round(sprite.width * ratio), round(sprite.height * ratio)), Image.Resampling.NEAREST)
            x = col * CELL[0] + (CELL[0] - sprite.width) // 2
            y = row * CELL[1] + 119 - sprite.height
            if x < col * CELL[0] + 2 or x + sprite.width > (col + 1) * CELL[0] - 2:
                raise ValueError(f"{kind}: sprite touches horizontal cell border")
            atlas.alpha_composite(sprite, (x, y))
    TARGET.mkdir(parents=True, exist_ok=True)
    atlas.save(TARGET / f"{kind}_actions_v1.png")
    print(f"{kind}: {atlas.size}, scale={ratio:.3f}, cuts={cuts}")


if __name__ == "__main__":
    for name in KINDS:
        pack(name)
