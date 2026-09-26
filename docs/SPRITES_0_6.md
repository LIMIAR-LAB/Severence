# Sprites 0.6 — roupas do Marty, inimigos das Docas e o Almirante

Fontes: folhas do conceito v1 (Higgsfield, gpt_image_2_5), salvas em `art/source/`:
`marty-outfits-v1.png`, `enemies-docas-v1.png` (a variante `enemies-docas-v2.png` ficou guardada), `boss-almirante-v1.png`.
Recorte: `python tools/prepare_sprites_v6.py` (fundo cinza e sombras removidos, pose normalizada com pivô nos pés).
Prévia de tudo: `art/sprites-v06-preview.png`.

## Marty — 4 visuais, armadura continua binária

| Estado | Visual | Efeito em jogo |
|---|---|---|
| SEM armadura | **Padrão** (jaqueta de aviador) | equilibrado |
| SEM armadura | **Disfarce de Londres** | inimigos só percebem Marty a ~55% da distância normal |
| SEM armadura | **Mecânico do Hangar** | golpe corpo a corpo 42 (em vez de 26) |
| COM armadura | **Armadura Ômega** (lendária, silhueta maior) | −35% de dano e golpe reflete projéteis (regra antiga da armadura) |

- Trocar: vitrine do Refúgio (E percorre Padrão → Londres → Mecânico → Ômega), tela de equipamento (clicar de novo em SEM ARMADURA troca a roupa) ou **R** para ligar/desligar a Ômega.
- Echo (parceiro IA) usa o Mecânico.
- 8 direções usando as 5 vistas da folha (frente, frente-3/4, lado, costas-3/4, costas; lado esquerdo espelhado). Andando de lado alterna com a pose de corrida; nas outras direções há balanço e passo. Salto e dash usam a pose de corrida.
- `assets/marty/outfits.png`: 4 linhas × 6 colunas, células 96×96, pés em (48, 92).

## Inimigos das Docas de 1941

| Tipo (código) | Inimigo | Projétil | Comportamento |
|---|---|---|---|
| `cult` | Cultista Atirador | orbe magenta | mantém ~240px, 1 tiro a cada 1,5s |
| `fish` | Arpoador das Profundezas | arpão com corrente | lento e forte (18); acerto **prende** (40% da velocidade por 0,9s) |
| `crawler` | Rastejante Tentacular | ácido verde (3, alcance curto) | enxame rápido; ao morrer vira **duas bolhas menores** (`crawler_small`) |
| `brute` | Soldado Possuído | leque de 5 balas violeta | rajadas que exigem esquiva; 65 de vida |

Poses: frente, costas, andando, atacando (mostra o clarão por 0,3s), morte (fica no chão e some em 1,2s).
`assets/enemies/docas.png`: 4 linhas × 5 colunas, células 144×96, pés em (56, 92). Projéteis em `assets/enemies/proj_*.png`.

## Chefe — O Almirante das Profundezas (600 de vida, ver docs/DOCAS_0_11.md)

| Estágio | Vida | Padrão | Pose |
|---|---|---|---|
| 1 | > 66% | anel radial de 16 orbes, alternando com leque de 7 mirado | parado / anel |
| 2 | 33–66% | **larga uma arma**; gira disparando em espiral; carrega o canhão (0,9s de brilho violeta) e dispara bala de canhão | espiral / carga |
| 3 — Fúria | < 33% | perde o chapéu; bolhas de tinta, arpão, **lança-chamas** de perto e anel de 20 | fúria |

Dano pisca a pose branca; na derrota ele afunda (2,6s) e libera a extração. Poses em `assets/boss/almirante_*.png`; projéteis (orbe, chama, canhão, tinta, arpão) em `assets/boss/proj_*.png`.

## Testes e capturas

- `tests/enemies_test.gd` (18 verificações): projétil de cada inimigo, leque do soldado, divisão do Rastejante, arpão que prende, percepção do Disfarce, golpe do Mecânico, os três estágios do Almirante e a derrota.
- Capturas: `-- --capture-arena --outfit=londres` → `test-output/arena-v06.png`; `-- --capture-boss --boss-hp=0.2 --armor` → `test-output/boss-v06.png`.

## Pendências

- **TITAN**: a folha descrita (estacionado, pilotado, ações) não veio nas imagens; o Titan mantém a arte anterior.
- As folhas têm uma pose por ação: caminhada e corrida são simuladas (alternância + balanço). Para animação completa, gerar ciclos de 4–6 quadros por direção em grade fixa.
- O vídeo do Refúgio animado (`Seamless-looping-animated-pixel-art-game.mp4`) ainda não foi usado; ele tem Marty e Titan pintados, que precisariam ser removidos antes de virar fundo.

## 0.7 — pernas, tiro e armas

- **Caminhada com pernas**: `tools/animate_sprites.py` separa as pernas de cada pose e gera 4 quadros de passada por direção (passo alternado de frente/costas, tesoura de lado), mais tiro (recuo) e salto. Inimigos ganharam o mesmo ciclo. Atlas: `assets/marty/marty_anim.png` e `assets/enemies/docas_anim.png`.
- **Arma real na mão**: as pistolas pintadas nas folhas foram apagadas (`tools/erase_painted_guns.py`) e o jogo desenha a arma equipada — pistola blaster, escopeta de cano duplo ou submetralhadora de tambor (`tools/make_weapons.py`, `assets/weapons/`). Ela gira 360° com a mira, fica atrás do corpo quando mira para cima, recua e solta clarão a cada disparo. A linha de mira foi removida.
- Parado, o personagem respira (1 px). A chave inglesa do Mecânico continua no ombro.
- Prévia animada: `art/walk-v07-preview.gif`.
- Ordem para regenerar: `prepare_sprites_v6.py` → `erase_painted_guns.py` → `animate_sprites.py`.
- Limite: é animação por recorte (as pernas se movem, braços não). Para braços e corrida completos, é preciso gerar folhas com ciclos de 4–6 quadros por direção.

## 0.8 — Transformação Ômega, baú e tiro

- **Transformação Ômega** (ao ligar a armadura: R, vitrine, equipamento ou baú): 1,4s em que Marty flutua, fica invulnerável, pisca entre a roupa antiga e a Ômega, com aura de energia dourada/ciano, pilar de luz, pedrinhas subindo e raios. No meio, clarão na tela e **onda de choque** (fere e empurra inimigos em 190px, apaga projéteis inimigos, treme a câmera). Depois fica uma aura leve permanente.
- **Ômega mais forte**: −50% de dano, 340 px/s, golpe 40, e a arma é trocada pelo **Canhão de Plasma Ômega** (exclusivo): disparo duplo, 24 de dano, perfura 2 inimigos, clarão e anel ciano.
- **Tiro**: arma dá tranco para trás e para cima, clarão em 3 estágios (estrela → brilho → fumaça), cápsulas ejetadas (escopeta/automática), faíscas de impacto, projéteis desenhados por arma e tremor na escopeta e no plasma.
- **Baú**: treme, a tampa abre, interior brilha, raios de luz e moedas saltam, texto "+10 ARMA NOVA".
- **Tela de equipamento**: coluna ARMADURAS agora tem só Padrão, Londres, Mecânico e Ômega. O Titan fica apenas na faixa ROBÔ.
- Testes: `tests/omega_test.gd` (13 verificações).
