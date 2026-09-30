# Sprites do Spectre e da fusão com Marty

Ambos seguem a organização do Marty Padrão: uma folha PNG transparente por
ação, oito linhas direcionais (`sul`, `sudeste`, `leste`, `nordeste`, `norte`,
`noroeste`, `oeste`, `sudoeste`), células de 128 × 128 px e pés/apoio em `y=122`.
O Spectre é desenhado a 112 px no jogo para continuar menor que Marty; a fusão
é desenhada a 128 px, com a altura percebida do protagonista.

| Forma | PixelLab | Ações no jogo |
| --- | --- | --- |
| Spectre | `159545f6-c40e-4217-a81f-65e706aa1b4a` | `idle` 4 quadros, `run` 6, `shoot` 4 |
| Marty fundido | `778a0488-6cea-410b-b5c7-0e51f0263c28` (estado do Marty) | `idle` 4, `run` 8, `jump` 9, `evade` 6, `shoot` 3, `melee` 6, `hurt` 6, `defeat` 7 |

As fontes ficam em `art/source/characters/spectre/` e
`art/source/characters/marty/spectre_fusion/`. Os PNGs usados pelo jogo ficam
em `assets/characters/spectre/pixellab/` e
`assets/characters/marty/spectre_fusion/pixellab/`. O render usa a mesma
seleção de direção e de ação do Marty Padrão, sem espelhar os lados.

As rotações do PixelLab fixam a identidade de cada forma. A animação automática
do Spectre deformou tentáculos e acrescentou símbolos soltos; por isso sua
flutuação e o recuo do disparo são movimentos curtos montados sobre as oito
rotações aprovadas. As animações automáticas da fusão perderam os tentáculos;
as poses finais usam os quadros aprovados do Marty Padrão, escurecidos pela
simbiose, com tentáculos extraídos das rotações da fusão. A vista frontal da
fusão foi corrigida em `front-correction-source.png`, pois a rotação original
mostrava as costas. Projéteis e clarões continuam em camadas do jogo.

## Cabeça simbiótica

A pedido de revisão, a fusão agora cobre também a cabeça de Marty. Ela tem
crânio violeta quase preto, olhos brancos angulares e mandíbula com dentes
claros. Cabelo, rosto e goggles humanos não aparecem durante a fusão. A fonte
`symbiote-heads-v1.png` contém as oito vistas da cabeça; o importador encontra
a posição da cabeça em cada quadro, remove a anterior e aplica a vista
correspondente. Rolamento e queda também inclinam a cabeça com o corpo.

Para regenerar as folhas sem alterar as fontes:

```powershell
python tools/import_spectre_pixellab.py
```

O importador usa as exportações PixelLab já salvas no projeto e as folhas do
Marty Padrão. Se as animações do Marty mudarem, regenerar e revisar a fusão no
zoom de jogo antes de substituir os PNGs em produção.
