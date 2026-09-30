---
title: 'Tornar o Inventário da Missão encontrável'
type: 'bugfix'
created: '2026-09-29'
status: 'done'
baseline_commit: '32eb60c665d55315989a6ac1c81805024bdf7181'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** O Inventário da Missão existe, porém está escondido como última ação da pausa e o atalho de equipamento abre apenas a pausa. Na prática, o jogador não encontra a tela planejada.

**Approach:** Promover o inventário a uma ação principal e visualmente destacada da pausa, adicionar acesso direto pelo atalho `B` durante a missão e documentar o caminho sem alterar o menu de preparação.

## Boundaries & Constraints

**Always:** manter a tela pré-missão atual; abrir o inventário sem retomar a simulação; `B` deve alternar de forma previsível entre jogo, inventário e pausa; preservar mouse, teclado, controle, saves e online.

**Ask First:** trocar o atalho por uma tecla já usada ou redesenhar novamente todo o menu de pausa.

**Never:** esconder o inventário atrás de submenus, remover Arquivo/Salvar/Voltar ou misturar recursos da missão no inventário persistente.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Partida ativa | Pressionar `B` com UI fechada | Abrir diretamente Inventário da Missão | Manter partida pausada offline |
| Inventário aberto | Pressionar `B` ou Voltar | Retornar à pausa | Não retomar o jogo |
| Pausa aberta | Selecionar ação destacada | Abrir Inventário da Missão | Foco permanece navegável |
| Pré-missão | Abrir Equipamento | Manter preparação atual | Nenhuma mudança de rota |

</frozen-after-approval>

## Code Map

- `scripts/terminal_ui.gd` -- ordem, destaque e navegação da ação na pausa.
- `scripts/main.gd` -- atalho direto durante uma partida.
- `tests/mission_inventory_ui_test.gd` -- acesso por pausa e atalho, estado pausado e retorno.
- `tests/controller_input_test.gd` -- foco inicial e sequência de navegação da pausa.
- `README.md` -- instrução encontrável para o jogador.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/terminal_ui.gd` -- promover e destacar a ação do inventário na pausa.
- [x] `scripts/main.gd` -- abrir diretamente o inventário com `B` e preservar retorno à pausa.
- [x] `tests/mission_inventory_ui_test.gd` -- cobrir ambos os caminhos e impedir retomada acidental.
- [x] `tests/controller_input_test.gd` -- validar foco inicial e sequência de navegação.
- [x] `README.md` -- registrar pausa e atalho direto.

**Acceptance Criteria:**
- Given an active mission with no menu open, when `B` is pressed, then Mission Inventory opens directly and the offline simulation remains paused.
- Given Pause is open, when the highlighted inventory action is activated, then the planned mission menu opens.
- Given Mission Inventory is open, when `B`, Escape or Back is used, then Pause opens without resuming gameplay.
- Given the pre-mission flow, when Equipment opens, then its existing preparation behavior is unchanged.

## Spec Change Log

## Design Notes

`B` already has a dedicated `gear` edge in `main.gd` and is not a P1 gameplay action. Reusing it avoids a new binding conflict. The controller continues using Start → highlighted pause action because controller B remains Dodge during gameplay.

## Verification

**Commands:**
- Godot headless mission inventory, title, controller and save-flow tests -- expected: zero failures.
- 1920×1080 pause and mission captures -- expected: action visible without scrolling and destination visually identifiable.

**Results:**
- `mission_inventory_ui_test.gd`: 32 verificações aprovadas após integrar a cobertura da bazuca presente na `main`.
- `controller_input_test.gd`, `save_game_flow_test.gd`, `inventory_ui_test.gd` e `title_screen_test.gd`: aprovados.
- Suíte completa: 42 testes, zero falhas.
- Capturas verificadas em `test-output/pause-inventario-destacado.png.png` e `test-output/menu-inventario-missao-final.png`.

## Suggested Review Order

**Acesso e transições**

- Centraliza a precedência dos atalhos e mantém o inventário sincronizado com a missão.
  [`main.gd:397`](../../scripts/main.gd#L397)

**Descoberta e navegação**

- Coloca o inventário no topo, destacado, focado e integrado ao ciclo da pausa.
  [`terminal_ui.gd:294`](../../scripts/terminal_ui.gd#L294)

- Explica ao jogador os dois caminhos e o retorno seguro à pausa.
  [`README.md:13`](../../README.md#L13)

**Proteção contra regressões**

- Exercita acesso direto, pausa, recursos vivos, retornos e atalhos simultâneos.
  [`mission_inventory_ui_test.gd:13`](../../tests/mission_inventory_ui_test.gd#L13)

- Confirma foco inicial e sequência de navegação por controle.
  [`controller_input_test.gd:48`](../../tests/controller_input_test.gd#L48)
