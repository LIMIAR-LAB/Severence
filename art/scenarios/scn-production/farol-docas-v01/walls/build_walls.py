from pathlib import Path
from PIL import Image,ImageDraw
import json,hashlib
R=Path(__file__).resolve().parent; B=R.parent; PRE='res://art/scenarios/scn-production/farol-docas-v01/walls/'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
protected={str(p.relative_to(B)):sha(p) for folder in ['stairs','connectors'] for p in (B/folder).glob('*.png')}
textures={}
def save(im,name):
 im.save(R/name);textures[name]={'texture':PRE+name,'dimensions':list(im.size),'sha256':sha(R/name)};return im
def crop(name,box,out):return save(Image.open(B/'kit'/name).convert('RGBA').crop(box),out)
n=crop('tile_1.png',(19,14,83,82),'face-north-64x68.png')
s=crop('tile_3.png',(19,42,83,110),'face-south-64x68.png')
w=crop('tile_4.png',(19,14,45,62),'edge-west-26x48.png')
# East edge authored natively from existing palette: fixed upper-left light, no mirror.
e=w.copy();d=ImageDraw.Draw(e);d.line((0,0,0,47),fill='#58606b');d.line((24,0,24,47),fill='#424951');d.line((25,0,25,47),fill='#34383c');save(e,'edge-east-26x48.png')
def tile(im,width,height,px=0,py=0):
 out=Image.new('RGBA',(width,height));pixels=out.load()
 for y in range(height):
  for x in range(width):pixels[x,y]=im.getpixel(((x+px)%im.width,(y+py)%im.height))
 return out
# Corner pixels remain in the exterior shell; no extension into any opening.
for name,base in [('corner-nw.png',n),('corner-sw.png',s),('corner-se.png',s)]:
 c=base.crop((0,0,26,68));dd=ImageDraw.Draw(c);xx=25 if name.endswith('se.png') else 0;dd.line((xx,0,xx,67),fill='#34383c');save(c,name)
layers=[]
def plate(id,rect,source,phase=(0,0)):
 im=tile(source,rect[2],rect[3],*phase);name=id+'.png';save(im,name);layers.append({'id':id,'rect':rect,'texture':PRE+name,'mode':'plate','depth':'ground','order':len(layers)+100,'world_units_per_pixel':1})
