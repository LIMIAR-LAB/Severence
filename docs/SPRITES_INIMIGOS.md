# Sprites dos inimigos — primeira leva

Os novos sprites do **Guardião** e do **Exploder** seguem a mesma leitura visual de Marty: silhueta nítida, contorno escuro, volume compacto e detalhes ciano sobre o uniforme e o equipamento de 1941. O Guardião usa escudo frontal de metal rebitado; o Exploder tem um núcleo incandescente que comunica o perigo de aproximação. Foram criados no PixelLab e preservados nas fontes `art/source/pixellab/guard_v1.zip` e `bomber_v1.zip`.

| Inimigo | ID do personagem no PixelLab | Escala desenhada no jogo |
| --- | --- | --- |
| Guardião (`guard`) | `8c90bdf0-0c6b-43b2-86ab-8615555ecd9a` | 84 px |
| Exploder (`bomber`) | `dc6ef3b7-aeae-41e6-9e7d-3270546f110b` | 72 px |

`tools/build_pixellab_enemies.py` converte cada ZIP em um atlas transparente de 480 × 768 px. Cada célula mede 96 × 96 px; as oito linhas seguem sul, sudeste, leste, nordeste, norte, noroeste, oeste e sudoeste. A primeira coluna é a pose parada; as quatro seguintes são o movimento. O apoio dos pés fica em `y=92`, mantendo o personagem preso ao chão em todas as vistas. O renderer usa a direção real do inimigo sem espelhamento adicional.

Nesta primeira leva, o movimento gerado cobre quatro direções do Guardião e duas do Exploder. As outras direções usam temporariamente a pose parada correta, sem misturar frentes e costas. O pipeline aceita completar os quadros dessas direções e reconstruir os atlas sem alterar o código do jogo. O aviso de detonação do Exploder pisca em laranja; após explodir, ele desaparece sem deixar o cadáver de outro inimigo.
