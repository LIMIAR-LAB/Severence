---
title: 'Armadura Ômega carregada por cinco minutos'
type: 'feature'
created: '2026-09-29'
status: 'done'
route: 'one-shot'
---

# Armadura Ômega carregada por cinco minutos

## Intent

**Problem:** A Armadura Ômega começava cada expedição em recarga e permanecia ativa por apenas cinco segundos.

**Approach:** Fazer cada expedição começar com a armadura pronta para ativação e conceder cinco minutos completos de uso, mantendo a transformação e a recarga posterior existentes.

## Suggested Review Order

**Comportamento**

- Define os cinco minutos e mantém a recarga existente após o uso.
  [`simulation.gd:132`](../../scripts/simulation.gd#L132)

- Inicia cada expedição com a Armadura Ômega pronta para vestir.
  [`simulation.gd:322`](../../scripts/simulation.gd#L322)

- Comunica imediatamente ao jogador que a armadura está disponível.
  [`simulation.gd:361`](../../scripts/simulation.gd#L361)

**Interface e verificação**

- Alinha a descrição da tela de equipamento com o novo comportamento.
  [`equipamento.json:48`](../../data/equipamento.json#L48)

- Protege duração, ativação e carga inicial contra regressões.
  [`omega_test.gd:14`](../../tests/omega_test.gd#L14)
