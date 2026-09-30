---
stepsCompleted: [1, 2, 3, 4, 5, 6]
scope: SCN-01 readiness; later waves retain their gates
---
# Prontidão dos cenários — 30/09/2026

Fonte selecionada pela execução autorizada: epics-cenarios.md e stories-cenarios; docs/ARQUITETURA_ROGUELIKE.md prevalece sobre arquitetura histórica. Não há GDD/UX formal separado desta fase. Os requisitos explícitos SCN substituem essa fonte na revisão limitada. epics.md é complementar (run/meta), não duplicata a apagar.

## Inventário e alinhamento

- Arquitetura: docs/ARQUITETURA_ROGUELIKE.md; docs/architecture.md (histórico).
- Requisitos e experiência: epics-cenarios.md, docs/PLANO_CENARIOS.md, validacao-cenarios.md.
- Implementação real: simulation.gd usa seed_value e start_run; nenhum RunDirector/BiomeDef encontrado em scripts. Adaptador de bancada deve ler seed_value; não criar outra run.
- Mapa: autoria tools/build_docks_map.py, dados docks_map.gd e composição scenario_layout.gd. Capturar composição efetiva, não só constantes.
- Renderer: DockView existente pode ser instanciado pela bancada sem editar runtime ocupado.
- Viewport base 1280x800, opções em display_settings.gd, zoom normal 1.22.

## Cobertura e qualidade

20 FR, 10 NFR e 8 UX possuem mapeamento explícito em validacao-cenarios.md; SCN-01 cobre identidade, baseline, seed, contrato e inspeção. Sequência 01.01 → 01.02 → 01.03 → 01.04 → 01.05 sem dependências futuras internas. Valor imediato é autoria/inspeção reproduzível. Arte futura e montador não são necessários para abrir baseline.

As histórias têm quatro critérios Dado/Quando/Então e evidência definida. Caminhos novos da base: scripts/scenarios/, tools/scenarios/base/, tests/scenarios_base/. Status/evidências: cenarios-base/. Esse recorte torna as tarefas executáveis sem tocar arquivos concorrentes.

## Riscos e resolução

1. Alto: combate/Omega ativos alteram runtime. Base só cria componentes isolados; hashes detectam mudança do baseline. Integração normal aguarda arquivos livres.
2. Alto: SCN-01.04 deve representar alas, arte e colisão na mesma transformação; tradução apenas inicialmente, rotações/espelhos rejeitados.
3. Médio: ausência de RunDirector/BiomeDef. Adaptadores explicitamente identificados, sem alegar conclusão dos épicos externos.
4. Médio: UX formal ausente; oito requisitos SCN-UX e capturas reais orientam validação. Inspeção automatizada não equivale a playtest humano.
5. Produção posterior: budgets de desempenho, conteúdo narrativo futuro e geração válida são gates próprios; não declarar prontidão global.

