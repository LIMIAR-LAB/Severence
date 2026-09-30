# Estado atual — layout real entregue em 30/09/2026

Escopo completo retomado explicitamente; suspensão abaixo é histórica e substituída por esta atualização. Gerador físico entregue ao coordenador com API estável. Seeds 1941, 1, 42, 2026 e 999999: 5/5 sucessos em dois processos, cinco disposições distintas e hashes idênticos. 14 salas/19 arestas preservadas; sem interseções entre corredores de arestas distintas. Ver `layout-report.md` e `layout-tests*.json`.

Coordenador informou seed1941 integrada e navegável, snapshot/rehidratação e segredo aprovados; main ativado. Aceite visual e fechamento das histórias pertencem ao coordenador. Sem alteração runtime/catálogo neste lote; sem novos agentes.

## Histórico anterior à retomada
# Procedural status — 2026-09-30

**Frente encerrada por redução explícita de escopo/créditos.** Geração completa adiada; entrega vigente é Farol integrado jogável pelo coordenador. SCN04.03 interrompida antes de criar posicionador: somente spec-placement.md preservado como deferred, sem testes/mapa de ocupação novos. Implementador interrompido. Entregas anteriores (pesquisa, grafo, binding, diagnósticos e catálogo) preservadas. Não continuar testes/revisões/montagem nem retomar automaticamente.

Farol.connection_error corrigido pela base: relatório do coordenador conferido em `farol-connection/20260930-104954-323/results.json`,1 válido aceito/17 inválidos rejeitados, zero Script Error, fonte estável. Revisão original preservada com follow-up de resolução. Sem nova execução redundante. SCN04.03 segue bloqueada.

Lote texture_resource/Farol: robustez34 casos e binding50×2 verdes; hashes da base estáveis nos probes. Evidência `robustness/20260930-104656-888/`. Revisão de Farol.connection_error em `farol-connection/review.md`: 18 casos,2 erros de script retornando compatível e9 aceitações inválidas silenciosas;6 mismatches corretamente rejeitados/1 controle válido. Fonte estável; sugestões enviadas à base, sem edição runtime. Junção física/visual permanece não validada; SCN04.03 bloqueada.

Diagnóstico adicional das cinco regressões entregue em `regressions-investigation.md`: áudio/solo com expectativa antiga; Guardião com timing antigo no teste (intenção de balanceamento a confirmar); scenery016 com barril funcional removido; Marty com cache importado divergente da fonte atual. Quatro reproduções seletivas preservadas em regressions/, hashes monitorados estáveis, solo interrompido15s. Nenhum runtime/teste de outro dono alterado; nenhum teste grafo/binding repetido neste lote. Coordenador é responsável por integrar correções. Aguardando próxima liberação elegível.

**Resultado final do lote de robustez:** `robustness/retest-final.md`. Probes -Strict exit 0: 34 casos, 2 controles aceitos/32 mutações rejeitadas, sem Script Error; execução estável `robustness/20260930-102409-222/`. Binding 50 seeds × 2 processos exit 0 e hash anterior preservado, relatórios em `robustness/20260930-102307-236/` (bateria anterior teve alteração concorrente de RoomContract e foi repetida). Seis pendências anteriores resolvidas pela base. Lote encerrado; nenhum novo lote iniciado. Registros abaixo são histórico dos retestes.

Reteste mais recente após liberação da base: `robustness/retest-01.md`, logs preservados em `robustness/20260930-102139-503/`. 34 casos sem Script Error; 26 mutações rejeitadas, 6 ainda aceitas e 2 controles válidos. Pendências: connector ID vazio, radius negativo, escala pixel 0/-1, era vazia e versão NaN de bioma. Binding 50 seeds × 2 processos continua verde. Aguardando correções da base para novo reteste autorizado.

Último lote: auditoria de robustez executada sem editar a base. Primeira execução observou 28 casos (2 controles válidos, 12 mutações com erros de script, 14 aceitas silenciosamente); achados comunicados. Segunda execução coincidiu com correção da base e sobrescreveu logs fixos com erro de parse item_path em room_contract.gd:88. Ver ressalva em `robustness/report.md`; results.json atual não é a execução inicial. Runner corrigido para pastas por timestamp. Aguardando liberação para reteste: `tests/scenarios_prototype/run_public_contract_probes.ps1 -Strict`.

