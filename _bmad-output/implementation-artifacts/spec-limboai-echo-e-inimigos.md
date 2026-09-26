---
title: 'LimboAI para Echo e inimigos'
type: 'feature'
created: '2026-09-26'
status: 'ready-for-dev'
baseline_commit: '962b1d0'
context: ['{project-root}/docs/REGRAS_0_12.md', '{project-root}/docs/HISTORICO_CLAUDE.md']
---

<frozen-after-approval reason="human-owned intent">

## Intent

**Problem:** Hoje a IA do parceiro Echo e dos inimigos é um bloco grande de `if`/`match` em
GDScript (`step_enemies`, `step_boss`, e a lógica de Echo dentro de `step_actor`/movimento
de IA em `scripts/simulation.gd`). Isso funciona, mas é difícil de estender: Echo tem
comportamento básico (segue, atira, tenta esquivar, reanima, usa robô perto), o parceiro
pode ficar preso longe do jogador, e a IA do Almirante já tem 3 estágios + enrage
codificados linha a linha.

**Approach:** Instalar o addon **LimboAI** (Behavior Trees + Hierarchical State Machines,
grátis, MIT, oficial da loja do Godot) e migrar a IA do Echo primeiro (menor escopo, mais
visível pro jogador), deixando a IA de inimigos comuns e do Almirante para uma segunda
etapa, só depois que o padrão para Echo estiver validado.

## Boundaries & Constraints

**Always:** Preservar os 23 testes headless de `tests/*_test.gd` (em especial
`tests/solo_robot_test.gd`, `tests/enemies_test.gd`, `tests/warden_test.gd` que cobrem
Echo/IA hoje). Preservar `Expedition.snapshot()`/`apply_snapshot()` como dados simples
serializáveis — qualquer árvore de comportamento/estado do LimboAI deve viver do lado do
host (autoridade da simulação) e nunca ser guardada dentro de `sim.actors`/`sim.enemies`
como Node; o resultado da decisão da IA (posição desejada, ação) continua sendo escrito
nos mesmos campos Dictionary de hoje. Preservar o comportamento observável atual como
baseline: Echo segue, atira, reanima, usa robô; Almirante tem 3 estágios + enrage após
`BOSS_ENRAGE_TIME`. Qualquer mudança de comportamento perceptível precisa ser intencional e
documentada, não um efeito colateral da migração.

**Ask First:** Trocar a autoridade de rede (a simulação continua 100% no host; LimboAI só
decide o que o host já decidia antes). Mudar valores de dificuldade/dano/HP como parte
desta spec — isso é outra spec.

**Never:** Deixar o cliente (não-host) executar a árvore de comportamento — hoje `step_*`
só corre no host (ver `mode == "run"` / autoridade em `main.gd`); manter assim. Quebrar o
fallback: se o LimboAI não estiver habilitado, o jogo não pode travar.

## I/O & Edge-Case Matrix

| Estado / entrada | Resultado | Limite |
|---|---|---|
| Echo sem alvo próximo | Segue Marty, mantém distância seguindo caminho válido | Não atravessa parede/obstáculo |
| Echo perto de robô livre | Pode pilotar durante o combate | Mesma regra de hoje (`interact`) |
| Marty caído, Echo livre | Vai reanimar | Não reanima se estiver sob ameaça imediata (ver Tasks) |
| Simulação roda no cliente (não-host) | Árvore de IA não executa; estado vem do snapshot | Sem duplicar decisão em coop online |
| LimboAI desabilitado | IA volta ao comportamento antigo (`if`/`match`) sem crash | Nenhum erro em loop no console |
| Suíte headless | Continua passando | Nenhuma referência a Node do LimboAI dentro de `simulation.gd` fora de um bloco isolado e opcional |

</frozen-after-approval>

## Code Map

- `addons/limboai/`: pasta do addon (baixar de https://github.com/limbonaut/limboai ou pela
  loja do Godot); habilitar em Project Settings → Plugins.
- `scripts/simulation.gd`: `step_enemies` (~991), `step_boss` (~1130), IA do Echo dentro do
  laço de atores em `step` (procurar `coop == "ai"` e o bloco que decide `move`/`fire` do
  parceiro). **Toda a leitura de estado do mundo (posição de inimigos, obstáculos, sala
  atual) já existe nessas funções — a árvore de comportamento só decide, não recalcula.**
- `tests/solo_robot_test.gd`, `tests/enemies_test.gd`, `tests/warden_test.gd`: cobrem o
  comportamento hoje; servem de baseline de regressão.
- `docs/HISTORICO_CLAUDE.md`: "Pendências conhecidas" já cita "Sua inteligência e equilíbrio
  ainda são básicos" sobre o Echo — esta spec resolve isso.

