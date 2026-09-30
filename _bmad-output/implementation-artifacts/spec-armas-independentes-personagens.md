---
title: 'Armas independentes do personagem'
type: 'bugfix'
created: '2026-09-30'
status: 'done'
baseline_commit: 'b87303df9bcf757214ccff66e57c4ae40ac1109c'
context: ['docs/SPRITE_POSE_STANDARD.md']
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Marty esconde a arma fora do disparo; a fusão não desenha a arma equipada. A aparência e o comportamento da arma dependem excessivamente da roupa, e a sobreposição não respeita as costas do personagem. O usuário quer carregar a mesma arma independentemente da forma, seguindo as referências visuais fornecidas de Enter the Gungeon.

**Approach:** Separar equipamento, corpo, empunhadura e efeitos. Manter arma visível em repouso e deslocamento, com mira independente, conexão à mão e ordenação frente/costas. Uma troca de personagem ou forma não deve substituir silenciosamente a seleção. Robôs podem conservar armamento integrado; não é obrigatório convertê-los para armas empunhadas.

## Boundaries & Constraints

**Always:** Trabalhar na main, preservar alterações paralelas e a identidade dos sprites aprovados. Usar os mesmos dados de empunhadura/cano para desenho e projéteis. Preservar munição, propriedade e seleção através das transformações e snapshots. Tratar as imagens como referência de comportamento, não como fonte de assets a copiar. A Ômega conserva seu ataque especial de espada, sem apagar a arma carregada.

**Ask First:** Mudanças em dano, progressão, desbloqueios ou substituição de identidade artística. Resolver sobreposição com trabalho paralelo antes de editar trechos conflitantes.

**Never:** Colar mãos do Marty sem armadura na Ômega; esconder a arma em repouso para disfarçar desalinhamento; aceitar testes de transparência como prova de empunhadura correta; declarar animações finais sem inspeção visual em movimento.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Carry | Arma equipada, parado ou andando | Arma permanece visível e conectada à mão | Ausência de pose usa guarda consistente, não origem na cintura |
| Aim | Mira para cima ou diagonal traseira | Arma passa atrás do corpo; cano continua legível quando exposto | Evitar arma inteira desenhada sobre as costas |
| Transform | Troca de roupa, fusão ou Ômega | Seleção e munição preservadas | Nenhuma conversão silenciosa da arma equipada |
| Robot | Entrar/sair de robô | Armamento integrado durante pilotagem; seleção anterior preservada | Não consumir munição da arma guardada |
| Ammo | Bazuca vazia | Equipamento permanece identificável; disparo bloqueado | Manter aviso e permitir troca |
| Save | Snapshot carregado | Mesmo equipamento e munição | Compatibilidade com saves sem campos novos |

</frozen-after-approval>

## Code Map

