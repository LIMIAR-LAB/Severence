---
stepsCompleted: [1, 2]
inputDocuments:
  - docs/ARQUITETURA_ROGUELIKE.md
  - docs/SPRITE_POSE_STANDARD.md
  - _bmad-output/implementation-artifacts/ (specs existentes como contexto)
---

# Severence — Ecos do Tempo - Epic Breakdown

## Overview

**Atualização de escopo (30/09/2026):** Tsmar revogou macro fixo em favor de fases totalmente procedurais por bioma, com Doca/Desembarque e boss como possíveis composições fixas. O detalhamento está em [epics-cenarios.md](epics-cenarios.md). As formulações antigas de FR7–FR9, NFR2/NFR4/NFR5 e Epic 3 abaixo são histórico do plano original, substituídas pelos contratos SCN e pelo adendo da arquitetura. Run, estado e meta continuam dependências reutilizáveis, não entregas presumidas.

This document provides the complete epic and story breakdown for transforming
"Severence — Ecos do Tempo" into a roguelike, decomposing the decisions sealed in
`docs/ARQUITETURA_ROGUELIKE.md` into implementable stories. There is no formal GDD
for this phase — the architecture document is the canonical requirements source.

## Requirements Inventory

### Functional Requirements

FR1: O jogo deve ter um RunDirector que inicia runs (`new_run(seed)`), avança
     andares/biomas e encerra a run na morte (`on_death()`).
FR2: Estado de run (HP, armas, itens, moeda da run, névoa descoberta, variantes
     sorteadas, andar/bioma atual, seed) deve ser separado do estado meta e zerado
     na morte.
FR3: Estado meta deve persistir no save: `unlocked_weapons`, personagens/skins
     desbloqueados, variantes de sala no pool, moeda bancada, estatísticas, flags.
FR4: O save deve ganhar versão nova com migração do formato atual.
FR5: Toda aleatoriedade de run deve sair de um RNG seedado do RunDirector via
     sub-streams por sistema (mapa, loot, inimigos, mutadores); nenhum sistema de
     run chama `randf()`/`randi()` global direto.
FR6: A camada de variância deve sortear por seed: composição de squads e posições
     de spawn de inimigos, elites/modificadores, conteúdo de baús, drops de
     miniboss, traps armadas + fase/timing, presença de NPCs/quests, portas
     trancadas/chaves e atalhos, mutadores de sala/run, variantes de boss.
FR7: Salas de combate devem declarar N variantes (`ROOM_VARIANTS`) com footprint e
     âncoras de porta fixas e interior variável (paredes internas, props, hazards,
     spawns, extras, estilo).
FR8: Variantes devem ser autoradas em `tools/build_docks_map.py`; o arquivo gerado
     emite dados de todas as variantes; `dock_scenery.gd`/`simulation.gd` consomem
     a variante escolhida pela seed.
FR9: O validador do gerador deve garantir reachability em TODAS as variantes
     (constraint: footprint e portas nunca mudam).
FR10: Biomas devem ser definidos como dados (BiomeDef): pool de templates/
      variantes, floor/wall sets, props, pool de inimigos, boss, atmosfera,
      número de andares.
FR11: Uma run deve atravessar uma cadeia de biomas (Docas → Ferroviário →
      Adega/Santuário → boss final) com set piece autoral de transição.
FR12: A morte deve levar a uma tela de resumo e depois ao hub Refúgio, com NPCs em
      papel duplo (quests + loja/desbloqueio), estações de desbloqueio e quadro
      de runs.
FR13: Deve existir um pool de itens em dados (id, raridade, slot
      arma/passivo/ativo, stats, tags de sinergia); drops da run saem do pool
      desbloqueado.
FR14: Desbloqueios de meta devem alimentar o pool de drops da run
      (`unlocked_weapons` já existe como base).
FR15: A seed deve ser registrada na run e reproduzir a mesma run (base para daily
      run e compartilhamento).

### NonFunctional Requirements

NFR1: Runs determinísticas — mesma seed produz mesma variância (mapa, loot,
      inimigos) em qualquer máquina; necessário também para determinismo entre
      peers no coop.
NFR2: Variantes de sala nunca alteram footprint nem âncoras de porta.
NFR3: Conteúdo novo entra via pools/defs/dados — nunca hard-coded em renderer ou
      simulação.
NFR4: v1 pode rodar com 1 variante por sala e deve ser equivalente ao mapa atual
      (sem regressão visual ou de navegação).
NFR5: Set pieces autorados (Desembarque, Refúgio, arenas de boss) são âncoras
      fixas — nunca removidos pela variância.
NFR6: Geração/seleção de variantes acontece em tempo de carregamento de andar,
      nunca no hot path de gameplay (60fps).
