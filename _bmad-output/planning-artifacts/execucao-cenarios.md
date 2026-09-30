# Piloto vigente — Armazém7 v01 integrado, 30/09/2026

Após correção dos corredores, usuário autorizou explicitamente seguir. Armazém7/warehouse gerado e integrado, aguardando revisão visual. Uma geração Higgsfield GPT Image2.5 (job572ccb09-951e-4748-a7df-70ec7a100714, estimativa2,75créditos), referência Pátio aprovado. Fonte, prompt, gabarito e verificação em art/scenarios/scn-production/warehouse-fixed-v01. Capturas reais em implementation-artifacts/cenarios-base/captures/warehouse-fixed-v01.

Escala uniforme, footprint/carga traçados, sem props duplicados. Conexão Pátio→Armazém alinhada; corredor leste e portão do Mercado ajustados em conjunto. Baú e três armadilhas preservados/acessíveis; atalho norte destrutível. Testes focais Marty/Titan, interação de baú, objetivos, encontro e snapshot passaram; save original não gravado. Geometria revisão5. Mantido piloto fixo e corredores corrigidos. Doca, Santuário e Pátio aprovados preservados. Mercado permanece arte antiga; nenhuma sala seguinte iniciada.

---
# Ajuste vigente — corredores antes do Armazém, 30/09/2026

Pátio dos Guindastes aprovado pelo usuário e integrado. Próxima sala confirmada: Armazém7. Usuário interrompeu a preparação para priorizar corredores: geração do Armazém NÃO submetida (apenas gabarito/prompt/preflight, nenhum job).

Corredores corrigidos: partes recortadas são reconhecidas como corredores, em vez de receber piso de tábuas/fachada de sala. Material de pedra e bordas baixos reutilizam a arte aprovada; molduras genéricas duplicadas retiradas no piloto, bloqueios de combate preservados. Entorno das passagens externas usa água da arte aprovada, sem piso caminhável fictício. Farol deixou de pintar extensões fora do seu piso, e as junções recebem acabamento após a camada do módulo. Nenhuma imagem nova gerada para esta correção.

Teste focal corridor_finish_test passou: travessias ida/volta com raios11/23, curva norte do Pátio, classificação de corredor recortado, água bloqueada e save intacto. Capturas reais inspecionadas em captures/corridor-before e captures/corridor-after (sob implementation-artifacts/cenarios-base). Sala seguinte ainda mantém arte antiga; o contraste no interior do Farol/Armazém será tratado nas respectivas salas, sem alterar as três imagens aprovadas.

---
# Piloto vigente — Guindastes v01, 30/09/2026

Usuário aprovou Santuário e autorizou somente a sala à direita da Doca. Pátio dos Guindastes/cranes gerado e integrado com uma imagem Higgsfield (job18fbce97-83df-4500-ad03-1ba4fa8820d8; estimativa2,75créditos). Fonte/gabarito/prompt/verificação: art/scenarios/scn-production/cranes-fixed-v01. Capturas: _bmad-output/implementation-artifacts/cenarios-base/captures/cranes-fixed-v01.

Novas expedições usam temporariamente mapa fixo (fixed-art-pilot-v1), conforme direção do piloto; geração procedural suspensa, código preservado. Saves antigos não são deslocados nem recebem a placa dos guindastes: iniciar nova expedição para revisar. Sem gravação do save pelas ferramentas. Revisão geométrica4. Santuário aprovado e Doca preservados. Testes focais de portas humano/Titan, combate, atalho, objetivos e snapshot passaram. Não declarar terceiro cenário iniciado nem aprovação do Pátio: aguarda revisão visual.

---
# Piloto vigente — Santuário fixo v01, 30/09/2026

Pedido posterior do usuário autoriza gerar uma sala por vez. Primeiro candidato do Santuário gerado e integrado; aguarda revisão visual. Pátio dos Guindastes (cranes), à direita da Doca, é o segundo alvo e permanece sem nova geração. Não confundir com Farol.

Higgsfield GPT Image 2.5, um candidato, estimativa 2,75 créditos, job 7206bc7b-b78b-42ee-9268-19d9db17819f. Gabarito e prompt preservados em art/scenarios/scn-production/santuario-fixed-v01. Imagem 1744×2336, escala uniforme, colisões traçadas após inspeção (a geração produziu oito bancos e portas diferentes do gabarito). Runtime scripts/scenarios/sanctuary_fixed.gd; imagem assets/environment/docks12/chapel/fixed_v01/sanctuary.png. Migração em memória para revisão geométrica 3; arquivo do save preservado.

