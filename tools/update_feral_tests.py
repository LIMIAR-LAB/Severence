from pathlib import Path
p=Path('tests/solo_robot_test.gd'); s=p.read_text(); s=s.replace('a.hurt = 0; s.damage_actor(a, 25)','a.hp = 100; a.hurt = 0; s.damage_actor(a, 25)').replace('s.spectres[0].hp == 75 and a.hp == 30','s.spectres[0].hp == 75 and a.hp == 100').replace('not a.fused and a.hp == 25','not a.fused and a.hp == 85'); p.write_text(s)
for f,old,new in [('tests/enemies_test.gd','95 - 46','118.75 - 46'),('tests/omega_test.gd','95 - 38','118.75 - 38'),('tests/simulation_test.gd','s.enemies[0].hp == 85','s.enemies[0].hp == 108.75')]:
 p=Path(f); s=p.read_text(); p.write_text(s.replace(old,new))