plate('north-face',[0,-68,1500,68],n)
plate('northwest-corner',[-26,-68,26,68],Image.open(R/'corner-nw.png'))
plate('west-upper',[-26,0,26,500],w)
plate('west-lower',[-26,700,26,600],w,(0,700%48))
plate('east-north-jamb',[1700,-68,26,68],e,(0,-68%48))
plate('east-upper',[1700,0,26,500],e)
plate('east-lower',[1700,700,26,600],e,(0,700%48))
plate('south-face-left',[0,1300,940,68],s)
plate('south-face-right',[1068,1300,632,68],s,(1068%64,0))
plate('southwest-corner',[-26,1300,26,68],Image.open(R/'corner-sw.png'))
plate('southeast-corner',[1700,1300,26,68],Image.open(R/'corner-se.png'))
manifest={'schema_version':1,'revision':3,'supersedes':'Initial 1700x900 proposal and continuous south wall withdrawn; preserve legacy south shortcut x940..1068.','status':'candidate_static_preview_only','footprint':[[0,0,1700,1300]],'origin':[0,0],'allowed_transforms':['translate'],'world_units_per_pixel':1,'material_family':'docks-stone','visual_face_height':68,'lateral_shell_width':26,'walkable_surface_height':0,'elevation_policy':'68 is native decorative face height; walls do not create raised surfaces or ramps. South uses exterior cutaway facade, not projected occluding wall.','layers':layers,'reusable_textures':textures,'connectors':[{'side':'west','position':[0,600],'normal':[-1,0],'width':200,'height':0},{'side':'east','position':[1700,600],'normal':[1,0],'width':200,'height':0},{'side':'north','position':[1600,0],'normal':[0,-1],'width':200,'height':0}],'collision':{'new_obstacles':[],'policy':'Existing union of room and corridor walkable footprints provides boundary collision; do not add collision for wall pixels. Do not extend footprint to include exterior art. If runtime permits leaving that union, owner must enforce its boundary separately.'},'ordering':'Draw ground floor and connectors first, then these exterior ground plates in listed order, then actors and existing depth-sorted stair face. No new foreground strip. Omit material=floor. Do not clip walls to walkable footprint, since all wall art is exterior.','north_corner':'North horizontal wall stops at x1500. Opening x1500..1700 stays free for every y<0. Exterior east jamb occupies x1700..1726,y-68..0; joins east-upper at y0. No conventional NE corner, lintel, cap, or collision may bridge north aperture. Neighbor corridor owns continuation north of y-68.','provenance':{'method':'Native crops and deterministic tiling/palette edging; no new generation, image rotation or scaling.','source_crops':{'tile_1.png':[19,14,64,68],'tile_3.png':[19,42,64,68],'tile_4.png':[19,14,26,48]},'sources':{p.name:sha(p) for p in [B/'kit/tile_1.png',B/'kit/tile_3.png',B/'kit/tile_4.png']}},'protected_png_hashes':protected}
manifest['auxiliary_connectors']=[{'id':'south-shortcut','type':'shortcut','position':[1004,1300],'normal':[0,1],'width':128,'height':0,'opening_range':[940,1068],'corridor_rect':[940,1300,128,800],'source':'DOCKS.SHORTCUTS[0]','note':'Separate from three regular walk gates; preserve existing functional path.'}]
# Native preview includes adjacent corridor stubs, current connectors, unchanged stairs.
bounds=(-330,-330,2130,2180);ox,oy=330,330
canvas=Image.new('RGBA',(2460,2510),'#0c1320');floor=Image.open(B/'stairs/floor-stone.png').convert('RGBA')
for x,y,ww,hh in [(0,0,1700,1300),(-300,500,300,200),(1700,500,400,200),(1500,-300,200,300),(940,1300,128,800)]:canvas.alpha_composite(tile(floor,ww,hh,x%64,y%48),(x+ox,y+oy))
cm=json.loads((B/'connectors/manifest.json').read_text(encoding='utf-8'))
for c in cm['connectors']:
 rect=c['rect'];im=Image.open(B/'connectors'/f"{c['side']}-combined.png").convert('RGBA')
 # Clip connector ornament to walkable union, matching accepted base captures.
 for yy in range(im.height):
  for xx in range(im.width):
   x,y=rect[0]+xx,rect[1]+yy
   if not ((0<=x<1700 and 0<=y<1300) or (-300<=x<2100 and 500<=y<700) or (1500<=x<1700 and -300<=y<0) or (940<=x<1068 and 1300<=y<2100)):im.putpixel((xx,yy),(0,0,0,0))
 canvas.alpha_composite(im,(rect[0]+ox,rect[1]+oy))
canvas.alpha_composite(Image.open(B/'stairs/module-native-preview.png').convert('RGBA'),(250+ox,256+oy))
for layer in layers:canvas.alpha_composite(Image.open(R/(layer['id']+'.png')).convert('RGBA'),(layer['rect'][0]+ox,layer['rect'][1]+oy))
canvas.save(R/'perimeter-native-preview.png')
canvas.crop((890+ox,1250+oy,1118+ox,1420+oy)).save(R/'south-shortcut-detail.png')
canvas.crop((1450+ox,-100+oy,1760+ox,100+oy)).save(R/'north-corner-detail.png')
manifest['previews']={'native':PRE+'perimeter-native-preview.png','north_detail':PRE+'north-corner-detail.png','south_shortcut_detail':PRE+'south-shortcut-detail.png','native_preview_local_bounds':list(bounds),'note':'Offline native composition, not runtime capture; no actors. Detail is a 1:1 crop.'}
(R/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def intersects(a,b):return max(a[0],b[0])<min(a[0]+a[2],b[0]+b[2]) and max(a[1],b[1])<min(a[1]+a[3],b[1]+b[3])
walkable=[[0,0,1700,1300],[-300,500,300,200],[1700,500,400,200],[1500,-300,200,300],[940,1300,128,800]]
assert all(not intersects(l['rect'],f) for l in layers for f in walkable)
assert all(sha(B/p)==h for p,h in protected.items())
assert all(Image.open(R/(l['id']+'.png')).size==tuple(l['rect'][2:]) for l in layers)
(R/'inspection.json').write_text(json.dumps({'status':'geometry_checked_visual_review_pending','layers':len(layers),'native_dimensions_match':True,'wall_intersections_walkable_union':0,'protected_pngs_unchanged':len(protected),'new_obstacles':0,'limitations':['Offline composition only; runtime camera, actor occlusion and corridor continuation require integration review.']},indent=2)+'\n',encoding='utf-8')
print('Created',len(layers),'native wall plates; protected',len(protected),'existing PNGs; no walkable intersection.')
