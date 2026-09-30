---
title: 'Corrigir armas, rolamento e interação dos menus'
type: 'bugfix'
created: '2026-09-30'
status: 'done'
baseline_commit: '779af10f763738a0ee29fa6c83b8702a7934cb56'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** O jogador relata disparos fora da ponta da arma, conteúdo da pausa ultrapassando a moldura, armas que desaparecem ao acabar a munição, sprites pouco legíveis na esquiva e inventário sem ações úteis. As capturas são evidências visuais desses problemas, não instruções adicionais.

**Approach:** Corrigir a geometria compartilhada entre arma e projétil, preservar armas vazias na seleção, ajustar a composição interna da pausa, melhorar a leitura da animação de esquiva e conectar as ações do inventário às regras já implementadas. Entregar os cinco ajustes solicitados como um conjunto de correções, com verificação específica de cada comportamento.

## Boundaries & Constraints

**Always:** preservar partidas salvas, propriedade de armas, separação entre inventário persistente e itens da tentativa, validação do anfitrião online, controles existentes e arte atual. Manter alcance, recarga e janela de invulnerabilidade da esquiva. Armas sem munição continuam possuídas e selecionáveis, mas não disparam. Ações disponíveis devem modificar o estado real e apresentar feedback.

**Ask First:** introduzir novos efeitos de consumíveis, economia, descarte de itens ou trocar o sistema de armas vinculado aos uniformes; essas decisões ultrapassam a correção das ações existentes.

**Never:** gerar munição ao selecionar uma arma; permitir que o convidado altere diretamente o estado autoritativo; fingir que recursos automáticos ou itens de protótipo possuem ações implementadas; substituir sprites ou aumentar a invulnerabilidade apenas para alongar a animação.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Disparo | Arma de fogo, mira em qualquer direção | Projétil e clarão partem da ponta visível | Origem próxima a obstáculo não atravessa paredes |
| Última bala | Bazuca equipada com um foguete | Disparo consome a bala e mantém a seleção | Próxima tentativa informa falta de munição, sem projétil |
| Troca e recarga | Bazuca possuída, vazia ou carregada | Q/RB alterna com a arma básica; munição coletada abastece a mesma arma | Arma não possuída não pode ser selecionada |
| Pausa | Cinco ações, rodapé e mensagem de salvamento | Todo conteúdo fica na área interna da moldura | Mensagens longas quebram linha sem cobrir ações |
| Esquiva | Oito direções, com ou sem dano recente | Pose e sequência do rolamento ficam distinguíveis | Fim da animação não mantém invulnerabilidade |
| Inventário | Selecionar arma, equipar, comparar e trocar abas | Ações produzem efeito ou informação concreta | Bloqueios reais explicam o motivo |

</frozen-after-approval>

## Code Map

