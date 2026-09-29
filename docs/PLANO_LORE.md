# PLANO DE CONCLUSÃO — "Marty: Fraturas do Tempo" (baseado na lore)

> Revisão do estado atual + passos para concluir o jogo conforme `docs/LORE.md`.
> Compatível com `docs/ARQUITETURA_ROGUELIKE.md` e `_bmad-output/planning-artifacts/epics.md`
> (épicos de infra roguelike já aprovados). Este documento cobre o CONTEÚDO da lore;
> os épicos 1-5 cobrem a espinha de run/meta/seed.

## Divisão em duas partes (DECIDIDO)

**Parte A — PRÉ-VENDA:** Passos 0, 1 e 2. Entrega um jogo completo em si:
loop roguelike funcional, Docas de 1941 polida e alinhada à lore, e o sistema de
personagens jogáveis. É o que vai para pré-venda/early access.

**Parte B — PÓS-LANÇAMENTO:** Passos 3, 4 e 5. As eras 2-5, o confronto final
(Arauto + Cthulhu) e a cinemática inicial entram como conteúdo depois do lançamento.

> ⚠️ Decisão pendente na Parte A (Passo 2): a lore amarra o desbloqueio dos
> personagens ao resgate na era de cada um — que só vem na Parte B. Recomendação:
> os caminhos de desbloqueio são **data-driven** (`unlock` no CharacterDef), então
> na pré-venda personagens podem ser liberados por estações do Refúgio / moeda de
> meta / quests das Docas, e a missão de resgate vira a forma "história" de obtê-los
> depois. Assim o roster já vende o jogo sem contradizer a lore: quem comprar cedo
> encontra o personagem na estação; quem jogar a era vê a versão dramática.

---

## 1. Estado atual (auditado no código)

### Docas de 1941 — a primeira era já está de pé

- 14 salas autorais: Desembarque, Pátio dos Guindastes, Armazém 7 (maze), Mercado de
  Peixe, Oficina, Último Gerador (opcional), Depósito de Munição, Pátio Ferroviário,
  Balcão do Farol, Capela do Culto (story), Doque Seco, Adega Inundada, arena do
  Almirante, Contrabando (secreta).
- **O Almirante das Profundezas**: boss 3 estágios + enrage (600 HP), portal de
  extração pós-vitória, recompensa atual = núcleo + armadura Ômega desbloqueada.
- **Warden**: miniboss quadrúpede 420 HP, drop de baú dourado — corresponde ao
  **Guardião da Maré** da lore (autômato corrompido). Falta batizar/amarrar na
  narrativa.
- Bestiário da Ordem: cult, fish, crawler (→crawler_small), brute, bomber, guard,
  elites com modificadores seedados (`mode == "run"` já existe com ~16% elite).
- Refúgio hub (sala única), Desembarque com arte autoral + fenda animada.
- Marty jogável: 4 roupas, armas modulares, dash, combo de espada; Titan
  pilotável; Spectre + fusão; coop 2P; remap de input.
- Sistemas: baús com chave, baú de recompensa de miniboss, quests/NPC diálogo,
  traps telegrafadas, fog por sala, arena de ondas.
- Docs de narrativa prontos: `docs/LORE.md`, `docs/ROTEIRO_CINEMATICA_INICIAL.md`,
  `docs/STORYBOARD_ABERTURA.md`, legendas `art/storyboard/intro-legendas-ptbr.srt`.

### O que falta vs a lore

| Lore | Estado |
|---|---|
| Letícia, Vincent, Elias, Íris jogáveis | Não existem — só Marty (P2 é segundo Marty) |
| Sistema de personagem jogável (roster/kit) | Não existe — só "outfit" do Marty |
| Eras: Japão (Vincent), Medieval (Elias), Laboratório (Íris), Região antiga (Letícia) | Só Docas 1941 |
| Portas do Refúgio para cada era | Refúgio é sala única, sem portas de era |
| Resgate → personagem desbloqueável | Sem sistema (MetaState ainda não existe) |
| Recompensa garantida de 1ª vitória | Recompensa fixa existe (núcleo/ômega), mas não o framework "1ª vitória = story beat garantido" |
| Pista do ataque à nave por era | Só ambientação (capela) — sem sistema de pistas |
| Cinemática inicial | Roteiro escrito; NÃO implementada |
| Arauto da Maré Negra + Cthulhu | Não existem |
| Horror cósmico sistêmico (vozes, sonhos, mutações) | Só ambientação estática |

### Insight-chave

A lore e a arquitetura roguelike **se encaixam perfeitamente**:
- "Resgate de amigo" = **desbloqueio de meta** (MetaState do Epic 1/4).
- "Repetir fase oferece novos achados sem prender a história ao RNG" = é exatamente
  o modelo de variância sistêmica + recompensa garantida (Epic 2 + regra nova).
- "Cada era com minichefe + chefe + pista" = template de BiomeDef (Epic 5).
- Refúgio hub + portas de era = o hub do Epic 4 ganhando a função narrativa
  que a lore já prevê.

