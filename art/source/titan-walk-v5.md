# Titan v5 — ciclo de passos

Gerado com image_gen integrado. Fonte: titan-walk-v5.png.
Atlas: assets/mech/titan_v5.png. Importador: tools/import_titan_walk.gd.
Cinco vistas com quatro poses de passada e repouso. Escala comum 0,63,
pés ancorados em y=164, sem apagar extremidades para criar margens.
Colunas adicionais conservadas por compatibilidade. Renderer usa 0–4.
Tiro não interrompe caminhada. As diagonais usam vistas próprias.
Prévia reproduzível: tests/titan_walk_preview.gd.

## Prompt

Use attached Titan atlas as identity reference. Create NEW corrected production pixel art robot animation atlas on transparent background. Exactly 5 rows x 5 columns, equal cells, 25 complete robots. Row1 front, row2 front-right 3/4, row3 right profile, row4 rear-right 3/4, row5 full back. Columns: idle planted stance; left foot forward right foot back; left foot planted right knee lifted; right foot forward left foot back; right foot planted left knee lifted. Real visibly distinct WALK CYCLE with articulated knees, feet lift, alternating support, weight shifts. Keep same robot design and scale across ALL frames: chunky olive military mech, fully CLOSED helmet, cyan eyes, cyan chest core only visible on front, brass backpack tanks on rear, one compact cannon forearm and one mechanical hand. Top-down 3/4 pixel game perspective matching original. MOST IMPORTANT every sprite fully inside its cell with 15 percent transparent space on ALL edges. Entire feet, hands and muzzle tips visible, absolutely no cropping, no bleed into neighboring cells. Smaller robot within cell preferable to cut off parts. Keep feet support baseline consistent, no scale jitter. No muzzle flashes, bullets, thruster flames, text, labels, grid or environment. Crisp hand-crafted pixel art matching Marty game, sharp plates/rivets, clean silhouettes. Rear views show rear plates only, not cyan face/chest. Deliver all 25 sprites.
