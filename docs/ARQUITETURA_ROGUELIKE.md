# Arquitetura Roguelike — "Marty: Fraturas do Tempo"

> **Documento canônico de decisões de arquitetura.** Fonte: sessão Cloud Dragonborn
> (Game Architect) + Tsmar. Todas as IAs que trabalharem neste projeto (Claude, GPT,
> Codex, Devin) devem tratar este arquivo como referência das decisões seladas.
> Divergências só valem se este documento for atualizado junto.

---

## 1. Contexto e decisões seladas

**Pergunta respondida:** é possível fazer roguelike com cenários fixos? **Sim.** O que
define o gênero é o loop de run (permadeath → reset → meta-progressão) + variedade
sistêmica. Geração procedural é apenas um meio de obter variedade — não o único.
Precedentes: Hades (câmaras autoradas, sequência randomizada), Risk of Rain 2
(estágios fixos, teleporter/inimigos/drops randomizados), Vampire Survivors (mapas
fixos, variedade de build).

**Decisões tomadas:**

| Decisão | Escolha |
|---|---|
| Geração de mapa | **Macro fixo + miolo remixado** — espinha autoral fixa; salas de combate sorteiam entre variantes autoradas por seed |
| Meta-progressão | **Hub + desbloqueios** — Refúgio como hub; armas/personagens/salas desbloqueáveis entram no pool da run |
| Biomas | **Cadeia de biomas** — Docas → Ferroviário → Adega/Santuário → boss final |
| Variância espacial | Variant por slot de sala (interior varia; footprint e portas fixos) — começa com 1 variante (= mapa atual) e cresce incremental |

**Por que NÃO procedural completo:** o gerador `tools/build_docks_map.py` é autoral
(topologia desenhada à mão). "N layouts" = N mapas autorados, multiplicando o custo
de arte que já é o gargalo. Variantes de sala reutilizam o modelo de dados existente
(`ROOM_EXTRA`, estilos, props seedados, hazards) sem portar montador pro runtime.

---

## 2. Sistemas novos (o que precisa existir)

### 2.1 RunDirector (novo nó/sistema)

Dono da run. Responsabilidades:
- `new_run(seed)` — inicia run, distribui sub-streams de RNG
- `advance_floor()` / `advance_biome()` — transições da cadeia
- `on_death()` — encerra run, grava meta, retorna ao Refúgio
- É o único lugar que conhece "em qual run/andar/bioma estamos"

### 2.2 Run State vs Meta State (separação obrigatória)

Hoje `simulation.gd` mistura tudo. Separar:

- **RunState** (zera na morte): seed, andar/bioma atual, HP, armas e itens da run,
  moeda da run, névoa descoberta, posição, variantes sorteadas desta run
- **MetaState** (persiste no save): `unlocked_weapons`, personagens/skins
  desbloqueados, variantes de sala no pool, moeda bancada, estatísticas, flags

Requer bump de versão do save + migração do formato atual.

### 2.3 Disciplina de seed/RNG

- Um `RandomNumberGenerator` seedado por run, criado pelo RunDirector
- Sub-streams por sistema (`map_rng`, `loot_rng`, `enemy_rng`, `mutator_rng`) para
  que sistemas não disputem a mesma sequência
- **CONTRATO:** nenhum sistema de run chama `randf()`/`randi()` global direto —
  sempre via sub-stream do RunDirector. Isso garante runs reproduzíveis e habilita
  "daily run" / compartilhamento de seed.

### 2.4 Camada de Variância (o "gerador" deste jogo)

O mapa macro é fixo e autoral; a seed sorteia o conteúdo por run:

| Camada | Randomiza por run |
|---|---|
| Inimigos | composição de squads, posições de spawn, elites/modificadores |
| Recompensas | conteúdo de baús, drops de miniboss, pool de itens desbloqueados |
| Hazards | quais traps armadas, fase/timing (usa `trap`/`phase`/`warn` existentes) |
| Narrativa | quais NPCs/quests aparecem, diálogos variantes |
| Rotas | portas trancadas/chaves, atalhos abertos ou fechados |
| Mutadores | modificadores de sala/run ("escura", "alagada", "crawlers em dobro") |
| Boss | padrões de movimento/fases variantes |

### 2.5 Variantes de sala (ROOM_VARIANTS)

- Cada sala de combate declara N variantes: **mesma footprint e mesmas âncoras de
  porta**; interior varia (paredes internas, props, hazards, spawns, extras, estilo)
