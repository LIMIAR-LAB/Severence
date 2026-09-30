"""Build the unified Chapel-Dock plate, its stable animation and review assets.

The image uses world pixels at 1:1 scale. Transparent pixels are outside the
chapel's fixed room/wing/corridor geometry; gameplay collision remains explicit
in build_docks_map.py.
"""
from __future__ import annotations

from math import sin, tau
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/environment/docks12/chapel/unified"
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = OUT / "chapel_source_imagegen_v2.png"
FISHERMAN_SOURCE = OUT / "fisherman_source_imagegen_v2.png"

WORLD_ORIGIN = (200, 2700)
SIZE = (1600, 3300)
OVERLAY_ORIGIN = (450, 3600)
OVERLAY_SIZE = (800, 900)
FLOORS = [
    (700, 2700, 200, 900),       # north service bridge
    (200, 3600, 1300, 1400),    # sanctuary and nave
    (1500, 4200, 300, 200),     # east cargo transept
    (300, 5000, 300, 340),      # west reliquary
    (1200, 5000, 300, 340),     # east reliquary
    (900, 5000, 200, 1000),     # south procession passage
]
BLOCKERS = [
    (680, 3888, 340, 62, "altar"),
    (575, 4138, 165, 36, "pew"), (950, 4138, 165, 36, "pew"),
    (565, 4228, 175, 38, "pew"), (940, 4228, 175, 38, "pew"),
    (565, 4318, 180, 40, "pew"), (935, 4318, 185, 40, "pew"),
    (365, 4510, 275, 112, "reliquary"), (1055, 4510, 285, 112, "reliquary"),
    # Bases das muralhas/void pintados na fonte. As aberturas coincidem com os portais fixos.
    (200, 3600, 400, 300, "wall"), (1000, 3600, 500, 300, "wall"),
    (200, 3600, 105, 1400, "wall"),
    (1395, 3600, 105, 530, "wall"), (1395, 4470, 105, 530, "wall"),
    (200, 4622, 250, 378, "wall"), (1350, 4622, 150, 378, "wall"),
]
PORTALS = [
    (700, 3500, 200, 180, "north"),
    (1420, 4200, 380, 200, "east"),
    (900, 4920, 200, 1080, "south"),
]
ANCHORS = {"chest": (700, 4470), "npc": (1160, 4740), "center": (850, 4600)}

def local_box(box):
    x, y, w, h = box[:4]
    return (x - WORLD_ORIGIN[0], y - WORLD_ORIGIN[1], x + w - WORLD_ORIGIN[0] - 1, y + h - WORLD_ORIGIN[1] - 1)

def wp(x: int, y: int) -> tuple[int, int]:
    return x - WORLD_ORIGIN[0], y - WORLD_ORIGIN[1]

def rect(draw: ImageDraw.ImageDraw, box, fill, outline=None, width=1):
    draw.rectangle(local_box(box), fill=fill, outline=outline, width=width)

def line(draw: ImageDraw.ImageDraw, points, fill, width=1):
    draw.line([wp(x, y) for x, y in points], fill=fill, width=width)

def floor_mask() -> Image.Image:
    mask = Image.new("L", SIZE, 0)
    d = ImageDraw.Draw(mask)
    for r in FLOORS:
        d.rectangle(local_box(r), fill=255)
    return mask

