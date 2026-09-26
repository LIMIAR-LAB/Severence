# Titan — embarque e desembarque

Fonte titan-cockpit.png gerada via image_gen integrado; atlas final
assets/mech/titan_cockpit.png, normalizado por tools/import_titan_cockpit.gd.
Escotilha frontal abre e fecha em 1,2 segundo. O piloto é uma camada separada,
preservando roupa equipada. Durante a transição, comandos do piloto ficam
bloqueados; dano continua possível. Saída exige espaço e entrada exige combustível.
Prévia reproduzível: tests/titan_cockpit_preview.gd.

## Prompt

Create transparent pixel art animation strip, exactly 6 columns one row, six complete identical-scale Titan robots facing FRONT. Use reference robot identity: olive military armor, closed round head cyan eyes, big round cyan chest core, short legs, cannon forearm, brass backpack. Animate CHEST COCKPIT HATCH: frame1 fully closed normal; frame2 chest plates slightly separate; frame3 half open chest; frame4 fully open chest revealing dark EMPTY pilot seat and ladder/step; frame5 same fully open; frame6 fully closed again. No pilot/person inside, pilot will be rendered as separate game sprite. Head stays closed in ALL frames. Same silhouette, planted feet baseline, same camera and size. Full feet and cannon visible with generous transparent margins for EVERY frame, no clipping. Crisp detailed pixel art consistent with reference. No text, grid, floor, background, flames. Robot fits each cell; absolutely no overlapping cells.
