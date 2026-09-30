# Entrega reduzida — Farol integrado

**Concluído nesta etapa:** Farol jogável na expedição, carregado pelo catálogo, com escadas, patamar, paredes e junções. Três portas e atalho secreto sul preservados. Legado substituído sem duplicar pilares. Sombras/anel seguem terreno; integração Omega preservada.

**Abrir:** execute `Jogar.cmd` na raiz. Nova Expedição → Marty → modo desejado → equipamento → Ir ao Refúgio → portal DOCAS/1941 (E). O Farol é a sala09. Alternativa: abra `project.godot` no Godot e pressione F5. A bancada isolada permanece em `tools/scenarios/base/farol_workbench.gd` (setas, Shift, espaço, E), sem alterar saves.

**Verificação existente:**9suítes base verdes (`base-tests.json`);51/51 testes existentes com retestes afetados (`regression-published/final-summary.json`). Cleanup de áudio nos12testes já foi concluído; lógica de áudio do jogo não foi alterada nesta correção. Percursos runtime:4passagens×81frames, sem fundo detectado nas aberturas;Titan/parceiro testados nos dois sentidos. Arte revisou5capturas+20keyframes sem defeito concreto.

**Arquivos principais:** `scripts/scenarios/modules.json`, `templates/farol.json`, `farol_runtime.gd`, `farol_connections.gd`, `layer_painter.gd`; integração em `scripts/simulation.gd` e `scripts/world_view.gd`.

**Evidência visual:** `captures/farol/runtime/`, `captures/farol/runtime-motion/report.json`, `../cenarios-arte/runtime-review-r1/review.json`. Baselines anteriores preservados. Templatev1 SHA256:46088864afc12c521205a747f018574713d496f2636690d54b7b8e7c5c57f14a.

**Limites:** mapa continua fixo; não é conclusão das76histórias. Não houve playtest humano. Pequenas diferenças de amostragem entre origens ficaram documentadas, sem lacuna nos percursos verificados. Salvamentos antigos sem identificação do módulo mantêm renderização legada.

**Adiados por pedido do usuário:** SCN-03, geração procedural completa, outras salas/biomas, novos trabalhos de save/coop e refinamentos cosméticos. As frentes Arte/Procedural encerraram trabalho. SCN04.03 deixou apenas spec adiada, sem posicionador implementado; auditoria de entrada não foi entregue. Os gates do backlog original não foram removidos: histórias01/02 ficam em review documental, distinguindo entrega reduzida concluída de aceite integral do plano.

Histórico anterior: `status-history-before-publication.md`. Nenhum novo teste amplo, geração de arte ou automação é necessário para fechar esta entrega.
