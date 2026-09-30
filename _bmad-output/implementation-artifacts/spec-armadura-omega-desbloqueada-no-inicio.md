---
title: 'Armadura Ômega desbloqueada desde o início'
type: 'bugfix'
created: '2026-09-29'
status: 'done'
route: 'one-shot'
---

# Armadura Ômega desbloqueada desde o início

## Intent

**Problem:** A Armadura Ômega estava carregada, mas continuava bloqueada pela progressão do chefe, impedindo seu uso no começo do jogo.

**Approach:** Tornar a Ômega um desbloqueio inicial e migrar exclusivamente esse desbloqueio em saves de expedições antigas, preservando o estado dos demais equipamentos.

## Suggested Review Order

**Regra e migração**

- Torna a Ômega oficialmente disponível em jogos novos.
  [`equipamento.json:53`](../../data/equipamento.json#L53)

- Reconciliação focada corrige saves antigos sem liberar outros equipamentos.
  [`simulation.gd:1564`](../../scripts/simulation.gd#L1564)

**Verificação**

- Confirma desbloqueio, ativação inicial e duração completa.
  [`equipment_unlock_test.gd:18`](../../tests/equipment_unlock_test.gd#L18)

- Confirma a apresentação desbloqueada na tela de equipamento.
  [`equipment_ui_test.gd:30`](../../tests/equipment_ui_test.gd#L30)

- Protege a migração seletiva de snapshots antigos.
  [`inventory_persistence_test.gd:23`](../../tests/inventory_persistence_test.gd#L23)
