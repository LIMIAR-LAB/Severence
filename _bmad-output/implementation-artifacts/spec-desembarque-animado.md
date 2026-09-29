---
title: Desembarque com ambiente animado
status: done
baseline_commit: 33e406d
context: [docs/DESEMBARQUE_ARTISTICO_0_19.md]
---

## Pedido aprovado
Animar o cenário do Desembarque: água, reflexos, espuma, luzes e fumaça. A pintura estática continua como base e recebe camadas em tempo real. Preservar o combate e a geometria.

## Aceite
- Na expedição, água/reflexos e atmosfera mudam visivelmente com o tempo.
- Os efeitos ficam nas regiões apropriadas da pintura e não ocultam atores nem projéteis.
- Refúgio e salas não descobertas não recebem efeitos de Desembarque.
- A pausa congela a animação, usando o relógio da simulação já sincronizado em coop.
- Renderização validada com quadros em tempos diferentes, teste headless e jogo aberto.

## Arquivos
scripts/arrival_art.gd: camadas procedurais sobre a pintura.
tests/arrival_animation_preview.gd: comparação visual de tempos.
docs/DESEMBARQUE_ARTISTICO_0_19.md: registrar animação e validação.



## Validação
Três revisões independentes sem achados acionáveis. Teste de geometria/sincronização passou. Captura renderizada comparou t=0 e t=1,5: 53.490 pixels de água alterados; failures=0. Inspeção visual da captura final concluída.

## Suggested Review Order
- Camadas animadas no desenho do chão: [arrival_art.gd](../../scripts/arrival_art.gd#L6).
- Comparação de quadros sem atores ou fenda: [arrival_animation_preview.gd](../../tests/arrival_animation_preview.gd#L1).
