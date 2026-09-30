---
title: SCN-04.03–07 layout procedural de Docas
status: implemented-awaiting-coordinator-acceptance
updated: 2026-09-30
---

A redução anterior foi explicitamente revogada; escopo completo retomado pelo coordenador. Edições desta frente limitadas a tools/scenarios/prototype, tests/scenarios_prototype e esta pasta de evidências. Runtime, catálogo e histórias pertencem ao coordenador. Sem novos agentes.

Entrega: generate_layout(seed_value, input_rooms, input_edges) retorna origens, corredores Rect2, portas e manifesto, ou erro estruturado sem layout parcial. Usa os contratos e templates reais recebidos de ProceduralDocks.inputs(sim), preservando identidade e metadados de todas as 14 salas/19 arestas. Colocação por translação, âncoras fixas, reservas conservadoras de footprint/layers/art_bounds e roteamento ortogonal limitado. Walk 200; atalhos explicitamente selecionados com garganta 128; caps/gates necessários declarados no manifesto.

Aceite local: cinco seeds reais em dois processos, cinco disposições distintas, hashes idênticos, zero falhas; ver layout-report.md. PNG/SVG de ocupação e manifestação serializada da seed 1941 preservados. Fixtures dedicadas L/T e demonstração universal de navegação não são alegadas. Integração seed1941 aprovada segundo relato do coordenador; aceite em jogo e conclusão SCN04.03–07 cabem a ele.