Santuário e cranes têm posições fixas nas novas partidas. As três conexões do Santuário são obrigatórias; demais salas ainda usam o sistema existente. Teste focado sanctuary_fixed_test passou; travessia de portas humana/robô passou; nova partida seed42 passou em procedural_runtime_test. Capturas reais zoom1,05 em _bmad-output/implementation-artifacts/cenarios-base/captures/sanctuary-fixed-v01. A transição para a arte antiga do Farol ainda apresenta contraste visual; não declarar o restante do mapa revisado/aprovado.

---
# Direção vigente — salas em imagens fixas, 30/09/2026

O usuário rejeitou a direção visual modular e aprovou salas/mapas como imagens fixas com qualidade equivalente à Doca inicial, colisões e portas alinhadas, corredores acabados entre portas compatíveis e aleatoriedade na seleção/ordem das salas. A capela e o Farol modulares não são solução visual final aprovada.

Produção interrompida nesta etapa. Ajustar o plano antes de qualquer nova geração ou implementação. Nenhuma nova tarefa para Arte/Procedural. Código, correções e evidências existentes preservados sem rollback; seed, catálogo, conectores, save, minimapa e rede poderão ser reaproveitados. A pergunta sobre reaproveitamento não autoriza retomar a produção.

Os registros abaixo são históricos e não substituem esta decisão.

---
Correção visual vigente: Doca preservada; capela modular móvel, Farol plano com cobertura, junções de pedra e portões compactos. Save real72044 inspecionado, capturas antes/depois em cenarios-base/captures/junction-*, teste físico focal161verificações/0falhas. Patamar44 revogado pelo usuário; evidência anterior é histórica.

# Escopo vigente — geração completa retomada, 30/09/2026

O usuário revogou a redução ao Farol e pediu concluir as pendências. Prioridade: fase Docas procedural jogável no fluxo normal, depois demais biomas. Integração ativada: 14 salas, conexões selecionadas por seed (17–18 nos casos finais), 11 salas deslocáveis; somente entrada e chefe conservam posição; capela modular participa da geração. Correção posterior ao feedback de mapa igual: topologia e distribuição agora variam; quatro novas runs reais passaram sem fallback, duas com caminhada física até chefe e save/continuar preservados. O lote35seeds pertence à versão anterior. Runtime1941 validado para navegação, objetivos, segredo, atalhos, encontros, snapshot e Salvar/Continuar. Capturas reais: test-output/procedural-map.png, procedural-farol.png e procedural-junction.png. Detalhes em ../implementation-artifacts/cenarios-base/status.md. Isto não conclui as76histórias nem outros biomas. Nenhuma automação ou commit global.

---

# Execução coordenada dos cenários

Início: 30/09/2026. Autorização do usuário: criar chats e executar simultaneamente na ordem correta, otimizando o trabalho. Este registro organiza a execução; não declara histórias concluídas.

## Chats iniciados

Host: `local`. Projeto: `6781f020-3cee-4ed3-a413-e4f174cbd0f7`. Mesmo checkout, arquivos separados conforme propriedade abaixo.

- Base e integração / coordenador: `01a0f264-7654-7bc2-a970-5d98f97c09f5`.
- Arte e identidade dos biomas: `01a0f264-bd2b-7d73-b62b-ce4d1adc1b35`.
- Gerador procedural GDQuest: `01a0f265-5552-78b0-89a7-d1fe8482aeea`.

As três frentes receberam instruções para começar imediatamente. A confirmação de criação não comprova conclusão de nenhuma história.

## Fonte e direção

Usar `epics-cenarios.md`, `stories-cenarios/README.md` e os arquivos individuais. Fase totalmente procedural; Doca/Desembarque e boss podem ter arte interna fixa; Refúgio é hub. Biomas têm materiais, arquitetura e circulação próprios. Preservar o checkout e alterações existentes.

## Frentes e propriedade de arquivos

