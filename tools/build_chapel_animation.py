from pathlib import Path
from math import sin, tau

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "art" / "source" / "altar-pixellab-v2"
SOURCE = SOURCE_DIR / "altar-pixellab-native.png"
OUTPUT_PNG = SOURCE_DIR / "altar-mapa-1344x752.png"
OUTPUT_GIF = SOURCE_DIR / "altar-mapa-animado-1344x752.gif"
PREVIEW_GIF = SOURCE_DIR / "altar-preview.gif"

FRAME_COUNT = 12
FRAME_MS = 110


def glow(size, ellipse, color, blur):
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).ellipse(ellipse, fill=color)
    return layer.filter(ImageFilter.GaussianBlur(blur))


def make_frame(base, index):
    phase = tau * index / FRAME_COUNT
    frame = base.convert("RGBA")

    # The altar relic breathes gently without changing the surrounding geometry.
    relic_alpha = int(34 + 22 * (0.5 + 0.5 * sin(phase)))
    frame = Image.alpha_composite(
        frame, glow(base.size, (326, 91, 360, 130), (54, 255, 213, relic_alpha), 8)
    )

    # The stained glass catches a slower cold pulse.
    window_alpha = int(12 + 12 * (0.5 + 0.5 * sin(phase - 0.8)))
    frame = Image.alpha_composite(
        frame, glow(base.size, (302, 12, 388, 96), (159, 255, 221, window_alpha), 10)
    )

    # The temporal fracture has a violet pulse offset from the altar.
    rift_alpha = int(24 + 25 * (0.5 + 0.5 * sin(phase + 1.6)))
    frame = Image.alpha_composite(
        frame, glow(base.size, (449, 53, 512, 151), (133, 55, 255, rift_alpha), 9)
    )

    # Small, deliberately sparse candle flicker. Coordinates follow the native art.
    lights = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(lights)
    candles = [(263, 116), (276, 119), (289, 119), (397, 115), (410, 119),
               (424, 116), (87, 214), (99, 214), (111, 213)]
    for n, (x, y) in enumerate(candles):
        flicker = sin(phase * (1 + (n % 3) * 0.17) + n * 1.7)
        height = 2 if flicker > -0.15 else 1
        alpha = 155 + int(55 * (0.5 + 0.5 * flicker))
        draw.rectangle((x, y - height, x + 1, y), fill=(255, 218, 93, alpha))
    frame = Image.alpha_composite(frame, lights)

    # A few stars twinkle outside the platform; the room itself remains still.
    stars = Image.new("RGBA", base.size, (0, 0, 0, 0))
    star_draw = ImageDraw.Draw(stars)
    star_points = [(17, 64), (32, 30), (660, 55), (645, 175), (28, 284),
                   (73, 348), (615, 351), (676, 306), (591, 18)]
    for n, (x, y) in enumerate(star_points):
        brightness = 80 + int(150 * (0.5 + 0.5 * sin(phase + n * 0.91)))
        star_draw.point((x, y), fill=(194, 214, 255, brightness))
    frame = Image.alpha_composite(frame, stars)
    return frame.convert("RGB")


def scale_and_crop(image):
    doubled = image.resize((1376, 768), Image.Resampling.NEAREST)
    return doubled.crop((16, 8, 1360, 760))


def main():
    base = Image.open(SOURCE).convert("RGB")
    if base.size != (688, 384):
        raise ValueError(f"Expected PixelLab image at 688x384, got {base.size}")

    native_frames = [make_frame(base, i) for i in range(FRAME_COUNT)]
    frames = [scale_and_crop(frame) for frame in native_frames]
    frames[0].save(OUTPUT_PNG)
    frames[0].save(
        OUTPUT_GIF,
        save_all=True,
        append_images=frames[1:],
        duration=FRAME_MS,
        loop=0,
        disposal=2,
        optimize=False,
    )

    preview = [frame.resize((672, 376), Image.Resampling.NEAREST) for frame in frames]
    preview[0].save(
        PREVIEW_GIF,
        save_all=True,
        append_images=preview[1:],
        duration=FRAME_MS,
        loop=0,
        disposal=2,
        optimize=False,
    )

    print(f"Created {OUTPUT_PNG.relative_to(ROOT)}")
    print(f"Created {OUTPUT_GIF.relative_to(ROOT)} ({len(frames)} frames)")


if __name__ == "__main__":
    main()