NFR7: Compatibilidade com coop/multiplayer, save/load existente, fog/discovery
      por sala, navegação/colisão e remap de input — comportamento dentro da run
      inalterado.
NFR8: Arte nova de personagens segue `docs/SPRITE_POSE_STANDARD.md`; armas seguem
      modulares (nunca cozidas no sprite).

### Additional Requirements

- `tools/build_docks_map.py` continua sendo a ferramenta de autoria/validação
  offline; o runtime consome os dados emitidos — não se porta o montador.
- Budget de spawn por sala e curva de raridade de loot por andar devem existir
  como dados (decisão de balanceamento cedo, para a variância não virar loteria).
- Contratos para todas as IAs já listados em `docs/ARQUITETURA_ROGUELIKE.md` §4
  valem como requisitos de implementação.
- Inimigos/boss existentes, baús, traps (`trap`/`phase`/`warn`), quests e fog por
  sala são reutilizados — dirigidos pela camada de run, não reescritos.

### UX Design Requirements

N/A — não existe documento de UX formal para esta fase. Requisitos de UX
identificáveis pela arquitetura (tela de resumo de run, hub Refúgio, quadro de
runs, estações de desbloqueio) são capturados como FR12 e detalhados nas stories.

### FR Coverage Map

FR1: Epic 1 — RunDirector (new_run/advance/on_death)
FR2: Epic 1 — RunState separado, zera na morte
FR3: Epic 1 — MetaState persiste no save (preenchido pelo Epic 4)
FR4: Epic 1 — versionamento/migração de save
FR5: Epic 1 — RNG seedado + sub-streams por sistema
FR6: Epic 2 — camada de variância sistêmica
FR7: Epic 3 — ROOM_VARIANTS por sala de combate
FR8: Epic 3 — autoria de variantes no build_docks_map.py + consumo por seed
FR9: Epic 3 — validador cobre todas as variantes
FR10: Epic 5 — BiomeDef como dados
FR11: Epic 5 — cadeia de biomas + transição autoral
FR12: Epic 4 — morte → resumo → hub Refúgio
FR13: Epic 4 — pool de itens (raridade/slots/tags de sinergia)
FR14: Epic 4 — desbloqueios alimentam o pool de drops
FR15: Epic 1 (seed registrada/reproduzível) + Epic 4 (daily run/compartilhamento)

## Epic List

### Epic 1: Fundação da Run
O jogo ganha o conceito de *run* como cidadão de primeira classe: uma sessão com
seed que nasce, vive e morre. RunDirector + split RunState/MetaState + RNG
seedado com sub-streams + migração de save. Destrava todos os outros épicos.
**FRs covered:** FR1, FR2, FR3, FR4, FR5, FR15 · **NFRs:** NFR1, NFR7

### Epic 2: Variância Sistêmica
Cada run joga diferente no mesmo mapa: squads e spawns de inimigos, conteúdo de
baús, drops de miniboss, traps armadas, presença de NPCs/quests, portas/atalhos,
mutadores de sala/run e variantes de boss — sorteados pela seed, com budgets de
spawn e curva de raridade como dados. *Este épico sozinho já entrega um roguelike
jogável.*
**FRs covered:** FR6 · **NFRs:** NFR2, NFR3, NFR6, NFR7

### Epic 3: Salas Remixadas (ROOM_VARIANTS)
O miolo do mapa muda entre runs: salas de combate ganham variantes autoradas de
interior (props, hazards, spawns, paredes internas, estilo) sorteadas por seed.
Footprint e âncoras de porta sempre fixos; o validador cobre todas as variantes.
v1 roda com 1 variante/sala (= mapa atual, sem regressão).
**FRs covered:** FR7, FR8, FR9 · **NFRs:** NFR2, NFR4

### Epic 4: Loop Completo & Meta-Progressão
O ciclo fecha: morte → tela de resumo → hub Refúgio → desbloqueios de
armas/personagens/variantes → nova run. Pool de itens com raridade/slots/tags de
sinergia, estações de desbloqueio, quadro de runs, daily run e compartilhamento
de seed.
**FRs covered:** FR12, FR13, FR14, FR15 (daily/share) · **NFRs:** NFR5

### Epic 5: Cadeia de Biomas
Runs atravessam múltiplos biomas definidos como dados (BiomeDef): Docas →
Ferroviário → Adega/Santuário → boss final, com set piece autoral de transição
entre biomas. Bioma novo = dados + passada de arte.
**FRs covered:** FR10, FR11 · **NFRs:** NFR5

<!-- Stories: geradas pelo workflow gds-create-epics-and-stories (step 3). -->

