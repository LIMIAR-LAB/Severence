"""Download and pack generated Omega flight frames; no drawing or rescaling."""
import json
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import requests
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'art/source/characters/marty/omega/flight'
DIRECTIONS=['south','south-east','east','north-east','north','north-west','west','south-west']

def main():
 if (WORK/'approved-anchors.json').exists():
  points=json.loads((WORK/'approved-anchors.json').read_text())
  atlas=Image.new('RGBA',(112,896));anchors=[]
  for row,direction in enumerate(DIRECTIONS):
   im=Image.open(WORK/'rotations'/f'{direction}.png').convert('RGBA')
   assert im.size==(96,96) and im.getbbox()
   atlas.alpha_composite(im,(8,row*112+8))
   assert len(points[direction])==4
   anchors.append([[[x+8,y+8] for x,y in points[direction]]])
  output=ROOT/'assets/characters/marty/omega/rounded_v4';atlas.save(output/'flight.png')
  (output/'flight.json').write_text(json.dumps({'cell':112,'frames':1,'directions':DIRECTIONS,'anchors':anchors,'source_character':'465590a4-dc1f-474b-af69-7384493b2184','animation':'Dedicated upright pose; dynamic renderer exhaust and smooth lift/landing'},indent=2)+'\n')
  print('Packed eight native upright flight poses, transparent padding only');return
 jobs=json.loads((WORK/'jobs.json').read_text(encoding='utf-8-sig'))
 def fetch(pair):
  url,path=pair
  if path.exists():return
  path.parent.mkdir(parents=True,exist_ok=True)
  r=requests.get(url,timeout=90);r.raise_for_status();path.write_bytes(r.content)
 with ThreadPoolExecutor(max_workers=9) as pool:
  list(pool.map(fetch,[(u,WORK/'raw'/j['direction']/f'{i}.png') for j in jobs for i,u in enumerate(j['frames'])]))
 for job in jobs:
  frames=[Image.open(WORK/'raw'/job['direction']/f'{i}.png').convert('RGBA') for i in range(9)]
  sheet=Image.new('RGBA',(frames[0].width*9,frames[0].height))
  for i,im in enumerate(frames):sheet.alpha_composite(im,(i*im.width,0))
  sheet.save(WORK/(job['direction']+'-review.png'))
 selections_path=WORK/'selections.json'
 if not selections_path.exists():print('Raw review sheets ready');return
 selections=json.loads(selections_path.read_text())
 if set(selections)!=set(DIRECTIONS):print('Awaiting all eight approved directions');return
 atlas=Image.new('RGBA',(448,896));anchors=[]
 for row,direction in enumerate(DIRECTIONS):
  item=selections[direction];assert len(item['frames'])==4 and len(item['anchors'])==4
  for col,index in enumerate(item['frames']):
   im=Image.open(WORK/'raw'/direction/f'{index}.png').convert('RGBA')
   # V3 may pad the reference uniformly. Remove only transparent border.
   margin=(im.width-112)//2
   assert im.width==im.height and margin>=0
   box=im.getbbox();assert box and box[0]>margin and box[1]>margin and box[2]<112+margin and box[3]<112+margin
   im=im.crop((margin,margin,112+margin,112+margin))
   atlas.alpha_composite(im,(col*112,row*112))
  anchors.append(item['anchors'])
 output=ROOT/'assets/characters/marty/omega/rounded_v4';atlas.save(output/'flight.png')
 (output/'flight.json').write_text(json.dumps({'cell':112,'frames':4,'directions':DIRECTIONS,'anchors':anchors},indent=2)+'\n')
 print('Packed approved flight: 4 frames x 8 directions, native 112px')

if __name__=='__main__':main()