## Requisitos extraídos da fonte aprovada
- SCN-FR01: Representar era, bioma/setor, sala, variante e instância com IDs estáveis e dados validados, sem misturar essas escalas.
- SCN-FR02: Preservar mapa atual como baseline e carregar uma sala/variante pelo mesmo contrato consumido por simulação, navegação e renderização.
- SCN-FR03: Selecionar conteúdo com seed, subfluxos independentes, versão do gerador e catálogo; registrar o resultado materializado da geração.
- SCN-FR04: Produzir arte com PixelLab e/ou Higgsfield conforme adequação, referências por bioma, escala de personagem, camadas, origem e metadados; qualidade em jogo decide o aceite.
- SCN-FR05: Renderizar composições fixas, conectores e props dinâmicos sem duplicação de colisão, decoração ou luz.
- SCN-FR06: Reconstruir Farol/escadas e as 14 áreas das Docas como catálogo de famílias/templates, preservando funções essenciais sem exigir todas as salas ou posições antigas em cada run.
- SCN-FR07: Diferenciar portuário, ferroviário, industrial, alagado e cultista por materiais, arquitetura, circulação e atmosfera.
- SCN-FR08: Autorar templates de dimensões e conectores declarados; variantes intercambiáveis preservam o contrato do template, e o montador acomoda diferentes templates.
- SCN-FR09: Avaliar e adaptar BasicDungeonGenerator/MST da GDQuest em bancada isolada, com versão e origem rastreáveis.
- SCN-FR10: Gerar a fase completa por seed com grafo, salas/módulos autorados, ramificações, ciclos e corredores; usar no fluxo normal após validação, com baseline apenas como fallback de falha.
- SCN-FR11: Validar caminhos, alturas, conexões, fechaduras/chaves, spawns e perigos para jogador, parceiro e robôs permitidos.
- SCN-FR12: Transitar entre setores/biomas/eras com entrada, saída e set pieces definidos, sem perder estado ou duplicar recompensas.
- SCN-FR13: Integrar descoberta, minimapa, encontro, save/load e snapshots ao mapa materializado.
- SCN-FR14: Preservar minichefe, chefe, pista e recompensa essencial garantidos; aleatoriedade varia extras, não bloqueia história.
- SCN-FR15: Construir o Japão de Vincent com identidade própria e espaços para defesa/despedida.
- SCN-FR16: Construir o reino medieval de Elias com espaço para o Mago de Ferro e sua fonte de vozes.
- SCN-FR17: Construir o laboratório de Íris com infiltração, prisioneiros e instalação do Spectre.
- SCN-FR18: Construir a região antiga de Letícia após definir sua identidade, com comunidade ativa e defesa.
- SCN-FR19: Construir acessos do Refúgio e cenários finais do Arauto/R'lyeh, preservando a resolução por selamento.
- SCN-FR20: Oferecer ferramentas de prévia, validação em lote, evidências visuais e rejeição de conteúdo inadequado por bioma.
- SCN-NFR01: Mesma seed + versões + catálogo elegível produzem mesmo manifesto; diferenças de versão são detectadas, nunca ocultadas.
- SCN-NFR02: Godot 4.7.2/GL Compatibility e arquitetura atual preservados; sem Python, PixelLab ou rede externa exigidos durante a partida.
- SCN-NFR03: Geração fora do combate, tentativas e tempo limitados, fallback conhecido e registro de falhas reproduzível.
- SCN-NFR04: Mira de 60 fps; custos de carregamento/memória e referência de hardware devem ser medidos antes de fechar orçamentos. Sem promessa de desempenho baseada apenas no conceito.
- SCN-NFR05: Recarga, coop e host autoritativo preservam exatamente a geometria e o estado do andar.
- SCN-NFR06: Caminhos, perigo, altura e interação legíveis por forma/contraste além de cor, na câmera real com atores e projéteis.
- SCN-NFR07: Densidade de pixels, perspectiva e direção da luz consistentes dentro de cada conjunto; sem ampliação não uniforme para encaixar arte.
- SCN-NFR08: Pools isolados por bioma e overlays explícitos; asset ausente/ID inválido tem diagnóstico e fallback aprovado, nunca substituição aleatória por outra era.
- SCN-NFR09: Fontes, versões, licenças e prompts rastreáveis; código GDQuest MIT com avisos preservados; arte deles CC BY 4.0 apenas se adotada e creditada.
- SCN-NFR10: Referências arquiteturais futuras são propostas identificadas. Aprovação estética não equivale a validação de caminho, colisão ou combate.
- SCN-UX01: Escadas têm início, orientação dos degraus, patamar e face de altura coerentes; nenhum texto RAMPA é necessário para reconhecer a subida.
- SCN-UX02: Conexões entre sala e corredor mantêm bordas, material, escala e caminhos contínuos.
- SCN-UX03: Pisos das áreas de combate têm baixa competição visual; desgaste e objetos agrupados onde fazem sentido.
- SCN-UX04: Elementos dianteiros ocultam atores apenas dentro da política definida; pés, ameaças e saídas continuam compreensíveis.
- SCN-UX05: Objetos acionáveis e portas úteis se distinguem da decoração; luz decorativa não promete interação inexistente.
- SCN-UX06: Água, névoa, luz e som reforçam o bioma sem esconder projéteis ou limites caminháveis; efeitos intensos possuem redução.
- SCN-UX07: Identidade do bioma combina arquitetura, materiais e ritmo espacial, não apenas troca de cor.
- SCN-UX08: Transições comunicam destino e perigo; a entrada não nasce sob ataque sem espaço seguro para orientar-se.
- SCN-FR01: SCN-01, SCN-06.
- SCN-FR02: SCN-01.
- SCN-FR03: SCN-01.
- SCN-FR04: SCN-02.
- SCN-FR05: SCN-02.
- SCN-FR06: SCN-02, SCN-03.
- SCN-FR07: SCN-03, SCN-06.
- SCN-FR08: SCN-04.
- SCN-FR09: SCN-04.
- SCN-FR10: SCN-04.
- SCN-FR11: SCN-04, SCN-12.
- SCN-FR12: SCN-05, SCN-06, SCN-11.
- SCN-FR13: SCN-05, SCN-12.
- SCN-FR14: SCN-03, SCN-05, SCN-07, SCN-08, SCN-09, SCN-10, SCN-11.
- SCN-FR15: SCN-07.
- SCN-FR16: SCN-08.
- SCN-FR17: SCN-09.
- SCN-FR18: SCN-10.
- SCN-FR19: SCN-11.
- SCN-FR20: SCN-01, SCN-12.

## Parecer final
READY para bancada SCN-01 isolada. NEEDS WORK para integração/publicação de ondas posteriores. Cinco riscos documentados; próximos passos são capturar baseline efetivo, provar determinismo, validar o contrato e só então liberar dependentes. Revisão: Codex, 30/09/2026.

