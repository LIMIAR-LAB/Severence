"""Small original placeholder terrain and synthesized feedback, replaceable independently."""
from pathlib import Path
import random
import wave
import numpy as np
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
(root / 'assets/environment').mkdir(parents=True, exist_ok=True)
(root / 'assets/audio').mkdir(parents=True, exist_ok=True)
rng = random.Random(1941)
image = Image.new('RGB', (64, 64), '#262831')
draw = ImageDraw.Draw(image)
for row in range(4):
    for col in range(-1, 5):
        x, y = col * 16 + (8 if row % 2 else 0), row * 16
        light = rng.randrange(-5, 6)
        color = (63 + light, 61 + light, 64 + light)
        draw.rounded_rectangle((x + 1, y + 1, x + 14, y + 14), radius=2, fill=color)
        draw.line((x + 3, y + 2, x + 12, y + 2), fill=(79 + light, 75 + light, 75 + light))
        for _ in range(4):
            px, py = x + rng.randrange(3, 13), y + rng.randrange(4, 13)
            draw.point((px, py), fill=(51 + light, 51 + light, 57 + light))
image.save(root / 'assets/environment/cobble.png')

sample_rate = 22050
for name, duration, freq, noise in [('shot', .09, 250, .4), ('heavy', .18, 90, .5), ('jump', .15, 600, .05), ('hit', .12, 100, .7)]:
    t = np.arange(int(sample_rate * duration)) / sample_rate
    prng = np.random.default_rng(1941)
    signal = (np.sin(2 * np.pi * freq * t * (1 - t / duration * .45)) * (1-noise) + prng.uniform(-1, 1, len(t)) * noise)
    signal *= np.exp(-t / duration * 5) * .35
    with wave.open(str(root / f'assets/audio/{name}.wav'), 'wb') as out:
        out.setnchannels(1); out.setsampwidth(2); out.setframerate(sample_rate)
        out.writeframes((signal * 32767).astype('<i2').tobytes())
print('Created original placeholder floor texture and 4 synthesized sound effects.')
