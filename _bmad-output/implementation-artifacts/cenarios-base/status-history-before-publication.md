## Retomada — piloto nativo de escadas

FarolModule e tools/scenarios/base/farol_workbench.gd materializam as mesmas peças de44px em duas origens. Capturas atuais: captures/farol/captures.json,16 sondas separadas Marty/Titan. Primeiro frame corrigido com atualização da câmera e espera de renderização. Texturas PNG de autoria são decodificadas/validadas sem reimportar globalmente o projeto. Módulo permanece candidato, fora do catálogo de produção.

Seis suítes base verdes em base-tests.json. Testes dirigidos áudio, Guard, solo/robôs e scenery016 verdes e sem erros em *-reconciled.log. Correção funcional: ScenarioLayout preserva barril explosivo autorado a até220 unidades da parede de atalho; testes de áudio verificam durações exatas do manifest, Guard usa aviso0.85s, solo acompanha navegação direta e libera recursos. Baseline anterior preservado em captures/before-shortcut-fix; baseline atual recapturado após essa correção.

Limite aberto: sombra/anel dos personagens usam coordenada física inferior no renderizador compartilhado, enquanto sprite usa altura. Evidência nas sondas separadas; ajuste coordenado com origem antes de tocar arquivo de outra frente. A bancada oferece movimento por setas, Shift acelera, espaço ignora face como sonda aérea; isto não equivale a validar salto/dash/pilotagem completos da expedição. Testes físicos cobrem dois raios, dois sentidos, translação, face bloqueada e travessia aérea. Sem playtest humano nem aceite global alegado.
# Base e integração — status

Atualizado em30/09/2026. Implementação isolada entregue e verificada; aceite global e geração integrada continuam pendentes.

## Resultado por história

| História | Entrega real | Estado de aceite |
|---|---|---|
| SCN-01.01 | Bancada de salas com alas/portas/colisão, fallback, capturas e hash da geometria efetiva; teste compara baseline capturado | in-progress; gates globais pendentes |
| SCN-01.02 | Adaptador sim.seed_value, subfluxo map SHA256 versionado, manifesto/catálogo canônicos; isolamento de RNG testado | in-progress; nenhum RunDirector criado |
| SCN-01.03 | BiomeCatalog JSON, dois perfis, materiais/atmosfera/pools/roles/conectores/fallback e validação robusta | in-progress; somente baseline_only/test_only |
| SCN-01.04 | RoomContract v1, transformação única, alas, portas, spawns, colisões/baked, adapter legado e renderer separado | in-progress; API estável para protótipo, sem geração na run |
| SCN-01.05 | Câmera fit/normal1.22, atores reais1.12, régua, movimento, neutral/colisão e densidade sem esticar | in-progress; inspeção automatizada não é playtest humano |
| SCN-02.01 | AtlasTextures fornecidos pela Arte carregados e montados com Marty sobre pedra e madeira | piloto visual aceito com restrições; sem catálogo final |

## Evidências e testes

- `tests/scenarios_base/run.ps1`: cinco suítes verdes; recibos em `base-tests.json`. Inclui comparação de geometria com captura, determinismo, catálogo, instâncias e densidade.
- Revisão independente: `../cenarios-gerador/robustness/retest-final.md`,34 casos em fontes estáveis:2 controles aceitos,32 mutações rejeitadas,zero Script Error. Corrigidos números/tipos malformados, IDs vazios, radius/escala não positivos, origem não finita e versão NaN.
- Adapter procedural executado novamente pelo coordenador:50 seeds ×2 processos,zero falhas e hash `d63b8938a3ce6597a45fdc78ffdef91db218f03ad07c0854edb147dd09698f33`. Grafos/bindings de fixtures, NÃO layouts físicos. Corpus anterior de5 perfis ×1000 seeds ×2 processos pertence à frente Procedural.
- Capturas baseline em `captures/`: Farol/Guindastes/Capela e overlays. Primeira revisão preservada em `captures/initial-before-merge/`; outro chat mudou o runtime durante a execução. `baseline.json` registra hashes e manifesto da captura mais recente.
- `captures/inspection/`:39 imagens nas13 resoluções das opções +3 sondas de oclusão; relatório registra resolução pedida/real, zoom, viewport e fontes. As amostras1280x800/1920x1080 e oclusão foram inspecionadas. Neutral remove modulação noturna/luz aditiva, não iluminação pintada.
- `captures/contract-docks.png` e `contract-rail_test.png`: renderer por dados, recorte pelas alas, overlay da mesma instância. Fixture sintética não é arte de produção.
- `captures/pilot-materials.png` e `pilot-materials-wood.png`: texturas agora visíveis, nativas1:1, personagem real. Bug de quadro branco corrigido mantendo referências das texturas até o frame. Arte aceitou direção material do piloto; madeira repete demais para áreas extensas. Escadas não aprovadas.
- Smoke da cena normal executado sem erro. Não houve edição de main/simulation/world_view/dock_scenery pela base.

## Bloqueios restantes

