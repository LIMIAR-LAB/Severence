# Investigation: cinco regressões da suíte atual

## Hand-off Brief
Três falhas vêm de expectativas antigas, uma é perda de barril funcional na composição do cenário e a falha Omega está prejudicada por cache de importação desatualizado. Quatro testes foram reproduzidos seletivamente com arquivos monitorados estáveis; não foi reexecutado Marty sobre arte em andamento. Recomenda-se ao coordenador corrigir o barril e alinhar os contratos dos três testes, preservando as assertivas funcionais; Omega precisa de importação estável antes de julgar âncoras.

## Case Info
Data: 30/09/2026. Status: Concluded (diagnóstico). Godot 4.7.2/Windows. Escopo: game_audio_test, guard_opening_test, scenery_016_test, marty_actions_test, solo_robot_test. Diretórios de runtime e testes existentes somente leitura; Omega ativo. HEAD observado 2f13b58960828ec8b0ab827dcd4bf3a513023245; checkout contém alterações, portanto HEAD sozinho não identifica o código testado.

## Problem Statement
Hipótese inicial: cinco regressões atuais precisam de causa e direção de correção. Falha de teste não implica automaticamente defeito introduzido pelo contrato de cenários.

## Evidence Inventory
- Available: logs/err e summary.json em cenarios-base/regression-current (10:24–10:25).
- Available: código e histórico git do checkout compartilhado.
- Partial: proveniência por arquivo da execução original; não assumir snapshot estável.
- Pending: reproduções seletivas com timeout e hashes.

## Investigation Backlog
1. Traçar logs/assertivas até fonte — em andamento por três revisões isoladas.
2. Reproduzir somente casos necessários com controle de concorrência.
3. Consolidar diagnóstico e enviar ao coordenador.

## Hypothesized Paths
H1: defeitos reais — aberto, confirmar causalidade e reproduzir.
H2: expectativas desatualizadas — aberto, comparar contrato atual e assertivas.
H3: execução invalidada por concorrência — aberto, comparar hashes/revisões.

## Confirmed Findings e Source Code Trace

### 1. game_audio_test — expectativa desatualizada (confiança alta)
`tests/game_audio_test.gd:20` exige >=45s e loop para todas as faixas. `tools/generate_boss_music.py:9`–11 compõe 16×4×0.5=32s; `tools/generate_game_audio.py:229` documenta 32s. `scripts/game_audio.gd:36`–38 carrega OGG e ativa loop. Probe real em `regressions/audio-duration/probe.log`: boss32s/looptrue, refuge64s/looptrue, expedition51.2s/looptrue. Hashes antes/depois preservados em hashes.json. A falha não é ausência de loop.

Correção sugerida: separar duração e loop, usar duração mínima documentada por faixa (tolerância de codificação para boss32s), mantendo mínimo45s onde ainda faz parte do contrato. Não remover a checagem de duração nem reduzir todos os limiares. Se45s for requisito de produto ainda vigente, corrigir a trilha; a evidência do gerador atual favorece32s intencionais.

### 2. guard_opening_test — tempo anterior ainda codificado no teste (alta para causa; média para decisão de balanceamento)
`tests/guard_opening_test.gd:19` exige warn>1s; linha20 avança1s e linha21 exige continuar sem disparo. `scripts/simulation.gd:19` define GUARD_WARNING=.85; linha2149 aplica a constante e linha2076 transita ao ataque ao expirar. Commit0f85249e563c69cc189bd17cd26ffac964b4dcac mudou1.1→.85 (junto de ataque2.4→2.05 e intervalo.48→.42). As quatro assertivas seguintes passam no log.

Correção sugerida: confirmar que .85 é balanceamento vigente e testar imediatamente antes/depois dessa fronteira, mantendo abertura de escudo, rajada, dano frontal e recuperação. Não restaurar1.1 só para satisfazer teste, nem eliminar cobertura de aviso. Se produto exigir>1s, corrigir runtime em vez do teste.

### 3. scenery_016_test — regressão real de conteúdo funcional (confiança alta)
`scripts/docks_map.gd:88`: parede primeira SHORTCUTS centrada(2804,5794). Linha101: barril legado centrado(2960,5915), distância≈197.4. `scripts/scenario_layout.gd:5,80` remove obstáculos não estruturais da sala cranes; linha13 coloca barris novos em(3331,6085)/(3349,6121), distâncias≈602/636. `scripts/simulation.gd:388` consome essa composição. Explosão do barril tem raio150 (linha556) e abre parede até raio+70=220 (linha960).

`tests/scenery_016_test.gd:52` procura barril até260; nenhum existe. `b=-1` na linha55 faz damage_obstacle retornar cedo (`simulation.gd:578`); as falhas de abertura e sprite nas linhas57/58 são cascata, não três causas independentes.

Correção mínima sugerida: preservar o barril de função obrigatória durante composição ou colocar barril explícito próximo da parede, dentro de220 unidades, com posição/circulação segura. Não aumentar260 para capturar um barril que não alcança a parede. Fonte de autoria é tools/build_docks_map.py; não editar docks_map.gd gerado manualmente. Corrigir na composição/autoria pertencente ao coordenador, validar rota e manter asserts de abertura/colisão/sprite.