- `scripts/simulation.gd` — seleção de arma, consumo de munição, origem dos projéteis e temporização da esquiva.
- `scripts/world_view.gd` — ancoragem da arma, recuo, altura visual das balas e quadros de esquiva.
- `scripts/terminal_ui.gd` — composição da pausa, rotas do inventário e aplicação do equipamento.
- `scripts/equipment_screen.gd` — abas, seleção, ações, comparação e atualização do inventário da missão.
- `scripts/main.gd` — integração de entrada e autoridade de comandos online, se necessária para seleção pelo inventário.
- `tests/run_weapons_test.gd`, `tests/marty_actions_test.gd`, `tests/mission_inventory_ui_test.gd`, `tests/inventory_ui_test.gd` — cobertura existente a ajustar e ampliar.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/simulation.gd`, `scripts/world_view.gd` — centralizar a transformação da ponta da arma e reutilizá-la na geração e apresentação do disparo, incluindo espelhamento e elevação.
- [x] `scripts/simulation.gd`, `scripts/world_view.gd` — manter seleção e apresentação coerentes da arma vazia, impedir disparos sem munição e permitir alternância explícita para a arma básica.
- [x] `scripts/terminal_ui.gd` — redistribuir título, cinco botões e feedback dentro da área útil da moldura; manter navegação completa.
- [x] `scripts/world_view.gd`, `scripts/simulation.gd` — melhorar visibilidade e cadência visual da esquiva sem alterar sua distância ou proteção; reduzir interferência de transparência e trilhas.
- [x] `scripts/equipment_screen.gd`, `scripts/terminal_ui.gd`, `scripts/main.gd` — habilitar seleção da arma temporária pelo inventário, apresentar comparação real e verificar cliques/foco nas abas e ações; preservar autoridade de rede.
- [x] `tests/run_weapons_test.gd`, `tests/marty_actions_test.gd`, `tests/mission_inventory_ui_test.gd`, `tests/inventory_ui_test.gd` — cobrir regressões e atualizar expectativas que codificam o comportamento antigo.
- [x] `docs/INVENTARIO.md`, `README.md` — atualizar apenas os comportamentos e controles afetados.

**Acceptance Criteria:**
- Given the game is running, when the player uses mouse, keyboard or controller to navigate inventory actions, then selection, equipment changes and feedback remain consistent with the simulation.
- Given a saved expedition with an empty owned weapon, when restored, then ownership, ammunition and selected weapon are preserved without granting resources.
- Given multiple viewport sizes, when Pause opens, then buttons and feedback remain inside the usable frame and legible.
- Given existing combat and multiplayer flows, when the targeted regression suite runs, then unrelated progression, damage, movement and authority rules continue passing.

## Spec Change Log

## Design Notes

Confirmed causes: bullets originate at the actor plus a fixed directional offset, while the renderer computes the weapon tip from a hand anchor, grip, dimensions and recoil. Bullet drawing also applies its own vertical offset. These independent calculations need one coherent contract.

The bazooka remains in `run_weapons` at zero ammunition, but `weapon_of` rejects it, `toggle_run_weapon` skips it and the last shot clears `run_weapon`. Existing tests explicitly expect the automatic fallback, so they must change with the requested behavior.

Pause places its final action and footer below the decorative frame's interior. Inventory currently disables all transient actions, including the bazooka, and comparison only displays a descriptive sentence instead of differences. Some catalog entries are explicitly unimplemented prototypes; correcting menus does not imply inventing those mechanics.

The current dash lasts 0.20 seconds and moves at 900 pixels per second. The newer six/seven-frame animation is compressed into that interval; damage blinking can also reduce alpha to 0.45. Prefer separate visual timing over changing gameplay duration.

## Verification

- Run targeted Godot headless tests for weapons, combat, Marty actions, inventory, equipment, controller navigation and save restoration; expect zero failures.
- Capture pause and inventory at representative widescreen and compact viewport sizes; inspect frame bounds, text and focus.
- Inspect successive gameplay frames for eight-direction muzzle alignment, the last rocket, empty-weapon selection and roll readability.
- Exercise actual input events for menu interaction, rather than relying only on direct method calls or synthetic button signals.
- Review final changes independently and resolve confirmed regressions before marking this specification done.

## Implementation Evidence

- Implementação e três revisões independentes concluídas. Quatro achados confirmados foram corrigidos e verificados; nenhum achado confirmado permanece aberto.
- 13 suítes direcionadas passaram após as alterações finais: run_weapons, marty_actions, inventory_ui, mission_inventory_ui, inventory_persistence, inventory_model, equipment_ui, equipment_unlock, combat_regression, combat_framework, controller_input, simulation e save_game_flow. Logs: `test-output/*-targeted-bugfix.log`.
- Testes reais de entrada cobrem cliques nas cinco abas, filtro, seleção, comparação e equipamento; Enter alterna bazuca vazia/arma básica. Testes de geometria incluem oito direções, três uniformes, bazuca em salto e escala visual 1,12; parede fina bloqueia origem além do obstáculo.
- `tests/weapon_menu_bugfix_preview.gd` captura pausa, inventário e comparação em 1920×1080 e 960×720, além de oito direções da arma e três momentos do rolamento. Imagens `test-output/bugfix-{pause,inventory,comparison}-*.png`, `bugfix-muzzles-empty.png`, `bugfix-roll-sequence.png` inspecionadas. Marcadores magenta da folha de armas representam a origem do projétil.
- Uma tentativa anterior da suíte completa foi interrompida por erros de compilação durante edições concorrentes em dock_scenery/terminal_ui; não foi considerada aprovação da suíte completa. A validação direcionada posterior terminou sem falhas. Não houve teste físico de controle nem teste de rede em duas máquinas.

### Correções após revisão independente

- Varredura entre ator e cano agora resolve inimigos próximos com as mesmas regras de impacto, explosão, ricochete e perfuração do voo. A verificação de parede ocorre apenas após detectar candidato próximo; teste cobre bazuca contra inimigo em (545,500) com ator em (500,500), além de parede fina entre ambos.
- Estado ativo/morto/Titan/armadura participa da atualização do inventário; fim da armadura reativa a ação sem reabrir o menu.
- Arma carregada em idle/run ancora na direção do corpo; a rotação continua seguindo a mira. O primeiro tiro usa geometria de disparo explicitamente, independente da direção anterior do movimento. Preview inclui movimento oposto à mira.
- Comparação identifica corretamente ARMA BÁSICA → BAZUCA, mesmo quando a bazuca já está equipada.
- Pós-revisão: run_weapons, marty_actions, inventory_ui, mission_inventory_ui, combat_regression, combat_framework, guard_opening e titan_weapons passaram. Capturas regeneradas e inspecionadas também pelo agente principal; revisão concluída. Alterações simultâneas em cenários, conceitos de menus e arte Ômega foram preservadas e excluídas do escopo desta correção.

## Suggested Review Order

**Geometria e combate**

- Centraliza mão, cano e escala para alinhar arma e projétil.
  [simulation.gd:1013](../../scripts/simulation.gd#L1013)

- Preserva arma vazia e resolve alvos próximos sem atravessar paredes.
  [simulation.gd:1028](../../scripts/simulation.gd#L1028)

**Interface e estado**

- Conecta seleção e comparação ao estado real da missão.
  [equipment_screen.gd:297](../../scripts/equipment_screen.gd#L297)

- Encaminha seleção online para validação pelo anfitrião.
  [main.gd:290](../../scripts/main.gd#L290)

- Mantém ações e feedback dentro da moldura.
  [terminal_ui.gd:389](../../scripts/terminal_ui.gd#L389)

**Apresentação e verificação**

- Separa leitura visual do rolamento da duração mecânica.
  [world_view.gd:958](../../scripts/world_view.gd#L958)

- Cobre munição zero, recarga, persistência e inimigos próximos.
  [run_weapons_test.gd:10](../../tests/run_weapons_test.gd#L10)

- Reproduz capturas dos menus e poses em duas resoluções.
  [weapon_menu_bugfix_preview.gd:29](../../tests/weapon_menu_bugfix_preview.gd#L29)
