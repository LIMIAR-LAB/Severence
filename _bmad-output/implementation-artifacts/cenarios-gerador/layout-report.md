# Layout procedural real — 30/09/2026

Implementado em `tools/scenarios/prototype/layout_generator.gd`, API `generate_layout(seed_value, rooms, edges)`. Entrada real de `ProceduralDocks.inputs(sim)`: 14 salas e 19 arestas. Nenhuma alteração de API ou runtime neste lote.

| Seed | Resultado | Tentativas | Processo 1 / 2 (ms) |
|---|---|---|---|
| 1941 | sucesso | 2 | 98 / 82 |
| 1 | sucesso | 11 | 333 / 318 |
| 42 | sucesso | 2 | 91 / 85 |
| 2026 | sucesso | 1 | 63 / 55 |
| 999999 | sucesso | 1 | 62 / 56 |

Cinco disposições distintas. Hash canônico idêntico entre dois processos para cada seed. Fontes monitoradas estáveis durante a segunda execução. Zero falhas nos testes de preservação de salas/arestas, âncoras, reservas de arte, ausência de interseções entre corredores de arestas distintas, gargantas de atalhos de 128, independência da ordem da entrada e falha atômica para rotação/ocupação impossível. Tempos medem somente a chamada do gerador, não integração nem carregamento da run.

Evidências: `layout-tests.json`, `layout-tests-process-2.json`, `layout-provenance.json`, `layout-current.json`, `layout-occupancy.svg` e `layout-occupancy.png`. Mapa da seed 1941: azul = footprint; contorno amarelo = reserva de arte; cinza = corredor; verde = porta walk; laranja = atalho.

O gerador usa até 12 tentativas determinísticas, com orçamento limitado de busca, sem fallback legado silencioso. A seed 1 consome 11 tentativas: este corpus pequeno não demonstra confiabilidade universal. Templates mantêm escala e orientação; entry/chapel/boss permanecem fixos; outras 11 salas variam. AABB conservadora inclui todas as asas, layers e art_bounds; não há margem extra além da arte autorada. Rotas curvas permitem normais diferentes e saem por stubs orientados; ligação direta exige normais opostas.

`manifest.gates_needed` informa colisores exatos na garganta de atalhos que precisam ser substituídos por gates dinâmicos. Não equivale a validar navegação interna de todas as salas. `caps_needed` informa portas não utilizadas. O consumidor é responsável pela aplicação física e pelo estado dos gates/segredo.

Coordenador informou integração real da seed 1941 aprovada: navegação às salas não secretas, pontos de missão, snapshot/rehidratação do Farol e abertura do segredo. Informou main ativado e tratamento de gates por rect/kind exatos, preservando a parede quebrável. Essa evidência pertence ao coordenador; não foi reproduzida por este lote. Aceite visual e encerramento das histórias permanecem com o coordenador.

## Amostra adicional solicitada — seeds 2..31

Uma única execução adicional do gerador, sem repetir a bateria completa: **30/30 sucessos**, 30 disposições distintas, zero erros. Tempo mínimo 56 ms, máximo 254 ms, média 105.5 ms. Máximo de 8 tentativas (seed 4), abaixo do teto determinístico de 12; orçamento global de busca permanece 120000 visitas. Não foi necessário alterar gerador, teto, API ou retries; nenhum fallback legado. Runner: tests/scenarios_prototype/layout_sample.gd. Dados individuais em layout-sample-2-31.json.

Somadas à amostra anterior são 35 seeds reais distintas aprovadas. Isto reduz o risco observado, mas não prova sucesso para todas as seeds arbitrárias. Os tempos são medições deste ambiente e não constituem garantia de prazo de 1 segundo. Esta amostra verifica sucesso/diversidade/tempo; não repete as verificações geométricas completas da bateria anterior.