- Autoradas em `tools/build_docks_map.py` — Python continua sendo a ferramenta de
  autoria; o arquivo gerado emite dados de todas as variantes
- Na run, a seed escolhe uma variante por sala; `dock_scenery.gd`/`simulation.gd`
  consomem a variante escolhida
- **Constraint dura:** variantes NÃO alteram contorno nem portas → reachability
  garantida pelo validador existente, sem custo novo
- v1 pode ter 1 variante por sala (= mapa atual). Novas variantes são conteúdo
  incremental, não migração

### 2.6 Cadeia de biomas (BiomeDef)

Bioma é **definição de dados**: pool de templates/variantes, floor/wall sets, props,
pool de inimigos, boss, atmosfera, número de andares. Uma run = sequência de
BiomeDefs. Bioma novo = ~80% dados + passada de arte, não código novo. Transição
entre biomas via set piece autoral (descida/elevador), como o Desembarque.

### 2.7 Hub: Refúgio

Morte → tela de resumo da run → Refúgio. NPCs existentes (pescador etc.) ganham
papel duplo: quests + loja/desbloqueio. Estações de desbloqueio + quadro de runs.
`unlocked_weapons` existente vira o pool que alimenta drops da run.

### 2.8 Pool de itens

Dados: `id`, raridade, slot (arma/passivo/ativo), stats, tags de sinergia.
Simples primeiro: modificadores de stat + 1 efeito especial por item. Sinergias por
tags (`fire`, `dock`, `spectral`, …).

---

## 3. O que NÃO muda

Combate, inimigos, framework de boss, balas, HUD, fog por sala (já roguelike-native),
baús, traps, quests, remap de input — todos continuam, apenas passam a ser *dirigidos*
pela camada de run. O padrão de sprites/animação (`docs/SPRITE_POSE_STANDARD.md`) é
independente e continua valendo. Armas seguem modulares (nunca cozidas no sprite).

---

## 4. Contratos para todas as IAs

1. Toda aleatoriedade de run sai do RNG seedado do RunDirector (sub-streams)
2. Estado permanente vai pro MetaState; nunca em campo de run
3. Variantes de sala: footprint e portas fixos; interior livre
4. Set pieces autorados (Desembarque, Refúgio, arenas de boss) são âncoras fixas
5. Conteúdo novo entra via pools/defs/dados — nunca hard-coded em renderer
6. Colunas/linhas de atlas seguem `docs/SPRITE_POSE_STANDARD.md`

---

## 5. Roadmap de implementação

1. **Run/meta split + RunDirector + disciplina de seed**
2. **Camada de variância no mapa atual** — inimigos, loot, hazards, mutadores por
   seed. *Isso sozinho já entrega um roguelike jogável, sem geometria nova.*
3. **ROOM_VARIANTS** — interiores remixados nas salas de combate das Docas
4. **Loop morte → Refúgio → nova run** + pool de itens/desbloqueios
5. **Segundo bioma** (Ferroviário) para provar que a cadeia é data-driven
6. Polish: daily run, seed sharing, mutadores avançados

## 6. Riscos conhecidos

- **Migração de save** — MetaState é formato novo; versionar e migrar
- **Balanceamento** — budget de spawn e curva de raridade por andar precisam ser
  decididos cedo, senão a variância vira loteria
- **Repetição espacial** — mitigada por variantes + mutadores, não por geometria
  procedural; aceito conscientemente em troca de qualidade autoral

## 7. Referências

- `tools/build_docks_map.py` — autoria e validação de mapa (continua offline)
- `scripts/simulation.gd` — simulação; hoje mistura run+meta (alvo do split)
- `scripts/world_view.gd`, `scripts/dock_scenery.gd`, `scripts/arrival_art.gd` — render
- `scripts/combat_hud.gd` — minimapa/descoberta
- `docs/SPRITE_POSE_STANDARD.md` — padrão de poses/vistas de personagens
- `_bmad-output/implementation-artifacts/` — specs de implementação anteriores
- **PixelLab MCP** — disponível no ambiente para gerar as artes necessárias
  (sprites, tiles, props, animações pixel art); toda arte gerada deve seguir
  `docs/SPRITE_POSE_STANDARD.md` e ser integrada ao renderer — PNG solto em
  `assets/` não conta como entrega. Ver `docs/PROMPT_ROGUELIKE_HANDOFF.md`.
