---
title: 'Armas detalhadas, munição abundante e energia azul do Omega'
type: feature
created: '2026-10-04'
status: done
baseline_commit: '87fe42e55592e2d8944b94ec8e17429994c312af'
context: []
---

<frozen-after-approval reason="Implementação solicitada diretamente pelo usuário; preservar a força do Omega">

## Intent

**Problem:** Armas recentes têm apresentação simplificada e poucas cargas; a animação de espada do Omega desagrada ao usuário.

**Approach:** Refazer mosquete, Tesla e arpoador com arte raster detalhada, integrada ao mundo e HUD; multiplicar cargas recebidas e reservas aproximadamente por cinco; substituir o ataque de espada por grandes esferas de energia azul lançadas da mão. O disparo final do combo deve ter presença maior. Manter os controles existentes e a força do Omega já pedida anteriormente.

## Boundaries & Constraints

**Always:** Preservar trabalho anterior, saves, arte de personagens, vida/escudo/duração/recarga/velocidade/voo/poderes do Omega. Melhorar o ataque, sem nerf. Usar a mesma imagem e geometria para arma na mão, pickup e UI. Separar altura visual de colisão. Testar com perfil isolado antes dos autoloads. Fazer alterações localizadas pois há trabalho simultâneo de outro chat em NPCs e efeitos de explosão.

**Ask First:** Publicação remota ou descarte de saves.

**Never:** Refazer NPCs, alterar outras formas/robôs, substituir arte do peixe, criar dependência de API no jogo, incluir imagens só no diretório externo de geração, reduzir munição existente ao restaurar snapshots.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Arma adquirida | Mosquete/Tesla/arpoador/bazuca | Recebe carga ampliada, respeitando reserva ampliada | Valores validados sem ultrapassar teto |
| Reabastecimento | Drop/loja/quest já existente | Quantidade proporcionalmente maior | Sem recompensas duplicadas |
| Save antigo | Quantidade pequena salva | Quantidade preservada; futuros pickups ampliados | Migração não inventa compra/recompensa |
| Ataque Omega | Controle antigo da espada | Esfera azul pela mão na direção da mira | Colisão bloqueada por parede; alvos próximos funcionam |
| Combo | Terceiro ataque | Esfera maior/forte mantendo poder de finalização | Não aplicar duas vezes ao mesmo alvo |
| Voo/esquerda | Disparo em altura/outra direção | Emissão acompanha mão e altura | Sem espada flutuante ou enorme textura original |

</frozen-after-approval>

## Code Map

- `scripts/simulation.gd`: tabelas de munição, recompensas, geometria e ataque Omega.
- `scripts/world_view.gd`: arma, pose, efeitos e projéteis; evitar área `draw_fx_013` onde outro chat pode trabalhar.
- `scripts/weapon_visuals.gd`: fontes e medidas de armas compartilhadas por HUD/UI.
- `assets/weapons/*_hd.png`: três imagens novas geradas com image_gen e transparência, já copiadas e inspecionadas.
- `tests/`: regressões, preview de combate e integridade do Omega.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/weapon_visuals.gd`, `scripts/world_view.gd`, `scripts/simulation.gd`: integrar três artes novas com transparência, escala/hands/muzzle consistentes; cortar margens transparentes em runtime via AtlasTexture se necessário, sem editar os arquivos gerados.
- [x] `scripts/simulation.gd`, dados relevantes: mosquete 20 por aquisição, Tesla 90, arpoador 30, bazuca 30; reservas 60/180/90/90 respectivamente. Reabastecimentos/loja/quest cinco vezes a quantidade anterior, respeitando tetos. Atualizar texto que divulga quantidade e fixtures afetadas.
- [x] `scripts/simulation.gd`, `scripts/world_view.gd`: substituir golpes de espada por esferas azuis da mão, usando efeitos animados nativos, sem animação de corte da espada. Preservar dano próximo, reflexão, acesso ao segredo e força do combo; adicionar alcance através das esferas sem dupla contagem em alvos já atingidos.
- [x] `tests/`: validar quantidades, caps, persistência, geometria em oito direções, bolas/rastro/sem espada; rodar regressões Omega/voo/armas em sandbox.
- [x] `docs/`: registrar mudanças e prompts das imagens; capturas reais isoladas mostrando três armas e bolas Omega; revisão independente e triagem.

**Acceptance Criteria:**
- Given any of the three new weapon pickups, when collected, then the game displays the corresponding detailed weapon and grants the expanded amount.
- Given an existing save with finite ammunition, when restored, then it retains its ammunition and accepts larger future refills.
- Given Omega melee input, when the attack triggers in any aim direction, then a blue energy sphere emerges from the hand without a visible sword or slash pose.
- Given close targets and walls, when firing spheres, then collisions neither tunnel through cover nor double-count one attack against the same target.
- Given Omega flight, protection and special powers, when comparing regressions, then the previously strong armor remains intact.

## Design Notes

Keep legacy identifiers if needed for save/test compatibility, but change player-facing names to energy. Use idle directional body frames with a small recoil/arm-energy effect instead of the disliked sword atlas. Native animated blue sphere drawing is preferable to a static raster projectile. Generated full-resolution sprites stay on disk; rendering uses a bounded logical size and the same barrel/grip geometry across code paths. Existing simple SVGs remain as historical source; active paths point to PNGs.

Snapshot for this request: `output/weapon-energy/baseline`. HEAD includes much older work; review only this request's localized delta. No commit of unrelated changes.

## Verification

Use tools/run_isolated_tests.ps1 with Godot console 4.7.2. Import new assets in an isolated project or bounded editor import before tests. Inspect rendered screenshots, not only dimensions. Check ammunition collection/cap/save, close-range hits, wall blocking, reflected projectiles, flight placement and Omega parameters. Report any unverified claim explicitly.

## Spec Change Log

- User authorized the complete weapon/combat presentation change; routine implementation choices proceed without an extra approval gate. New sprites generated before code integration and original images preserved.

## Review Outcome

Três revisões independentes concluídas. Corrigidos: contato da borda de esferas através de paredes finas, tamanho da faca/chave inglesa com arma HD equipada e atributo desatualizado do finalizador. Regressões adicionadas e aprovadas. Última rodada: weapon_energy, omega e run_weapons, sem falhas; logs em output/isolated-tests/1aa1468fe96a4ee2a185ba1b1efd601e. Outras suítes e limitação preexistente estão no relatório da entrega.

Sem commit automático: árvore contém alterações anteriores e simultâneas de outras frentes. Revisão usa snapshot localizado da solicitação. Spec sem story_key; sincronização de sprint não aplicável.

## Suggested Review Order

- Emissão pela mão conserva impacto e acrescenta esferas ao combo.
  [simulation.gd:1716](../../scripts/simulation.gd#L1716)

- Cobertura bloqueia inclusive o contato da borda das esferas.
  [simulation.gd:2351](../../scripts/simulation.gd#L2351)

- Arte compartilhada mantém armas coerentes na mão, no chão e na interface.
  [weapon_visuals.gd:4](../../scripts/weapon_visuals.gd#L4)

- Dimensões próprias preservam faca e chave inglesa com arma detalhada equipada.
  [world_view.gd:1283](../../scripts/world_view.gd#L1283)

- Regressões verificam munição, geometria, combo e cobertura.
  [weapon_energy_test.gd:1](../../tests/weapon_energy_test.gd#L1)

