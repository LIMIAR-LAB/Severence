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
# Correção visual e física focada — 30/09/2026

Doca inicial preservada. Foi inspecionado o save real do usuário, seed72044/layoutv1, sem gravá-lo. A sala à direita do templo é stairs/Farol. O save permanece byte-idêntico (SHA256 registrado em junction-physics.json).

Causas: a placa capela continha céu/vazio e arquitetura dentro do retângulo considerado piso; a construção da placa repetia recortes de paredes e altar nos corredores. Portões decidiam escala comparando posições legadas, portanto salas deslocadas recebiam torres gigantes. O Farol continha um patamar44 e escadas sem função clara no combate.

Correção: capela usa piso, paredes, bancos, altar físico encostado na parede e objetos modulares existentes; não usa mais a pintura cósmica nem seus recortes nos corredores. NPC/objetivo acompanham a posição procedural da capela; ela deixou de ter origem fixa. Farol agora é Posto do Farol, piso plano com dois grupos de cobertura e rádio/carga como marco, sem escadas, patamar ou desnível físico. Portões compactos usam identidade da sala, molduras de pedra discretas e aberturas preservadas. Corredores compartilham piso de pedra e bordas baixas. A Doca de entrada e seus assets não foram modificados; boss mantém arena autorada.

Antes: captures/junction-before/{chapel-east,chapel-altar,farol-south,farol-west}.png. Depois no mesmo save/câmeras: captures/junction-final/ (1280x800,zoom1.05). Inspecionados altar, saída leste, saída sul, antigo patamar e portas do Farol. Capturas com Titan em chapel-east-titan/farol-west-titan. Também foi inspecionada capela deslocada da seed42 em captures/junction-procedural/.

Teste dirigido junction_physics_test.gd:161 verificações,zero falhas; atravessou todos os conectores de capela/Farol nos dois sentidos com raios11/23 de personagem/Titan, bloqueou aproximação através do altar e saída para vazio, verificou altura zero no antigo patamar, NPC/baú acessíveis e hash do save inalterado. Runtime42 passou incluindo capela não fixa,NPC/altar acompanhando sua sala,nav/objetivos/segredo/atalhos/encontros/snapshot. Só estes testes dirigidos e capturas; não foi repetida a bateria global, nem criada arte/agentes novos.

A geometria antiga é adaptada em memória ao continuar saves pré-revisão2; não há sobrescrita automática do arquivo nesta verificação. O módulo publicado Farolv1 e testes históricos de degraus permanecem como evidência anterior; seus aceites de patamar44 foram revogados pela simplificação solicitada. Esta entrega não conclui demais biomas ou todo o backlog.

## Histórico anterior
# Correção da variação visível — 30/09/2026

Feedback reproduzido: duas NOVAS expedições pelo fluxo real do menu usaram seeds4005/6949 diferentes, sem fallback, mas mantiveram as mesmas19ligações e as salas nas mesmas faixas. A diferença era essencialmente espaçamento. O launcher e Continuar não eram a causa.

Correção: modo normal usa árvore de conexões com laços variáveis, ordem de crescimento sorteada e distribuição espacial ampla. Conexões removidas são fechadas com colisão/parede, e Farol desenha soleiras apenas das portas conectadas. As duas poças de tentáculos não contam como ligações obrigatórias para alcançar suas próprias condições. Antes de publicar, a validação segue condições de progressão alcançáveis e verifica objetivos/salas/segredo. Nova Expedição sorteia seed independente do tempo desde abrir o programa; seed explícita continua reproduzível. Se a geração falhar, a mensagem do jogo identifica o fallback, sem ocultar que foi usado o mapa de segurança.

Evidência visual antes: captures/variation-before/run-0.png e run-1.png. Evidência depois pelo MESMO menu: captures/variation-after/run-0.png e run-1.png, seeds145910271/1330921371, distribuições e conexões diferentes; save/continuar idênticos ao layout salvo, nenhum fallback. Capturas adicionais de percurso: captures/variation-walk/run-0.png e run-1.png, seeds458216874/1978583481. Ambas chegaram fisicamente ao chefe com move_body e colisão real em modo de teste, encontros removidos, sem teleporte entre salas:12000/11000unidades percorridas. Relatório variation-walk/report.json:0falhas, boss_reachable=true, walked_to_boss=true, save_restored=true nos dois casos. Entrada, capela e arte do chefe continuam fixas; os interiores autorados são reutilizados.

