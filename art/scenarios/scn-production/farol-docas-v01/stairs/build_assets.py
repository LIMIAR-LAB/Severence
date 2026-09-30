"""Native pixel composition from the reviewed PixelLab kit; no resizing of assets."""
from pathlib import Path
from PIL import Image, ImageDraw
import json, hashlib

ROOT = Path(__file__).resolve().parent
KIT = ROOT.parent / 'kit'
PREFIX = 'res://art/scenarios/scn-production/farol-docas-v01/stairs/'
PALETTE = {'mortar':'#34383c','dark':'#424951','stone':'#4d555d','lit':'#58606b','cap':'#6f7880','moss':'#464f48'}
HEIGHTS = [0,6,11,17,22,28,33,39]

def save(im, name):
    im.save(ROOT / name)
    return {'path':PREFIX+name, 'dimensions':list(im.size), 'sha256':hashlib.sha256((ROOT/name).read_bytes()).hexdigest()}

def face(variant):
    im = Image.new('RGBA',(64,44),PALETTE['mortar']); d=ImageDraw.Draw(im)
    rows = [(3,15,[0,23,49,64]),(17,28,[0,11,38,64]),(30,40,[0,29,53,64])]
    if variant:
        rows=[(3,15,[0,15,44,64]),(17,28,[0,31,57,64]),(30,40,[0,19,46,64])]
    for row,(top,bottom,edges) in enumerate(rows):
        for j,(left,right) in enumerate(zip(edges,edges[1:])):
            x0=left if left==0 else left+1; x1=right-1
            d.rectangle((x0,top,x1,bottom),fill=PALETTE['stone' if (row+j+variant)%3 else 'dark'])
            d.line((x0,top,x1,top),fill=PALETTE['lit'])
            if x1-x0>10:
                d.line((x0+3,top+3,x0+5,top+3),fill=PALETTE['dark'])
    d.rectangle((0,0,63,1),fill=PALETTE['lit']); d.line((0,0,63,0),fill=PALETTE['cap'])
    d.line((0,42,63,42),fill=PALETTE['dark']); d.line((0,43,63,43),fill=PALETTE['mortar'])
    for x in ([8,9,41,42,43] if not variant else [22,23,54]):
        d.point((x,41),fill=PALETTE['moss'])
    return im

floor=Image.open(KIT/'tile_0.png').convert('RGBA').crop((19,62,83,110))
floor_meta=save(floor,'floor-stone.png')
faces=[face(0),face(1)]
face_meta=[save(im,f'face44-{i}.png') for i,im in enumerate(faces)]

def floor_patch(w,h,phase_x=0,phase_y=0):
    out=Image.new('RGBA',(w,h)); pix=out.load()
    for y in range(h):
        for x in range(w): pix[x,y]=floor.getpixel(((x+phase_x)%64,(y+phase_y)%48))
    return out

def tread(side, phase_x=0):
    im=floor_patch(25,360,phase_x); d=ImageDraw.Draw(im)
    # Screen illumination remains upper-left for BOTH directions. No bitmap mirror.
    lip=0 if side=='west' else 24
    d.line((lip,0,lip,359),fill=PALETTE['dark'])
    # Narrow edge-on riser, with distinct authored illumination on either side.
    adjacent=1 if side=='west' else 23
    d.line((adjacent,0,adjacent,359),fill=PALETTE['lit'] if side=='west' else PALETTE['stone'])
    d.line((0,0,24,0),fill=PALETTE['lit'])
    return im

tread_meta={side:save(tread(side),f'tread-{side}.png') for side in ('west','east')}
landing=floor_patch(800,360,200); save(landing,'landing-top.png')
front=Image.new('RGBA',(800,44))
for x in range(0,800,64): front.paste(faces[(x//64)%2],(x,0))
save(front,'landing-face44.png')
module=Image.new('RGBA',(1200,404)); module.paste(landing,(200,0)); module.paste(front,(200,360))
for side in ('west','east'):
    flight=Image.new('RGBA',(200,404))
    for i,h in enumerate(HEIGHTS):
        x=i*25 if side=='west' else 175-i*25
        tile=tread(side,(x if side=='west' else x+1000)%64)
        flight.paste(tile,(x,44-h))
        if h:
            # Native crop of the authored face; never compress 44 to h.
            cheek=faces[(i//2)%2].crop((0,44-h,25,44))
            flight.paste(cheek,(x,404-h))
    save(flight,f'stairs-{side}-composed.png')
    module.alpha_composite(flight,(0 if side=='west' else 1000,0))
save(module,'module-native-preview.png')
# Review enlargement only; native outputs above are the deliverables.
sheet=Image.new('RGBA',(768,300),'#19222d')
for i,im in enumerate(faces): sheet.alpha_composite(im.resize((256,176),Image.Resampling.NEAREST),(i*280+20,24))
sheet.alpha_composite(floor.resize((192,144),Image.Resampling.NEAREST),(570,24))
save(sheet,'face-material-review.png')

manifest={'schema_version':1,'status':'art_candidate_awaiting_game_inspection','height':44,'world_units_per_pixel':1,'allowed_transforms':['translate'],
 'textures':{'face44':PREFIX+'face44-0.png','face44_variant':PREFIX+'face44-1.png','floor':PREFIX+'floor-stone.png','west_tread':PREFIX+'tread-west.png','east_tread':PREFIX+'tread-east.png'},
 'source':{'floor':'../kit/tile_0.png','palette':'../kit/tile_3.png','provider':'PixelLab','generation_id':'4803f5b5-6c5c-419d-bb2f-5cb3d70b0bc8'},
 'source_rect':[19,62,64,48], 'dimensions':{'face44':[64,44],'floor':[64,48],'west_tread':[25,360],'east_tread':[25,360]},
 'provenance':{'floor':'Lossless crop of reviewed generated stone floor','face44':'Deterministic native pixel authorship, 3 masonry courses, exact observed kit palette; build_assets.py','treads':'Native floor pixels plus explicit orientation-specific lips; no mirroring or scaling','permission':'User-authorized modular composition and coordinator explicit deterministic face authorship','pixellab_exact_draw_attempt':'Rejected before rendering: source canvas exceeded target bounds; no accepted generated result from that call'},
 'geometry':{'footprint':[1200,360],'landing':[200,0,800,360],'west':[0,0,200,360],'east':[1000,0,200,360],'tread_heights':HEIGHTS,'arrival_height':44,'tread_run':25,'projection':'visual_y=physical_y-height','canvas_origin':[0,-44]},
 'composed_previews':{'west':PREFIX+'stairs-west-composed.png','east':PREFIX+'stairs-east-composed.png','module':PREFIX+'module-native-preview.png','landing_top':PREFIX+'landing-top.png','landing_face':PREFIX+'landing-face44.png'},
 'native_preview_note':'Static quantized-tread composition for visual review. Continuous projected feet require game validation. Preview is not final collision geometry.',
 'palette':PALETTE,'assets':{'floor':floor_meta,'faces':face_meta,'treads':tread_meta},'runtime_approved':False,'catalog_approved':False}
(ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
print('Created native floor, face44 variants, two authored treads, composed stairs and review images.')
