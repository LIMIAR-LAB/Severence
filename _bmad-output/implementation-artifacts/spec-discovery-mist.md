---
title: 'Névoa nas transições de descoberta'
type: 'bugfix'
created: '2026-10-04'
status: 'in-progress'
context: []
baseline_commit: '87fe42e55592e2d8944b94ec8e17429994c312af'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** A captura do usuário mostra um encontro abrupto entre o deque detalhado do corredor e um piso genérico azul de sala ainda não descoberta. O retângulo de textura e o vazio preto expõem a montagem do cenário.

**Approach:** Ocultar o piso provisório indevidamente exposto e criar uma névoa marítima azul-acinzentada, irregular e discretamente animada, que suavize a passagem para áreas desconhecidas e se dissipe ao descobri-las. Preservar as pinturas autorais existentes.

## Boundaries & Constraints

**Always:** Manter geometria, colisões, progressão de descoberta, save, segredos e força do Omega. Preservar os trabalhos simultâneos do repositório. Névoa deve permanecer abaixo de personagens, projéteis e HUD; passagens e perigos precisam continuar legíveis. Reutilizar o estado de descoberta existente e recortar trabalho à câmera. A autorização do usuário cobre implementação e ajustes visuais reversíveis.

**Ask First:** Somente ampliação para trocar o estilo artístico inteiro ou mudar regras de exploração; não é necessário para esta implementação.

**Never:** Revelar inimigos ou segredos por conveniência visual; pintar piso transitável fictício sobre água ou paredes; aplicar filtro opaco sobre toda a tela; sobrescrever alterações alheias ou regenerar pinturas de salas.

## I/O & Edge-Case Matrix

| Cenário | Entrada / estado | Resultado esperado | Tratamento |
|---|---|---|---|
| Corredor para sala desconhecida | Só origem visitada | Piso provisório da sala não aparece inteiro; entrada se perde em névoa suave | Limitar máscara e desenho à geometria real |
| Descoberta | Destino entra em visited | Arte autoral aparece com dissipação contínua, sem retângulo piscando | Tempo reiniciado não deixa máscara permanente |
| Retorno | Duas salas já visitadas | Caminho permanece visível, sem nevoeiro forte de descoberta | Não regredir descoberta |
| Geometria recortada | Corredores fragmentados, alas e cruzamentos | Sem frestas duras ou pisos sobre água; passagens continuam completas | Usar geometria materializada |
| Conteúdo oculto | Segredo fechado, inimigo distante | Mesma elegibilidade de conteúdo anterior | Não ampliar vis_floors para efeito |
| Outro modo | Refúgio / arena | Sem névoa de exploração indevida | Ignorar modo fora da expedição |

</frozen-after-approval>

## Code Map