1. Última regressão de51 testes existentes:46 verdes,4 com falha e1 timeout com erro anterior. `game_audio_test`, `guard_opening_test`, `scenery_016_test`, `marty_actions_test` (18 falhas nas âncoras Omega) e `solo_robot_test` (null após seleção) estão registrados em `regression-current/summary.json`. Testes desses sistemas não importam os novos componentes da base. Não sobrescrever trabalho paralelo para torná-los verdes.
2. O conflito Git temporário de world_view foi resolvido pelo chat responsável; capturas voltaram a executar. Omega segue em trabalho e o histórico/renderer mudou durante o lote. Não há liberação de edição dos arquivos compartilhados para a iniciativa.
3. SCN-02.02: duas gerações rejeitadas. A proposta nativa da Arte tem dois lances200x360, patamar800x360 e altura44, mas face própria44/orientações/validação de pés ainda pendentes. Proposta aritmética não é arte integrada.
4. SCN-02.06 não publicado; SCN-03 e SCN-04.03 continuam sem dependência satisfeita. SCN-04.08/run/save/coop não liberados.

A skill gds-dev-story proíbe marcar review/concluído com regressões. Por isso SCN-01 permanece in-progress apesar das entregas isoladas. Não houve aprovação humana nem meta de desempenho inventada.

## Continuação concreta

1. Após os donos liberarem runtime, corrigir/reconciliar os cinco testes globais com o comportamento vigente, preservando alterações concorrentes; executar suite global em revisão estável.
2. Rever aceite de SCN-01 com os recibos atuais; atualizar checkboxes/estado apenas quando todos os gates forem satisfeitos.
3. Autorar face44 e duas orientações curtas com a proposta `art/scenarios/scn-production/farol-docas-v01/stairs-native-composition.proposal.json`; integrar/testar na bancada antes de SCN-02.03–06.
4. Só liberar montagem/catálogos após piloto e conectores validados. Reutilizar os dois chats cadastrados em execucao-cenarios.md.

Nenhuma automação criada; este registro não promete execução futura após encerrar o turno.

Atualização do piloto: suporte de sombra/anel/prompt corrigido SOMENTE em tools/scenarios/base/farol_preview.gd, overrides dos métodos de desenho. Patch focal descritivo em support-projection.patch.txt. Corpo, espada e seno de salto preservados; suporte usa apenas height_at do terreno.16 capturas regeneradas; world_view.gd permanece intocado até frente Omega terminar. Conectores agora têm testes positivos/negativos de largura, altura, tipo, família de material e orientação; dimensões reais dos PNGs e sort_y transladado cobertos.6 suítes base continuam verdes.

## Evidência posterior — contato e movimento reais
Arte aceitou visual estático restrito em cenarios-arte/farol-review-r3/review.json:16 sondas,8/8 pares idênticos foraUI nas duas origens. A bancada agora usa step_actor/interact reais: setas movimento, Shift dash/turbo, espaço salto, E pilotar/desembarcar. Teste Farol cobre salto real sobre face, dash real pelo lance oeste e desembarque nos dois lances/patamar; seis suítes base verdes após essas adições. Isso substitui a limitação anterior de controles sintéticos; não substitui playtest humano/coop completo.

Frente Omega ainda active na última consulta; patch de renderização segue isolado e não publicado no runtime compartilhado. Próximo lote Arte solicitado: soleiras/junções candidatas separadas para três conectores, preservando stairs. SCN02.05/06 não marcadas concluídas.

Validador de conectores reforçado após revisão independente: tipos/presença/domínio de normal cardinal, largura positiva finita, altura finita e strings não vazias verificados antes de comparar.18 probes em cenarios-gerador/farol-connection/20260930-104954-323/results.json:1controle válido aceito,17malformados/incompatíveis rejeitados,zero erros de script.6 suítes base permanecem verdes. Isto prova compatibilidade declarativa; emenda física/visual continua evidência separada02.05.

## Soleiras candidatas integradas na bancada
FarolConnections monta três corredores de teste a partir dos conectores reais W/E/N e manifest de Arte. Confere ID, posição, orientação, largura200, nível0, família material e dimensões nativas da placa. Piso comum preserva fase64x48; usa combined apenas, recortado à união caminhável. Capturas12 em captures/farol/*-join-*.png e connections.json. Norte inspecionado pela base: limite reto preservado sem faixa desenhada fora da área. Revisão Arte solicitada.

Sete suítes base verdes; farol_connections_test atravessa cada emenda nos dois sentidos, raios11/23, duas origens. Limitações: fixture isolada com corredores retos, não é catálogo de produção nem prova de todas as transições/cantos; captura estática não comprova câmera em movimento. Invocação interativa adicional: farol_workbench.gd -- --connections. Arte03 e runtime compartilhado ainda têm gates anteriores;02.05 permanece em implementação,02.06 não publicado.

Revisão Arte dos conectores concluída em cenarios-arte/connectors-review-r1/review.json:12 capturas arquivadas com hashes; aceite visual estático restrito, W/E contínuos e norte sem vazamento. Diferentemente das escadas r3, pares de junção NÃO são pixel-idênticos:W16/12 pixels,Marty/Titan;E138/137;N282/282;delta máximo14/255, detalhes do piso. Causa não diagnosticada. Registrar como ressalva de amostragem para avaliação com câmera contínua, sem alegar equivalência perfeita nem repintar arte. Paredes completas/cantos montados e publicação continuam fora desse aceite.
