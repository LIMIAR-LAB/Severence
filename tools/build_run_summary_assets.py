"""Build normalized runtime assets for the post-run summary.

PixelLab owns the ornamental source sheet and loot illustrations. This builder
owns sizes, crops, palette-safe fallbacks and semantic glyphs. It is deterministic
and may be rerun whenever source art is replaced.
"""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art" / "source" / "pixellab" / "run-summary"
RUNTIME = ROOT / "assets" / "ui" / "run_summary"
LOOT_RUNTIME = RUNTIME / "loot"

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
    return (fallback or panel_fallback(size)).copy()


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
    print(f"Built run-summary assets in {RUNTIME.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
