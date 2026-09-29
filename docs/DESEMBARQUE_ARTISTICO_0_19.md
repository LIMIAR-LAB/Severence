# Desembarque artístico — 0.19

Primeira sala piloto com composição exclusiva: cargueiro avariado, abrigo antiaéreo, armazém em ruínas, iluminação âmbar e cais recortado sobre água azul. As outras salas permanecem modulares.

## Arte e origem

`assets/environment/docks12/entry/desembarque_painted_v1.png`: imagem original gerada com a ferramenta ImageGen desta conversa (1536 × 1024). Usada diretamente como ambiente do jogo, sem recorte ou edição raster posterior. Direção de arte: docas de Londres em 1941, vista elevada compatível com Marty, pixel art detalhada, navio à esquerda, bunker e ruína ao norte, saídas norte/leste abertas, piso central livre, mar escuro e reflexos âmbar; sem personagens, interface ou portal incorporado. Este é o resumo do briefing, não a transcrição literal do prompt da geração.

## Mapeamento

Fonte única: `tools/build_docks_map.py`; executar o gerador antes de testar.

Imagem → mundo: `x = 187 + pixel_x * 2013 / 1536`, `y = 6000 + pixel_y * 1280 / 1024`.

Bounds: Rect2(187,6000,2013,1280). Pisos (x,y,largura,altura):

- Centro: (600,6380,1240,540).
- Faixa superior: (600,6260,1050,120), evita as caixas pintadas da ruína.
- Rua norte: (900,6000,200,260), liga à Capela.
- Ponte leste: (1840,6400,360,230), liga aos Guindastes.
- Recorte inferior: (1600,6920,160,65).

Navio, margem externa, água e carga não são superfícies caminháveis. Os antigos obstáculos, decorações e tentáculo da entrada foram removidos na fonte; colisões vêm da união dos pisos. Não há props invisíveis no centro. Spawns dos dois jogadores e inimigos, chave e rotas para o Titan são verificados automaticamente.

## Camadas e animação

`arrival_art.gd` desenha a composição somente no modo expedição quando a entrada está descoberta. Pisos, grunge e paredes modulares dessa sala são ignorados por `painted`; outras salas e corredores continuam no renderer existente. A imagem não invade os bounds de salas vizinhas.

A fenda está próxima do ponto de chegada: abre em 1,6 segundo e mantém contorno deformado pulsante, núcleo violeta, partículas e reflexo ciano. É animação Godot em tempo real, não GIF importado, e não bloqueia a passagem. `tick_time` reinicia na expedição e já é sincronizado pelo snapshot de rede. Efeito fica sob atores e projéteis para preservar leitura do combate.

Portões e descoberta de corredores agora consideram as alas das salas compostas. Margens internas descartam retângulos vazios ao testar alcovas estreitas.

## Validação

- `tests/arrival_art_test.gd`: chão inicial, duas rotas para Marty/Titan, margens não caminháveis, portas, spawns e tempo sincronizado.
- `tests/arrival_art_preview.gd`: capturas `entry-art-general.png`, `entry-art-normal.png`, `entry-rift-opening.png` em `test-output`.
- Gerador verifica acessibilidade do mapa inteiro e de baús/objetivos.
- `tests/scenery_test.gd`: ponto do cais atualizado para a margem de pedra pintada; ponto antigo ficou no mar.

Mudanças concorrentes de outro agente em `dock_scenery.gd` (shipwreck/bunker/arrival_rift e ROOM_AMBIENT) foram preservadas; esses props não são adicionados ao novo layout.

### Ambiente vivo — continuação 0.19

A pintura recebe movimento em tempo real, sob os personagens: a própria textura do mar é reamostrada em faixas com deslocamento suave, com filetes de água, reflexos âmbar quebrados e espuma dissipando junto às estacas. Os lampiões oscilam, poças refletem a luz e a chaminé do cargueiro solta fumaça leve. As regiões de água são delimitadas em coordenadas da imagem para não movimentar piso, navio ou colisões. Não há alteração do raster nem efeitos no Refúgio. Todos usam `tick_time`, portanto acompanham pausa e snapshots.

`tests/arrival_animation_preview.gd` captura dois instantes da paisagem sem atores/fenda e exige mudança em pelo menos 100 pixels da água: valida movimento próprio do cenário. Imagens: `test-output/entry-environment-0.0.png` e `entry-environment-1.5.png`.
