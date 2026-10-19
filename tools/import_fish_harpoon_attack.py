"""Stage/apply ONLY generated fish attack clips through the existing native importer."""
from pathlib import Path
import argparse, importlib.util,json,shutil,hashlib
from PIL import Image
import requests
from concurrent.futures import ThreadPoolExecutor
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'art/source/pixellab/enemy-motion-v3'
WORK=SOURCE/'fish/harpoon-fire-v2'
spec=importlib.util.spec_from_file_location('enemy_import',ROOT/'tools/import_enemy_motion.py');module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
def main():
 parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');args=parser.parse_args()
 data=json.loads((SOURCE/'jobs.json').read_text(encoding='utf-8'))
 incoming=json.loads((WORK/'generated-jobs.json').read_text(encoding='utf-8'))
 assert all(j['kind']=='fish' and j['action']=='attack' for j in incoming)
 stage=WORK/'staged';module.TARGET=stage
 manifest=json.loads((ROOT/'assets/enemies/motion_v3/fish/manifest.json').read_text(encoding='utf-8'))
 staged={}
 def fetch(pair):
  url,path=pair
  if path.exists(): return
  path.parent.mkdir(parents=True,exist_ok=True)
  response=requests.get(url,timeout=90);response.raise_for_status();path.write_bytes(response.content)
 downloads=[(url,SOURCE/job["source_dir"]/f"{i:03}.png") for job in incoming if not job.get("mirrored_from") for i,url in enumerate(job["frames"])]
 with ThreadPoolExecutor(max_workers=6) as pool:list(pool.map(fetch,downloads))
 for job in sorted(incoming,key=lambda j:bool(j.get('mirrored_from'))):
  if job.get('mirrored_from'):
   source=Image.open(stage/'fish'/('attack-'+job['mirrored_from']+'.png')).convert('RGBA')
   count=source.width//module.CELL; atlas=Image.new('RGBA',source.size)
   for i in range(count):
    frame=source.crop((i*128,0,(i+1)*128,128)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if i==0:frame=Image.open(WORK/'backup'/('walk-'+job['direction']+'.png')).crop((0,0,128,128)).convert('RGBA')
    atlas.alpha_composite(frame,(i*128,0))
   atlas.save(stage/'fish'/('attack-'+job['direction']+'.png'))
   clip=dict(staged[job['mirrored_from']]);clip.update(path='res://assets/enemies/motion_v3/fish/attack-'+job['direction']+'.png',job_id=job['job_id'],mirrored_from=job['mirrored_from'],source_anchor=manifest['clips']['walk'][job['direction']]['source_anchor'])
   staged[job['direction']]=clip
   continue
  clip=module.process(job,data['jobs']);clip['fire_frame']=job.get('fire_frame',5);clip['recover_frame']=7;clip['path']='res://assets/enemies/motion_v3/fish/attack-'+job['direction']+'.png';staged[job['direction']]=clip
 for job in incoming:
  if job.get('frame_order'):
   path=stage/'fish'/('attack-'+job['direction']+'.png'); source=Image.open(path).convert('RGBA'); atlas=Image.new('RGBA',source.size)
   for i,index in enumerate(job['frame_order']):atlas.alpha_composite(source.crop((index*128,0,(index+1)*128,128)),(i*128,0))
   atlas.save(path)
  staged[job['direction']]['recover_frame']=job.get('recover_frame',7)
 (WORK/'staged-clips.json').write_text(json.dumps(staged,indent=2)+'\n',encoding='utf-8')
 if args.apply:
  dirs={'south','south-east','east','north-east','north','north-west','west','south-west'}
  assert set(staged)==dirs,'All eight reviewed directions required'
  assert all(j.get('approved') for j in incoming),'Review before applying'
  for direction in staged:shutil.copy2(stage/'fish'/('attack-'+direction+'.png'),ROOT/'assets/enemies/motion_v3/fish'/('attack-'+direction+'.png'))
  manifest['clips']['attack']=staged
  (ROOT/'assets/enemies/motion_v3/fish/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
  (WORK/'approved').mkdir(exist_ok=True)
  for job in incoming:
   name='attack-'+job['direction']+'.png'
   shutil.copy2(stage/'fish'/name,WORK/'approved'/name)
   job['packed_native_sheet']=(WORK/'approved'/name).relative_to(SOURCE).as_posix()
   job['packed_clip']=staged[job['direction']]
  data['jobs']=[j for j in data['jobs'] if not (j['kind']=='fish' and j['action']=='attack')]+incoming
  (SOURCE/'jobs.json').write_text(json.dumps(data,ensure_ascii=False,indent=1)+'\n',encoding='utf-8')
  for p in (WORK/'backup').glob('walk-*.png'):
   assert hashlib.sha256(p.read_bytes()).digest()==hashlib.sha256((ROOT/'assets/enemies/motion_v3/fish'/p.name).read_bytes()).digest()
 print('Applied' if args.apply else 'Staged',list(staged))
if __name__=='__main__':main()
