"""Pack PixelLab RGBA exports into eight directions x five poses.

A single scale per creature and fixed animation pivots preserve alignment.
Available generated movement is imported; other views hold their own idle
sprite with the renderer's existing bob. Coverage is recorded explicitly.
"""
from io import BytesIO
from pathlib import Path
from zipfile import ZipFile
import argparse
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/source/pixellab/dock-monsters-v2'
TARGET = ROOT / 'assets/enemies'
DIRECTIONS = ('south', 'south-east', 'east', 'north-east', 'north', 'north-west', 'west', 'south-west')
KINDS = ('crawler', 'cult', 'fish', 'brute')
CELL = 96


def read_suffix(archive, suffix):
    matches = [name for name in archive.namelist() if name.endswith(suffix)]
    if len(matches) != 1:
        raise ValueError(f'Expected one {suffix}, found {matches}')
    with Image.open(BytesIO(archive.read(matches[0]))) as source:
        image = source.convert('RGBA')
    if not image.getbbox():
        raise ValueError(f'Empty frame: {suffix}')
    if image.getextrema()[3][0] != 0:
        raise ValueError(f'Missing transparency: {suffix}')
    return image


def pivot(image):
    left, _, right, bottom = image.getbbox()
    return ((left + right) / 2, bottom)


def build(kind):
    rows, animated = [], []
    with ZipFile(SOURCE / f'{kind}.zip') as archive:
        names = archive.namelist()
        metadata = json.loads(archive.read('metadata.json'))
        for direction in DIRECTIONS:
            idle = read_suffix(archive, f'rotations/{direction}.png')
            poses = [(idle, pivot(idle))]
            prefix = f'animations/dock_walk/{direction}/'
            frames = sorted(n for n in names if prefix in n and n.endswith('.png'))
            declared = [state['frames'].get('animations', {}).get('dock_walk', {}).get(direction)
                        for state in metadata['states']]
            declared = [paths for paths in declared if paths is not None]
            if len(declared) > 1 or (declared and sorted(declared[0]) != frames) or (frames and not declared):
                raise ValueError(f'{kind}/{direction}: animation files disagree with export metadata')
            if frames:
                if len(frames) not in (4, 5):
                    raise ValueError(f'{kind}/{direction}: expected 4 or 5 frames, got {len(frames)}')
                images = [read_suffix(archive, name) for name in frames]
                if len({im.size for im in images}) != 1:
                    raise ValueError(f'{kind}/{direction}: animation canvases differ')
                # V3 includes one unchanged reference followed by four generated poses.
                anchor = pivot(images[0])
                poses.extend((im, anchor) for im in (images[1:] if len(images) == 5 else images))
                animated.append(direction)
            else:
                poses.extend([(idle, pivot(idle))] * 4)
            rows.append(poses)

    radius, above, below = 0.0, 0.0, 0.0
    for row in rows:
        for pose, (px, py) in row:
            left, top, right, bottom = pose.getbbox()
            radius = max(radius, abs(left-px), abs(right-px))
            above = max(above, py-top)
            below = max(below, bottom-py)
    ratio = min(1.0, 42 / radius, 84 / (above + below))
    baseline = 92 - below * ratio
    atlas = Image.new('RGBA', (CELL * 5, CELL * 8))
    for row_index, row in enumerate(rows):
        for column, (pose, (px, py)) in enumerate(row):
            box = pose.getbbox()
            sprite = pose.crop(box)
            sprite = sprite.resize((max(1, round(sprite.width * ratio)),
                                    max(1, round(sprite.height * ratio))), Image.Resampling.NEAREST)
            x = round(48 + (box[0] - px) * ratio)
            y = round(baseline + (box[1] - py) * ratio)
            if x < 1 or y < 1 or x + sprite.width > 95 or y + sprite.height > 95:
                raise ValueError(f'{kind}: pose touches cell border')
            atlas.alpha_composite(sprite, (column * CELL + x, row_index * CELL + y))
    TARGET.mkdir(parents=True, exist_ok=True)
    atlas.save(TARGET / f'{kind}_pixellab_v2.png')
    pixels = np.asarray(atlas)
    report = {'kind': kind, 'size': list(atlas.size), 'scale': ratio,
              'animated_directions': animated,
              'held_directions': [d for d in DIRECTIONS if d not in animated],
              'near_white_pixels': int(((pixels[:, :, :3].min(axis=2) > 215) & (pixels[:, :, 3] > 128)).sum())}
    (SOURCE / f'{kind}-import.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report))
    return atlas


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('kinds', nargs='*', help='Monster names; defaults to all four')
    args = parser.parse_args()
    if any(kind not in KINDS for kind in args.kinds):
        parser.error('Unknown monster; choose ' + ', '.join(KINDS))
    for kind in args.kinds or KINDS:
        build(kind)
