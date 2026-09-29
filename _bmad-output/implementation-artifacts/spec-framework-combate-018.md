---
title: 'Framework de combate 0.18 — ataques legíveis e esquadrões'
type: feature
created: 2026-09-28
status: done
baseline_commit: 809406b2f4dbca4a33d9535f8445f3ba78a88c75
context:
  - docs/architecture.md
  - docs/JOGABILIDADE_0_17.md
---

<frozen-after-approval reason="intenção do usuário">

## Intent

**Problema:** inimigos comuns atiram ao terminar um cooldown, sem aviso nem recuperação tática. As Docas sorteiam classes por ponto, impedindo combinações previsíveis de ameaças. O desafio depende mais de quantidade e atributos que de leitura e reação.

**Abordagem:** implementar um framework de combate com estados explícitos, projéteis configuráveis, grupos desenhados por sala e elites ocasionais. Manter os controles e os equipamentos existentes. O objetivo é tornar cada encontro mais variado e difícil, mas compreensível.

## Boundaries & Constraints

**Sempre:** preservar coop local, simulação autoritativa e snapshots online; usar RNG da expedição para variações reproduzíveis; manter Refúgio, Capela e labirinto sem encontros; respeitar colisões, portas e névoa. Avisos devem preceder dano e permanecer visíveis para todos os jogadores. Novos campos têm defaults. Mudanças locais alheias ficam preservadas.

**Consultar antes:** alterar controles, progressão permanente, quantidade de corações ou substituir os padrões completos do Warden e do Almirante.

**Nunca:** depender do renderer para simular dano, usar sorteio para substituir a composição básica dos esquadrões, transformar avisos em dano instantâneo ou fazer merge na main nesta tarefa.

## I/O & Edge-Case Matrix

| Cenário | Entrada/estado | Resultado esperado | Tratamento |
|---|---|---|---|
| Ataque comum | Alvo válido e vaga livre | aviso → ataque → recuperação | Alvo morto/inativo cancela aviso e libera vaga |
| Saturação | Três atacantes preparando/executando | Demais se reposicionam sem iniciar ataque | Vaga é liberada ao recuperar, morrer ou perder alvo |
| Cultista | Aviso concluído | Orbe divide em quatro após tempo definido | Impacto anterior cancela divisão; filhos não se dividem |
| Arpoador | Linha de mira travada | Arpão rápido deixa obstáculo temporário | Não criar sobre jogador, porta ou fora do piso |
| Soldado | Rajada encerrada | Procura sacos de areia e recarrega abaixado | Sem cobertura válida, recua e recarrega normalmente |
| Rastejante | Área marcada | Salta até destino válido e deixa ácido | Parede no percurso interrompe; não atravessa geometria |
| Mudança de modo | Retorno ao Refúgio | Limpa projéteis, riscos e obstáculos temporários | Nenhum efeito de combate sobrevive |
| Elite morta | Modificador explosivo | Aviso de explosão antes do dano | Resolve uma vez, inclusive mortes em cadeia |

</frozen-after-approval>

## Code Map

- `scripts/simulation.gd`: spawn_enemy, step_enemies, step_bullets, colisões, reset de modos e snapshots. Guard atualmente rebate em step_enemies; mover a decisão para a colisão do projétil evita atravessamento em alta velocidade.
- `scripts/world_view.gd`: leitura do estado para linhas, círculos, poses, projéteis e riscos temporários.
- `tools/build_docks_map.py`: fonte dos pontos de encontro e reforços. Hoje grava grupos e simulation sorteia classes.
- `scripts/docks_map.gd`: arquivo gerado, nunca editar isoladamente.
- `tests/new_enemies_test.gd`, `tests/enemies_test.gd`: compatibilidade de Bomber, Guard e boss.

## Tasks & Acceptance

