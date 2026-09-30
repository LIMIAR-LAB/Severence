"""Native connector candidates. PixelLab floor retained; deterministic flat edging."""
from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
ROOT=Path(__file__).resolve().parent
SPEC=json.loads((ROOT/'specification.json').read_text(encoding='utf-8'))
SOURCE=ROOT.parent/'stairs/floor-stone.png'
FLOOR=Image.open(SOURCE).convert('RGBA')
PREFIX='res://art/scenarios/scn-production/farol-docas-v01/connectors/'
COLORS={'base':'#4d555d','light':'#58606b','joint':'#424951'}

def write(im,name):
    im.save(ROOT/name)
    return {'texture':PREFIX+name,'dimensions':list(im.size),'sha256':hashlib.sha256((ROOT/name).read_bytes()).hexdigest()}

entries=[]
preview=Image.new('RGBA',(720,300),'#19222d');pd=ImageDraw.Draw(preview)
for index,s in enumerate(SPEC['connectors']):
    rx,ry,w,h=s['rect'];ax,ay,aw,ah=s['useful_aperture_canvas']
    floor=Image.new('RGBA',(w,h));border=Image.new('RGBA',(w,h));pix=floor.load()
    for y in range(ay,ay+ah):
        for x in range(ax,ax+aw):
            pix[x,y]=FLOOR.getpixel(((rx+x)%64,(ry+y)%48))
    d=ImageDraw.Draw(border)
    for bx,by,bw,bh in s['border_regions_canvas']:
        d.rectangle((bx,by,bx+bw-1,by+bh-1),fill=COLORS['base'])
        # Flat paving trim: soft light from upper-left, no vertical face or shadow spill.
        d.line((bx,by,bx+bw-1,by),fill=COLORS['light'])
        d.line((bx,by,bx,by+bh-1),fill=COLORS['light'])
        if bw>bh:
            for x in range(bx,bx+bw):
                if (rx+x)%32==0:d.line((x,by,x,by+bh-1),fill=COLORS['joint'])
        else:
            for y in range(by,by+bh):
                if (ry+y)%32==0:d.line((bx,y,bx+bw-1,y),fill=COLORS['joint'])
    combined=floor.copy();combined.alpha_composite(border)
    side=s['side'];floor_info=write(floor,side+'-floor.png');border_info=write(border,side+'-border.png');plate_info=write(combined,side+'-combined.png')
    overlay_pixels_in_aperture=sum(border.getpixel((x,y))[3]>0 for y in range(ay,ay+ah) for x in range(ax,ax+aw))
    floor_phase_mismatches=sum(floor.getpixel((x,y))!=FLOOR.getpixel(((rx+x)%64,(ry+y)%48)) for y in range(ay,ay+ah) for x in range(ax,ax+aw))
    assert overlay_pixels_in_aperture==0 and floor_phase_mismatches==0
    item={**s,'height':0,'material_family':'docks-stone','mode':'plate','depth':'ground','textures':{'floor':floor_info,'border':border_info,'combined':plate_info},'floor_phase_at_canvas_origin':[rx%64,ry%48],'checks':{'border_pixels_inside_aperture':overlay_pixels_in_aperture,'floor_phase_mismatches':floor_phase_mismatches,'useful_width':200}}
    entries.append(item)
    px=index*240+(240-w)//2;py=45
    preview.alpha_composite(combined,(px,py));pd.text((index*240+20,15),side.upper()+' / useful 200 / z=0',fill='#dce3e7')
write(preview,'contact-sheet.png')
manifest={'schema_version':1,'status':'authored_candidate_not_runtime_validated','world_units_per_pixel':1,'height':0,'material_family':'docks-stone','allowed_transforms':['translate'],'width':200,'connectors':entries,'floor_phase':SPEC['floor_phase'],'source':{'path':'res://art/scenarios/scn-production/farol-docas-v01/stairs/floor-stone.png','source_rect':[0,0,64,48],'dimensions':[64,48],'sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'provider':'PixelLab derived lossless crop','generation_id':'4803f5b5-6c5c-419d-bb2f-5cb3d70b0bc8'},'provenance':'Existing native floor plus authored deterministic flat edging; build_connectors.py. No image generation, resizing, rotation, or mirrored illumination.','integration':'Use combined alone OR floor+border, never both. Ground only. Existing collision/connectors unchanged.','notes':SPEC['notes'],'source_hashes':{p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in ['scripts/docks_map.gd','scripts/simulation.gd','scripts/scenarios/room_contract.gd','scripts/scenarios/farol_module.gd']},'stairs_asset_changes':False,'catalog_publishable':False}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
print('Three native connectors authored; 200-unit apertures clear; floor phase exact.')
