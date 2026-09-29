---
title: Controle durante a partida
status: done
baseline_commit: e4551e7
context: []
---

## Pedido
Usuário consegue chegar à partida mas controle não responde. Diagnosticar reconhecimento e corrigir fluxo de controle sem mudar coop existente.

## Aceite
- Controle conectado comanda movimento, mira e ações do personagem local no solo/IA/online.
- Coop local preserva teclado P1 + controle P2; dois controles separados.
- Mira não salta para mouse imóvel ao soltar analógico.
- Pausa/retomada acessíveis pelo controle.
- Testes reproduzem eventos de controle; reportar limites de validação física.



## Validação
Godot em janela detectou `DualSense Wireless Controller`, dispositivo 0, reconhecido. `controller_input_test.gd` passou com eventos simulados para andar, mirar, atirar, saltar, pausar e retomar. `input_remap_test.gd` passou na repetição; houve uma falha intermitente de movimento na primeira execução, sem alteração correspondente no código de teclado. Pressionamento físico pelo usuário ainda requer conferência.

## Suggested Review Order
- [main.gd:274](../../scripts/main.gd#L274) — conexão, direção de mira e alocação dos controles.
- [main.gd:347](../../scripts/main.gd#L347) — pausa pelo botão Options/Start.
- [controller_input_test.gd:1](../../tests/controller_input_test.gd#L1) — eventos de controle na cena real.
