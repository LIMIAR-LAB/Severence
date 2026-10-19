# Golden animado

## Movimento v2

Desenho aprovado preservado, sem alterar o PNG. Passos alternados em quatro patas, cadência proporcional à velocidade, transição suave entre passeio e repouso, balanço do corpo e movimento secundário da cabeça/orelhas/língua. Rabo gira em torno da raiz. A boca usa a mesma deformação do corpo para a lambida continuar conectada. Prévia: `output/dog-animation/golden-movimento-v2.gif`. Validação geométrica em `tests/dog_motion_test.gd` verifica continuidade e as duas faces de cada célula para impedir inversões da malha.

Sprite: `assets/npcs/golden_dog_v1.png`. Geração pelo image_gen integrado, com transparência preservada e referência em `assets/ui/title/golden_dog.png`.

Prompt final: Create a production-ready full-body game sprite matching the character identity of this tiny reference: a VERY CHUBBY ROUND GOLDEN RETRIEVER, goofy slightly cross-eyed big expressive eyes, warm golden fluffy fur, floppy ears, happy silly face and comically long pink tongue hanging out. One dog only. No clothes, no collar needed, no humanoid body. Four clearly readable short dog legs and large soft paws. Three-quarter side view facing RIGHT, visible top of back/head suitable for a top-down 2D action game. Body horizontally oriented, head on right, fluffy curved tail clearly separated from body at left, feet planted. Raised tail should be visible for wagging animation; long hanging tongue clearly separated on right. Hand-painted PIXEL ART with crisp edges, rich golden fur shading, warm rimlight, dark readable outlines, very appealing caricature, matches detailed dark maritime dieselpunk game art but dog remains friendly and bright. Genuine transparent alpha background, no shadow, no ground, no scenery, no text, no sheet/grid, no other pose. Full dog visible including tail tongue and all paws with 8% transparent margin. Landscape 4:3 canvas. This is the character for both exploration scene and safe refuge; preserve the reference's fat goofy golden identity.

Animação contínua por malha em `scripts/dog_visuals.gd`: respiração, rabo, orelha, língua e patas durante o passeio. O mesmo desenho é usado no Contrabando e no Refúgio. A progressão existente foi preservada: após o encontro e teleporte nas Docas, passa a morar no Refúgio. Interagir cura, vira o cachorro para o personagem e estende a língua; o passeio pausa e retoma sem salto.

Verificação: `tests/dog_p8_test.gd` terminou com zero falhas e cobre encontro, cura, teleporte, residência, persistência e pausa/retomada da lambida. `tools/preview_dog_animation.gd` capturou 80 quadros no Refúgio, incluindo caminhada e interação, com textura carregada e saída 0. Prévia final em `output/dog-animation/golden-refugio-final.gif`.

## Refúgio: colisão e tamanho

Sprite reduzido de 144×108 para 120×90 (cerca de 17%), preservando a arte e a animação. Sombra e indicador de encontro acompanham a nova escala. O passeio deixou de atribuir posições de uma órbita que passava fora do piso: agora percorre quatro pontos na área central livre, a 28 unidades/s, usando move_body e clear_at com raio 28. A colisão em pequenos passos impede atravessar paredes mesmo com intervalos grandes. Sessões antigas com posição inválida são recuperadas para um ponto livre da rota. Lambida continua pausando o passeio.

Validação: dog_hub_collision_test.gd passou, incluindo dois minutos de percurso, quatro destinos visitados, limite de deslocamento por quadro, recuperação de posição antiga, parede fina com intervalo de 10 segundos e parada para lambida. dog_motion_test.gd passou após redução do tamanho, sem inversões ou saltos da malha.
