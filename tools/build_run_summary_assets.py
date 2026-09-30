"""Build normalized runtime assets for the post-run summary.

PixelLab owns the ornamental source sheet and loot illustrations. This builder
owns sizes, crops, palette-safe fallbacks and semantic glyphs. ImageGen owns the
faithful cinematic shell and editorial portraits. It is deterministic and may
be rerun whenever source art is replaced.
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "source" / "pixellab" / "run-summary"
FAITHFUL_SOURCE = ROOT / "art" / "source" / "run-summary-faithful"
RUNTIME = ROOT / "assets" / "ui" / "run_summary"
LOOT_RUNTIME = RUNTIME / "loot"
FAITHFUL_RUNTIME = RUNTIME / "faithful"
FAITHFUL_LOOT_RUNTIME = FAITHFUL_RUNTIME / "loot"

NAVY = (7, 25, 34, 255)
NAVY_2 = (12, 42, 52, 255)
OLIVE = (49, 57, 35, 255)
BRASS = (168, 119, 50, 255)
GOLD = (243, 221, 160, 255)
CYAN = (101, 240, 245, 255)


def panel_fallback(size: tuple[int, int]) -> Image.Image:
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    w, h = size
    d.rounded_rectangle((2, 2, w - 3, h - 3), radius=max(4, min(w, h) // 28), fill=NAVY, outline=BRASS, width=4)
    d.rectangle((10, 10, w - 11, h - 11), outline=OLIVE, width=3)
    for x, y in ((12, 12), (w - 13, 12), (12, h - 13), (w - 13, h - 13)):
        d.ellipse((x - 3, y - 3, x + 3, y + 3), fill=GOLD, outline=(38, 26, 15, 255))
    return im


def normalize(source: Path, size: tuple[int, int], fallback: Image.Image | None = None) -> Image.Image:
    if source.exists():
        with Image.open(source) as opened:
            return opened.convert("RGBA").resize(size, Image.Resampling.NEAREST)
    replacement = fallback or panel_fallback(size)
    return replacement.copy().resize(size, Image.Resampling.NEAREST)


def validate_rgba(image: Image.Image, expected_size: tuple[int, int], role: str, opaque: bool = False) -> None:
    if image.size != expected_size:
        raise ValueError(f"{role} must be {expected_size[0]}x{expected_size[1]}, got {image.size}")
    alpha_min, alpha_max = image.getchannel("A").getextrema()
    if alpha_max == 0:
        raise ValueError(f"{role} is fully transparent")
    if opaque and (alpha_min, alpha_max) != (255, 255):
        raise ValueError(f"{role} must be fully opaque, got alpha range {(alpha_min, alpha_max)}")


def crop_scaled(sheet: Image.Image, box: tuple[int, int, int, int], size: tuple[int, int]) -> Image.Image:
    return sheet.crop(box).resize(size, Image.Resampling.NEAREST)


def fallback_loot(kind: str) -> Image.Image:
    im = Image.new("RGBA", (96, 96), (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    if kind == "scrap":
        d.ellipse((18, 18, 78, 78), fill=BRASS, outline=GOLD, width=5); d.ellipse((36, 36, 60, 60), fill=NAVY)
        for x, y in ((17, 43), (43, 17), (69, 43), (43, 69)): d.rectangle((x, y, x + 10, y + 10), fill=BRASS)
    elif kind == "fragment":
        d.polygon([(48, 5), (72, 42), (56, 88), (34, 61), (25, 30)], fill=CYAN, outline=GOLD)
        d.line((48, 8, 48, 78), fill=(225, 255, 255, 255), width=3)
    elif kind == "blueprint":
        d.rounded_rectangle((17, 20, 79, 77), radius=7, fill=(22, 75, 119, 255), outline=BRASS, width=5)
        d.line((29, 38, 67, 38), fill=CYAN, width=3); d.line((29, 52, 61, 52), fill=CYAN, width=3)
    else:
        d.ellipse((12, 12, 84, 84), fill=BRASS, outline=GOLD, width=5); d.ellipse((30, 30, 66, 66), fill=CYAN)
        d.ellipse((40, 40, 56, 56), fill=(230, 255, 255, 255))
    return im


def build_semantic_icons() -> Image.Image:
    atlas = Image.new("RGBA", (384, 48), (0, 0, 0, 0)); d = ImageDraw.Draw(atlas)
    for index in range(8):
        x = index * 48; d.rounded_rectangle((x + 4, 4, x + 43, 43), radius=8, fill=NAVY_2, outline=BRASS, width=2)
    # time, progress, enemies, dealt, received, combo, refuge, replay
    d.ellipse((12, 10, 38, 36), outline=GOLD, width=4); d.line((25, 23, 25, 14), fill=CYAN, width=3); d.line((25, 23, 33, 28), fill=CYAN, width=3)
    d.arc((56, 10, 86, 40), 30, 330, fill=CYAN, width=5); d.polygon([(84, 9), (89, 20), (77, 18)], fill=CYAN)
    d.ellipse((108, 11, 132, 34), outline=GOLD, width=4); d.rectangle((113, 32, 127, 39), fill=GOLD)
    d.line((154, 35, 176, 13), fill=CYAN, width=5); d.polygon([(176, 9), (181, 22), (168, 17)], fill=CYAN)
    d.polygon([(217, 9), (232, 15), (229, 34), (217, 41), (205, 34), (202, 15)], outline=GOLD, fill=NAVY_2)
    d.polygon([(264, 7), (270, 20), (284, 19), (274, 29), (278, 42), (264, 34), (250, 42), (254, 29), (244, 19), (258, 20)], fill=GOLD)
    d.polygon([(300, 24), (312, 12), (324, 24)], fill=GOLD); d.rectangle((303, 23, 321, 39), fill=GOLD); d.rectangle((310, 30, 315, 39), fill=NAVY)
    d.arc((344, 10, 376, 40), 40, 330, fill=CYAN, width=5); d.polygon([(372, 7), (379, 19), (366, 18)], fill=CYAN)
    return atlas


def build_silhouette() -> Image.Image:
    """Deterministic portrait fallback that keeps the editorial layout intact."""
    im = Image.new("RGBA", (512, 512), (5, 20, 31, 255))
    d = ImageDraw.Draw(im)
    d.ellipse((112, 86, 400, 374), fill=(8, 35, 47, 255), outline=BRASS, width=10)
    d.polygon([(92, 244), (28, 174), (126, 188), (78, 98), (181, 155)], fill=(8, 35, 47, 255))
    d.polygon([(420, 244), (484, 174), (386, 188), (434, 98), (331, 155)], fill=(8, 35, 47, 255))
    d.ellipse((174, 178, 226, 230), fill=CYAN)
    d.ellipse((286, 178, 338, 230), fill=CYAN)
    d.arc((166, 220, 346, 348), 12, 168, fill=GOLD, width=13)
    return im


def build_faithful_assets() -> None:
    FAITHFUL_RUNTIME.mkdir(parents=True, exist_ok=True)
    FAITHFUL_LOOT_RUNTIME.mkdir(parents=True, exist_ok=True)

    shell_path = FAITHFUL_SOURCE / "summary_shell_master.png"
    if not shell_path.exists():
        raise FileNotFoundError(f"Missing faithful shell master: {shell_path.relative_to(ROOT)}")
    with Image.open(shell_path) as opened:
        shell = opened.convert("RGBA")
        validate_rgba(shell, (1672, 941), "Faithful shell", opaque=True)
        shell.save(FAITHFUL_RUNTIME / "shell.png")

    for name in ("fish", "victory"):
        source = FAITHFUL_SOURCE / f"portrait_{name}_master.png"
        if not source.exists():
            raise FileNotFoundError(f"Missing faithful portrait: {source.relative_to(ROOT)}")
        portrait = normalize(source, (512, 512))
        validate_rgba(portrait, (512, 512), f"Faithful {name} portrait")
        portrait.save(FAITHFUL_RUNTIME / f"portrait_{name}.png")
    build_silhouette().save(FAITHFUL_RUNTIME / "portrait_fallback.png")

    # PixelLab continues to own these illustrations; faithful presentation only
    # normalizes them into the new runtime directory.
    for kind in ("scrap", "fragment", "blueprint", "relic"):
        normalize(SOURCE / f"loot_{kind}.png", (128, 128), fallback_loot(kind)).save(
            FAITHFUL_LOOT_RUNTIME / f"{kind}.png"
        )


def main() -> None:
    RUNTIME.mkdir(parents=True, exist_ok=True); LOOT_RUNTIME.mkdir(parents=True, exist_ok=True)
    sheet = normalize(SOURCE / "run_summary_ui_sheet.png", (600, 448))
    # PixelLab ignored the no-text constraint on its button candidates. Keep the
    # source, but compose runtime decoration only from text-free regions.
    frame = panel_fallback((600, 448))
    frame.alpha_composite(sheet.crop((0, 0, 600, 48)), (0, 0))
    for box, at in [((0, 0, 52, 52), (0, 0)), ((548, 0, 600, 52), (548, 0))]:
        frame.alpha_composite(sheet.crop(box), at)
    frame.save(RUNTIME / "frame_main.png")
    # Stop above PixelLab's text-contaminated button row (starts around y=246).
    crop_scaled(sheet, (31, 34, 568, 229), (352, 208)).save(RUNTIME / "frame_obituary.png")
    crop_scaled(sheet, (16, 314, 148, 448), (192, 192)).save(RUNTIME / "grade_ring.png")
    crop_scaled(sheet, (149, 318, 331, 448), (128, 112)).save(RUNTIME / "loot_slot.png")
    crop_scaled(sheet, (349, 318, 590, 448), (176, 64)).save(RUNTIME / "stat_slot.png")
    primary = panel_fallback((320, 64)); secondary = panel_fallback((320, 64))
    ImageDraw.Draw(primary).rounded_rectangle((5, 5, 314, 58), radius=8, outline=CYAN, width=4)
    ImageDraw.Draw(secondary).rounded_rectangle((5, 5, 314, 58), radius=8, outline=BRASS, width=4)
    primary.save(RUNTIME / "button_primary.png"); secondary.save(RUNTIME / "button_secondary.png")
    for kind in ("scrap", "fragment", "blueprint", "relic"):
        normalize(SOURCE / f"loot_{kind}.png", (96, 96), fallback_loot(kind)).save(LOOT_RUNTIME / f"{kind}.png")
    build_semantic_icons().save(RUNTIME / "icons.png")
    build_faithful_assets()
    print(f"Built run-summary assets in {RUNTIME.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
