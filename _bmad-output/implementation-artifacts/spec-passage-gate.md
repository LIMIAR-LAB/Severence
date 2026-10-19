---
title: 'Continuidade da passagem da capela e barreira de ferro'
type: bugfix
created: '2026-10-04'
status: done
baseline_commit: '87fe42e55592e2d8944b94ec8e17429994c312af'
context: []
---

<frozen-after-approval reason="Solicitação direta do usuário para corrigir passagem e refazer barreira">

## Intent

**Problem:** A saída leste da capela parece terminar no vazio antes de revelar o Farol; a barreira de combate usa retângulos marrons provisórios que destoam da arte.

**Approach:** Verificar a continuidade real e mostrar um pequeno trecho do piso verdadeiro da próxima área sob a névoa, sem revelar seu conteúdo. Substituir a barreira provisória por arte de ferro ornamentada, com transparência e escala consistente.

## Boundaries & Constraints

**Always:** Concluir a implementação da névoa antes de integrar esta etapa. Preservar colisões, gatilhos de descoberta, combate, saves, força do Omega e alterações anteriores. Conservar passagem livre quando aberta e bloqueio quando fechada. Representar apenas chão realmente transitável, respeitando paredes e fossos.

**Ask First:** Mudanças nas regras de progressão ou publicação remota.

**Never:** Revelar inimigos, tesouros ou segredos para melhorar a aparência; inventar piso navegável sobre água; trocar pinturas completas das salas; alterar o save real para preparar capturas.

## I/O & Edge-Case Matrix

| Situação | Estado | Resultado |
|---|---|---|
| Aproximação | Capela conhecida, Farol oculto | Continuação curta do piso correto some na névoa |
| Travessia | Porta aberta | Marty e robô atravessam em ambos sentidos |
| Bloqueio | Combate ativo | Grade detalhada cobre a mesma barreira física |
| Liberação | Combate encerrado | Grade some, caminho legível |
| Outro eixo | Porta horizontal ou vertical | Mesma arte ajustada sem dimensões gigantes |
| Área perigosa | Parede, fosso, segredo | Nenhum piso fictício ou conteúdo antecipado |

</frozen-after-approval>

## Code Map

- `scripts/scenarios/sanctuary_fixed.gd`: saída leste autoral, limite em x1700.
- `scripts/scenarios/corridor_art.gd`: ligação até o Farol, termina na borda x1800.
- `scripts/scenarios/remaining_fixed.gd`: desenho do Farol condicionado à descoberta; amostra do material verdadeiro.
- `scripts/scenarios/cranes_painting.gd`: função gate compartilhada pelos cenários fixos desenha retângulos marrons.
- `scripts/discovery_mist.gd`: névoa de fronteira, integrar sem alterar descoberta.

## Tasks & Acceptance

- [x] `scripts/scenarios/remaining_fixed.gd` e helper localizado: desenhar aproximação curta do piso físico da sala não visitada apenas junto de corredor visível; manter restante oculto.
- [x] `assets/environment/docks12/gates/iron_gate_hd.png`, helper e `scripts/scenarios/cranes_painting.gd`: integrar arte gerada com alpha, recorte de margens em runtime e dimensões ligadas à porta.
- [x] `tests/passage_gate_test.gd`: testar continuidade física, ausência de pistas fora do piso, estado fechado/aberto e orientação da arte.
- [x] `tests/passage_gate_preview.gd`: capturas reais da saída da capela antes/depois de descoberta e da grade fechada/aberta.

**Acceptance:** Dada a saída conhecida, ao aproximar-se da próxima sala, a passagem deve continuar visualmente até desaparecer na névoa. Dada uma porta fechada, ao desenhar a cena, deve aparecer uma grade detalhada no local da colisão. Dada a porta aberta, ao atravessar, não deve restar bloqueio nem grade fechada. Dado conteúdo oculto, ao desenhar a aproximação, apenas o piso necessário deve aparecer.

## Design Notes

Piso da próxima sala precisa ser uma prévia puramente visual, limitada à largura da conexão e a uma distância curta; não acrescentar retângulos a sim.floors ou vis_floors. Reusar material_fill da sala evita criar um terceiro tipo de piso. Recortar por piso, obstáculos e gaps. A névoa desenvolvida anteriormente cobre a borda final; eventual ajuste deve preservar o comportamento já aprovado nas capturas norte. A arte da grade vem de image_gen, com fonte original preservada; não editar PNG por código. Snapshot localizado em output/passage-gate/baseline.

## Verification

Testes via tools/run_isolated_tests.ps1, Godot 4.7.2, dados isolados antes dos autoloads. Reexecutar regressões de corredores e névoa após integração. Capturas GPU com câmera atualizada antes do culling. Inspecionar dimensões da grade e clareza do personagem. Revisão independente localizada; nenhum commit que inclua trabalho alheio.

## Spec Change Log

- Escopo adicional solicitado pelo usuário durante conclusão da névoa, executado em sequência.


## Verification evidence

- Five isolated suites passed: passage_gate, discovery_mist, corridor_visibility, corridor_finish, all_corridors_finish. Logs: output/isolated-tests/cf8ff1d4980148378de87635a520df05.
- GPU captures before/after in output/passage-gate/captures. Closed-known, open-known and horizontal closed gate included. Final stderr empty.
- Collision traversal tested both directions at radii 11 and 23; locked gate blocks entrance. Preview bounded to220 units, clipped to actual floors minus obstacles/gaps, does not alter discovery.
- Gate uses generated image with runtime atlas Rect2(6,150,2160,370), no raster editing; fallback loads rawPNG on first run before Godot import.
- Review diff output/passage-gate/scoped.diff. No commit.

## Review Outcome

Revisões independentes blind e edge concluídas; auditoria de aceite realizada pelo agente principal após limite de agentes impedir terceiro revisor independente. Corrigidos: elegibilidade da extremidade específica, fallback de textura ausente, teste dos pixels reais, contraste da grade e tratamento de falhas/caminho configurável nas capturas. Rodada final passage_gate + discovery_mist sem falhas (34f937451a1e4baaaf78d8b43aa446cc); captura GPU exit0 e stderr vazio. Nenhum commit automático por árvore com trabalhos anteriores/simultâneos; sem story_key, sincronização de sprint não aplicável.

## Suggested Review Order

- Integra prévia do piso antes de revelar a próxima sala.
  [remaining_fixed.gd:142](../../scripts/scenarios/remaining_fixed.gd#L142)

- Restringe continuidade visual à extremidade visível e à geometria real.
  [passage_preview.gd:5](../../scripts/scenarios/passage_preview.gd#L5)

- Desenha grade detalhada apenas enquanto o bloqueio está fechado.
  [iron_gate_art.gd:22](../../scripts/scenarios/iron_gate_art.gd#L22)

- Valida travessia, bloqueio, ausência de spoilers e pixels da nova arte.
  [passage_gate_test.gd:10](../../tests/passage_gate_test.gd#L10)

