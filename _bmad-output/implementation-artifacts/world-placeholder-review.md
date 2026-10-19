# Revisão de arte provisória — 04/10/2026

Pedido: transformar os fiéis em pequenos encapuzados no estilo do Mestre Coral e revisar formas geométricas provisórias ainda visíveis.

## Entregue

- Cinco fiéis usam `assets/npcs/sanctuary_acolyte_v1.png`, com balanço rígido individual, pequenas variações de tamanho/tom e orientação voltada para o centro. Cada fiel entra na ordenação por profundidade, sem ser desenhado obrigatoriamente atrás do Mestre. Desenho anterior de polígonos removido.
- Galão e bateria deixaram de ser retângulos. Artes em `assets/pickups/fuel_can_v1.png` e `battery_cell_v1.png`.
- Bomba física deixou de ser um círculo liso; `assets/pickups/mortar_bomb_v1.png`, mantendo trajetória, sombra, pavio e aviso de área.
- Foguete em voo usa a arte existente `assets/ui/equipamento/icones/icon_foguete_v1.png`, orientada conforme a velocidade; conserva o rastro.
- Renderizador legado de obstáculo `mangrove` usa `mng_tree.png`, já existente, no lugar de círculos e linhas. Salas fixas podem ocultar esse obstáculo quando a árvore já faz parte da pintura.

Integração em `scripts/world_detail_art.gd` e trechos específicos de `scripts/world_view.gd`. Sem alterações na simulação, colisões, coleta, dano, missões ou saves.

## Revisão realizada

Inspeção dos renderizadores de entidades/objetos em world_view, dock_scenery, cenários, aliados, personagens e seleção de personagem. Personagens jogáveis, inimigos, robôs, chefe, mercador, cachorro, Mestre Coral e NPCs resgatados já têm texturas. Moto possui arte com desenho de emergência apenas caso o recurso falhe. Caixas, baús e decoração principal usam arte existente. O arquivo character_silhouette contém retratos provisórios antigos, mas a tela atual usa a arte de conceito e não instancia essas silhuetas. Permanecem primitivas intencionais de interface, sombras, luzes, indicadores de alvo, partículas, trilhos e grades. Esta é uma revisão dos caminhos de renderização, não uma afirmação de playtest exaustivo de todos os estados do jogo.

## Verificação

`titan_fuel_test.gd`: 16 verificações, zero falhas (coleta, combustível, bateria, disparo e bomba). `sanctuary_guardian_test.gd`: 10 verificações, zero falhas, incluindo missão e save intacto. Capturas no motor: fiéis em `output/sanctuary-guardian/encapuzados-animados.gif`; itens e projéteis em `output/world-details/pickups-bomb-tree.png`. Captura de itens concluída com quatro novas texturas carregadas, saída 0. A primeira captura revelou importação ausente do baú vazio, criado por outra frente; apenas sua importação foi concluída, sem alterar a arte ou lógica do baú. A captura posterior não apresentou esse erro.

## Geração

Skill imagegen, ferramenta integrada, alpha transparente preservado. Sem CLI. Originais preservados em `C:/Users/tsmar/.codex/generated_images/01a0f265-5552-78b0-89a7-d1fe8482aeea/`:

- Acólito: `exec-c7f020c2-52a7-4952-b9a9-f526d6b5c855.png` (referência: Mestre Coral aprovado).
- Galão: `exec-cf5efcb7-4e5e-4950-b137-7781332f1c89.png`.
- Bateria: `exec-502c25f3-daf1-47b5-a9de-d4d8a544a429.png`.
- Bomba: `exec-a5427a26-0228-4aa0-ad19-18d98c1f4db9.png`.

### Prompts finais

Acólito: One full body sprite of a SMALL HOODED MARITIME ACOLYTE standing in a sanctuary beside the elderly guardian in reference. Match reference's beautiful crisp hand-painted pixel art, rich worn fabric texture, outline and nautical dieselpunk world. Short squat adult follower, 3-quarter frontal facing slightly right, deep indigo hood with faded purple lining, face mostly shadowed but visible nose and chin, no glowing dot face. Heavy layered navy robes with stitched patches, frayed hems, rope belt, small tarnished brass anchor pendant, weathered leather boots. Both hands clasped at belly in peaceful reverence. Broad cloth folds, readable at 56x80 game size. Single character only, coherent anatomy, no staff, no weapons, no pedestal, no ground or shadow, no scenery or text. Full figure with generous 8 percent transparent margin, portrait canvas. Genuine transparent alpha. This is a sympathetic dockworker in ceremonial cloak, not a monster. Keep detailed quality of guardian but simpler lower-rank costume.

Galão: Production game pickup sprite, ONE vintage RED FUEL JERRY CAN, three-quarter slightly elevated perspective for top-down maritime dieselpunk pixel-art game. Worn scarlet enamel metal, dark burgundy edges, stamped X reinforcing ribs, integrated handle with visible open hole, brass screw cap, subtle rust and chipped paint revealing gray steel, tiny embossed flame pictogram but no letters. Highly readable strong silhouette at 28x34 pixels, detailed hand-painted pixel art with crisp dark outline, warm edge highlights. Object fills centered square canvas with 10 percent empty transparent margins. Genuine transparent alpha background. No floor, no shadow, no scenery, no text, no other objects.

Bateria: Production game pickup sprite: ONE compact industrial CYAN ENERGY BATTERY for dark maritime dieselpunk pixel-art game. Three-quarter slightly elevated view. Short chunky cylindrical power cell, dark navy steel casing with battered brass end caps, clearly visible positive terminal, luminous turquoise glass central chamber with coil inside, leather carrying loop folded on side. Detailed hand-painted PIXEL ART with crisp dark outline, warm worn metal highlights, readable blue silhouette at 26x32 game pixels. Single object centered fills canvas with 10 percent transparent margin. Genuine transparent alpha background. No floor, no shadow, no scenery, no text, no sheet or other items. Not a plain rectangle, a richly crafted retro mechanical energy cell.

Bomba: One small dieselpunk mortar bomb sprite for top-down action game, single squat spherical cast iron explosive shell with heavy segmented dark gunmetal plates, rivets, brass fuse socket and short curved unlit rope fuse pointing upper right. Three quarter elevated view, rich hand-painted pixel art, crisp readable edges and strong light from upper left, readable at 26x30 pixels, weathered steel texture, slight orange copper accents. Full object including fuse visible, centered with 12 percent transparent margin. Genuine transparent alpha background. No fire, no explosion, no ground or shadow, no words, no other objects. A crafted physical ammunition object, not a plain circle.
