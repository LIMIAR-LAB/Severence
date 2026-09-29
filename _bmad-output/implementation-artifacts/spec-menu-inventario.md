---
title: 'Menu de inventário e equipamento em abas'
type: 'feature'
created: '2026-09-29'
status: 'done'
baseline_commit: '28437a20363da65af0b014dbe5981757501ebed9'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** A tela de Equipamento atual mistura seleção de uniforme, armadura, robô e status numa única composição e não possui um inventário persistente, filtrável e seguro.

**Approach:** Criar um shell dieselpunk em cinco abas, com Inventário como entrada principal, sustentado por catálogo e estado separados da UI; reaproveitar regras, desbloqueios, cálculos e assets existentes e migrar saves sem perda.

## Boundaries & Constraints

**Always:** preservar os fluxos de abrir/fechar/iniciar, os ids e cálculos reais, a autoridade do host, os saves v1 e mudanças existentes; textos em português; navegação por mouse, teclado e controle; itens sem mecânica real ficam explicitamente não utilizáveis.

**Ask First:** ampliar combate/economia, introduzir item consumível com efeito novo, trocar identidade visual global ou remover uniforme, armadura ou robô existente.

**Never:** inventar efeitos, duplicar valores da simulação na UI, aceitar ids/quantidades inválidos, permitir mutação autoritativa pelo convidado ou usar assets externos sem licença.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Inventário normal | Catálogo válido e pilhas persistidas | Grade, filtros, ordenação, detalhes e equipar refletem o estado real | Operações retornam resultado explícito |
| Save antigo | Dados v1 sem inventário | Defaults seguros são migrados e o loadout existente é preservado | Campos ausentes/estranhos são ignorados |
| Limites | Cheio, pilha máxima, bloqueado ou item desconhecido | Nenhuma mutação parcial | Motivo legível e estado permanece consistente |
| Online convidado | Tentativa de mudar loadout | Pedido validado no host | Rejeição silenciosa/feedback sem mutar estado local autoritativo |

</frozen-after-approval>

## Code Map

- `data/inventario.json` -- catálogo inicial orientado a dados, incluindo protótipos rastreáveis.
- `scripts/inventory_data.gd` -- validação e consultas determinísticas do catálogo.
- `scripts/inventory_state.gd` -- pilhas, capacidade, seleção, filtros, ordenação e slots equipáveis.
- `scripts/equipment_screen.gd` -- shell visual em abas, grade, detalhes e páginas reais.
- `scripts/terminal_ui.gd` -- integração com navegação e aplicação do loadout.
- `scripts/main.gd` -- persistência versionada, migração e autoridade de rede.
- `scripts/simulation.gd` -- estado serializável e validação central do loadout.
- `tests/inventory_model_test.gd` -- catálogo, limites, filtros, ordenação e equipamento.
- `tests/inventory_ui_test.gd` -- abas, foco, detalhes e estados visuais.
- `tests/save_game_flow_test.gd` -- persistência/migração sem regressão.
- `docs/INVENTARIO.md` -- modelo, fluxo e limitações.

## Tasks & Acceptance

**Execution:**
- [x] `data/inventario.json`, `scripts/inventory_data.gd`, `scripts/inventory_state.gd` -- implementar catálogo validado e estado seguro, independente da apresentação.
- [x] `scripts/equipment_screen.gd`, `scripts/terminal_ui.gd` -- implementar as cinco abas e navegação completa em 16:9, mantendo APIs legadas usadas pelos testes.
- [x] `scripts/main.gd`, `scripts/simulation.gd` -- persistir/migrar inventário e loadout e manter mutações host-authoritative.
- [x] `tests/*.gd` -- cobrir unidade, UI, persistência e regressões existentes.
- [x] `docs/INVENTARIO.md` -- registrar decisões e limites; capturar e inspecionar a tela final.

**Acceptance Criteria:**
- Given a keyboard, mouse or controller, when the equipment screen opens, then Inventory is selected and every tab is reachable with visible focus and meaningful real content.
- Given valid or invalid inventory operations, when they execute, then capacity, stack, unlock and slot constraints are deterministic and no invalid partial state is produced.
- Given a v1 or current save, when it loads and saves again, then gameplay state, loadout and inventory survive without unknown data crashing the game.
- Given existing equipment, unlock, stats and save tests, when the complete headless suite runs, then all relevant tests pass.
- Given the representative unlocked state, when captured at 16:9, then no content is clipped and the visual hierarchy matches the supplied concept.

## Spec Change Log

## Design Notes

Inventory entries reference stable catalog ids. Existing uniforms/robots/armor remain authoritative in `equipamento.json`; inventory weapon entries point to those loadout ids instead of duplicating gameplay values. Persistent inventory represents owned meta-items, while run-only keys, money, fuel and batteries remain simulation resources.

## Verification

**Commands:**
- Godot headless test scripts -- expected: zero failures and exit code 0.
- Godot capture of equipment UI at 16:9 -- expected: PNG written and visually inspected against the concept.

## Suggested Review Order

**Shell visual e interação**

- Entrada principal monta o shell, compatibilidade legada e Inventário por padrão.
  [`equipment_screen.gd:78`](../../scripts/equipment_screen.gd#L78)

- Grade separa catálogo, posse, bloqueio, filtros, paginação e foco visível.
  [`equipment_screen.gd:136`](../../scripts/equipment_screen.gd#L136)

- Equipar é transacional e preserva escolhas quando a aplicação falha.
  [`equipment_screen.gd:232`](../../scripts/equipment_screen.gd#L232)

- Status usa a composição real compartilhada com a simulação.
  [`equipment_screen.gd:297`](../../scripts/equipment_screen.gd#L297)

**Modelo e autoridade**

- Catálogo valida schema antes de expor dados à interface.
  [`inventory_data.gd:8`](../../scripts/inventory_data.gd#L8)

- Estado sanitiza saves, pilhas, capacidade, seleção e slots.
  [`inventory_state.gd:19`](../../scripts/inventory_state.gd#L19)

- Host preflighta loadout atomicamente e isola o inventário persistente do P2.
  [`simulation.gd:1312`](../../scripts/simulation.gd#L1312)

**Persistência e compatibilidade**

- Save v2 inclui inventário sem rejeitar expedições v1.
  [`main.gd:528`](../../scripts/main.gd#L528)

- Carregamento valida atores e Spectres antes de alterar a simulação.
  [`main.gd:564`](../../scripts/main.gd#L564)

- Snapshots sanitizam inventário e ignoram campos desconhecidos.
  [`simulation.gd:1425`](../../scripts/simulation.gd#L1425)

**Verificação**

- Casos de pilha, capacidade, filtros, ordenação e slots ficam isolados.
  [`inventory_model_test.gd:11`](../../tests/inventory_model_test.gd#L11)

- Migração real v1, autoridade P2 e atomicidade têm regressão dedicada.
  [`inventory_persistence_test.gd:12`](../../tests/inventory_persistence_test.gd#L12)

- Captura determinística renderiza a UI num SubViewport 1920×1080.
  [`inventory_preview.gd:3`](../../tests/inventory_preview.gd#L3)