**Execução:**
- [x] `scripts/simulation.gd`: adicionar parâmetros de aviso/ataque/recuperação por classe e reserva de ataque por alvo. Começar com limite três por jogador; inimigos em recuperação não ocupam vaga. Morte e cancelamento liberam imediatamente.
- [x] `scripts/simulation.gd`: implementar strafe, recuo e busca de cobertura para recuperação. Bomber terá fusível anunciado; Guard fará ataque anunciado mantendo defesa frontal; pequenos rastejantes terão bote curto. Preservar ciclos próprios de boss/miniboss.
- [x] `scripts/simulation.gd`: projéteis com idade, curvatura, aceleração limitada, divisão única, trajetória em arco e depósito de rastro. Processar filhos após iteração; projéteis expirados não causam dano. Riscos têm duração finita, limite de quantidade e colisão justa.
- [x] `scripts/simulation.gd`: Cultista usa orbe dividido; Arpoador usa mira fixa e arpão cravado; Soldado dispara leque sequencial; Rastejante salta e deixa ácido. Integrar curva/aceleração aos tiros e arco à ameaça de área, com sinalização correspondente.
- [x] `tools/build_docks_map.py` e mapa gerado: definir classes explícitas por sala/reforço, incluindo Bomber e Guard. Garantir combinações de pressão, suporte e flanco; preservar posições validadas e salas seguras.
- [x] `scripts/simulation.gd` e `scripts/world_view.gd`: elites com exatamente um modificador — escudo frontal, rastro ou explosão ao morrer — anunciado por símbolo/cor distintos. Distribuição ocasional determinística, fora da entrada e das salas seguras; sem aplicar a boss, Warden ou pequenos gerados por divisão.
- [x] `scripts/world_view.gd`: desenhar avisos, recuperação abaixada, altura do salto/arco, ácido e arpão cravado. Hitbox permanece no plano do chão e avisos contrastam com o cenário.
- [x] `tests/combat_framework_test.gd`: cobrir matriz, reserva simultânea, divisão única, curva/aceleração, arco sem dano antecipado, limpeza, elites e round-trip de snapshots.
- [x] `docs/COMBATE_0_18.md`: documentar parâmetros, padrões, esquadrões e roteiro de teste.

**Critérios de aceite:**
- Dado inimigo pronto, quando recebe vaga, então anuncia por pelo menos 0,45 s antes de atacar; a mira fica travada no fim do aviso.
- Dado encontro saturado, quando atacantes recuperam ou morrem, então vagas circulam sem bloquear os demais indefinidamente.
- Dado Soldado recuperando, quando existe cobertura alcançável, então se move para o lado protegido e mostra pose abaixada; sem cobertura não fica preso.
- Dada a mesma seed, quando se inicia duas expedições, então esquadrões e modificadores coincidem.
- Dado snapshot durante salto/aviso/risco, quando aplicado em outro simulador, então estados, destino e duração são preservados.

## Spec Change Log

## Design Notes

Manter a lógica em Expedition, com helpers pequenos e dados em dicionários conforme o projeto. Campos temporários devem entrar no snapshot e em todos os resets. Não inserir arpões na geometria permanente: usar coleção temporária consultada pela colisão, evitando desalinhamento entre obstacle_kinds e obstacle_hp. Limitar tempo de vida evita bloquear permanentemente passagens estreitas. Dano de área deve respeitar paredes e invulnerabilidade existente.

## Verification

- Executar `python tools/build_docks_map.py`: validação de alcance, portas e rota do Titan sem falhas.
- Executar Godot headless com cada `tests/*_test.gd`: saída zero e nenhuma falha/script error.
- Capturar um encontro de cada classe, avisos, cobertura e elites; conferir contraste no zoom padrão.
- Testar solo e coop local; verificar sincronização por snapshot automatizado. Informar separadamente se partida online real não for exercitada.

## Complemento aprovado pelo usuário (2026-09-28)

Aumentar discretamente personagens, inimigos e projéteis em relação ao cenário. Usar cerca de 12% para corpos e 15% para balas, mantendo hitboxes justas, armas e mãos alinhadas. Diferenciar movimentação por classe, incluindo recuperação. Não aumentar cenário nem zoom como substituto.




## Revisão em 2026-09-28

Uma revisão independente encontrou três correções pontuais: salto não entra em salas seguras, cancelamento limpa altura visual e ácido respeita damage_scale. Corrigidas e cobertas por quatro novas verificações (27 checks no teste do framework). Testes enemies, new_enemies e update_017 reexecutados sem falhas. As revisões independentes de casos extremos e aceite falharam por limite de uso; prompts preservados em review-combat018-edge.md e review-combat018-acceptance.md. Status permanece in-review; sem commit desta tarefa até fechar a revisão.

## Fechamento da revisão

As duas revisões restantes foram concluídas. Correções pontuais: validar alvo reservado também durante ataque em coop e incluir percurso até cobertura no tempo de recuperação do Soldado. Testes novos confirmam ambos. Não houve mudança de escopo.

## Suggested Review Order

- Estados e reservas de ataque.
  [simulation.gd](../../scripts/simulation.gd#L1606)
- Projéteis e riscos temporários.
  [simulation.gd](../../scripts/simulation.gd#L1212)
- Escala corporal e avisos visuais.
  [world_view.gd](../../scripts/world_view.gd#L307)
- Regressões do combate.
  [combat_framework_test.gd](../../tests/combat_framework_test.gd#L1)
