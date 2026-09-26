---
status: done
route: one-shot
version: "0.15"
---

# Corrigir direção da fusão e atlas do Titan

## Intenção

Fazer a fusão Marty + Spectre mostrar a pose de costas ao caminhar para cima e
eliminar fragmentos de poses vizinhas que apareciam ao lado do Titan.

## Implementação

- A direção visual da fusão usa o movimento enquanto Marty caminha e volta a
  acompanhar a mira durante ataques.
- O Titan usa um atlas normalizado com margem transparente e somente o principal
  componente visual de cada quadro.
- O gerador do atlas permanece em `tools/clean_titan_atlas.py` para permitir a
  reprodução do resultado.
- O teste de atlas confere dimensões, isolamento lateral dos 50 quadros e direção
  da fusão.

## Ordem sugerida de revisão

1. `scripts/world_view.gd`
2. `tools/clean_titan_atlas.py`
3. `tests/robot_sprite_atlas_test.gd`
4. `assets/mech/titan_v3_clean.png`

## Validação

Suíte headless completa: 18 arquivos de teste aprovados, sem falhas.
