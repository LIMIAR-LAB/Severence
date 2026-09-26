# Marty modular — integração 0.18

O jogo usa assets/marty/marty_anim_v3.png: quatro roupas, cinco vistas,
dez quadros por vista em células de 96 px. Nenhuma arma faz parte do corpo.
Fonte: art/source/marty-todas-skins-sem-armas-v1.png.

O importador tools/import_marty_unarmed.gd normaliza transparência e pés
na linha 92. As passadas deslocam os pés; salto e golpe usam a pose-base,
com movimento do personagem e da arma controlado pelo renderer.
Não são animações novas desenhadas quadro a quadro.

world_view.gd ancora as armas à mão por vista e sobrepõe um recorte dos
dedos da própria arte. Braços geométricos foram removidos. Recuo angular
preserva a posição da empunhadura. Armas continuam intercambiáveis.

Validação visual reproduzível: tests/marty_grip_preview.gd cria uma imagem
com as quatro roupas nas cinco vistas em test-output/marty-grips.png.
