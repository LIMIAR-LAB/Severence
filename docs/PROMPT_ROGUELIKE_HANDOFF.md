# PROMPT DE HANDOFF — Transformar "Marty — Fraturas do Tempo" em roguelike

Cole o texto abaixo na outra IA (Claude / GPT / Codex). Ele assume que a IA tem
acesso a este repositório (branch `main` já contém todos os documentos citados).

---

Você está no repositório do jogo **"Marty — Fraturas do Tempo"** (Godot 4.7.2,
GDScript, Windows). Atenção: este NÃO é um projeto Godot convencional de cenas por
entidade — o mundo é simulado em `scripts/simulation.gd` e desenhado
proceduralmente por renderers (`world_view.gd`, `dock_scenery.gd`) a partir de um
arquivo de mapa GERADO (`scripts/docks_map.gd`).

## Passo 1 — Leia, nesta ordem, antes de escrever qualquer código

1. `docs/ARQUITETURA_ROGUELIKE.md` — decisões de arquitetura CANÔNICAS. Nunca
   contradiga; se divergir, atualize o documento junto.
2. `_bmad-output/planning-artifacts/epics.md` — épicos aprovados, FRs/NFRs e mapa
   de cobertura.
3. `docs/SPRITE_POSE_STANDARD.md` — só se tocar em sprites/animação de
   personagens.

## Passo 2 — Onde as coisas vivem

- `tools/build_docks_map.py` — ferramenta de AUTORIA do mapa. Gera
  `scripts/docks_map.gd` (nunca edite o `.gd` à mão — regenere pelo script).
- `scripts/simulation.gd` — simulação completa. Hoje mistura estado de run e de
  meta — é o alvo do split.
- `scripts/world_view.gd` — renderer do mundo, atores, inimigos, balas, luzes.
- `scripts/dock_scenery.gd` — pisos, paredes, props, decals, hazards, atmosfera.
- `scripts/combat_hud.gd` — HUD, minimapa, fog/discovery por sala.
- `scripts/arrival_art.gd` — set piece autoral do Desembarque.
- `tests/*.gd` — testes headless Godot.

## Passo 3 — Contratos obrigatórios (de `docs/ARQUITETURA_ROGUELIKE.md` §4)

1. Toda aleatoriedade de run sai do RNG seedado do RunDirector via sub-streams —
   nunca `randf()`/`randi()` global em sistemas de run.
2. Estado permanente vai pro MetaState; estado de run zera na morte.
3. Variantes de sala: footprint e âncoras de porta SEMPRE fixos; só o interior
   varia.
4. Conteúdo novo entra via pools/defs/dados — nunca hard-coded em renderer.
5. Manter compatibilidade com: coop/multiplayer, save/load, fog por sala,
   navegação/colisão, remap de input, âncoras de armas/animação.
6. Set pieces autorados (Desembarque, Refúgio, arenas de boss) são âncoras fixas.

## Passo 4 — Sua missão

Implementar o **Epic 1 — Fundação da Run** (ver `epics.md`):

- `RunDirector`: `new_run(seed)`, `advance_floor()`, `on_death()`
- Split `RunState` (zera na morte) / `MetaState` (persiste no save)
- RNG seedado por run com sub-streams por sistema (mapa, loot, inimigos,
  mutadores)
- Migração/versionamento do save atual
- Seed registrada na run e reproduzível (mesma seed = mesma run)

Critérios de aceite: FR1–FR5 e FR15 no `epics.md`. NFRs relevantes: NFR1
(determinismo), NFR7 (compatibilidade). Se o épico estiver grande demais para uma
sessão, implemente na ordem: split de estado → RunDirector → RNG → migração de
save — e descreva no fim o que ficou pendente.

## Passo 5 — Verificação

- Regenerar mapa: `python tools/build_docks_map.py`
- Testes headless:
  `"C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script tests/<teste>.gd`
- Rode no mínimo: `tests/simulation_test.gd`, `tests/combat_regression_test.gd`,
  `tests/arrival_art_test.gd` + crie um teste para o que implementar.
- Rodar o jogo: `Jogar.cmd`

## Regras do repositório

- Há muitas modificações não-commitadas de outros agentes — NÃO faça reset,
  clean ou checkout que descarte trabalho alheio.
- Siga o estilo existente (GDScript compacto, português nos comentários/docs).
- Não commite segredos. Não faça push a menos que peçam.
- Ao terminar, reporte: o que foi implementado, testes que passaram, e o que
  ficou pendente.

---