1. **Base e integração (coordenador):** SCN-01.01–01.05 em sequência; revisão de prontidão e contratos; integra contribuições depois das dependências. Dono exclusivo de alterações de runtime compartilhado dentro desta iniciativa, dos estados das histórias, índice consolidado e deste registro. Criar componentes novos sempre que possível. Antes de editar `main.gd`, `simulation.gd`, `world_view.gd` ou HUD, verificar os chats já ativos de combate/Omega e aguardar liberação dos arquivos; não sobrescrever alterações concorrentes. Preparar patches fora desses arquivos enquanto estiverem ocupados.
2. **Arte:** pré-produção de SCN-02, depois produção e catálogo SCN-03 quando liberados. Escrita inicial exclusiva em `art/scenarios/scn-production/` e `_bmad-output/implementation-artifacts/cenarios-arte/`. Não editar runtime, contratos compartilhados nem status das histórias. Gerar peças com PixelLab/Higgsfield disponíveis, inspecionar resultado, registrar prompts/origem/camadas/medidas. Pré-produção não satisfaz dependência SCN-01.05 nem aceite em jogo.
3. **Procedural:** pesquisa verificável GDQuest e protótipo isolado de SCN-04.01/02; escrita exclusiva em `tools/scenarios/prototype/`, `tests/scenarios_prototype/` e `_bmad-output/implementation-artifacts/cenarios-gerador/`. Não editar runtime, arquivos da base, arte ou status das histórias. Não duplicar o contrato definitivo: adaptar ao SCN-01.04 quando publicado. SCN-04.03 exige SCN-02.06 e SCN-04.08 exige também entrada/boss.

Cada frente escreve seu próprio `status.md` no diretório de evidências. O coordenador é o único escritor deste registro. Novos caminhos precisam ser acordados pelo coordenador antes de duas frentes os usarem. Não fazer reset, clean, checkout, commits globais ou exclusão de trabalho alheio. Não instalar plugins nem gerar quantidades ilimitadas de assets para contornar indisponibilidade; registrar bloqueios concretos e avançar no trabalho independente.

## Ondas e liberações

- Onda 1: base SCN-01 em ordem, arte em pré-produção, pesquisa/protótipo GDQuest isolado. Validar alinhamento do backlog com arquitetura vigente usando skill apropriada e corrigir lacunas sem nova rodada de autorização rotineira.
- Onda 2: após SCN-01.04, adapter/graph SCN-04.01/02; após SCN-01.05, piloto visual SCN-02.01/02 e integração SCN-02.03–06 pelo coordenador, com arte apoiando.
- Onda 3: após SCN-02.06, catálogo SCN-03 e montagem SCN-04.03–07 podem avançar em paralelo em caminhos distintos. Integrar entrada/boss antes de SCN-04.08.
- Onda 4: estado/save/coop SCN-05 na ordem declarada; hub SCN-11.01 quando liberado. Aplicar SCN-12 por lote, não só no final.
- Onda 5: setores/eras SCN-06–11 respeitando dependências e capacidade de produção. Não marcar campanhas completas usando fixtures de inimigos ou quests.

## Comunicação e continuidade

O usuário autorizou a coordenação destes chats: o coordenador pode enviar atribuições e liberações às duas frentes, que podem responder ao coordenador com evidências, impedimentos e pedidos de contrato. Reutilizar esses chats para as ondas seguintes. Não criar novos chats sem necessidade; não delegar trabalho em arquivos já ocupados. IDs serão registrados pelo chat de origem antes da transferência da coordenação.

O coordenador deve acompanhar entregas com `wait_threads`, revisar evidências, liberar a próxima tarefa elegível e continuar enquanto houver trabalho executável. Trabalho aguardando dependências permanece explicitamente pendente. Não declarar execução futura garantida após encerrar: se precisar interromper, deixar estado e próximo comando claros. Nenhuma automação recorrente foi criada.

Aceite exige evidência dos critérios, testes pertinentes e inspeção visual quando aplicável. Separar implementado, verificado automaticamente e validado visualmente. Não fabricar aprovação humana ou desempenho medido.

## Andamento verificado — base, 30/09/2026

Bancada isolada implementada em tools/scenarios/base/workbench.gd. Cinco suítes novas passaram (baseline, seed, bioma, contrato, inspeção). Contrato v1 publicado em cenarios-base/contrato-v1.md; liberada somente adaptação isolada de SCN-04.01/02 à frente Procedural. SCN-04.03 continua bloqueada por SCN-02.06.