- `scripts/simulation.gd`: weapon_of, select_run_weapon, weapon_geometry e fire_actor; o ramo de combate Ômega atualmente força sword_attack.
- `scripts/world_view.gd`: draw_actor retorna após desenhar fusão sem arma; marty_padrao_shows_weapon restringe ao disparo; draw_weapon compartilha geometria mas não organiza todas as camadas.
- `scripts/combat_hud.gd`: rótulo de arma depende da roupa e precisa acompanhar o equipamento real.
- `scripts/main.gd`: seleção de arma local/remota delegada à simulação.
- `tests/run_weapons_test.gd`: propriedade, munição, snapshots e origem de foguetes.
- `tests/marty_actions_test.gd`: contratos antigos de visibilidade e âncoras deverão ser atualizados somente onde o requisito mudou.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/simulation.gd` — separar seleção de equipamento da forma e ajustar despacho de disparo/espada; manter compatibilidade de saves e rede.
- [x] `scripts/world_view.gd` — implementar desenho de arma atrás/corpo/arma à frente para humanos e fusão; eliminar desaparecimento no repouso; alinhar orientação corporal, mão e arma em movimento lateral.
- [x] `scripts/combat_hud.gd` e interface de seleção existente — refletir arma real sem depender do nome do uniforme.
- [x] `tests/run_weapons_test.gd` e teste específico de armas independentes — cobrir matriz, oito direções, troca de forma, munição e snapshots.
- [x] Preview de renderização — capturar arma com cada forma em repouso, deslocamento e disparo nas oito direções; revisar empunhadura e oclusão em tamanho real.

**Acceptance Criteria:**
- Given uma arma selecionada, when a forma muda, then o equipamento e sua munição não são substituídos pela roupa.
- Given corpo em deslocamento lateral, when a mira aponta para outro lado, then arma e mão permanecem conectadas sem atravessar o tronco.
- Given um disparo, when o projétil aparece, then sua posição visual coincide com a boca do cano renderizada, inclusive durante salto.
- Given o robô pilotado, when o jogador desembarca, then sua arma anterior volta sem perda de munição.

## Spec Change Log

- 2026-09-30: usuário aprovou a implementação e acrescentou verificar/corrigir a transformação distorcida, comparando com a versão anterior. Preservar a arte aprovada e a proporção original do efeito.

## Design Notes

Separar claramente estado de equipamento e arma temporária usada pelo ataque especial. Para a Ômega, ataque de espada não deve converter permanentemente a seleção do jogador. Animações de voo e espada continuam pendentes de revisão artística: não considerar deslocamento da imagem inteira como articulação dos pés, nem flexão repetida de joelhos como corte de samurai.

## Verification

- Executar Godot headless com `tests/run_weapons_test.gd`, testes de combate e testes novos de persistência/visibilidade; esperado zero falhas.
- Capturar preview com renderizador real, não headless sem imagem, e inspecionar frente, perfil e costas para todas as formas abrangidas.
- Comparar movimento com as referências fornecidas; registrar separadamente o que foi testado estruturalmente e o que foi verificado visualmente.

### Resultado de implementação e revisão

- Testes: `run_weapons_test`, `omega_test`, `marty_actions_test`, `independent_weapons_test`, `combat_framework_test`, `combat_regression_test`, `mission_inventory_ui_test`: zero falhas. O teste novo verifica 72 combinações de cano/direção/forma com salto, persistência, robô, migração e seleção com desbloqueio.
- Renderer OpenGL real: `tests/independent_weapons_preview.gd` gera 24 capturas (5 formas + transformação, 4 tempos), além de `equipment.png`, em `test-output/independent-weapons/`. Inspeção revelou âncoras antigas da Ômega baixas demais e da fusão altas demais; corrigidas. Tronco de mira separado da faixa inferior de corrida no Marty/fusão.
- Transformação: células originais são 271,5×724; o desenho antigo forçava 124×124. Preservada proporção, retirado progressivamente o corpo original e acrescentada transição para a forma atual. O histórico consultado já continha a compressão: não foi recuperada uma suposta versão anterior perfeita.
- Limitações artísticas: o atlas de montagem ainda mostra a armadura antiga mais alta; a transição suaviza, mas não recria sua identidade para o modelo compacto. Voo articulado da Ômega e redesenho do combo de espada não foram refeitos neste escopo e continuam pendentes, conforme Design Notes.
- Revisão independente: corrigidos dois achados pontuais — whitelist do convidado online em `scripts/main.gd` e comparação da bazuca contra `basic_weapon` em `scripts/equipment_screen.gd`. Teste de inventário ganhou regressão escopeta/roupa e passou novamente; teste independente reexecutado com zero falhas. Fluxo online revisado estaticamente, sem sessão de rede ponta a ponta.
- Sem commit: os arquivos compartilham alterações concorrentes anteriores, inclusive da forma azul, e não há baseline limpo por arquivo para separar tudo com segurança.

## Suggested Review Order

1. Seleção persistente: [simulation.gd](../../scripts/simulation.gd#L1048).
2. Corpo e camadas da arma: [world_view.gd](../../scripts/world_view.gd#L673).
3. Proporção da montagem: [world_view.gd](../../scripts/world_view.gd#L1555).
4. Seleção remota e comparação: [main.gd](../../scripts/main.gd#L318) e [equipment_screen.gd](../../scripts/equipment_screen.gd#L579).
5. Evidências: [teste de armas](../../tests/independent_weapons_test.gd) e [preview](../../tests/independent_weapons_preview.gd).