- `scripts/dock_scenery.gd` — `visible_floors` inclui retângulos inteiros por interseção com corredor; `draw_floors` pode pintar fallback sem sala descoberta; `draw_reveal` hoje desenha retângulo preto por 0,5 s.
- `scripts/world_view.gd` — `draw_expedition_ground` ordena pinturas, deques e decoração; chamada final de `draw_reveal` fica antes das entidades. `seen` depende de `vis_floors`.
- `scripts/scenarios/corridor_art.gd` — rotas, recortes, materiais e superfícies reais; os deques detalhados usam `transition_v02/timber.png` e são desenhados após salas.
- `tests/corridor_visibility_test.gd` — contrato: pisos retornados pertencem a sim.floors e não desaparecem durante exploração rumo ao norte.
- `tests/scenarios_base/corridor_finish_test.gd` — travessia e água lateral continuam intransitáveis.
- `output/discovery-mist/baseline/` — cópia dos três fontes acima antes desta implementação, com `.gdignore`; estado local já difere de HEAD.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/dock_scenery.gd` — separar cobertura visual do fallback e descoberta lógica, evitando pintar a sala inteira apenas porque toca um corredor — eliminar a causa do piso azul exposto.
- [x] `scripts/world_view.gd` e helper/shader localizado se útil — integrar máscara atmosférica irregular sob gameplay com dissipação ao descobrir — suavizar corte espacial e temporal.
- [x] `tests/discovery_mist_test.gd` — verificar casos da matriz, limites de visibilidade e reset — proteger descoberta sem testes que apenas repetem implementação.
- [x] `tests/discovery_mist_preview.gd` — capturar entrada desconhecida, descoberta e retorno em orientação vertical e horizontal — comprovar resultado visual real.

**Acceptance Criteria:**
- Na aproximação pelo corredor norte do desembarque, a troca brusca entre madeira detalhada e piso azul não é visível como um retângulo recortado.
- Névoa tem borda orgânica e movimento lento; não parece círculos sobrepostos, listras ou gradiente retangular.
- Nenhuma alteração de combate, movimento, descoberta persistida ou HUD é necessária para o efeito.

## Spec Change Log

- Revisão independente: transições sem sobreposição positiva não tinham névoa; áreas da pintura fora do corredor surgiam imediatamente; culling era menor que nuvens. Acrescentada cobertura orgânica de toda a sala/alas recém-descobertas e faixa nas entradas adjacentes; margem ampliada a 360. KEEP: visibilidade lógica, colisões e névoa aprovada ao norte. Testes agora exigem alpha positivo decrescente, cobertura interior/ala e entrada horizontal contígua.

## Design Notes

A raiz é dupla: descoberta em blocos inteiros e materiais diferentes em camadas. `visible_floors` também governa entidades; alterar seu contrato indiscriminadamente pode causar regressão. Preferir uma cobertura de desenho separada ou máscara segura que esconda fallback, sem aumentar conteúdo descoberto. Dissolução orgânica pode usar ruído de baixa frequência em coordenadas do mundo, limitada à fronteira; cachear geometria de máscara quando descoberta/geometria mudarem, animando apenas parâmetros. A escolha final do helper/shader é da implementação.

Na reprodução inicial, usar seed 1941, ator próximo de `(1000, 5650)` olhando para norte; comparar também `(1000, 5450)` e avançar até encontrar a entrada materializada da capela. Rotas mudam com cenários fixos: derivar os pontos finais de `run_corridors`/`sim.floors` em vez de assumir que o retângulo legado termina na pintura. Para orientação horizontal, usar rota entre desembarque e guindastes, aproximadamente `(2350,6500)`, ajustando aos recortes atuais.

## Verification

**Commands:**
- Executar pelo `tools/run_isolated_tests.ps1` os testes novos e `tests/corridor_visibility_test.gd`, `tests/scenarios_base/corridor_finish_test.gd`, `tests/scenarios_base/all_corridors_finish_test.gd` — esperado: zero falhas e dados do usuário preservados.
- Capturar a prévia com Godot gráfico em projeto/dados isolados — esperado: PNGs reais em `output/discovery-mist/captures`, sem erros de shader ou execução.

**Inspeção visual:** Conferir a aproximação desconhecida, dissipação intermediária, destino conhecido e retorno; personagem e HUD nítidos em todos. Medir custo do efeito ou ao menos comprovar que nenhuma geração de textura/máscara extensa ocorre por quadro.

## Implementation evidence

- Sources changed: dock_scenery.gd and discovery_mist.gd; world_view and corridor_art unchanged.
- GPU captures: output/discovery-mist/captures/before-north-frontier.png and after-north-frontier.png, plus unknown/known/reveal and east connection. Preview forces camera update and redraw before capture.
- Isolated discovery_mist, corridor_visibility, corridor_finish and all_corridors_finish passed (zero failures). Logs: output/isolated-tests/f29e8cb9bcbe437dae867070dc1fecf6. Full traversal checked 16 fragments and 18 routes.
- New mist caches one 192×192 procedural texture; only visible overlaps draw. Logical discovery/seen untouched.
- Scoped review diff: output/discovery-mist/scoped.diff. No commit.

## Review Outcome

Três revisões independentes concluídas. Corrigidos cobertura da revelação em toda a pintura e alas, entradas que apenas encostam no corredor e margem de culling. Rechecagem de aceite sem novos achados. Quatro suítes aprovadas na rodada final em output/isolated-tests/909e5032a7564383a655ff5a39cc1b00. Capturas GPU inspecionadas. Nenhum commit automático devido a trabalhos anteriores/simultâneos; spec livre sem story_key.

## Suggested Review Order

- Névoa fica abaixo das entidades e substitui o retângulo preto.
  [dock_scenery.gd:324](../../scripts/dock_scenery.gd#L324)

- Revelação inclui pintura completa e alas, com dissipação suave.
  [discovery_mist.gd:41](../../scripts/discovery_mist.gd#L41)

- Fronteiras incluem entradas encostadas, preservando visibilidade lógica.
  [discovery_mist.gd:60](../../scripts/discovery_mist.gd#L60)

- Regressões cobrem descoberta, reinício e geometrias das entradas.
  [discovery_mist_test.gd:1](../../tests/discovery_mist_test.gd#L1)

