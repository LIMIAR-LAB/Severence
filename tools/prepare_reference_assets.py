"""Extract reusable art from the user's supplied concept, preserving source files."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / 'art/source/docks-reference.png').convert('RGBA')
out = ROOT / 'assets/environment/reference'
out.mkdir(parents=True, exist_ok=True)

def crop(name, box, polygon=None):
    im = source.crop(box)
    if polygon:
        mask = Image.new('L', im.size)
        ImageDraw.Draw(mask).polygon(polygon, fill=255)
        im.putalpha(mask)
    im.save(out / (name + '.png'))

crop('floor', (526,440,654,568))
crop('water', (700,0,828,60))
crop('wall', (534,64,662,145))
crop('crate', (286,137,337,204), [(1,3),(48,0),(50,62),(2,66)])
crop('lamp', (484,88,517,140), [(13,0),(23,8),(29,12),(29,42),(17,51),(3,44),(1,14)])
crop('chest', (934,526,1008,603), [(12,10),(32,1),(62,8),(72,22),(69,64),(48,75),(0,60),(0,27)])
crop('barrel', (816,144,876,241), [(11,5),(32,0),(53,8),(59,76),(49,91),(12,96),(0,82),(0,20)])
crop('sandbags', (691,143,813,242), [(30,7),(68,0),(101,9),(110,28),(106,43),(122,54),(115,76),(115,93),(69,99),(11,86),(0,56),(8,28)])
crop('rope', (367,206,442,268), [(26,0),(54,1),(74,17),(67,36),(39,45),(25,60),(3,59),(0,49),(16,25)])
crop('portrait', (12,12,104,103))
crop('heart', (122,15,143,36))
crop('key', (1077,691,1109,727))
crop('coin', (1170,691,1199,725))
crop('crystal', (1266,688,1293,728))
crop('gun', (310,24,371,65))
print('Extracted 15 reference assets')
