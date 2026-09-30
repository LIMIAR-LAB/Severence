---
title: 'Segunda transformação: Forma Azul e garra do chão'
type: feature
created: 2026-09-30
status: done
baseline_commit: b87303df9bcf757214ccff66e57c4ae40ac1109c
context: []
---

## Intent

Adicionar uma segunda transformação selecionável, inspirada no humanoide luminoso azul da referência. Seu poder faz uma garra afiada emergir do chão sob o inimigo mais próximo. A autorização é o pedido de implementação do usuário; preservar as alterações de trabalho existentes.

## Boundaries & Constraints

Manter Ômega, armas independentes, robôs, controles, saves e simulação autoritativa. Uma transformação equipada por vez. Forma Azul disponível desde o início e em progresso existente. Não sobrescrever artes anteriores. Sem operações remotas.

## I/O & Edge-Case Matrix

| Estado | Ação | Resultado |
|---|---|---|
| Azul equipada e pronta | R | Transforma com corpo azul, aura e levitação |
| Azul ativa, alvo vivo visível a até 520px | F/botão direito ou T | Garra emerge sob o inimigo elegível mais próximo, causa 64 de dano, recarga 1,2s |
| Nenhum alvo elegível | Ataque | Não causa dano nem consome recarga |
| Alvos mortos, atrás de parede ou fora de alcance | Ataque | Ignorados |
| Recarga ativa ou transformação em curso | Ataque | Sem repetição indevida |
| Ômega ativa | Ataques | Mantém espada e raio existentes |
| Forma ativa | Trocar tipo equipado | Recusa sem divergência entre ator e inventário |
| Save antigo | Carregar | Defaults seguros e nova opção disponível |

## Code Map

- `scripts/simulation.gd`: armaduras, combate, estados e carregamento.
- `scripts/world_view.gd`: desenho de personagens, transformação e efeitos.
- `data/equipamento.json`, `data/inventario.json`: catálogo e inventário.
- `scripts/equipment_screen.gd`, `scripts/terminal_ui.gd`: seleção e informações.
- `scripts/main.gd`: preferências e seleção na partida.
- `scripts/combat_hud.gd`: forma ativa, recarga e poder.
- `assets/characters/marty/azul/`: atlas gerado em quatro vistas.

## Tasks & Acceptance

- [x] Simulação: adicionar tipo azul (300s, recarga 60s, velocidade 430, escudo 3 corações) e garra com seleção determinística do mais próximo, áudio e efeito serializável.
- [x] Arte: salvar atlas transparente, renderizar vistas e aura azul animada, garra de energia com pontas afiadas emergindo do chão.
- [x] Equipamento: disponibilizar seleção, persistência, nomes e poder nos menus e HUD.
- [x] Testes: comportamento de alvo, recarga, incompatibilidades e regressão da Ômega; importação Godot e captura visual.

**Acceptance Criteria:**
- Given Azul selecionada, when iniciar ou carregar partida, then seleção permanece e R ativa visual luminoso azul.
- Given inimigos elegíveis, when atacar, then somente o mais próximo recebe o dano e a garra aparece em seus pés.
- Given recarga ou ausência de inimigos, when atacar, then comportamento segue matriz acima.
- Given Ômega equipada, when transformar e lutar, then comportamento prévio permanece.

## Design Notes

Arma de fogo continua equipada. A garra usa F/botão direito e também o controle de especial T/controle direcional direito, com recarga compartilhada. Arte gerada por ferramenta integrada image_gen, animação de levitação e efeitos no renderizador. Estado e efeitos seguem a replicação e salvamento atuais.

## Verification

Testes headless de combate, equipamento e persistência; captura real do jogo com a Forma Azul e garra; revisão independente das alterações desta tarefa.

Resultados: 29 verificações em `blue_form_test.gd`, 10 em `blue_form_ui_test.gd`, e suítes `equipment_ui_test.gd`, `mission_inventory_ui_test.gd`, `marty_actions_test.gd` passaram. Importação Godot e captura gráfica concluídas. Três revisões independentes realizadas; os três problemas concretos encontrados foram corrigidos e cobertos por regressão. A captura foi inspecionada em `test-output/blue-form/gameplay.png`. Rede validada por simulação autoritativa, sem sessão física com duas máquinas.

## Spec Change Log

- Correção visual solicitada pelo usuário: retirar corpo realista gerado; usar as próprias folhas do Marty Padrão, com paleta azul de seis tons no renderizador. Preservar escala, oito direções, todas as ações, pivôs e empunhadura; retrato e menus usam a mesma paleta. Reduzir garra/brilho e usar contornos escuros e partículas quadradas. Comparação real lado a lado em `test-output/blue-form/style-comparison.png`; 39 verificações de combate/UI passaram após a correção. Revisão independente confirmou integração e apontou modulação dos ícones desabilitados, corrigida no shader. O atlas gerado anterior fica somente como histórico, sem uso no jogo.

- Revisão: preservar tipo ao recriar atores no refúgio; redirecionar golpe azul somente fora do Titan. No online, elegibilidade usa alcance e linha de visão, sem filtrar pela câmera do anfitrião, pois cada jogador possui câmera independente. Testes cobrem retorno após morte/vitória, portal, soco do Titan e alvo do convidado.

## Suggested Review Order

- Seleção do alvo e dano autoritativo.
  [simulation.gd](../../scripts/simulation.gd)
- Persistência da transformação equipada.
  [main.gd](../../scripts/main.gd)
- Corpo luminoso e animação da garra.
  [blue_form_art.gd](../../scripts/blue_form_art.gd)
- Regras de combate, persistência e interações.
  [blue_form_test.gd](../../tests/blue_form_test.gd)
- Seleção na interface, HUD e perfil antigo.
  [blue_form_ui_test.gd](../../tests/blue_form_ui_test.gd)

