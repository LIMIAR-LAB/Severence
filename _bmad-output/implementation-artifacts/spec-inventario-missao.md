---
title: 'Inventário da missão separado da preparação'
type: 'feature'
created: '2026-09-29'
status: 'in-review'
baseline_commit: '28437a20363da65af0b014dbe5981757501ebed9'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** O menu criado atende à preparação pré-missão, mas o jogo ainda não possui uma tela própria para consultar o que foi levado e adquirido durante a tentativa. Os ícones de itens protótipo também continuam provisórios.

**Approach:** Preservar o menu atual como loadout persistente e adicionar, dentro da pausa, um Inventário da Missão inspirado diretamente no anexo, reutilizando o mesmo shell visual com dados e ações específicos da tentativa.

## Boundaries & Constraints

**Always:** separar claramente preparação persistente de recursos temporários; manter pausa, saves, multiplayer e loadout host-authoritative; usar valores reais da simulação; foco visível por mouse, teclado e controle; identificar placeholders como provisórios.

**Ask First:** criar efeitos novos para consumíveis, alterar economia/combate ou produzir um pacote definitivo de ícones.

**Never:** copiar recursos temporários para o inventário persistente, permitir descarte destrutivo falso, aplicar loadout do convidado sem validação do host ou substituir o menu pré-missão já entregue.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Pausa em missão | Partida solo/local/online ativa | Botão abre Inventário da Missão e volta à pausa | Nunca retoma a partida acidentalmente |
| Recursos da tentativa | Chaves, moedas, fragmentos, combustível e energia | Quantidades refletem a simulação ao vivo | Zero é omitido ou explicado sem erro |
| Loadout levado | Uniforme, robô e Ômega disponíveis | Itens aparecem como equipados e podem ser comparados | Troca inválida é rejeitada e revertida |
| Convidado online | Pedido de troca | Host valida e aplica ao ator 1 | Inventário persistente do host não é sobrescrito |

</frozen-after-approval>

## Code Map

- `data/inventario.json` -- descrições dos recursos temporários, ainda sem duplicar quantidades.
- `scripts/equipment_screen.gd` -- dois modos visuais/dados no mesmo shell, com retorno contextual.
- `scripts/terminal_ui.gd` -- rota da pausa para o inventário em missão e RPC de loadout existente.
- `scripts/main.gd` -- atalhos/retorno e captura da nova tela.
- `tests/mission_inventory_ui_test.gd` -- integração da pausa, recursos, foco e retorno.
- `tests/inventory_preview.gd` -- captura representativa 16:9 do modo em missão.
- `docs/INVENTARIO.md` -- separação entre preparação e tentativa.

## Tasks & Acceptance

**Execution:**
- [x] `data/inventario.json`, `scripts/equipment_screen.gd` -- representar recursos reais da tentativa e adaptar o shell sem contaminar o estado persistente.
- [x] `scripts/terminal_ui.gd`, `scripts/main.gd` -- integrar entrada/saída pela pausa e restaurar a rota host-authoritative de troca em missão.
- [x] `tests/mission_inventory_ui_test.gd`, `tests/inventory_preview.gd` -- cobrir navegação, dados ao vivo, autoridade e captura 16:9.
- [x] `docs/INVENTARIO.md` -- documentar os dois contextos e ícones provisórios.

**Acceptance Criteria:**
- Given an active mission, when Inventory is chosen from Pause, then the mission layout opens without resuming simulation and Back returns to Pause.
- Given run resources and a loadout, when the mission inventory opens, then real quantities and equipped items are shown without entering persistent stacks.
- Given mouse, keyboard or controller, when navigating tabs, filters, cards and actions, then focus is visible and deterministic.
- Given a guest loadout request, when an item is selected, then only the host validates/applies actor state and P1 persistence is unchanged.
- Given the complete automated suite and a 1920×1080 capture, when verification completes, then no prior flow regresses and the mission screen resembles the attached concept.

## Spec Change Log

- 2026-09-29: implementado o inventário contextual da missão, integrado à pausa e validado em 1920×1080.

## Design Notes

The shared shell prevents two interfaces from drifting visually, while `mission_mode` changes the source of quantities and the return route. Persistent catalog entries mean “owned before launch”; transient entries are read-only projections of `Expedition` state and never enter `InventoryState.stacks`.

## Verification

**Commands:**
- Godot headless test suite -- expected: every `*_test.gd` exits 0.
- Godot 1920×1080 preview -- expected: mission inventory capture has no clipping and visually matches the reference hierarchy.

**Results:**
- 36/36 arquivos `tests/*_test.gd` aprovados (25 até `save_game_flow_test.gd` + 11 restantes).
- `test-output/menu-inventario-missao-final.png` gerado em 1920×1080 e inspecionado sem recortes.