### 4. solo_robot_test — setup de UI antigo, robôs ainda não avaliados (confiança alta)
`tests/solo_robot_test.gd:20` espera screen=play após SoloChoice; linha21 usa EquipAndEnter inexistente. `scripts/terminal_ui.gd:383,394` liga SoloChoice a choose_adventure e abre equipment imediatamente para solo. `tests/title_screen_test.gd:108,110` já exige ausência de EquipAndEnter e abertura imediata. Mudança documentada no commit3c607da, abre modo ao selecionar cartão.

A reprodução em15s repetiu a assertiva e null.pressed; terminou por timeout controlado, pois nunca chega ao quit. Não há evidência de falha de gameplay dos robôs: esse trecho não foi alcançado.

Correção mínima sugerida: somente setup — após selecionar solo, esperar frame se necessário e verificar equipment/pending_mode=solo/not playing; remover emissão do botão antigo. Preservar todas as assertivas de robôs e então rodar só este teste para revelar eventual problema posterior. Não substituir resultado de robôs por aprovação presumida.

### 5. marty_actions_test — importação incompatível com fonte atual (alta para cache, média para explicar histórico)
Log original registra18 falhas de âncora melee. `tests/marty_actions_test.gd:97` usa load(Texture2D), portanto textura importada; linhas98–104 verificam48 poses. `assets/characters/marty/omega/pixellab/melee.png.import:6` aponta CTEX `melee.png-0a75f57a3ab43572e1029a4833d8e732.ctex`. MD5 da fonte atual é83632c80eaa295b532de94822b21f82b, mas metadata do import registra852d4506717a1206441f17b41a8e14c4. Observação preservada em `regressions/omega-cache-observation.json`.

Fonte PNG foi gravada10:18, CTEX10:13, world_view/test10:19 e log10:24. `tools/import_marty_omega_pixellab.py:178` mudou normalização vertical; âncoras são tabela fixa `scripts/world_view.gd:998`–1008. Conversão do teste é coerente com desenho (`world_view.gd:1154`). A espada só aparece quadros>=3 (`world_view.gd:1017`); nove das18 falhas históricas pertencem a quadros desenhados, mas não comprovam defeito com fonte atual.

Correção sugerida: aguardar estabilização pelo dono Omega, reimportar e conferir MD5; executar apenas marty_actions_test com hashes PNG/CTEX/world_view/test antes/depois. Se persistir, inspecionar mão/âncora sobretudo quadros3 das linhas2/3/6/7. Não relaxar raio de alpha nem alterar âncoras agora. A origem exata das18 falhas históricas permanece hipótese, pois faltam hashes daquele processo.

## Reproduções e controle de concorrência
Runner isolado `tests/scenarios_prototype/reproduce_regression.ps1` usa processo oculto, timeout, logs próprios e hashes de todos scripts, teste e project.godot; para áudio inclui recursos de assets/audio. Quatro execuções atuais tiveram changed_paths vazio e mesma revisão antes/depois:

| Pasta em regressions/ | Resultado |
| --- | --- |
| 20260930-103236-251-game_audio_test | exit1, mesma assertiva |
| 20260930-103236-470-guard_opening_test | exit2, mesmas duas assertivas |
| 20260930-103237-066-scenery_016_test | exit1, mesmas três assertivas |
| 20260930-103238-634-solo_robot_test | timeout15s, mesmo setup/null.pressed |

Cada pasta contém provenance.json/stdout.log/stderr.log. Hashes iguais nos extremos não provam ausência de alterações transitórias revertidas, mas não há indicação disso. Não foi executada suíte global, reimportação nem repetição do grafo/binding. A execução de áudio mede recurso efetivo; não é avaliação auditiva.

## Hypothesis Resolution / Refutation pass
- H1 Confirmed para scenery: perda de barril funcional explica a falha; não é somente expectativa espacial arbitrária, pois o novo barril está fora do alcance real da explosão.
- H2 Confirmed para áudio/solo; Deduced para guard, sujeito à intenção de balanceamento. Loop efetivo e teste de título vigente refutam defeitos sugeridos por mensagens genéricas.
- H3 Refuted como explicação necessária para as quatro reproduções estáveis; permanece Open para origem histórica de Marty. Cache atual incompatível é Confirmed e impede concluir sobre a arte atual.

## Missing Evidence
Intenção final de balanceamento Guardião requer dono do combate; não se infere aprovação do usuário pelo código. Hashes do processo histórico Marty inexistem. Aceite visual das poses exige versão importada vigente e inspeção pelo dono Omega.

## Conclusion e Recommended Next Steps
Confiança alta nas quatro causas mecânicas reproduzidas e na divergência de cache. Integração mínima pertence ao coordenador: preservar função do barril; alinhar setups/limiares aos contratos documentados sem enfraquecer asserts; coordenar Omega antes de importar/julgar âncoras. Skill gds-quick-dev é próxima etapa adequada para correções autorizadas pelo coordenador. Investigação encerrada, nenhuma correção aplicada por esta frente; aguarda lote elegível. SCN-04.03 continua bloqueada pelo piloto SCN-02.06.
