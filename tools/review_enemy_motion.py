"""Download completed PixelLab clips and build unmodified-frame review sheets/GIFs."""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import json
from PIL import Image, ImageDraw
from import_enemy_motion import SOURCE, ROOT, fetch

data = json.loads((SOURCE / 'jobs.json').read_text(encoding='utf-8'))
out = ROOT / 'output/enemy-motion-v3'
out.mkdir(parents=True, exist_ok=True)
for job in data['jobs']:
    if not job.get('frames'):
        continue
    folder = SOURCE / job.get('source_dir', f"{job['kind']}/{job['action']}/{job['direction']}")
    paths = [folder / f'{i:03}.png' for i in range(len(job['frames']))]
    with ThreadPoolExecutor(max_workers=6) as executor:
        list(executor.map(fetch, zip(job['frames'], paths)))
    images = [Image.open(p).convert('RGBA') for p in paths]
    if job.get('corrected_sheet'):
        sheet = Image.open(SOURCE / job['corrected_sheet']).convert('RGBA')
        width, height = images[0].size
        columns = sheet.width // width
        images = [sheet.crop(((i % columns) * width, (i // columns) * height,
                              (i % columns + 1) * width, (i // columns + 1) * height))
                  for i in range(len(images))]
    name = f"{job['kind']}-{job['action']}-{job['direction']}"
    size = max(max(im.size) for im in images)
    cell = size * 2 + 20
    sheet = Image.new('RGB', (cell * 5, (len(images) + 4) // 5 * cell), '#18232e')
    draw = ImageDraw.Draw(sheet)
    animation = []
    for i, im in enumerate(images):
        sprite = im.resize((im.width * 2, im.height * 2), Image.Resampling.NEAREST)
        xy = ((i % 5) * cell + 10, (i // 5) * cell + 15)
        sheet.paste(sprite, xy, sprite)
        draw.text(((i % 5) * cell + 4, (i // 5) * cell + 2), str(i), fill='white')
        frame = Image.new('RGB', (size * 4, size * 4), '#18232e')
        enlarged = im.resize((im.width * 4, im.height * 4), Image.Resampling.NEAREST)
        frame.paste(enlarged, (0, 0), enlarged)
        animation.append(frame)
    sheet.save(out / (name + '.png'))
    if job['action'] == 'death':
        animation.extend([animation[-1]] * 18)
    animation[0].save(out / (name + '.gif'), save_all=True,
                      append_images=animation[1:], duration=65, loop=0, disposal=2)
    print(name, len(images), 'frames')
