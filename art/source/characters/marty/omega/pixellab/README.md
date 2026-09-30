# Marty — Armadura Ômega (PixelLab)

- Personagem PixelLab aprovado: `b41db246-47d5-4914-a111-a6bd644abc2b`
- Personagem-base: Marty Padrão `812c6637-c0c0-461a-bce5-22da22348ad7`
- Estado: `Armadura Omega`
- Tela-base: 96×96, oito direções, perspectiva `low top-down`
- Célula de produção no jogo: 112×112

## Identidade visual

A forma é uma exoestrutura de cavaleiro futurista agressiva e facetada:
capacete fechado em cunha, peitoral em V, placas marfim com arestas douradas,
juntas de grafite, visor e núcleo ciano, ombreiras pontudas e capa curta roxa.
As oito rotações aprovadas estão em `reference/rotations/`. Rosto, cabelo,
armas e efeitos não fazem parte dos sprites do corpo.

## Ações

As folhas finais ficam separadas em `assets/characters/marty/omega/pixellab/`:

- `idle`: respiração;
- `run`: corrida pesada;
- `jump`: salto;
- `evade`: dash por fissura/teleporte;
- `melee`: movimento corporal do combo da espada;
- `hurt`: reação de dano;
- `defeat`: derrota.

A espada Ômega, a onda do terceiro golpe e os demais efeitos continuam em
camadas separadas no jogo.

`omega-actions-preview.png` mede 896×6272 e empilha as sete folhas completas
em escala nativa, preservando todos os quadros e as oito direções para QA.

## Proveniência PixelLab

| Ação | Grupo PixelLab |
| --- | --- |
| `idle` | `3aa75c6b-8378-42d9-af3a-9ba796bcfac4` |
| `run` | `de4daf12-95f8-47cb-b436-d050f07f9472` |
| `jump` | `b5ae32c6-55fa-4cf3-a0ec-4117ba842baf` |
| `evade` | `7f0a6eb1-4af4-4696-80f0-8c7fdde0a7e5` |
| `hurt` | `b4a66c18-db45-412a-923f-dc7c77cec2ba` |
| `hurt` oeste limpo | `6e1c87d3-73d4-4318-aeb3-7257cb8747a8` (animação `50c342d6-9e33-454f-8151-af48aacee0e6`) |
| `defeat` | `6a92b77d-1235-4e6a-a166-d7514931b27c` |

O `idle` exporta a rotação retida no índice 0 mais quatro quadros gerados; o
importador usa explicitamente `[1, 2, 3, 4]`. O `evade` é gerado com oito
quadros por limitação do PixelLab e normalizado para sete preservando os
extremos. O `hurt/west` usa somente o grupo de retry acima e ignora as linhas
defeituosas do grupo principal. O `melee` usa os jobs PixelLab e índices
aprovados por direção registrados em `melee-pixellab/manifest.json`; nenhum
quadro com matte, lâmina ou rastro gerado foi aceito.