## Tasks & Acceptance

**Execution:**
- [ ] Instalar `addons/limboai/` (GDExtension, não precisa de build customizado do Godot);
  habilitar o plugin.
- [ ] Criar `scripts/ai/echo_bt.gd` (ou pasta equivalente) com uma Hierarchical State Machine
  (`LimboHSM`) para Echo com pelo menos os estados: `follow`, `engage` (atirar/perseguir
  inimigo perto), `revive` (reanimar Marty caído), `pilot_robot` (usar robô livre em
  combate). Delegar a implementação via `LimboState` com callbacks simples (permitido pelo
  próprio addon para prototipagem rápida) para não reescrever toda a lógica de movimento —
  a HSM decide QUAL estado, a lógica de "como mover"/"como atirar" continua reaproveitando
  o que já existe em `simulation.gd` (`move_body`, `fire_actor`, etc. chamados a partir do
  estado).
- [ ] A HSM roda só quando `mode == "run"` e só no host (mesma guarda que hoje decide
  autoridade de rede); no cliente, o Echo remoto some da lógica local e vem só pelo
  snapshot, igual a hoje.
- [ ] Regra explícita: Echo não tenta reanimar se houver inimigo a menos de X px do corpo
  caído (evitar a IA "burra" indo pra cima de ameaça pra reanimar, comportamento hoje
  reportado como problema no relatório da sessão anterior).
- [ ] Fallback: se `ClassDB.class_exists("LimboHSM")` for falso (addon ausente/desabilitado),
  cair automaticamente na implementação antiga baseada em `if`/`match` (não remover o código
  antigo nesta primeira etapa — só desviar para ele).
- [ ] Atualizar/adicionar teste (`tests/echo_ai_test.gd` ou expandir `solo_robot_test.gd`)
  cobrindo: segue o jogador, ataca inimigo próximo, reanima quando seguro, evita reanimar
  sob ameaça, usa robô livre.
- [ ] Rodar a suíte completa e confirmar 0 falhas nos 23 arquivos existentes + os novos.
- [ ] Documentar em `docs/IA_ECHO_LIMBOAI.md` (novo): o que mudou, como o fallback funciona,
  e deixar claro que inimigos comuns e o Almirante **não foram tocados nesta etapa** (ficam
  para uma spec seguinte, só depois de validar o padrão aqui).

**Acceptance Criteria:**
- Given LimboAI habilitado e uma expedição solo com IA, when Marty se afasta de um inimigo,
  then Echo continua perseguindo e atirando sem ficar preso.
- Given Marty caído e um inimigo a menos de X px do corpo, when Echo decide o próximo passo,
  then ele NÃO tenta reanimar até o inimigo se afastar ou morrer.
- Given coop online com dois jogadores reais (sem IA), when o host processa o quadro, then
  nenhuma árvore de comportamento roda para o Echo (ele não existe como atuante nesse modo).
- Given o addon desabilitado, when o jogo abre, then a IA volta ao comportamento anterior
  sem erro.
- Given a suíte completa, when executada, then 0 falhas.

## Spec Change Log

## Design Notes

Link do addon: https://www.godotengine.org/asset-library/asset/4852 (repo:
https://github.com/limbonaut/limboai). Versão GDExtension é a recomendada aqui (não exige
build customizado do Godot, só limita alguns recursos de editor que não importam para IA
em runtime).

Por que começar por Echo e não pelos inimigos: Echo é o comportamento mais visível e mais
reclamado (ver `docs/HISTORICO_CLAUDE.md`, "Pendências conhecidas"); inimigos e o Almirante
já têm testes de regressão mais rígidos (`enemies_test.gd`, `warden_test.gd`) e uma migração
malfeita ali afeta o combate principal do jogo. Provar o padrão em Echo primeiro reduz risco.

Nunca guardar o `LimboHSM`/`LimboState` dentro dos Dictionaries de `sim.actors` — eles não
são serializáveis por `var_to_bytes`. Guardar a árvore de comportamento em uma estrutura
paralela (ex.: `Dictionary` chaveado por `actor.id`, mantida em `main.gd` ou num autoload,
fora de `Expedition`), e só escrever o RESULTADO da decisão (um `Dictionary` cmd, igual ao
que `player_input()` já produz) de volta no fluxo existente.

## Verification

Importar com os addons habilitados; rodar a suíte completa headless
(`Get-ChildItem tests\*_test.gd | ForEach-Object {...}`), 0 falhas esperadas. Depois, jogar
uma expedição solo com IA e observar Echo em pelo menos: perseguição, reanimação segura,
uso de robô livre, comportamento perto de portão trancado (não deve tentar atravessar).
Testar também com o addon desabilitado para confirmar o fallback.
