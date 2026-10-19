---
title: 'Dez salas com identidade visual própria e acabamento das duas rotas'
type: feature
created: '2026-10-03'
status: done
context: []
---

## Intent

Concluir as dez salas pendentes, cada uma com tema e disposição distintos, preservando os cenários aprovados e a compatibilidade dos saves. A Adega deve mostrar com precisão as plataformas e canais definidos pela frente de mecânica.

## Resultado

| Sala | Identidade e circulação |
|---|---|
| Mercado | Três bancas, redes e piso molhado; passagens alternadas entre coberturas |
| Oficina | Bancadas, peças mecânicas e piso de madeira; área central de atendimento |
| Gerador | Duas bobinas de cobre iluminadas, circulação em torno das máquinas |
| Munição | Três ilhas de caixas militares e sacos de areia |
| Ferrovia | Vagões em dois desvios, trilhos e cruzamento central livre |
| Farol | Torre iluminada e rosa náutica no piso; circulação ao sul/leste |
| Doque | Casco em reparo e fosso inundado alinhado à pintura |
| Adega | Quatro bases, canais de 80 px e limite claro de aterrissagem |
| Contrabando | Cargas cobertas, madeira escura e luz verde |
| Antessala | Âncoras monumentais, bandeiras e bússola central |

Mangue preserva árvores/raízes externas, ganha solo contínuo e trilha de madeira. Ponte recebe madeira pintada, juntas por segmento e água coerente nos trechos desabados. Sua mecânica não foi alterada.

## Integração

- `scripts/scenarios/remaining_fixed.gd`: pinturas fixas, recortes medidos e colisões de objetos. Objetos mantêm escala uniforme; o espaço restante recebe material da própria imagem. Bordas são reconstruídas fora do piso para manter todas as portas nas posições físicas reais. A Adega reutiliza a arte das plataformas ajustada às bases de `CellarPlatforms`; não usa a geometria aproximada produzida pelo gerador.
- `scripts/simulation.gd`: instala somente em novas expedições fixas. Revisão 6 e `remaining_fixed_version=1` no manifesto. Reposiciona personagens, baús, armadilhas e pontos de interação que conflitariam com a nova cobertura.
- `scripts/world_view.gd`, `scripts/dock_scenery.gd`: desenho sem duplicar o Farol antigo ou obstáculos já pintados, preservando portões dinâmicos.
- `art/scenarios/scn-production/remaining-fixed-v01/manifest.json`: prompts, URLs e dez IDs reais de geração. Uma imagem por sala; estimativa total de 27,5 créditos. Nenhuma repetição de geração.
- `assets/environment/docks12/remaining_fixed_v01/`: dez imagens originais, 2048 × 2048.

## Verificação

- `remaining_fixed_test.gd`: 188 verificações, zero falhas; imagens, manifesto, colisões, portas nos dois sentidos com Marty/Titan, inimigos, baús, interações e snapshots.
- `cellar_platforms_test.gd`: 15 verificações, zero falhas; salto existente, canais, recuperação, coop e save.
- `all_corridors_finish_test.gd`: 18 ligações, 16 fragmentos externos, zero falhas.
- `route_p12_test.gd`: passou; travessia real, colapso, reinício, coop e saves legados.
- Capturas reais: `test-output/remaining-fixed-v01/`, incluindo visão geral das dez salas, duas rotas, detalhes e ponte desabada. Save real não gravado.

## Limites preservados

Saves antigos mantêm aparência e geometria anteriores. Usar uma nova expedição para ver as dez salas. Nenhum commit, push, agente adicional ou substituição das pinturas aprovadas. As alterações externas existentes foram preservadas. A revisão é local; não houve revisão por agentes adicionais.
