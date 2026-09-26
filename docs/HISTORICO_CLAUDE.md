# Histórico do trabalho do Claude (set/2026, até a 0.14)

Este documento reúne tudo o que foi feito nas sessões com o Claude: o que existe, onde está no código, como testar e o que falta.
Os detalhes de cada versão ficam nos documentos por tema, indicados em cada item.

## Linha do tempo

| Versão | O que entrou | Onde / documento |
|---|---|---|
| 0.5 | Refúgio • Fora do Tempo ilustrado, com colisão invisível sobre a arte | `REFUGIO_0_5.md` |
| 0.6 | Sprites do Marty (4 visuais), inimigos das Docas e o Almirante | `SPRITES_0_6.md` |
| 0.7 | Animação de caminhada com pernas, tiro e abertura de baú | `assets/marty/marty_anim.png`, `art/walk-v07-preview.gif` |
| 0.8 | Transformação da Armadura Ômega (aura, onda de choque) e espada | `world_view.gd` `draw_transform_fx` |
| 0.9 | Uniformes (Padrão, Mecânico, Espião) separados da Armadura; o Titan não é armadura | `EQUIPAMENTO_0_9.md` |
| 0.10 | Titan com viseira, passada pesada e turbo (Shift) | `assets/mech/titan_v2.png` |
| 0.11 | Mapa fixo e grande, minimapa/mapa (Tab/M), cápsula de extração, inimigos mais fortes, armadura 5s/60s | `DOCAS_0_11.md` |
| 0.12 | Opções de vídeo e resoluções (Steam), armas v2, Cápsula Temporal (invocar/recolher robôs), regras de corações/portões/tentáculo, Titan com canhão e bomba | `VIDEO_0_12.md`, `REGRAS_0_12.md`, `TITAN_0_12.md` |
| 0.13 | Docas recriadas: 13 salas + secreta, paredes, névoa, portões, props destrutíveis, barris em cadeia, reforços, queda na água | `CENARIO_0_13.md` |
| 0.13 | Tela inicial animada | `scripts/menu_background.gd`, `shaders/menu_bg.gdshader` |
| 0.14 | Retratos estilo Toriyama, tela de Equipamento v2, Ômega lendária, navegação por controle | este documento |
| 0.14 | Correção: vida inicial fixa em 3 corações; STATUS da tela calculado das constantes reais | este documento |

A 0.14 também tem o Warden e o combustível do Titan, feitos pelo Codex. Veja o commit `75adfc3`.

## Recuperação da 0.12 (lição aprendida)

Numa sessão anterior, o Claude gravou arquivos inteiros por cima do trabalho do Codex, e o mapa voltou à versão antiga.
Não havia cópia no OneDrive, então a 0.13 foi reconstruída a partir dos assets (`assets/environment/docks12/`) e dos documentos da 0.12.
Desde então:

- Cada IA trabalha na **própria branch** (`dev-claude`, `dev-codex`...). A `main` é integrada manualmente.
- Nada de gravar arquivo inteiro sem conferir a data de modificação; prefira edições pontuais.

## 0.13 — Docas grandes e dinâmicas

Detalhes em `CENARIO_0_13.md`. Resumo:

- **Layout:** `tools/build_docks_map.py` gera `scripts/docks_map.gd`. O script valida que:
  - cada corredor encosta em 2 salas;
  - nenhum prop bloqueia uma porta;
  - todas as salas e pontos são alcançáveis a pé;
  - o Titan chega ao chefe.

  **Edite o script, não o `.gd`.** Se alguém editar o `docks_map.gd` direto, passe a mudança para o script antes de rodá-lo de novo, senão ela se perde.
- **Mundo:** `world_view.gd` usa o `dock_scenery.gd` para desenhar piso, água, paredes por estilo (`ROOM_STYLE`), portões, névoa, luz noturna aditiva e decoração.
- **Dinâmica** (`simulation.gd`):
  - `DESTRUCTIBLE`, `damage_obstacle` e `BARREL_BLAST`, com fusível em cadeia;
  - `WAVES` e `spawn_wave` para os reforços;
  - grade espacial de obstáculos (`ob_grid`) para desempenho;
  - queda na água devolve ao ponto do salto (`jump_from`).

## Tela inicial animada (0.13)

O fundo `assets/ui/menu.png` ganha vida por shader, sem recortes:
- fogo que tremula e ar quente;
- brilho ciano pulsando;
- engrenagens girando e destroços flutuando;
- mar ondulando e raios crepitando.

Por cima, `menu_background.gd` desenha relâmpagos com clarão, faróis varrendo o céu, brasas, garoa e névoa.
Prévia: `tools/preview_menu_bg.gd` → `art/menu-animado-preview.gif`.

## Retratos (0.14)

- Folha original: `art/source/portraits-toriyama-v1.png`, gerada com `art/source/portraits-toriyama-prompt.txt` (homenagem ao traço de Akira Toriyama, sem personagens dele).
- `tools/make_portraits.py`:
  - recorta as 6 figuras e remove o fundo branco, inclusive os buracos entre pernas e tentáculos;
  - monta um cenário para cada uma → `assets/ui/portraits/*.png` (930×672).