Capturas reais: Farol/Guindastes/Capela, 39 imagens nas 13 resoluções das opções e três sondas de oclusão. Neutral desativa modulação noturna/luzes aditivas; luz incorporada à textura permanece. Capturas iniciais conservadas em captures/initial-before-merge: outro chat integrou alterações de runtime durante o lote, com mudança de HEAD e renderer. Não confundir as duas revisões.

Regressão ampla de51 testes existentes:47 passaram,3 falharam e1 terminou por timeout com erro anterior. Falhas em áudio boss, Guardião, atalho explosivo e solo_robot; arquivos não editados pela base. Registro completo cenarios-base/regression/summary.json. Aceite global permanece aberto, sem esconder essas falhas ou substituir trabalho concorrente.

## Fechamento deste lote

Contrato v1 reforçado após revisão independente:34 probes verdes em fontes estáveis,5 suítes base verdes e binding procedural50×2 verde. Atlas do piloto corrigido por retenção de recursos até o frame; materiais montados e inspecionados com Marty. Arte aceitou direção material com restrições de repetição; duas escadas rejeitadas e proposta nativa não são conteúdo final.

Última regressão:46/51 verdes,4 falhas e1 timeout. Além dos achados iniciais, marty_actions_test registra18 falhas nas âncoras Omega sob alterações concorrentes. Conflito temporário resolvido pelo dono; nenhum runtime compartilhado editado pela base. SCN-01 permanece in-progress pelo gate de regressão da skill, SCN-03/04.03 não liberados. Próximos passos e comandos em cenarios-base/status.md. Sem automação ou promessa de execução posterior.
## Retomada — piloto nativo de escadas

FarolModule e tools/scenarios/base/farol_workbench.gd materializam as mesmas peças de44px em duas origens. Capturas atuais: captures/farol/captures.json,16 sondas separadas Marty/Titan. Primeiro frame corrigido com atualização da câmera e espera de renderização. Texturas PNG de autoria são decodificadas/validadas sem reimportar globalmente o projeto. Módulo permanece candidato, fora do catálogo de produção.

Seis suítes base verdes em base-tests.json. Testes dirigidos áudio, Guard, solo/robôs e scenery016 verdes e sem erros em *-reconciled.log. Correção funcional: ScenarioLayout preserva barril explosivo autorado a até220 unidades da parede de atalho; testes de áudio verificam durações exatas do manifest, Guard usa aviso0.85s, solo acompanha navegação direta e libera recursos. Baseline anterior preservado em captures/before-shortcut-fix; baseline atual recapturado após essa correção.

Limite aberto: sombra/anel dos personagens usam coordenada física inferior no renderizador compartilhado, enquanto sprite usa altura. Evidência nas sondas separadas; ajuste coordenado com origem antes de tocar arquivo de outra frente. A bancada oferece movimento por setas, Shift acelera, espaço ignora face como sonda aérea; isto não equivale a validar salto/dash/pilotagem completos da expedição. Testes físicos cobrem dois raios, dois sentidos, translação, face bloqueada e travessia aérea. Sem playtest humano nem aceite global alegado.


## Evidência posterior — contato e movimento reais
Arte aceitou visual estático restrito em cenarios-arte/farol-review-r3/review.json:16 sondas,8/8 pares idênticos foraUI nas duas origens. A bancada agora usa step_actor/interact reais: setas movimento, Shift dash/turbo, espaço salto, E pilotar/desembarcar. Teste Farol cobre salto real sobre face, dash real pelo lance oeste e desembarque nos dois lances/patamar; seis suítes base verdes após essas adições. Isso substitui a limitação anterior de controles sintéticos; não substitui playtest humano/coop completo.

Frente Omega ainda active na última consulta; patch de renderização segue isolado e não publicado no runtime compartilhado. Próximo lote Arte solicitado: soleiras/junções candidatas separadas para três conectores, preservando stairs. SCN02.05/06 não marcadas concluídas.