def draw_stone_floor(img: Image.Image, mask: Image.Image) -> None:
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0)); d = ImageDraw.Draw(layer)
    # Large dock-stone modules avoid the noisy 64 px checkerboard of the old room.
    for y in range(2700, 6000, 48):
        for x in range(200, 1800, 64):
            shift = 32 if (y // 48) % 2 else 0
            xx = x + shift
            tone = 0 if ((xx // 64) * 7 + (y // 48) * 11) % 5 else 8
            c = (43 + tone, 51 + tone, 49 + tone, 255)
            rect(d, (xx + 2, y + 2, 60, 44), c, (25, 31, 31, 255), 2)
            if ((xx // 64) + (y // 48)) % 9 == 0:
                line(d, [(xx + 12, y + 35), (xx + 28, y + 29), (xx + 42, y + 34)], (75, 85, 76, 150), 2)
    # Water stains and worn traffic lanes bind the dock and chapel materials.
    for x, y, w, h in [(620, 3370, 360, 80), (1410, 4165, 330, 270), (850, 4860, 300, 920)]:
        rect(d, (x, y, w, h), (31, 47, 49, 95))
    img.alpha_composite(Image.composite(layer, Image.new("RGBA", SIZE), mask))

def draw_wall_segment(d, x1, y1, x2, y2, thickness=28):
    line(d, [(x1, y1), (x2, y2)], (18, 21, 23, 255), thickness + 12)
    line(d, [(x1, y1), (x2, y2)], (77, 66, 55, 255), thickness)
    line(d, [(x1, y1), (x2, y2)], (132, 104, 68, 255), 4)
    length = int(abs(x2-x1) + abs(y2-y1))
    for n in range(24, length, 48):
        t = n / max(1, length)
        x = int(x1 + (x2-x1)*t); y = int(y1 + (y2-y1)*t)
        line(d, [(x-5, y-5), (x+5, y+5)], (32, 29, 28, 255), 2)

def draw_pew(d, x, y, w, h):
    # Painted contact base is exactly the declared collision box.
    rect(d, (x, y, w, h), (38, 25, 20, 255), (12, 12, 14, 255), 4)
    rect(d, (x+8, y-65, w-16, 65), (100, 57, 34, 255), (25, 18, 17, 255), 4)
    rect(d, (x+14, y-56, w-28, 12), (157, 97, 50, 255))
    rect(d, (x+18, y-35, w-36, 8), (69, 38, 27, 255))
    for leg in (x+22, x+w-34): rect(d, (leg, y+h-3, 12, 18), (44, 28, 22, 255))

def draw_master() -> Image.Image:
    if not SOURCE.exists():
        raise FileNotFoundError(f"missing approved source: {SOURCE}")
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    source = Image.open(SOURCE).convert("RGBA")
    room = source.resize((1300, 1400), Image.Resampling.NEAREST)
    # The approved image is the room master, preserved at the exact gameplay Rect2.
    img.alpha_composite(room, (0, 900))

    # Continue each painted threshold using samples from the matching edge.
    north_tile = room.crop((500, 0, 700, 180))
    for y in range(0, 900, 180):
        tile = north_tile if (y // 180) % 2 == 0 else north_tile.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        img.alpha_composite(tile, (500, y))
    east = room.crop((1120, 535, 1300, 735)).resize((300, 200), Image.Resampling.NEAREST)
    img.alpha_composite(east, (1300, 1500))
    south_tile = room.crop((700, 1220, 900, 1400))
    for y in range(2300, 3300, 180):
        tile = south_tile if (y // 180) % 2 == 0 else south_tile.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        img.alpha_composite(tile, (700, y))
    # The two fixed lower wings inherit the adjacent reliquary material.
    left_wing = room.crop((100, 1060, 400, 1400))
    right_wing = room.crop((1000, 1060, 1300, 1400))
    img.alpha_composite(left_wing, (100, 2300)); img.alpha_composite(right_wing, (1000, 2300))
    # Open the two fixed reliquary mouths through the source's lower parapet.
    img.alpha_composite(left_wing.crop((0, 0, 300, 132)), (100, 2208))
    img.alpha_composite(right_wing.crop((0, 0, 300, 132)), (1000, 2208))

    d = ImageDraw.Draw(img)
    # Thin rails and brass thresholds finish the edge extensions without repainting the room.
    for x in (700, 900): draw_wall_segment(d, x, 2700, x, 3600, 18)
    for y in (4200, 4400): draw_wall_segment(d, 1500, y, 1800, y, 18)
    for x in (900, 1100): draw_wall_segment(d, x, 5000, x, 6000, 18)
    rect(d, (710, 3582, 180, 14), (164, 111, 50, 255), (35, 25, 22, 255), 2)
    rect(d, (1494, 4210, 14, 180), (164, 111, 50, 255), (35, 25, 22, 255), 2)
    rect(d, (912, 4990, 176, 14), (164, 111, 50, 255), (35, 25, 22, 255), 2)
    return img

def animated_overlay(index: int) -> Image.Image:
    glow = Image.new("RGBA", OVERLAY_SIZE, (0,0,0,0)); d = ImageDraw.Draw(glow)
    pulse = 0.5 + 0.5 * sin(index / 12.0 * tau)
    # Stable geometry: only translucent light and flame pixels change.
    cx, cy = 1115 - OVERLAY_ORIGIN[0], 3890 - OVERLAY_ORIGIN[1]
    for radius, alpha in [(142, int(13+10*pulse)), (100, int(19+13*pulse)), (62, int(28+18*pulse))]:
        d.ellipse((cx-radius,cy-radius,cx+radius,cy+radius), fill=(137,52,220,alpha))
    for n,(x,y) in enumerate([(680,3890),(1020,3890),(500,4100),(1200,4100),(850,4450)]):
        flick = ((index+n*3)%4)-1
        px,py=x+5-OVERLAY_ORIGIN[0],y-40-flick*2-OVERLAY_ORIGIN[1]
        d.rectangle((px-3,py-7,px+3,py+6),fill=(255,204,76,230))
        d.rectangle((px-1,py-5,px+1,py+2),fill=(255,246,188,255))
        d.ellipse((px-30,py-30,px+30,py+30),fill=(255,151,48,18+int(10*pulse)))
    # Small occult motes travel in a closed loop.
    for n in range(6):
        import math
        a=(index/12.0+n/6.0)*tau
        x=cx+int(math.cos(a)*82); y=cy+int(math.sin(a)*60)
        d.rectangle((x-2,y-2,x+2,y+2),fill=(211,141,255,210))
    return glow

def draw_fisherman(index: int) -> Image.Image:
    # The approved imagegen fisherman remains the visual master.  The four idle
    # frames move the whole silhouette only, so anatomy and equipment stay stable.
    if not FISHERMAN_SOURCE.exists():
        raise FileNotFoundError(f"missing approved NPC source: {FISHERMAN_SOURCE}")
    source = Image.open(FISHERMAN_SOURCE).convert("RGBA")
    alpha = source.getchannel("A")
    crop = source.crop(alpha.getbbox())
    crop.thumbnail((76, 106), Image.Resampling.NEAREST)
    img = Image.new("RGBA", (80, 112), (0, 0, 0, 0))
    x = (80 - crop.width) // 2
    y = 112 - crop.height - 2
    img.alpha_composite(crop, (x, y))
    # Localized lantern pulse/breathing highlight; feet and silhouette never jitter.
    pulse = (22, 42, 68, 40)[index % 4]
    detail = Image.new("RGBA", img.size, (0, 0, 0, 0)); dd = ImageDraw.Draw(detail)
    dd.ellipse((48, 38, 65, 58), fill=(50, 226, 244, pulse))
    dd.rectangle((51, 53, 54, 55), fill=(255, 205, 90, 70 if index in (1, 2) else 30))
    img = Image.alpha_composite(img, detail)
    return img

def review(master: Image.Image) -> Image.Image:
    out=master.copy(); d=ImageDraw.Draw(out)
    for x,y,w,h,name in BLOCKERS:
        rect(d,(x,y,w,h),(255,50,50,85),(255,70,70,255),4)
    for x,y,w,h,name in PORTALS:
        rect(d,(x,y,w,h),(30,255,130,45),(70,255,150,255),4)
    for name,(x,y) in ANCHORS.items():
        px,py=wp(x,y); d.ellipse((px-12,py-12,px+12,py+12),fill=(40,210,255,255),outline=(255,255,255,255),width=3)
    line(d,[(850,4000),(850,4920),(1000,5100),(1000,5950)],(70,230,255,255),10)
    return out

def main() -> None:
    master=draw_master()
    master.save(OUT/"chapel_master.png",optimize=True)
    master.save(OUT/"chapel_static.png",optimize=True)
    for old in OUT.glob("chapel_frame_*.png"):
        old.unlink()
    for i in range(12): animated_overlay(i).save(OUT/f"chapel_overlay_{i:02d}.png",optimize=True)
    review(master).save(OUT/"chapel_collision_review.png",optimize=True)
    for i in range(4): draw_fisherman(i).save(OUT/f"fisherman_frame_{i:02d}.png",optimize=True)
    print(f"chapel unified: static {SIZE[0]}x{SIZE[1]}, 12 overlays {OVERLAY_SIZE[0]}x{OVERLAY_SIZE[1]}, 4 fisherman frames, {len(BLOCKERS)} blockers")

if __name__ == "__main__": main()