| Retrato | Cenário |
|---|---|
| Padrão | cais com holofotes |
| Mecânico | oficina |
| Espião | rua com garoa |
| **Ômega** | **céu em duotom dourado, por ser lendária** |
| Titan | cidade em chamas |
| Spectre | céu violeta |

## Tela de Equipamento v2 (0.14)

- **Conceito:** `art/concept/equipamento-v2-conceito-*.png`, feito com `tools/equipment_concept.py`.
- **Fundo estático:** `assets/ui/equipment_v2.png`, gerado por `python tools/equipment_concept.py bg`. Tem só molduras, títulos e o rodapé de teclas e controle.
- **Conteúdo real** (`terminal_ui.gd`, `build_equipment` / `refresh_gear`):
  - cartões de uniforme com **o sprite do jogo** (`outfits.png`);
  - vaga da Armadura Ômega **dourada** ("★ LENDÁRIA", liberada para os testes);
  - palco com o retrato em cena e o nome;
  - painel STATUS;
  - descrições com sprites;
  - robôs com as tags PILOTAR/FUNDIR;
  - abas MARTY/ECHO para o coop local;
  - botões IR AO REFÚGIO, INICIAR ARENA e VOLTAR.
- **STATUS coerente:**
  - os números vêm de `Expedition.loadout_stats(kind, outfit)`, que lê as mesmas constantes usadas no combate (`UNIFORMS`, `WEAPONS`, `ARMORS`, `SWORD`, `MECH_SHELL`, `MECH_BOMB`, `SPECTRE_SHOT`, `FUSION`...);
  - `fire_actor` passou a ler a tabela `WEAPONS`, então tela e jogo nunca divergem;
  - o painel muda conforme a seleção: uniforme, Ômega, Titan ou Spectre.

## Controle no menu (0.14)

- Toda tela do menu foca o primeiro botão (`focus_first`). No Equipamento, o foco vai para o uniforme atual.
- O direcional navega e A confirma (ações `ui_*` do Godot).
- B volta ao menu principal; LB/RB trocam o uniforme no Equipamento (`_unhandled_input`).

## Correção: corações (0.14)

- `max_hp()` agora é sempre `BASE_HEARTS * HEART`: **3 corações para todos**.
- As melhorias salvas (`upgrade`) continuam no save, mas não somam vida por enquanto.
- A bancada do Refúgio avisa "em breve" e não gasta fragmentos.
- **Ainda em aberto:** como aumentar a vida (itens, bancada, chefe...). Quando decidirmos, basta mexer em `max_hp()` e na bancada (`interact`, caso `"bench"`).

## Testes

Rode cada um com `--headless --path . --script tests/<nome>.gd`. Todos devem terminar com 0 falhas.

| Teste | Cobre |
|---|---|
| `simulation_test` | Regras gerais, loja, desafio, secreta, rampas, navegação, rede |
| `combat_regression_test` | Dash, cadência, colisão |
| `enemies_test` | Inimigos, Almirante, roupas |
| `omega_test` | Transformação, espada, escudo |
| `solo_robot_test` | Solo, Titan e Spectre, fusão |
| `refuge_test` | Refúgio |
| `input_scene_test` | Cena completa com teclado e mouse |
| `scenery_test` | Névoa, arte 0.12, Sala 01, portões, tentáculo |
| `dynamic_map_test` | Mapa grande, caixa destrutível, barril em cadeia, reforços, fosso |
| `titan_weapons_test` / `titan_fuel_test` | Canhão, bomba, gasolina |
| `warden_test` | Mini-chefe Warden |
| `summon_fx_test` | Cápsula Temporal |
| `equipment_ui_test` | Tela de Equipamento v2, foco, LB/RB, Ômega lendária (guarda e devolve `user://settings.json`) |
| `hearts_stats_test` | 3 corações fixos, bancada congelada, STATUS = números reais do tiro, do Titan, da Ômega e do Spectre |

Os testes de interface mexem nas preferências salvas. Se um teste de robô falhar por causa de uma escolha salva, apague o `user://settings.json`.

## Ferramentas (tools/)

| Script | Faz |
|---|---|
| `build_docks_map.py` | Gera e valida o `docks_map.gd` |
| `make_portraits.py` | Retratos da tela de Equipamento |
| `equipment_concept.py [padrao\|…\|bg]` | Conceito da tela / fundo `equipment_v2.png` |
| `preview_menu_bg.gd` | Quadros da tela inicial animada |
| `preview_summon_fx.gd` | Prévia da Cápsula Temporal |
| `make_weapons_v2.py` | Sprites das armas v2 |

## Pendências conhecidas

- Tela de **seleção de personagens** antes do menu principal.
- Tirar "Equipar e entrar" e "Robôs invocados nos dois modos" da tela de modo (estão pintados em `assets/ui/adventure.png`).
- Definir como a vida aumenta além dos 3 corações.
- Novo Spectre em sprite (prompt pronto em `portraits-toriyama-prompt.txt`, item EXTRA).
- Push da branch `dev-claude`: o ambiente do Claude não tem credencial do GitHub, então o `git push origin dev-claude` precisa ser feito no Windows.
