"""Pack approved PixelLab motion clips without per-frame resizing or recentering.

Raw frame 0 is the untouched input reference. Its anchor is applied to every
frame; the same pixels-to-world scale is used for walking, attacking and death.
Only explicitly approved clips in jobs.json are eligible for the game.
"""
from pathlib import Path
from urllib.request import urlopen
from concurrent.futures import ThreadPoolExecutor
import argparse
import json
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'art/source/pixellab/enemy-motion-v3'
TARGET = ROOT / 'assets/enemies/motion_v3'
CELL = 128
PIVOT = (64, 112)
SIZES = {'crawler': 96, 'cult': 88, 'fish': 88, 'brute': 112, 'guard': 84, 'bomber': 72}


def fetch(pair):
    url, path = pair
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with urlopen(url, timeout=90) as response:
        payload = response.read()
    path.write_bytes(payload)


def process(job):
    folder = SOURCE / job.get('source_dir', f"{job['kind']}/{job['action']}/{job['direction']}")
    paths = [folder / f'{i:03}.png' for i in range(len(job['frames']))]
    with ThreadPoolExecutor(max_workers=6) as executor:
        list(executor.map(fetch, zip(job['frames'], paths)))
    images = [Image.open(path).convert('RGBA') for path in paths]
    if job.get('corrected_sheet'):
        sheet = Image.open(SOURCE / job['corrected_sheet']).convert('RGBA')
        width, height = images[0].size
        columns = sheet.width // width
        corrected = [sheet.crop(((i % columns) * width, (i // columns) * height,
                                  (i % columns + 1) * width, (i // columns + 1) * height))
                     for i in range(len(images))]
        assert corrected[0].tobytes() == images[0].tobytes(), 'Correction changed the reference'
        images = corrected
    assert len(images) >= 9, 'Motion must have at least eight generated poses'
    assert len({im.size for im in images}) == 1, 'Canvas must stay fixed'
    boxes = [im.getbbox() for im in images]
    assert all(boxes), 'Empty frame'
    assert len({im.tobytes() for im in images}) >= 8, 'Repeated stills are not animation'
    if job['action'] == 'walk':
        head_widths = []
        for image, box in zip(images, boxes):
            alpha = np.asarray(image)[:, :, 3] > 128
            # The upper third holds the octopus head or a humanoid hood/helmet.
            upper = alpha[box[1]:box[1] + max(12, round((box[3] - box[1]) * 0.36))]
            widths = [int(xs[-1] - xs[0] + 1) for row in upper
                      if (xs := np.flatnonzero(row)).size]
            head_widths.append(max(widths))
        reference = head_widths[0]
        if not all(reference * 0.9 <= width <= reference * 1.1 for width in head_widths):
            raise ValueError(f"{job['kind']}/{job['direction']}: head width drifts {head_widths}")
    anchor = (round((boxes[0][0] + boxes[0][2]) / 2), boxes[0][3])
    offset = (PIVOT[0] - anchor[0], PIVOT[1] - anchor[1])
    atlas = Image.new('RGBA', (CELL * len(images), CELL))
    for i, im in enumerate(images):
        box = boxes[i]
        # PixelLab's fall frames drift upward inside the canvas. Keep the
        # lowest opaque pixel on the original floor without scaling the art.
        ground = anchor[1] - box[3] if job['action'] == 'death' else 0
        assert 0 <= box[0] + offset[0] < box[2] + offset[0] <= CELL
        assert 0 <= box[1] + offset[1] + ground < box[3] + offset[1] + ground <= CELL
        atlas.alpha_composite(im, (i * CELL + offset[0], offset[1] + ground))
    output = TARGET / job['kind'] / f"{job['action']}-{job['direction']}.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(output)
    return {'path': 'res://' + output.relative_to(ROOT).as_posix(),
            'frames': len(images), 'duration': 0.9 if job['action'] == 'walk' else 1.0,
            'job_id': job['job_id'], 'source_anchor': list(anchor)}


def main():
    data = json.loads((SOURCE / 'jobs.json').read_text(encoding='utf-8'))
    manifests = {}
    for job in data['jobs']:
        if not job.get('approved') or not job.get('frames'):
            continue
        kind = job['kind']
        if kind not in manifests:
            old = ROOT / f'art/source/pixellab/dock-monsters-v2/{kind}-import.json'
            ratio = json.loads(old.read_text())['scale'] if old.exists() else 1.0
            manifests[kind] = {'cell': CELL, 'pivot': list(PIVOT),
                               'world_scale': ratio * SIZES[kind] / 96.0, 'clips': {}}
        clip = process(job)
        manifests[kind]['clips'].setdefault(job['action'], {})[job['direction']] = clip
    for kind, manifest in manifests.items():
        (TARGET / kind / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        print(kind, {a: list(rows) for a, rows in manifest['clips'].items()})


if __name__ == '__main__':
    main()