Preparação implementada e verificada: pesquisa GDQuest, experimentos reais e grafo isolado de SCN-04.01/02. Contrato SCN-01.04 v1 liberado pelo coordenador e consumido pelo adapter isolado; nenhuma história integrada na run ou marcada concluída.

## Evidências
- `research.md`: revisão GDQuest 19c98cee16ed18e642b3ce178f4c649d56b334b2, licenças, comandos e resultados Basic/MST. Originais e LICENSE preservados sob tools/scenarios/prototype/reference; sem .git aninhado.
- `graph-tests.json`, `graph-tests-process-2.json`, `cross-process.json`: 5 perfis × 1000 seeds, dois processos Godot 4.7.2, zero falhas, hashes canônicos iguais.
- `sample-*.json`: duas seeds por perfil, com salas/arestas/roles/caminho obrigatório. Formato `provisional-graph-only`.
- `review.md`: três revisões independentes; correções aplicadas no teste.

## Resultado e limites
Portuário: 977 grafos distintos; ferroviário: 235; industrial: 1000; alagado: 457; cultista: 675 no corpus 0..999. Contagem usa salas/arestas (sem seed), não isomorfismo abstrato nem layouts físicos. Perfis são propostas topológicas, ainda sem aprovação de gameplay.

Os testes verificam conectividade, separadores obrigatórios, ordem pista/minichefe, IDs e arestas válidos, ciclos, limites, ordem de Dictionary, rejeição sem saída parcial e seeds extremas. O custo registrado inclui validações/testes; não é benchmark de geração nem orçamento de frame.

Não implementados: geometria autorada, portas/chaves, colisões por ator, subfluxos/catálogo definitivos, navegação física, arte, integração de run/save/coop ou fallback runtime. Nenhuma inspeção visual ou aceite em jogo alegado.

## Próximo passo
Binding v1 implementado: `tools/scenarios/prototype/contract_adapter.gd`. Usa diretamente RoomContract e SeedManifest; fixtures test_only com portas reais e roles explícitos. `contract-adapter-tests.json` e `contract-adapter-process-2.json` registram 50 seeds em dois processos, hashes iguais e zero falhas. `contract-binding-sample.json` conserva IDs, portas, versões, fingerprint, grafo e regras. Execute `& tests/scenarios_prototype/run_contract.ps1`.

O binding verifica mapeamento perfil→bioma/era, conteúdo elegível, portas compatíveis/exclusivas e tradução. Rejeita altura/tipo/largura/normal/borda/role/bioma/era/elegibilidade incompatíveis, IDs inválidos e esgotamento. Não valida colocação global; origens não são algoritmo de montagem e conexões têm physical_connection_validated=false.

Próximo lote depende de liberação do coordenador. Não antecipar SCN-04.03 antes de SCN-02.06.

Reexecutar na raiz: `& tests/scenarios_prototype/run.ps1` (aceita `-GodotPath`). Nenhuma automação criada; a continuação depende de nova liberação do coordenador neste chat.


## Amostra adicional solicitada — seeds 2..31

Uma única execução adicional do gerador, sem repetir a bateria completa: **30/30 sucessos**, 30 disposições distintas, zero erros. Tempo mínimo 56 ms, máximo 254 ms, média 105.5 ms. Máximo de 8 tentativas (seed 4), abaixo do teto determinístico de 12; orçamento global de busca permanece 120000 visitas. Não foi necessário alterar gerador, teto, API ou retries; nenhum fallback legado. Runner: tests/scenarios_prototype/layout_sample.gd. Dados individuais em layout-sample-2-31.json.

Somadas à amostra anterior são 35 seeds reais distintas aprovadas. Isto reduz o risco observado, mas não prova sucesso para todas as seeds arbitrárias. Os tempos são medições deste ambiente e não constituem garantia de prazo de 1 segundo. Esta amostra verifica sucesso/diversidade/tempo; não repete as verificações geométricas completas da bateria anterior.
