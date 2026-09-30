# Arquitetura Roguelike — "Severence — Ecos do Tempo"

> **Documento canônico de decisões de arquitetura.** Fonte: sessão Cloud Dragonborn
> (Game Architect) + Tsmar. Todas as IAs que trabalharem neste projeto (Claude, GPT,
> Codex, Devin) devem tratar este arquivo como referência das decisões seladas.
> Divergências só valem se este documento for atualizado junto.

---

## 1. Contexto e decisões seladas

**Decisão atualizada por Tsmar em 30/09/2026:** fases com distribuição totalmente procedural de salas e corredores. A restrição anterior de macro fixo foi revogada. Doca/Desembarque e arena do chefe podem manter composições fixas; o Refúgio permanece hub fora do gerador. Os contratos abaixo recebem o adendo vinculante ao final deste documento. Mudança de plano, ainda não implementação.

**Pergunta respondida:** é possível fazer roguelike com cenários fixos? **Sim.** O que
define o gênero é o loop de run (permadeath → reset → meta-progressão) + variedade
sistêmica. Geração procedural é apenas um meio de obter variedade — não o único.
Precedentes: Hades (câmaras autoradas, sequência randomizada), Risk of Rain 2
(estágios fixos, teleporter/inimigos/drops randomizados), Vampire Survivors (mapas
fixos, variedade de build).

**Decisões tomadas:**

| Decisão | Escolha |
|---|---|
| Geração de mapa | **Macro procedural + módulos autorados** — seed define salas, posições, corredores, ramificações e ciclos válidos por bioma |
| Meta-progressão | **Hub + desbloqueios** — Refúgio como hub; armas/personagens/salas desbloqueáveis entram no pool da run |
| Biomas | **Cadeia de biomas** — Docas → Ferroviário → Adega/Santuário → boss final |
| Variância espacial | Templates com footprints e conectores declarados; distribuição do andar e seleção de módulos variam por seed |

**Histórico da decisão revogada:** o gerador `tools/build_docks_map.py` é autoral
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

Além do grafo, templates, posições e corredores procedurais, a seed sorteia o conteúdo por run:

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

- Cada template declara dimensões, conectores, alturas e orientações permitidas.
  Templates diferentes podem ter contornos e portas diferentes; variantes internas
  intercambiáveis respeitam o contrato do seu template.
- A autoria parte de `tools/build_docks_map.py`; o catálogo exporta dados de geometria,
  arte, colisão, spawns e variantes para o montador runtime.
- Na run, a seed determina grafo, seleção e posição de templates, corredores e
  variantes. Simulação, navegação e desenho consomem o mesmo mapa materializado.
- A conectividade precisa de validação global após a montagem, além da validação
  local de cada template. O validador antigo não garante uma fase procedural nova.
- O mapa atual fica como baseline/fallback validado. Saves legados preservam seu
  mapa, enquanto novas runs usam o gerador após cumprir os critérios SCN.

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
3. Footprints/conectores pertencem ao contrato de cada template; a montagem global varia e exige validação
4. Desembarque e boss podem usar composição fixa com conectores; arte interna fixa não obriga posição global fixa. Refúgio é hub externo ao gerador
5. Conteúdo novo entra via pools/defs/dados — nunca hard-coded em renderer
6. Colunas/linhas de atlas seguem `docs/SPRITE_POSE_STANDARD.md`

---

## 5. Roadmap de implementação

1. **Run/meta split + RunDirector + disciplina de seed**
2. **Camada de variância no mapa atual** — inimigos, loot, hazards, mutadores por
   seed. *Isso sozinho já entrega um roguelike jogável, sem geometria nova.*
3. **Geração completa por bioma** — grafo, módulos, corredores e interiores conforme backlog SCN
4. **Loop morte → Refúgio → nova run** + pool de itens/desbloqueios
5. **Segundo bioma** (Ferroviário) para provar que a cadeia é data-driven
6. Polish: daily run, seed sharing, mutadores avançados

## 6. Riscos conhecidos

- **Migração de save** — MetaState é formato novo; versionar e migrar
- **Balanceamento** — budget de spawn e curva de raridade por andar precisam ser
  decididos cedo, senão a variância vira loteria
- **Qualidade procedural** — mitigar repetição, costuras e bloqueios com módulos autorados, validação global, tentativas limitadas e fallback; aleatoriedade sozinha não garante qualidade

## 7. Referências

### Adendo vinculante — geração completa, 30/09/2026

Este adendo substitui restrições antigas de macro fixo, slots fixos e ausência de montador runtime nas seções 2.5 e 4 e nos handoffs anteriores.

- GDQuest é referência de algoritmos; adaptar ao jogo existente, sem importar todo o demo ou usar física como garantia de determinismo entre máquinas.
- Cada template declara footprint, conectores, alturas, roles, biomas e transformações permitidas. Variantes intercambiáveis preservam esse contrato; outro footprint é outro template.
- O montador materializa o andar em Godot durante o carregamento, com seed/subfluxos, versão e catálogo registrados. Simulação, arte, navegação e minimapa consomem esse mesmo resultado.
- Validar cada módulo e também o conjunto final, incluindo caminhos para atores permitidos, portas/chaves, spawns, segredos e objetivos. Não bastam retângulos que não se sobrepõem.
- `tools/build_docks_map.py` continua fonte do mapa legado e apoio à autoria/validação; não editar o arquivo gerado à mão. O mapa antigo é baseline/fallback, não objetivo final de distribuição.
- A Doca significa Desembarque neste plano. Doca e boss podem usar placas fixas; Farol e demais salas usam kits/composições locais reutilizáveis. Não exigir as mesmas 14 salas em toda run.
- Arte de ambiente pode usar PixelLab e/ou Higgsfield, com rastreabilidade e aceitação em jogo; não gerar arte durante a partida. A escolha da ferramenta não substitui revisão de estilo e escala.
- Detalhamento de requisitos e histórias: `../_bmad-output/planning-artifacts/epics-cenarios.md`. Eras posteriores continuam Parte B conforme o plano da lore.

### Fontes de implementação

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
