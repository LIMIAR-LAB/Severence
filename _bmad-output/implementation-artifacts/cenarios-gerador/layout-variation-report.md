# Variação estrutural — correção após teste do usuário

API opcional: `generate_layout(seed, rooms, edges, {"variable_topology":true})`. Chamadas anteriores permanecem no modo completo. Novo manifesto `scn-layout-2`, `topology=seeded-walk-tree-with-loops`, `dropped_edges`. Não altera interiores, escala, orientação ou âncoras recebidas (entry/chapel/boss).

Seleciona árvore de conexões walk com ordem seeded e até um loop opcional, deixando ao menos uma ligação removível de fora. Preserva secret, os dois shortcuts e corridor-07/08 consumidos pelos gates atuais. Shortcuts e corridor-07/08 não participam da árvore obrigatória: ambos os gates começam bloqueados (sealed=false). A árvore mantém acesso a todas as salas não secretas mesmo com ambos fechados. Varia ordem de crescimento das salas, preferência de pais e espaçamento de 800 a 5200 unidades; isso muda ramos, comprimentos e silhueta, mantendo as portas autoradas. Não inventa novos conectores nem reconecta pares ausentes da entrada.

`caps_needed` informa posição mundial, normal, largura e altura além de room/connector_id/type. O consumidor deve fechar essas portas em geometria/rendering e desenhar extensões do Farol apenas nas portas utilizadas. Sem esse consumo, esta entrega isolada não é um mapa corretamente fechado.

Teste real limitado após correção dos gates: seeds 1941 e 42, ambas 14 salas/18 arestas/2 caps, 1 e 2 tentativas, 84 e 167ms. Removida 1941: corridor-09; removida 42: corridor-01. Treze salas não secretas conectadas por walk sem atalhos nem gates07/08, conexões obrigatórias preservadas, caps completos, reservas sem sobreposição e nenhum cruzamento entre corredores de arestas diferentes. Âncoras preservadas; entradas reordenadas retornam resultado idêntico; rotação e ocupação impossível falham atomicamente. O teste anterior de15arestas foi superado: contava gates inicialmente bloqueados como árvore e causava dependência circular para side.

Evidências: layout-variation-tests.json, layout-variation-current.json (1941), layout-variation-1941.svg/png e layout-variation-42.svg/png. Imagens inspecionadas: primeira silhueta mais horizontal; segunda mais vertical, rotas e ligação removida diferentes. Amostras usam enquadramento automático próprio, portanto comparar tamanhos absolutos exige coordenadas SVG. Relatório anterior de 35 seeds se refere ao modo antigo e não comprova confiabilidade deste modo.

Runtime/aceite visual final pertencem ao coordenador. Nenhum arquivo runtime editado, nenhum novo agente e nenhuma bateria ampla repetida.