---

## 2. Passos para concluir (ordem de execução)

### ⮕ PARTE A — PRÉ-VENDA (passos 0-2)

### Passo 0 — Espinha roguelike (Epics 1-2, já aprovados)
RunDirector, RunState/MetaState, seed, camada de variância. **Pré-requisito de
tudo abaixo** — resgates e recompensas vivem no MetaState.

### Passo 1 — Docas alinhadas à lore (polish narrativo)
- Renomear/tematizar warden como **Guardião da Maré** (autômato corrompido pela
  fissura — já é quadrúpede, 420 HP).
- 1ª vitória sobre o Almirante → **peça do Titan + símbolo da Ordem** (recompensa
  garantida, não sorteada) + retorno ao Refúgio.
- Pista inicial: objeto/diálogo no final revelando que o ataque foi planejado.
- Guardiões opcionais (7 em 55s) viram "pontos do ritual" das Docas.
- Áudio/ambientação de horror: sussurros na água, sons perto da capela.

### Passo 2 — Sistema de personagens jogáveis
- `CharacterDef` (dados): id, nome, atlas, cell_size, kit (armas/habilidades),
  desbloqueio meta, retrato.
- Roster no Refúgio: personagem selecionável por jogador; resgatados aparecem
  desbloqueados; P1 e P2 podem ser personagens diferentes (coop).
- Kits mínimos por personagem (da lore):
  - **Letícia**: rápida, saltos altos, golpes próximos precisos (melee/mobilidade)
  - **Vincent**: espada, parry no timing, contra-ataque
  - **Elias**: projéteis de luz, barreira temporária, micro-deslocamento
  - **Íris**: contenção (slow/root), análise de inimigo (marca fraqueza), cura limitada
- Atlases seguem `docs/SPRITE_POSE_STANDARD.md`; gerar arte via PixelLab MCP.
- Desbloqueio por resgate gravado no MetaState; Letícia/Vincent/Íris só viram
  jogáveis depois da primeira vitória da era deles.

### ⮕ PARTE B — PÓS-LANÇAMENTO (passos 3-5)

### Passo 3 — Eras 2-5 (uma por vez, template fixo)
Cada era usa o molde das Docas: entrada autoral (set piece), 8-14 salas +
variantes, miniboss guardando pista/chave, boss da Ordem, recompensa garantida de
1ª vitória, pista do ritual, NPCs com personalidade da era.

Ordem sugerida (pode ajustar — a lore não trava a ordem das eras):
1. **Japão era de guerras — Vincent**: miniboss + chefe de clã/culto local;
   resgate exige cumprir promessa dele (defender comunidade) + despedida.
2. **Reino medieval — Elias**: ele É o boss (Mago de Ferro no mecha). Vencer =
   quebrar a fonte das vozes → resgate; mecha recuperável separadamente.
3. **Laboratório avançado — Íris**: infiltração, prisioneiros, Spectre quase
   desmontado; resgate libera Íris + regras de simbionte do Spectre.
4. **Região antiga — Letícia**: defesa de comunidade contra criaturas da fissura;
   ela se junta por escolha com a pista do atacante.

### Passo 4 — Confronto final
- **Arauto da Maré Negra** (penúltimo boss): tenta abrir a última passagem.
- **Cthulhu** (final): manifestação pelas fraturas + Refúgio sendo puxado;
  vitória = romper os pontos do ritual e selar (não "matar" Cthulhu).
- Usa os personagens/robôs recuperados como parte da solução.

### Passo 5 — Cinemática + polish
- Implementar a cinemática inicial (`ROTEIRO_CINEMATICA_INICIAL.md` + storyboards
  já escritos).
- Horror cósmico sistêmico leve: eventos ambientes por era (sonhos, vozes,
  geometria), sem explicar a criatura.
- Playtest de balanceamento por era; mutadores opcionais (Epic 2).

---

## 3. Dependências (o que destrava o quê)

```
Epic 1 (Run/meta/seed) ─┬─> Epic 2 (variância) ──> repetir era = novos achados
                        ├─> Passo 2 (roster)   — resgates = unlocks no MetaState
                        └─> Passo 3+ (eras)    — BiomeDef + variantes por seed
Epic 4 (hub) ──────────────> Refúgio ganha portas de era + estações de desbloqueio
Epic 5 (BiomeDef) ─────────> era nova = dados + arte, não código novo
```

Regra da lore a preservar em TODOS os passos: **personagem essencial nunca
depende de sorte** — primeira vitória sempre concede story beat garantido;
RNG só distribui extras.

## 4. Arte pendente conhecida

- Rolamento do Marty (cols 10-13): prompts em `art/source/marty-roll-*-prompt.txt`
- Atlases dos 4 novos personagens (por `SPRITE_POSE_STANDARD.md`)
- Set pieces de entrada das 4 eras + arena do Arauto/Cthulhu
- Cinemática inicial (3 pranchas já roteirizadas)
- Tudo pode ser gerado via PixelLab MCP seguindo os padrões.
