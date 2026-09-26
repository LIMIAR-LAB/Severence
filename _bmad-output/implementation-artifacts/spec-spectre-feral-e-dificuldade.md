---
title: 'Equipamento, Spectre feral e dificuldade'
type: 'feature'
created: '2026-09-26'
status: 'in-progress'
baseline_commit: 'NO_VCS'
context: ['{project-root}/docs/architecture.md']
---

<frozen-after-approval reason="human-owned intent">

## Intent

**Problem:** Armadura e uniforme disputam o mesmo painel de descrição; Spectre parece um drone e sua fusão não tem identidade animal. A primeira sala é pouco ameaçadora e tiros removem menos de um coração.

**Approach:** Separar descrições, redesenhar companheiro/fusão e adicionar um elite veloz no desembarque, seguido do aumento geral da dificuldade, na sequência solicitada.

## Boundaries & Constraints

**Always:** Preservar solo, IA, coop e autoridade do anfitrião; três uniformes com armas/atributos, Ômega temporária e controles existentes. Manter invulnerabilidade de dash, salto, transformação e intervalo entre danos. Preservar arquivos anteriores.

**Ask First:** Remover armas ou substituir progressão permanente e sistema de armaduras.

**Never:** Apagar trabalho local, embutir credenciais, exigir API para jogar ou permitir dano/movimento através de paredes.

## I/O & Edge-Case Matrix

| Estado / entrada | Resultado | Limite |
|---|---|---|
| Alternar uniforme/armadura | Painéis separados e persistentes | Sem sobreposição de texto |
| Invocar/fundir/separar | Animal ao lado; simbionte em Marty; restauração do uniforme | Sem duplicação ou cura grátis |
| Fundir com Ômega ativa | Recusar com mensagem | Não consumir recurso |
| Projétil contra Marty | Piso líquido de vida máxima/8 após resistência | Respeitar invulnerabilidade |
| Tiro contra Titan/fusão | Drenar integridade/energia primeiro | Excedente da fusão atinge Marty |
| Elite investindo | Aviso, direção travada, colisão e recuperação | Não atravessar obstáculos |

</frozen-after-approval>

## Code Map

- `scripts/terminal_ui.gd`: montagem do equipamento e descrições por último clique.
- `scripts/simulation.gd`: atributos, dano, IA, fusão e snapshots.
- `scripts/docks_map.gd`: primeira sala 1200×800, chegada (700,4750).
- `scripts/world_view.gd`: animação e profundidade de atores/inimigos.
- `scripts/combat_hud.gd`: oito corações normalizados pela vida máxima.

## Tasks & Acceptance

**Execution:**
- [ ] `scripts/terminal_ui.gd`: áreas permanentes de uniforme/arma, armadura temporária e companheiro; preview do selecionado. Uniformes possuem atributos e não serão descritos como cosméticos puros.
- [ ] `art/source/spectre-feral-prompts.txt`, `assets/mech/spectre-feral.png`, `assets/marty/spectre-fusion.png`: sprites de repouso, movimento e ataque em quatro direções. Spectre predador baixo, mandíbula, garras e tendrilos; negro/violeta com energia ciano. Fusão bípede animalesca, maior que Marty, com detalhes dos óculos; inspiração simbionte Venom/Carnificina.
- [ ] `scripts/world_view.gd`: integrar sprites da criatura e fusão, com pivô nos pés, salto, direção e dano; atualizar miniaturas e transição sem desenhar Marty duplicado.
- [ ] `scripts/simulation.gd`: piso de dano de projétil inimigo após mitigação, igual à vida máxima/8. Não aplicar inadvertidamente a melee/ambiente. Atualizar textos de resistência. Comuns: +25% HP, +20% perseguição, −15% recarga, conservando lacunas esquiváveis.
- [ ] `scripts/docks_map.gd`, `scripts/simulation.gd`, `scripts/world_view.gd`, `assets/enemies/warden.png`: elite “Cão de Guerra”, autômato quadrúpede corrompido, cerca de três vezes a altura de Marty; 420 HP, perseguição 300 px/s, investida 850 px/s. Aviso 0,55s, investida até 0,4s, recuperação 0,9s. Um por expedição, posição livre a pelo menos 500 px da chegada, ativação por visão. Não compartilha recompensa/extração do chefe final.
- [ ] `tests/hard_mode_test.gd`, `tests/solo_robot_test.gd`: piso de dano com uniformes/Ômega/upgrades, absorção, fusão, elite único, colisão e sincronização. Atualizar expectativas antigas somente onde houve alteração intencional.
- [ ] `docs/COMBAT_FERAL.md`: controles, números, fontes de arte e limitações.

**Acceptance Criteria:**
- Given uniforme selecionado, when clicar em Ômega, then ambas as descrições continuam visíveis em áreas exclusivas.
- Given Spectre invocado, when fundir, mover, saltar, atacar e separar, then forma e direção acompanham a ação, restaurando o uniforme e preservando energia.
- Given vida máxima 100 ou 130, when um tiro válido atingir Marty, then o dano após resistência é pelo menos 12,5 ou 16,25 HP; recursos de Titan/fusão continuam absorvendo impactos.
- Given qualquer seed, when iniciar expedição, then existe exatamente um elite no desembarque; seu ataque é antecipado, bloqueado por cobertura e seguido por recuperação.

## Spec Change Log

## Design Notes

O HUD tem oito corações mesmo com upgrades. Portanto, um valor fixo de 12,5 deixaria de equivaler a um coração ao aumentar a vida máxima. A velocidade extrema do elite exige aviso e pausa para permitir reação. A arte e o sistema de refúgio existentes permanecem neste escopo.

## Verification

Importar com Godot headless; executar testes afetados e integração ENet local. Capturar equipamento, Spectre, fusão e elite em aviso/ataque. Conferir legibilidade, pés, escala e colisões. Teste local não comprova conectividade pela internet.
