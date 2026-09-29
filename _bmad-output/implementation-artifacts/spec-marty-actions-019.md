---
title: Padrão de ações do Marty
status: done
baseline_commit: 62cc533
context: [docs/PADRAO_SPRITES_MARTY_0_19.md]
---

## Pedido
Definir um padrão único de sprites para movimento, começando pelo protagonista. A rolada comum deve funcionar nas diagonais. A esquiva com Armadura Ômega deve parecer um teleporte, inclusive nas diagonais.

## Implementação
Fontes geradas pelo ImageGen integrado, salvas em art/source. Importador normaliza 96 × 96 e ancora os pés. O renderer escolhe vista lateral, diagonal frente ou diagonal costas a partir de dash_dir; espelha à esquerda. Roupas comuns usam rolada; Ômega usa teleporte. Arma fica oculta durante a ação e retorna ao fim. Documento de padrão define estados e regras para atlas seguintes sem mudar o atlas antigo neste passo.

## Aceite e verificação
Marty percorre diagonal em ambos eixos com direção normalizada. Quatro quadros por ação durante 0,20 s. Ômega não mostra rolamento nas vistas integradas. Todas as folhas abrem em Godot, atlas antigo e equipamento seguem carregando. Testes de ações, atlas antigo, UI e controle passaram. Capturas inspecionadas em diagonal comum e Ômega de frente e costas. Sem teste de pressionamento físico do controle.

## Suggested Review Order
- [world_view.gd:540](../../scripts/world_view.gd#L540) — seleção da direção e da ação no desenho do Marty.
- [import_marty_actions_v1.gd:1](../../tools/import_marty_actions_v1.gd#L1) — células 96 × 96 e pivô.
- [PADRAO_SPRITES_MARTY_0_19.md:1](../../docs/PADRAO_SPRITES_MARTY_0_19.md#L1) — contrato para as próximas ações.
- [marty_actions_test.gd:1](../../tests/marty_actions_test.gd#L1) — oito rumos e recursos.