Verificações dirigidas: runtime1941 e42 passaram com portas fechadas, navegação, objetivos, segredo, atalhos, encontros e snapshot; teste42 inclui asserções novas sobre topologia removida, tampas físicas e Farol sem passagem fantasma. Gerador confirmou1941/42 estáveis e conectados com portões de evento inicialmente bloqueados. Não foi repetida a bateria geral51testes, nem o lote35seeds da versão anterior. O contador35 abaixo é histórico, não certifica esta nova versão.

Nota sobre recibo antigo variation-before/report.json: seu campo boss_reachable foi calculado por índices de navegação anteriores ao carregamento e ficou false indevidamente, embora a asserção inicial tivesse passado. A sonda foi corrigida para registrar a condição antes do reload; a evidência final inclui também caminhada física posterior ao carregamento.

## Histórico da integração anterior, preservado abaixo
# Docas procedural integrada — 30/09/2026

O usuário revogou a entrega reduzida ao Farol. A expedição normal agora usa o gerador de salas e corredores: 14 salas autoradas, 19 ligações, 11 salas deslocáveis. Entrada, capela e chefe mantêm a posição para preservar pinturas existentes. Os interiores continuam autorados; a topologia conserva as ligações legadas, enquanto posições e traçados variam com a seed.

Abrir: Jogar.cmd → Nova Expedição → Marty → modo/equipamento → Refúgio → portal DOCAS. TAB/M abre o mapa. Continuar preserva o layout materializado; expedições antigas continuam carregáveis.

Implementação: scripts/scenarios/procedural_docks.gd integra layout_generator.gd, transforma salas, obstáculos, elevações, inimigos, objetivos e pontos de interação. Corredores curvos são reconhecidos pelo renderer/minimapa. Farol segue sua origem gerada. Segredo é revelado dinamicamente; atalhos conservam as paredes quebráveis e também fecham durante encontros. A parede estática de labirinto declarada no manifesto como bloqueio de garganta é removida, preservando a barreira quebrável.

Verificado nesta integração:
- Gerador: 35 sementes distintas aprovadas; cinco repetidas em processos independentes. Reservas, cruzamentos, portas e falha atômica no relatório ../cenarios-gerador/layout-report.md. Amostra adicional2..31:30/30,56–254ms. Não é garantia universal; falhas limitadas têm fallback legado com motivo registrado.
- procedural_runtime_test.gd: navegação às salas/objetivos, segredo aberto, duas paredes quebráveis, garganta para raio23, selagem/abertura de encontro, snapshot/replica, tamanho compatível com pacote online e origem Farol.
- save_game_flow_test.gd: geração no main e layout idêntico após Salvar/Continuar, coop local, progresso e tratamento de falha de gravação.
- dynamic_map_test.gd: regressão de encontros e objetos existentes passou.
- Capturas reais inspecionadas: captures/procedural/map.png, farol.png e junction.png. Mapa, módulo deslocado e junção com curva aparecem no renderer normal.

Evidência histórica:51testes existentes e9suítes base pertencem à entrega anterior; não foram repetidos integralmente após a integração procedural. Farol publicado e suas capturas/percursos permanecem preservados. Histórico da redução: status-history-farol-reduced.md.

Limites: sem playtest humano; demais biomas e o backlog completo não concluídos. A geração varia disposição/traçado, sem catálogo novo de variantes internas nem alteração combinatória de topologia. A arte das outras salas é reutilizada. Não declarar as76histórias concluídas.

Coop online: tools/test_network.ps1 passou com host/cliente reais, movimento remoto e entrega de estado comprimido, sem erros de engine. O encerramento do teste passou a aguardar liberação do mixer de áudio. Antes de publicar um novo layout, o runtime agora valida navegação real em simulação candidata; só aplica o estado após validar objetivos, salas e segredo. O grafo de navegação é reconstruído na geometria gerada.

Fechamento da integração: runtime completo passou para seeds1941,1,42,2026,999999 após validação pré-publicação (procedural-runtime-tests.json). Salvar/Continuar e rede host/cliente foram repetidos na versão final e passaram. SCN04.03/04/08 em review;04.06/07 em andamento,04.05 planejada. Demais critérios não foram marcados concluídos.