## Soleiras candidatas integradas na bancada
FarolConnections monta três corredores de teste a partir dos conectores reais W/E/N e manifest de Arte. Confere ID, posição, orientação, largura200, nível0, família material e dimensões nativas da placa. Piso comum preserva fase64x48; usa combined apenas, recortado à união caminhável. Capturas12 em captures/farol/*-join-*.png e connections.json. Norte inspecionado pela base: limite reto preservado sem faixa desenhada fora da área. Revisão Arte solicitada.

Sete suítes base verdes; farol_connections_test atravessa cada emenda nos dois sentidos, raios11/23, duas origens. Limitações: fixture isolada com corredores retos, não é catálogo de produção nem prova de todas as transições/cantos; captura estática não comprova câmera em movimento. Invocação interativa adicional: farol_workbench.gd -- --connections. Arte03 e runtime compartilhado ainda têm gates anteriores;02.05 permanece em implementação,02.06 não publicado.

Revisão Arte dos conectores concluída em cenarios-arte/connectors-review-r1/review.json:12 capturas arquivadas com hashes; aceite visual estático restrito, W/E contínuos e norte sem vazamento. Diferentemente das escadas r3, pares de junção NÃO são pixel-idênticos:W16/12 pixels,Marty/Titan;E138/137;N282/282;delta máximo14/255, detalhes do piso. Causa não diagnosticada. Registrar como ressalva de amostragem para avaliação com câmera contínua, sem alegar equivalência perfeita nem repintar arte. Paredes completas/cantos montados e publicação continuam fora desse aceite.
# Cenários — estado atual

30/09/2026. SCN-01 e SCN-02 implementados e aceitos tecnicamente por testes e revisão visual de agente. Nenhum playtest ou aprovação humana é alegado. SCN-03.01 e SCN-04.03 iniciados; geração completa ainda não está ativa na expedição.

## Entrega ativa

Farol `docks.farol.pilot` v1 persistido em `scripts/scenarios/modules.json` + `templates/farol.json`, SHA256 `46088864afc12c521205a747f018574713d496f2636690d54b7b8e7c5c57f14a`. Carregamento somente leitura, checksum, codec seguro, footprint1700x1300, transformação translate, repetição1 e vizinhança docks-stone/nível0. Três portas regulares e atalho sul128 explicitamente preservados. Escadas44, paredes exteriores68, piso em fase64x48. A expedição consome o módulo publicado; o catálogo ausente/inválido mantém fallback legado.

Runtime remove somente os obstáculos substituídos dentro do Farol, preserva demais salas e portas/atalho funcionais. Renderer não sobrepõe piso/escadas/pilares legados e usa camadas com origem comum. Sombra/anel/prompt/barras do Titan acompanham terreno; corpo/salto/espada preservados. Integração Omega existente preservada. Réplica reidrata módulo pelo catálogo; snapshot antigo permanece legado.

## Evidência vigente

- `base-tests.json`: nove suítes verdes, incluindo catálogo roundtrip/duas posições/entradas inválidas, conectores, física e runtime/réplica.
- `regression-published/final-summary.json`:51/51 testes existentes verdes, reunindo execução ampla e retestes afetados. Os logs iniciais ficam preservados;12 testes precisaram cleanup de áudio em thread separada, sem mudar regras do jogo. O teste de layout agora exige preservação exata dos pilares fora do Farol, em vez de contar pilares deliberadamente substituídos dentro dele.
- `captures/farol/runtime/`:cinco capturas no renderer real. `runtime-motion/report.json`:4 travessias×81frames, sem amostra de fundo na abertura,20keyframes.
- `farol_runtime_test`:Titan e parceiro reais atravessam4passagens nos dois sentidos; teste separado cobre salto, dash e desembarque nos lances/patamar.
- `cenarios-arte/runtime-review-r1/review.json`:revisão visual das5capturas e20keyframes, sem defeito concreto; não afirma inspeção de todos os324frames.
- Baselines históricos em `captures/initial-before-merge`, `before-shortcut-fix`, `before-published-module`; baseline efetivo atual recapturado com manifesto.

## Limites e próximos trabalhos

A geração espacial procedural permanece isolada. Liberado SCN-04.03 para a frente Procedural: encaixe determinístico, margens de arte, L/T, busca limitada/falha atômica. Arte audita chegada existente para SCN-03.01; não regenerar Doca/portal sem necessidade. Conectores auxiliares exigem política de fechamento em montagens futuras.

Diferenças pequenas de amostragem entre origens das soleiras permanecem documentadas no review estático (até14/255, sem deslocamento geométrico ou lacuna nos percursos testados); não são equivalência pixel a pixel. Autoria r1 das paredes1700x900 e parede sul contínua foram retiradas após testes; revisão3 respeita sala1300 e atalho.

Histórico detalhado: `status-history-before-publication.md`. Registro coordenado: `../../planning-artifacts/execucao-cenarios.md`.







