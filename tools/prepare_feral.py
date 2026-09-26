"""Pack generated transparent art into four-direction game atlases; preserve sources."""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

def pack(source, target, cell):
    im = Image.open(ROOT / source).convert('RGBA')
    a = np.asarray(im)[:, :, 3]
    # Generated sheets have generous gutters but not mathematically equal rows.
    def bounds(projection, n):
        spans = []
        start = None
        for i, occupied in enumerate(projection):
            if occupied and start is None: start = i
            if not occupied and start is not None: spans.append((start, i)); start = None
        if start is not None: spans.append((start, len(projection)))
        gaps = sorted([(spans[i+1][0]-spans[i][1], spans[i][1], spans[i+1][0]) for i in range(len(spans)-1)], reverse=True)[:n-1]
        cuts = [0] + sorted([(lo+hi)//2 for _,lo,hi in gaps]) + [len(projection)]
        if len(cuts) != n+1: cuts = [round(i*len(projection)/n) for i in range(n+1)]
        return cuts
    ys = bounds((a > 20).any(axis=1), 4)
    sprites = []
    for row in range(4):
        xs = bounds((a[ys[row]:ys[row+1]] > 20).any(axis=0), 4)
        for col in range(4):
            sprite = im.crop((xs[col],ys[row],xs[col+1],ys[row+1]))
            sprites.append(sprite.crop(sprite.getbbox()))
    scale = min((cell-12)/max(s.width for s in sprites), (cell-12)/max(s.height for s in sprites))
    out = Image.new('RGBA',(cell*4,cell*4))
    for i,s in enumerate(sprites):
        s = s.resize((max(1,round(s.width*scale)), max(1,round(s.height*scale))), Image.Resampling.NEAREST)
        out.alpha_composite(s, ((i%4)*cell+(cell-s.width)//2,(i//4)*cell+cell-6-s.height))
    out.save(ROOT/target)
    print(target, out.size)

pack('art/source/spectre-feral-source.png','assets/mech/spectre-feral.png',128)
pack('art/source/spectre-fusion-source.png','assets/marty/spectre-fusion.png',160)
if (ROOT/'art/source/warden-source.png').exists():
    pack('art/source/warden-source.png','assets/enemies/warden.png',256)
