"""Register the approved generated sheet without assuming exact AI grid spacing."""
from pathlib import Path
from PIL import Image
import numpy as np

ROOT = Path(__file__).resolve().parents[1]

def prepare(name, cols, destination):
    im = Image.open(ROOT / 'output/imagegen' / name).convert('RGBA')
    data = np.array(im)
    rgb = data[:,:,:3].astype(int)
    key = (rgb[:,:,0] > rgb[:,:,1]*1.6) & (rgb[:,:,2] > rgb[:,:,1]*1.6) & (rgb[:,:,0] > 65) & (rgb[:,:,2] > 65)
    data[key,3] = 0
    im = Image.fromarray(data)
    ys = np.where((data[:,:,3] > 0).sum(axis=1) > 30)[0]
    bands = np.split(ys, np.where(np.diff(ys)>6)[0]+1)
    assert len(bands) == 4, len(bands)
    atlas = Image.new('RGBA', (cols*64,320))
    for row, band in enumerate(bands):
        y0,y1 = max(0,int(band[0])-3), min(im.height,int(band[-1])+4)
        xs = np.where((data[y0:y1,:,3]>0).sum(axis=0)>3)[0]
        xbands = np.split(xs,np.where(np.diff(xs)>8)[0]+1)
        assert len(xbands) == cols, (name,row,len(xbands))
        for col, xb in enumerate(xbands):
            cell = im.crop((max(0,int(xb[0])-2),y0,min(im.width,int(xb[-1])+3),y1))
            cell = cell.crop(cell.getbbox())
            factor = min(65/cell.height,56/cell.width)
            cell = cell.resize((round(cell.width*factor),round(cell.height*factor)),Image.Resampling.NEAREST)
            atlas.alpha_composite(cell,(col*64+(64-cell.width)//2,row*80+74-cell.height))
    atlas.save(ROOT / destination)
    return atlas

walk = prepare('marty-v2.png',8,'assets/marty/marty-v2.png')
if (ROOT/'output/imagegen/marty-v2-actions.png').exists():
    prepare('marty-v2-actions.png',6,'assets/marty/actions-v2.png')
preview = Image.new('RGBA',(512,320),'#101c2b')
preview.alpha_composite(walk)
preview.resize((1024,640),Image.Resampling.NEAREST).save(ROOT/'art/marty-v2-preview.png')
print('Registered Marty v2 with transparent background and foot-aligned frames.')
