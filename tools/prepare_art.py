"""Remove the keyed background and register frames at a common foot pivot.

The generated sheets are source illustrations, never assumed to be engine-ready.
Each cell is inspected for alpha bounds, trimmed and normalized into a fixed atlas.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

ROOT = Path(__file__).resolve().parents[1]


def prepare(source, destination, columns, rows, cell, target_height):
    original = Image.open(ROOT / source).convert('RGBA')
    data = np.array(original)
    rgb = data[:, :, :3].astype(int)
    key = (rgb[:, :, 0] > rgb[:, :, 1] * 1.6) & (rgb[:, :, 2] > rgb[:, :, 1] * 1.6) & (rgb[:, :, 0] > 65) & (rgb[:, :, 2] > 65)
    data[key, 3] = 0
    original = Image.fromarray(data)
    atlas = Image.new('RGBA', (cell[0] * columns, cell[1] * rows))
    # Generated art does not obey exact grid spacing. Detect the separated bands,
    # rather than trusting the nominal rows and cutting heads into other frames.
    ys = np.where((data[:, :, 3] > 0).sum(axis=1) > 40)[0]
    bands = np.split(ys, np.where(np.diff(ys) > 6)[0] + 1)
    assert len(bands) == rows, (source, 'row bands', len(bands))
    for row in range(rows):
        y0, y1 = max(0, int(bands[row][0]) - 5), min(original.height, int(bands[row][-1]) + 6)
        xs = np.where((data[y0:y1, :, 3] > 0).sum(axis=0) > 3)[0]
        xbands = np.split(xs, np.where(np.diff(xs) > 8)[0] + 1)
        assert len(xbands) == columns, (source, 'column bands', row, len(xbands))
        for col in range(columns):
            box = (max(0, int(xbands[col][0]) - 2), y0,
                   min(original.width, int(xbands[col][-1]) + 3), y1)
            frame = original.crop(box)
            bounds = frame.getbbox()
            assert bounds, (source, row, col)
            frame = frame.crop(bounds)
            factor = min(target_height / frame.height, (cell[0] - 8) / frame.width)
            frame = frame.resize((round(frame.width * factor), round(frame.height * factor)), Image.Resampling.NEAREST)
            x = col * cell[0] + (cell[0] - frame.width) // 2
            y = row * cell[1] + cell[1] - 6 - frame.height
            atlas.alpha_composite(frame, (x, y))
    path = ROOT / destination
    path.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(path)
    return atlas


marty = prepare('art/source/marty-atlas-v1.png', 'assets/marty/marty.png', 8, 4, (64, 80), 65)
mech = prepare('art/source/mech-atlas-v1.png', 'assets/mech/titan.png', 4, 2, (176, 176), 148)
actions = prepare('art/source/marty-actions-v1.png', 'assets/marty/actions.png', 6, 4, (64, 80), 65)
preview = Image.new('RGB', (1152, 640), '#0c1521')
draw = ImageDraw.Draw(preview)
draw.text((25, 12), 'MARTY | SEM ARMADURA / COM ARMADURA | 4 DIRECOES x 4 FRAMES', fill='#8de5ee')
preview.paste(marty, (25, 45), marty)
draw.text((570, 12), 'TITAN-01 | 4 DIRECOES x 2 FRAMES', fill='#f4cd83')
small_mech = mech.resize((563, 282), Image.Resampling.NEAREST)
preview.paste(small_mech, (570, 45), small_mech)
draw.text((25, 395), 'PREVIEW 2x | SPRITES COM FUNDO TRANSPARENTE E PES ALINHADOS', fill='#8de5ee')
for i, col in enumerate([0, 4]):
    sprite = marty.crop((col * 64, 0, col * 64 + 64, 80)).resize((128, 160), Image.Resampling.NEAREST)
    preview.paste(sprite, (35 + i * 180, 435), sprite)
sprite = mech.crop((0, 0, 176, 176))
preview.paste(sprite, (510, 425), sprite)
preview.save(ROOT / 'art/marty-titan-preview.png')
print('Registered 32 walking frames, 24 action poses and 8 Titan frames. Preview: art/marty-titan-preview.png')
