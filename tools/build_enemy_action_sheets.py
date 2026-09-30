"""Pack eight-direction windup, shot, recoil and death sprites into Godot atlases."""

from pathlib import Path
from PIL import Image
import numpy as np
from scipy.ndimage import label

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/source/enemy-actions-ai"
TARGET = ROOT / "assets/enemies"
KINDS = ("cult", "crawler", "fish", "brute", "guard", "bomber")
CELL = (256, 160)
BASELINE = 145
IDLE_HEIGHT = {"cult": 77, "crawler": 71, "fish": 76, "brute": 98, "guard": 74, "bomber": 63}


def row_cuts(alpha: np.ndarray, count: int = 8) -> list[int]:
    height = alpha.shape[0]
    occupancy = (alpha > 96).sum(axis=1)
    cuts = [0]
    for row in range(1, count):
        expected = round(row * height / count)
        lo, hi = expected - 42, expected + 42
        quiet = np.where(occupancy[lo:hi] < 3)[0] + lo
        cuts.append(int(quiet[np.argmin(abs(quiet - expected))]) if quiet.size else int(np.argmin(occupancy[lo:hi]) + lo))
    return cuts + [height]


def extract(image: Image.Image, cuts: list[int], kind: str) -> list[list[Image.Image]]:
    sprites = []
    for row in range(len(cuts) - 1):
        pair = []
        for col, (left, right) in enumerate(((0, 520), (520, image.width))):
            block = image.crop((left, cuts[row], right, cuts[row + 1]))
            alpha = np.asarray(block)[:, :, 3]
            ys, xs = np.where(alpha > 64)
            if not len(xs):
                raise ValueError(f"{kind}: empty row {row}, column {col}")
            pair.append(block.crop((int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)))
        sprites.append(pair)
    return sprites


def pack(kind: str) -> None:
    peak_sheet = Image.open(SOURCE / f"{kind}.png").convert("RGBA")
    transition_sheet = Image.open(SOURCE / f"{kind}-transitions.png").convert("RGBA")
    for sheet in (peak_sheet, transition_sheet):
        if abs(sheet.width - 992) > 1 or abs(sheet.height - 1586) > 1:
            raise ValueError(f"{kind}: unexpected generated sheet size {sheet.size}")
    peak_cuts = row_cuts(np.asarray(peak_sheet)[:, :, 3])
    if kind == "guard":
        peak_cuts = [0, 198, 396, 578, 760, 956, 1128, 1312, peak_sheet.height]
    peak = extract(peak_sheet, peak_cuts, kind)
    if kind == "guard":
        # The generated southeast flash points left across the shield. The
        # mirrored southwest frame has the correct southeast barrel direction.
        peak[1][0] = peak[7][0].transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    # The fish source contains seven rendered directions. Mirror its northeast
    # pair for northwest while retaining the correct directional silhouette.
    transition_count = 7 if kind == "fish" else 8
    transition_cuts = row_cuts(np.asarray(transition_sheet)[:, :, 3], transition_count)
    if kind == "fish":
        transition_cuts = [0, 222, 430, 640, 848, 1054, 1262, transition_sheet.height]
    transitions = extract(transition_sheet, transition_cuts, kind)
    if kind == "fish":
        transitions.append([frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in transitions[1]])
    # The cultist and fish recoil art changes the gun's direction and apparent
    # body size. Return through their windup to keep the aim and silhouette stable.
    sprites = [[transitions[row][0], peak[row][0], transitions[row][0] if kind in ("cult", "fish") else transitions[row][1], peak[row][1]] for row in range(8)]
    # Equalize pose heights against the idle atlas, preserving proportions.
    ratios = []
    for col in range(4):
        frames = [sprites[row][col] for row in range(8)]
        median_height = float(np.median([frame.height for frame in frames]))
        ratios.append(min(IDLE_HEIGHT[kind] / median_height, 248 / max(frame.width for frame in frames), 140 / max(frame.height for frame in frames)))
    atlas = Image.new("RGBA", (CELL[0] * 4, CELL[1] * 8))
    for row in range(8):
        for col in range(4):
            frame = sprites[row][col]
            ratio = ratios[col]
            sprite = frame.resize((max(1, round(frame.width * ratio)), max(1, round(frame.height * ratio))), Image.Resampling.NEAREST)
            if col == 3:
                anchor_x, anchor_y = frame.width / 2, frame.height
            else:
                # Feet and torso are the pivot. Centering the whole bounding
                # box instead makes the body slide as the gun extends.
                alpha = np.asarray(frame)[:, :, 3] > 64
                lower_y, lower_x = np.where(alpha & (np.arange(frame.height)[:, None] >= frame.height * 0.55))
                anchor_x = float(np.median(lower_x))
                foot = lower_y[np.abs(lower_x - anchor_x) < frame.width * 0.23]
                anchor_y = float(np.percentile(foot, 99)) if len(foot) else frame.height - 1
            x = col * CELL[0] + CELL[0] // 2 - round(anchor_x * ratio)
            y = row * CELL[1] + BASELINE - round(anchor_y * ratio)
            if x < col * CELL[0] + 2 or x + sprite.width > (col + 1) * CELL[0] - 2:
                raise ValueError(f"{kind}: sprite touches horizontal cell border")
            if y < row * CELL[1] or y + sprite.height > (row + 1) * CELL[1]:
                raise ValueError(f"{kind}: sprite touches vertical cell border")
            atlas.alpha_composite(sprite, (x, y))
    pixels = np.array(atlas)
    for row in range(8):
        for col in range(4):
            cell = pixels[row * CELL[1]:(row + 1) * CELL[1], col * CELL[0]:(col + 1) * CELL[0]]
            components, count = label(cell[:, :, 3] > 64)
            for component in range(1, count + 1):
                if np.count_nonzero(components == component) < 100:
                    cell[components == component] = 0
    TARGET.mkdir(parents=True, exist_ok=True)
    Image.fromarray(pixels, "RGBA").save(TARGET / f"{kind}_actions_v2.png")
    print(f"{kind}: atlas {atlas.size}, scales {[round(value, 3) for value in ratios]}")


if __name__ == "__main__":
    for name in KINDS:
        pack(name)
