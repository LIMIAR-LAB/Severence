---
title: 'Acabamento dos corredores entre cenários'
type: bugfix
created: '2026-10-03'
status: done
baseline_commit: 87fe42e
context: []
---

<frozen-after-approval>
## Intent

Corrigir o acabamento dos corredores antes da próxima sala, conforme pedido direto do usuário. As capturas atuais mostram fundo preto, materiais repetidos e pilares genéricos sobre entradas já pintadas.

## Boundaries & Constraints

Preservar pinturas, alterações externas, colisões e progresso. Reutilizar materiais existentes sem geração paga. Trabalho focal, sem agentes adicionais, commits ou testes amplos.
</frozen-after-approval>

## Code Map

- `scripts/scenarios/corridor_art.gd`: água exterior e bordas do cais.
- `scripts/world_view.gd`: ordem de desenho e portões das salas pintadas.
- `scripts/dock_scenery.gd`: transição desenhada uma única vez.

## Tasks & Acceptance

- [x] Restaurar entorno aquático usando somente amostra de água, sem desenhar chão falso.
- [x] Dar volume às bordas sem ocupar a passagem.
- [x] Remover duplicação de transições e pilares sobre entradas já pintadas.
- [x] Capturar quatro junções e executar testes focais existentes.

Dado um corredor descoberto, ao atravessá-lo e retornar, seu piso permanece visível e caminhável. Dadas entradas pintadas, ao abrir o portão, não aparecem pilares genéricos duplicados. Dado um portão trancado, a barreira continua visível. Dado o save real, os testes não alteram seu conteúdo.

## Verification

Capturas Godot antes/depois; `tests/scenarios_base/corridor_finish_test.gd` e `tests/corridor_visibility_test.gd`. Revisão local do desenho, descoberta e limite entre água e piso.

Resultado: ambos os testes passaram com zero falhas. O teste de travessia verifica os dois sentidos com raios 11 e 23 e confirma hash do save inalterado. Capturas reais de quatro junções em `test-output/corridors-review-before/` e `test-output/corridors-review-after/`; execução gráfica sem erros. Nenhuma geração, alteração de geometria ou commit. Revisão local confirmou que o fundo usa apenas água, preserva limites autorais e não altera pisos ou descoberta. Barreiras trancadas continuam usando o desenho dinâmico existente.

## Suggested Review Order

### Correção de cobertura após retorno do usuário

A revisão anterior de quatro junções não cobria toda a malha. Agora foram capturadas 35 posições ao longo das 18 ligações (15 normais, uma secreta e dois atalhos), incluindo trechos longos. Identificados e corrigidos: fundo ausente na passagem secreta, atalhos recortados ainda classificados como sala e descoberta dos fragmentos de atalhos. Piso, bordas e fundo passam a usar a mesma lista de corredores materializados. A passagem secreta continua excluída antes de abrir.

O novo `all_corridors_finish_test.gd` passou: 18 rotas consideradas, 16 fragmentos não cobertos por pinturas verificados, classificação e presença do fundo, travessia nos dois sentidos com raios 11/23, save inalterado. Os testes anteriores de visibilidade e travessia também passaram. Capturas completas: `test-output/corridors-all-after/overview.png` e 35 imagens individuais. O modo `--all` da ferramenta de captura abre atalhos e segredo apenas na simulação temporária, sem gravar o save.

- Água e bordas fora da passagem: [corridor_art.gd](../../scripts/scenarios/corridor_art.gd).
- Fundo antes das salas e portões pintados: [world_view.gd](../../scripts/world_view.gd).
- Junções desenhadas apenas uma vez: [dock_scenery.gd](../../scripts/dock_scenery.gd).
- Evidência visual: [captura norte dos guindastes](../../test-output/corridors-review-after/cranes-north.png).
