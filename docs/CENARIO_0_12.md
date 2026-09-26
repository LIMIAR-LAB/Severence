# Cenário 0.12 — Docas com paredes, névoa e arte nova

Base: conceito v1 do cenário (Higgsfield, set/2026), salvo em `art/source/`:
`docks-tileset-v1.png`, `docks-props-v1.png` (usada), `docks-props-v2.png` (variante guardada), `docks-sala01-mockup-v1.png` (guia da Sala 01).
Comparação: `art/docks-v12-antes-depois.png`. Todos os recortes: `art/docks-v12-preview.png`.

## Recorte da arte

`python tools/prepare_docks_v12.py` (só numpy + pillow) gera `assets/environment/docks12/`:

- `tiles/`: tábuas (base + nó, pregos, rachadura, clara, molhada, óleo, buraco com água), granito (base, musgo, rachado, poça, linha amarela), beira do cais, água, parede de armazém (topo, tijolo normal/danificado/buraco/janela/cano, base suja, pilar), topo lateral da parede, grelha, bueiro, 3 símbolos do culto, estaca.
- `props/`: 47 props da folha v1 sem fundo (caixas, barris, sacos de areia, cabeços, luzes, contêineres, barco, guindaste, cabine, cartaz, baús, horror, destroços) + contêineres vermelho e oliva recoloridos.
- `fx/`: poças de luz âmbar/verde e círculo suave (camada aditiva).

Escala: 1 px da folha = 1 px de mundo; cada prop tem um fator em `PROP_SCALE` (`scripts/dock_scenery.gd`) para ficar proporcional ao Marty (~72 px).

## O que mudou no jogo

| Item | Como ficou |
|---|---|
| **Paredes** | Toda sala e corredor ganham parede. Topo: fachada de armazém de tijolo (topo, tijolos, base suja). Laterais: topo da parede visto de cima. Fundo: muro baixo. As aberturas para corredores são detectadas sozinhas e emolduradas por pilares. |
| **Névoa de guerra** | Só aparece o que já foi descoberto: salas visitadas e os corredores ligados a elas. Salas novas ficam no escuro e "acendem" em 0,5s ao entrar. Inimigos, tiros, baús, props e itens em áreas escuras não são desenhados. O fundo fora das salas é escuro, não mais água infinita. |
| **Piso** | Tábuas desencontradas com ~20% de variações (nós, pregos, rachaduras, manchas, buracos). Salas de pedra usam o granito, com musgo, rachaduras e poças. Corredores são passarelas de madeira. |
| **Sala 01 Desembarque** | Refeita pelo mockup: fachada com portas, cartaz e luminárias; água com estacas e barco à esquerda; faixa de cais de granito com linha amarela e cabeços embaixo; trilhos na diagonal; caixas, barris e sacos de areia em corredores de esquiva; contêiner aberto, guindaste, postes e braseiro; símbolos verdes, poça com tentáculo, grelha e bueiro. |
| **Outras salas** | Caixas, barris, sacos de areia, cabeços e contêineres usam a arte nova. O Pátio dos Guindastes usa o guindaste novo nas 4 bases. Pilares, altar, bancos, gerador e munição ainda usam a arte antiga. |
| **Luz** | Noite (tom azulado na expedição) e camada aditiva com poças de luz de postes, luminárias, janelas, braseiros e símbolos. O Refúgio não muda. |
| **Resolução** | O jogo abre **maximizado**. A interface continua em 1280×800 lógicos e escala junto; o mundo é desenhado na resolução da tela. |

## Onde mexer

- `scripts/dock_scenery.gd`: todo o desenho do cenário (piso, água, paredes, props, luzes, névoa).
- `scripts/docks_map.gd`: `ROOM_STYLE` (bordas de cada sala: `facade`, `wall`, `pier`, `quay`; `quay_band`; `auto_lamps`), `WATER` (mar visível por sala), `RAILS`, obstáculos e decoração da Sala 01.
- Decoração nova (em `DECOR`): `grate`, `manhole`, `symbol_0..2`, `tentacle_pool` (animada), `rowboat`, `poster`, `iron_door`, `wall_lamp`, `rope`, `anchor`, e qualquer nome de prop.
- Obstáculos novos: qualquer nome de prop (ex.: `crate_net`, `barrel_explosive`, `container_open`, `crane`, `lamp_post`, `brazier`).

## Testes

`tests/scenery_test.gd`: arte carrega, só o Desembarque aparece no início, o corredor de saída aparece, o Pátio fica escuro até entrar, e a Sala 01 continua atravessável (spawn → chave → saída → cais).

## Ainda não feito

- Barril explosivo e caixas destrutíveis como mecânica (sprites de destroços já recortados).
- Refazer as demais salas no mesmo nível da Sala 01 (Armazém 7, Capela, Arena do Almirante…).
- Tiles de canto/espuma da água e cantos dos pilares ainda não usados.
