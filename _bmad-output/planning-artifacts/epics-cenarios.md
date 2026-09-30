---
title: "Severence — geração e reconstrução dos cenários"
date: 2026-09-30
language: pt-BR
status: planned
stepsCompleted: [1, 2, 3, 4]
workflow: gds-create-epics-and-stories
execution: "Pedido explícito de escrever todas as histórias; produção completa sem novas rodadas de autorização. Decisões ainda abertas são identificadas, não tratadas como aprovadas."
inputDocuments:
  - docs/ARQUITETURA_ROGUELIKE.md
  - _bmad-output/planning-artifacts/epics.md
  - docs/architecture.md
  - docs/LORE.md
  - docs/PLANO_LORE.md
  - docs/PLANO_CENARIOS.md
  - docs/CENARIO_0_16.md
  - docs/CENARIO_0_18.md
  - docs/PROMPT_ROGUELIKE_HANDOFF.md
  - art/concept/cenario-direcao-v1/index.html
  - art/concept/cenario-direcao-v1/manifest.json
  - scripts/docks_map.gd
  - scripts/scenario_layout.gd
  - scripts/simulation.gd
  - scripts/dock_scenery.gd
  - scripts/world_view.gd
  - "Conversa: direção visual aceita; pesquisa GDQuest; pedido de todas as histórias por bioma"
---

# Geração e reconstrução dos cenários

## Escopo e precedência

Backlog de cenários, complementar aos épicos 1–5 de roguelike existentes. Não substitui o backlog de combate, personagens, economia ou resgates. Nenhuma história deste documento significa implementação concluída. Não existe GDD formal desta fase: requisitos vêm da arquitetura canônica, lore, código atual e conversa.

O projeto é existente, Godot 4.7.2, com simulação e desenho próprios. Não usar um projeto inicial novo nem trocar todo o jogo por um demo. `tools/build_docks_map.py` é a fonte de autoria do mapa; não editar manualmente `scripts/docks_map.gd`. Exemplos antigos de `docs/architecture.md` têm contagens e caminhos históricos: confirmar contratos no código antes da implementação.

**Decisão vigente, atualizada por Tsmar nesta conversa:** fase totalmente procedural; grafo, seleção/posição de salas e corredores variam por seed. Doca/Desembarque e boss podem manter composições fixas; esta é a interpretação de DOCA usada aqui. Refúgio é hub fora do gerador. Farol é conjunto modular, não outra âncora fixa obrigatória. A arquitetura foi atualizada. A bancada valida o montador; macro procedural é objetivo de produção, sem nova autorização pendente.

**Direção visual aceita:** composições maiores, poucas repetições perceptíveis, camadas separadas, escadas integradas e materiais coerentes. A imagem PixelLab do Farol é referência estética; sua altura, lances e posição de porta não são geometria aprovada. Não esticar o conceito 688×384 sobre a sala de 1700×1300 unidades.

**Horizonte:** Parte A = Docas de 1941, Refúgio e infraestrutura necessária à pré-venda. Parte B = novas eras e confronto final, conforme `docs/PLANO_LORE.md`. Ferroviário e Adega/Santuário são setores já presentes e também candidatos a biomas/andares da cadeia arquitetural; sua promoção não cria automaticamente uma nova era narrativa. Ordem das eras futuras, recorte cultural/geográfico da região antiga e número final de andares continuam decisões de conteúdo.

## Requirements Inventory

### Functional Requirements

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

### NonFunctional Requirements

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

### Additional Requirements

- Reutilizar o Epic 1 existente para RunDirector/estado/seed, Epic 2 para encontros/loot e Epic 5 para BiomeDef; evitar uma segunda implementação desses sistemas.
- Se a base de run ainda não existir, usar adaptador mínimo do estado atual, documentando a posterior ligação ao RunDirector; não declarar épicos externos concluídos.
- Arte deve entrar no renderer e ser inspecionada no jogo; PNG isolado não encerra uma história de produção.
- Autoridade de jogo, colisões, altura e geração pertencem à simulação/dados; renderers só consomem o resultado.
- Salas grandes podem ser divididas em placas conectadas na escala de uso; não tornar todo o mapa uma textura gigante.
- Compatibilidade com saves legados é parte do aceite. Save antigo não deve receber um novo layout silenciosamente.
- Novas eras precisam de hooks para conteúdo futuro, mas implementação de kits de personagens e IA de chefes é dependência externa, não escopo implícito deste backlog.

### UX Design Requirements

- SCN-UX01: Escadas têm início, orientação dos degraus, patamar e face de altura coerentes; nenhum texto RAMPA é necessário para reconhecer a subida.
- SCN-UX02: Conexões entre sala e corredor mantêm bordas, material, escala e caminhos contínuos.
- SCN-UX03: Pisos das áreas de combate têm baixa competição visual; desgaste e objetos agrupados onde fazem sentido.
- SCN-UX04: Elementos dianteiros ocultam atores apenas dentro da política definida; pés, ameaças e saídas continuam compreensíveis.
- SCN-UX05: Objetos acionáveis e portas úteis se distinguem da decoração; luz decorativa não promete interação inexistente.
- SCN-UX06: Água, névoa, luz e som reforçam o bioma sem esconder projéteis ou limites caminháveis; efeitos intensos possuem redução.
- SCN-UX07: Identidade do bioma combina arquitetura, materiais e ritmo espacial, não apenas troca de cor.
- SCN-UX08: Transições comunicam destino e perigo; a entrada não nasce sob ataque sem espaço seguro para orientar-se.

## Mapa de biomas e decisões abertas

| Escala / identidade | Base confirmada | Direção de produção proposta | Restrições |
| --- | --- | --- | --- |
| Era Docas 1941 / portuário | Porto em guerra e culto sob o mar | Pedra azulada, madeira úmida, ferragem e luz âmbar; cais aberto | Não espalhar símbolos por todo piso; conservar funções das 14 salas |
| Ferroviário / setor ou andar | Cadeia arquitetural e sala rails | Trilhos contínuos, plataformas, galpões e travessias laterais | Trilhos não viram textura solta; não introduzir trens letais sem história própria |
| Industrial / oficina e gerador | Salas shop/generator/ammo | Máquinas, cabos e estoque funcional; manutenção acessível | Reservar circulação Titan; área segura da loja não recebe combate por sorteio |
| Adega alagada / setor ou andar | cellar, água e vãos | Linha de maré, passagens secas, materiais degradados | Distinguir água visual, água atravessável e queda; sem natação implícita |
| Cultista / capela e Santuário | Chapel; Santuário citado na cadeia | Arquitetura do local apropriada pelo culto; marcas localizadas | Compartilhar símbolos da Ordem, não copiar a mesma sala em todas as eras |
| Japão de Vincent / era Parte B | Guerra entre clãs, comunidade e despedida | Pátios, construções de madeira e pedra, limiares e defesa | Data/local exatos e direção arquitetural a definir na história própria |
| Reino medieval de Elias / era Parte B | Reino, Mago de Ferro e mecha | Pedra monumental, pátios e câmara de poder; ferro como elemento excepcional | Layout permite mecha e resolução da fonte; sem presumir identidade cultural fechada |
| Laboratório de Íris / era Parte B | Instalações avançadas e prisioneiros | Setores limpos/contaminados, contenção e passagens de serviço | Não confundir cenário de laboratório com ampliação da oficina de 1941 |
| Região antiga de Letícia / era Parte B | Comunidade ameaçada e defesa | Direção visual/geográfica a definir antes da produção; ocupação funcional | Não inferir povo, país ou arquitetura a partir da aparência de Letícia |
| R'lyeh / clímax Parte B | Arauto e manifestação de Cthulhu | Escala cósmica fora da pista de combate; espaço jogável confiável | Geometria impossível visual não pode criar rotas fisicamente incompreensíveis |
| Refúgio / hub transversal | Nave + metrô de Londres 1941 | Mistura intencional de dois materiais com acessos às eras | Hub não é sala de combate sorteada; portas bloqueadas não fingem acesso |

## Fontes externas verificadas

- [GDQuest — repositório](https://github.com/gdquest-demos/godot-4-procedural-generation): exemplos, não um montador completo de campanha pronto para ativar.
- [BasicDungeonGenerator](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/master/godot4/basic_dungeon/03_bonus/generator.gd): salas, sobreposição e corredores; hoje devolve células, exigindo adaptação para preservar metadados de sala.
- [MST Dungeon](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/master/godot4/mst_dungeon/mst_dungeon.gd): posicionamento por física e conexões extras. Não presumir determinismo entre máquinas só por atribuir seed à física.
- [Licença](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/master/LICENSE): código MIT e arte CC BY 4.0, tratados separadamente.

## Epic List

### Epic SCN-01: Prévia reproduzível de um cenário por bioma

A equipe abre um cenário real com identidade, geometria e seed inspecionáveis.

**Horizonte:** A. **FRs:** SCN-FR01, SCN-FR02, SCN-FR03, SCN-FR20.

### Epic SCN-02: Farol bonito e escadas compreensíveis

O jogador atravessa o primeiro conjunto final de arquitetura com profundidade e caminhos legíveis.

**Horizonte:** A. **FRs:** SCN-FR04, SCN-FR05, SCN-FR06.

### Epic SCN-03: Docas completas e coerentes

As 14 salas existentes ganham arte integrada e transições que conservam suas funções.

**Horizonte:** A. **FRs:** SCN-FR06, SCN-FR07, SCN-FR14.

### Epic SCN-04: Expedições variadas com salas autoradas

Grafo, salas, corredores e interiores variam de forma válida; referências GDQuest sustentam o montador completo.

**Horizonte:** A. **FRs:** SCN-FR08, SCN-FR09, SCN-FR10, SCN-FR11.

### Epic SCN-05: Viajar e retomar a mesma expedição

Mudanças de bioma, descoberta, save e coop preservam o mundo materializado.

**Horizonte:** A. **FRs:** SCN-FR12, SCN-FR13, SCN-FR14.

### Epic SCN-06: Ferroviário, Adega e Santuário com identidade própria

Setores podem formar andares distintos sem virar apenas recolorações das Docas.

**Horizonte:** B; setores atuais entregues em A. **FRs:** SCN-FR01, SCN-FR07, SCN-FR12.

### Epic SCN-07: Explorar o Japão de Vincent

O cenário sustenta a comunidade, o conflito entre clãs e a despedida de Vincent.

**Horizonte:** B. **FRs:** SCN-FR15, SCN-FR14.

### Epic SCN-08: Atravessar o reino do Mago de Ferro

O cenário medieval conduz à fonte das vozes e comporta o encontro com Elias.

**Horizonte:** B. **FRs:** SCN-FR16, SCN-FR14.

### Epic SCN-09: Infiltrar o laboratório de Íris

Ambientes de contenção e fuga apresentam Íris, prisioneiros e Spectre com caminhos claros.

**Horizonte:** B. **FRs:** SCN-FR17, SCN-FR14.

### Epic SCN-10: Defender a comunidade de Letícia

Uma região antiga com identidade definida permite defesa e o encontro com Letícia.

**Horizonte:** B. **FRs:** SCN-FR18, SCN-FR14.

### Epic SCN-11: Voltar ao Refúgio e alcançar o clímax

Acessos do hub e cenários do Arauto/R'lyeh sustentam a progressão e o selamento.

**Horizonte:** A para hub; B para clímax. **FRs:** SCN-FR19, SCN-FR12, SCN-FR14.

### Epic SCN-12: Jogar cenários legíveis, fluidos e verificáveis

Cada lote de cenários passa por validação funcional, visual e de desempenho reproduzível.

**Horizonte:** A e B por lote. **FRs:** SCN-FR20, SCN-FR11, SCN-FR13.


## FR Coverage Map

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

## Histórias detalhadas

IDs SCN são próprios deste backlog e não renumeram os épicos aprovados de roguelike. Cada história possui um arquivo de trabalho em `stories-cenarios/`; esta consolidação registra o texto inicial. Mudanças de execução devem atualizar o arquivo de trabalho e o índice de estado, sem considerar o texto consolidado como evidência de implementação.


## Epic SCN-01: Prévia reproduzível de um cenário por bioma

A equipe abre um cenário real com identidade, geometria e seed inspecionáveis.

[Arquivo de trabalho SCN-01.01](stories-cenarios/scn-01-01.md)

### Story SCN-01.01: Abrir uma bancada de cenários com baseline preservado

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** abrir uma sala existente em uma bancada inspecionável,
**para** comparar melhorias contra a mesma posição e câmera.

**Dependências:** nenhuma história SCN; usar baseline existente.

**Requisitos:** SCN-FR02, SCN-FR20, SCN-NFR02.

**Escopo e tarefas:**

- [ ] Registrar hash/revisão do mapa e capturas de Farol, Guindastes e Capela.
- [ ] Criar seleção de sala e sobreposição de geometria nas ferramentas existentes.
- [ ] Isolar flags de inspeção do fluxo normal.

**Acceptance Criteria:**

**AC1 — Dado** o mapa atual e uma posição de referência, **quando** abrir a bancada sem gerar variantes, **então** a geometria, os objetos e os caminhos correspondem ao baseline registrado.

**AC2 — Dado** uma sala com alas e três saídas, **quando** selecioná-la, **então** a prévia mostra limites, âncoras e posição de personagem sem recortar as alas.

**AC3 — Dado** a bancada desligada, **quando** iniciar a expedição normal, **então** nenhum comportamento de jogo muda por causa das ferramentas.

**AC4 — Dado** uma sala ou captura inexistente, **quando** solicitar inspeção, **então** o erro identifica o ID e oferece o baseline, sem sobrescrever saves.

**Verificação e evidência:** Capturas comparáveis e teste de carregamento da cena normal e da bancada; conservar saves do usuário.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/simulation.gd; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-01.02](stories-cenarios/scn-01-02.md)

### Story SCN-01.02: Reproduzir a seleção de cenário por seed

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** reabrir a mesma composição a partir de uma seed,
**para** investigar e repetir uma expedição sem mudanças inesperadas.

**Dependências:** SCN-01.01.

**Requisitos:** SCN-FR03, SCN-NFR01.

**Escopo e tarefas:**

- [ ] Inspecionar Epic 1 existente e criar/reutilizar subfluxo de mapa.
- [ ] Definir derivação estável de seed por bioma/andar/sala e versão.
- [ ] Materializar IDs, seed, versões e fingerprint do catálogo no manifesto.

**Acceptance Criteria:**

**AC1 — Dado** seed, catálogo elegível e versões iguais, **quando** gerar duas vezes, **então** IDs de sala, variante e conexões do manifesto coincidem.

**AC2 — Dado** o mesmo cenário, **quando** consumir números do fluxo de loot ou de efeitos, **então** a composição espacial não muda.

**AC3 — Dado** RunDirector já implementado, **quando** iniciar geração, **então** a seed vem dele sem criar um segundo dono da run.

**AC4 — Dado** RunDirector ainda ausente, **quando** usar a bancada, **então** um adaptador explícito usa a seed atual e registra essa limitação, sem reescrever progressão.

**Verificação e evidência:** Teste de repetição e isolamento de fluxos; fixtures serializadas comparáveis byte a byte após ordenação canônica.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/simulation.gd; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-01.03](stories-cenarios/scn-01-03.md)

### Story SCN-01.03: Carregar a identidade de um bioma por dados

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** abrir ambientes com materiais e regras próprios,
**para** reconhecer onde estou sem depender somente de cor.

**Dependências:** SCN-01.02.

**Requisitos:** SCN-FR01, SCN-FR07, SCN-NFR08, SCN-UX07.

**Escopo e tarefas:**

- [ ] Estender/reutilizar BiomeDef do Epic 5 com IDs, materiais, conectores, roles, regras e versões.
- [ ] Distinguir perfis confirmados, candidatos a andar e eras futuras não publicadas.
- [ ] Validar referências e catálogo de fallback por bioma.

**Acceptance Criteria:**

**AC1 — Dado** definições de Docas e um segundo perfil de teste, **quando** selecionar um perfil, **então** arte, atmosfera, pools e regras de conexão vêm da definição escolhida.

**AC2 — Dado** uma sala ferroviária dentro de 1941, **quando** inspecionar seu registro, **então** era, biome_id e room_role são campos distintos.

**AC3 — Dado** ID duplicado, material ausente ou referência circular, **quando** validar o catálogo, **então** o registro é rejeitado com caminho e causa.

**AC4 — Dado** uma nova definição válida, **quando** carregar na bancada, **então** não é necessário acrescentar condicionais específicas no renderer.

**Verificação e evidência:** Teste de dois perfis e casos inválidos; tabela de origem dos assets e nenhuma publicação de era vazia.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/simulation.gd; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-01.04](stories-cenarios/scn-01-04.md)

### Story SCN-01.04: Instanciar uma sala autorada com arte e geometria alinhadas

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** percorrer uma sala descrita por um único contrato,
**para** ter colisões que correspondam ao que vejo.

**Dependências:** SCN-01.03.

**Requisitos:** SCN-FR02, SCN-FR05, SCN-FR11.

**Escopo e tarefas:**

- [ ] Definir RoomTemplate/RoomInstance e política de transformações permitidas.
- [ ] Adaptar uma sala existente sem migrar todo o mapa.
- [ ] Unificar origem dos dados usados pelo desenho, colisão e descoberta.

**Acceptance Criteria:**

**AC1 — Dado** template com footprint, portas e camadas, **quando** instanciá-lo em duas posições, **então** geometria, âncoras, arte e pontos de interesse recebem a mesma transformação.

**AC2 — Dado** slot com alas, **quando** carregar sua variante baseline, **então** navegação e identificação de sala incluem as alas.

**AC3 — Dado** porta desenhada fora da borda ou spawn dentro de parede, **quando** validar template, **então** a instância é rejeitada antes de entrar na partida.

**AC4 — Dado** template pintado, **quando** construir obstáculos, **então** objetos já incorporados à arte não criam cópias visuais extras.

**Verificação e evidência:** Fixture com deslocamento de sala, porta inválida e ala; caminhada com sobreposição de colisões.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/simulation.gd; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-01.05](stories-cenarios/scn-01-05.md)

### Story SCN-01.05: Inspecionar uma sala com diferentes personagens e câmeras

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** avaliar a composição na escala de jogo,
**para** perceber problemas de proporção antes de gerar todo o kit.

**Dependências:** SCN-01.04.

**Requisitos:** SCN-FR20, SCN-NFR07, SCN-UX03, SCN-UX04.

**Escopo e tarefas:**

- [ ] Adicionar presets de atores, câmera e overlays à bancada.
- [ ] Definir uma régua de pixels/altura baseada nos sprites em uso.
- [ ] Salvar captura normal, sem iluminação e com colisões.

**Acceptance Criteria:**

**AC1 — Dado** uma sala de teste, **quando** exibir Marty, Titan e inimigo existente, **então** a prévia usa seus tamanhos reais e não silhuetas redimensionadas para favorecer o cenário.

**AC2 — Dado** câmera normal e resoluções suportadas, **quando** capturar o mesmo percurso, **então** o relatório registra zoom, viewport e escala da arte.

**AC3 — Dado** uma textura incompatível com a densidade definida, **quando** inseri-la, **então** o relatório sinaliza a razão de escala e não aplica esticamento não uniforme.

**AC4 — Dado** camada frontal, **quando** mover o personagem atrás e à frente, **então** a prévia permite identificar o ponto em que os pés e a silhueta desaparecem.

**Verificação e evidência:** Conjunto de capturas nas resoluções efetivamente suportadas; relatório de escala e checklist visual preenchido.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/simulation.gd; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-02: Farol bonito e escadas compreensíveis

O jogador atravessa o primeiro conjunto final de arquitetura com profundidade e caminhos legíveis.

[Arquivo de trabalho SCN-02.01](stories-cenarios/scn-02-01.md)

### Story SCN-02.01: Produzir o kit piloto de pedra, madeira e ferro

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** ver materiais que pertencem ao mesmo porto,
**para** reconhecer uma direção visual consistente.

**Dependências:** SCN-01.05.

**Requisitos:** SCN-FR04, SCN-NFR07, SCN-NFR09, SCN-UX07.

**Escopo e tarefas:**

- [ ] Criar ficha visual do kit Docas e escolher ferramenta por tipo de asset.
- [ ] Produzir apenas piso, borda e parede piloto; separar áreas de conexão.
- [ ] Importar as peças e registrar aprovação/rejeição visual.

**Acceptance Criteria:**

**AC1 — Dado** o conceito aceito e sprites reais, **quando** definir o kit piloto, **então** escala, perspectiva, luz, materiais e limites de contraste ficam registrados em uma ficha.

**AC2 — Dado** PixelLab ou Higgsfield, **quando** produzir piso, borda e parede piloto, **então** prompts, referência, IDs de geração, versão, tamanho e origem são preservados.

**AC3 — Dado** arte vazia, deformada ou fora da linguagem, **quando** revisar a saída, **então** ela fica fora do catálogo publicável, com motivo e tentativa identificados.

**AC4 — Dado** as três peças montadas na bancada, **quando** avaliar lado a lado com Marty, **então** nenhuma exige esticamento não uniforme nem parece de outra escala.

**Verificação e evidência:** Prancha de peças e captura montada com personagem; verificação de dimensões, transparência e origem.

**Contexto de implementação:** art/concept/cenario-direcao-v1/index.html; scripts/world_view.gd; scripts/dock_scenery.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-02.02](stories-cenarios/scn-02-02.md)

### Story SCN-02.02: Desenhar o módulo baixo de escada e patamar

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** entender de onde a escada parte e onde chega,
**para** atravessar desníveis sem tentativa e erro.

**Dependências:** SCN-02.01.

**Requisitos:** SCN-FR06, SCN-UX01, SCN-NFR07, SCN-NFR10.

**Escopo e tarefas:**

- [ ] Gerar escada, faces laterais e patamar como conjunto, depois separar camadas necessárias.
- [ ] Registrar footprint, linha dos pés, altura e entradas.
- [ ] Criar versões de orientação apenas quando compatíveis com perspectiva e luz.

**Acceptance Criteria:**

**AC1 — Dado** o Farol atual com 44 unidades de altura, **quando** desenhar o piloto, **então** existem duas subidas laterais curtas e chegada contínua ao patamar.

**AC2 — Dado** o conceito com lances extras, **quando** produzir a peça, **então** a escadaria excessiva é corrigida e a altura representada coincide com a simulação.

**AC3 — Dado** a peça em duas posições de mundo, **quando** montar o módulo, **então** pés, sombra, laterais e origem mantêm alinhamento.

**AC4 — Dado** uma orientação não autorada, **quando** solicitar rotação, **então** o catálogo rejeita a orientação ou escolhe uma versão adequada, sem girar a iluminação arbitrariamente.

**Verificação e evidência:** Captura sem rótulo RAMPA; trajeto desenhado sobre a arte e comparação da face vertical com 44 unidades.

**Contexto de implementação:** art/concept/cenario-direcao-v1/index.html; scripts/world_view.gd; scripts/dock_scenery.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-02.03](stories-cenarios/scn-02-03.md)

### Story SCN-02.03: Integrar camadas e profundidade do Farol

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** passar diante e atrás das estruturas de forma convincente,
**para** sentir que o personagem ocupa o cenário.

**Dependências:** SCN-02.02.

**Requisitos:** SCN-FR05, SCN-UX04, SCN-UX05.

**Escopo e tarefas:**

- [ ] Estender o renderer existente com camadas por módulo e origem comum.
- [ ] Substituir apenas o desenho legado do piloto; marcar props já incorporados.
- [ ] Definir e demonstrar política de oclusão para estrutura alta.

**Acceptance Criteria:**

**AC1 — Dado** módulo com chão, face e primeiro plano, **quando** desenhá-lo, **então** camadas aparecem na ordem correta e objetos não são desenhados duas vezes.

**AC2 — Dado** Marty ou Titan junto da estrutura, **quando** atravessar seus limites, **então** ordenação usa posição dos pés e considera elevação.

**AC3 — Dado** elemento frontal ocultando o jogador, **quando** ativar a política de oclusão definida, **então** jogador e ameaça continuam identificáveis sem apagar toda a arquitetura.

**AC4 — Dado** área fora da câmera, **quando** renderizar o quadro, **então** peças são recortadas/culladas sem abrir costura nas bordas.

**Verificação e evidência:** Sequência de capturas antes/atrás/depois da estrutura com ambos os tamanhos de ator; teste de exclusão de duplicatas.

**Contexto de implementação:** art/concept/cenario-direcao-v1/index.html; scripts/world_view.gd; scripts/dock_scenery.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-02.04](stories-cenarios/scn-02-04.md)

### Story SCN-02.04: Alinhar escadas, colisão e circulação

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** subir, descer e contornar o módulo,
**para** confiar na correspondência entre aparência e caminho.

**Dependências:** SCN-02.03.

**Requisitos:** SCN-FR11, SCN-UX01, SCN-UX02.

**Escopo e tarefas:**

- [ ] Reconciliar raised/ramps e obstáculos com a nova peça.
- [ ] Testar volume real dos atores e saídas de robô.
- [ ] Remover rótulo de debug do jogo normal após comprovar legibilidade.

**Acceptance Criteria:**

**AC1 — Dado** o módulo integrado, **quando** subir e descer pelos dois lados, **então** o deslocamento é contínuo e a altura termina no patamar.

**AC2 — Dado** borda alta fora da escada, **quando** tentar andar para dentro, **então** a regra de elevação impede acesso incompatível sem paredes invisíveis fora da face desenhada.

**AC3 — Dado** dash, salto, parceiro e Titan permitidos, **quando** testar entradas e contorno, **então** não há aprisionamento, teleporte ou ponto de desembarque inválido.

**AC4 — Dado** as três saídas do Farol baseline, **quando** montar o piloto, **então** o conjunto conserva oeste, leste e norte; versões futuras declaram explicitamente seu próprio conjunto de portas.

**Verificação e evidência:** Teste de altura/clear_at/move_body e captura de travessia nos dois sentidos; evidência separada de caminhada, dash e salto.

**Contexto de implementação:** art/concept/cenario-direcao-v1/index.html; scripts/world_view.gd; scripts/dock_scenery.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-02.05](stories-cenarios/scn-02-05.md)

### Story SCN-02.05: Criar conectores de entrada sem emendas

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar do corredor ao Farol sem quebra visual,
**para** perceber uma arquitetura contínua.

**Dependências:** SCN-02.04.

**Requisitos:** SCN-FR05, SCN-UX02, SCN-UX05.

**Escopo e tarefas:**

- [ ] Produzir soleiras e junções retas/cantos necessárias ao piloto.
- [ ] Registrar lado, largura útil, nível e família material no conector.
- [ ] Integrar máscaras de borda sem alterar visualmente a área caminhável.

**Acceptance Criteria:**

**AC1 — Dado** porta compatível com corredor, **quando** encaixar as peças, **então** piso, soleira, bordas e altura são contínuos sem lacuna ou sobreposição.

**AC2 — Dado** uma parede sem saída, **quando** decorá-la, **então** ela não recebe sinalização idêntica à porta utilizável.

**AC3 — Dado** conector de largura ou material incompatível, **quando** tentar encaixe, **então** a montagem usa transição explicitamente cadastrada ou falha com diagnóstico.

**AC4 — Dado** câmera atravessando a emenda, **quando** mover continuamente, **então** não aparecem linhas de corte, mudança de escala ou vazamento do fundo.

**Verificação e evidência:** Capturas de cada junção e percurso contínuo; casos de encaixe recusado.

**Contexto de implementação:** art/concept/cenario-direcao-v1/index.html; scripts/world_view.gd; scripts/dock_scenery.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-02.06](stories-cenarios/scn-02-06.md)

### Story SCN-02.06: Publicar o Farol como módulo reutilizável

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar um Farol coerente em posições diferentes,
**para** ter variedade sem perder clareza arquitetural.

**Dependências:** SCN-02.05.

**Requisitos:** SCN-FR06, SCN-FR08, SCN-FR20.

**Escopo e tarefas:**

- [ ] Empacotar módulo, materiais e pontos de interesse como template.
- [ ] Documentar limites de repetição e vizinhança no catálogo.
- [ ] Registrar antes/depois e retirar do caminho ativo o desenho substituído.

**Acceptance Criteria:**

**AC1 — Dado** duas montagens de bancada, **quando** instanciar o kit em posições diferentes, **então** arte, objetos, luzes e limites conservam o alinhamento.

**AC2 — Dado** o catálogo de produção, **quando** publicar o módulo, **então** ele tem ID, versão, footprint, conectores e condições de uso validados.

**AC3 — Dado** antigas texturas e pilares do Farol, **quando** ativar o módulo, **então** não permanecem sobrepostos ao conjunto novo.

**AC4 — Dado** história de produção concluída, **quando** revisar evidências, **então** há captura e trajeto no jogo, não apenas arquivos PNG.

**Verificação e evidência:** Template recarregado a partir do catálogo e duas instâncias de bancada; baseline legado preservado para comparação.

**Contexto de implementação:** art/concept/cenario-direcao-v1/index.html; scripts/world_view.gd; scripts/dock_scenery.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-03: Docas completas e coerentes

As 14 áreas existentes viram famílias de módulos coerentes, combinadas segundo papéis de cada run.

[Arquivo de trabalho SCN-03.01](stories-cenarios/scn-03-01.md)

### Story SCN-03.01: Preparar a Doca de desembarque como entrada fixa encaixável

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** começar em um cais reconhecível e seguro,
**para** entender a chegada antes da primeira luta.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR14, SCN-UX08.

**Escopo e tarefas:**

- [ ] Auditar imagem/efeitos atuais em arrival_art.
- [ ] Separar bounds da pintura, footprint navegável e conectores.
- [ ] Criar ID de papel entry e pontos de spawn seguros.

**Acceptance Criteria:**

**AC1 — Dado** a pintura existente do Desembarque, **quando** adaptar sua interface, **então** arte e animação são preservadas onde adequadas e saídas recebem conectores declarados.

**AC2 — Dado** uma nova run, **quando** entrar na Doca, **então** spawn fica em piso seguro com caminho até a primeira saída.

**AC3 — Dado** nova posição da entrada no mapa, **quando** aplicar transformação, **então** portal, câmera, pickups e água acompanham a instância.

**AC4 — Dado** o grafo do andar, **quando** selecionar entrada, **então** há exatamente uma Doca de início, sem cópias do evento de chegada.

**Verificação e evidência:** Cena da Doca conectada a dois corredores de teste; captura e teste de pontos relocados.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.02](stories-cenarios/scn-03-02.md)

### Story SCN-03.02: Compor o Pátio dos Guindastes por módulos

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** combater em um pátio de carga legível,
**para** usar coberturas sem me perder em decoração.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR07, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir guindaste/base/carga e bordas compatíveis.
- [ ] Autorar uma composição baseline e sockets de coberturas.
- [ ] Reconciliar pilares provisórios e fosso com cenário novo.

**Acceptance Criteria:**

**AC1 — Dado** kit portuário, **quando** montar pátio, **então** guindaste, carga e trilhos formam grupos funcionais nas bordas.

**AC2 — Dado** rotas entre portas, **quando** posicionar cobertura e fosso, **então** existe contorno válido e a base dos objetos coincide com colisão.

**AC3 — Dado** variante sem fosso, **quando** montar a área, **então** não sobra borda pintada sugerindo uma queda inexistente.

**AC4 — Dado** explosivos permitidos, **quando** selecionar sua posição, **então** não bloqueiam spawn nem detonavam automaticamente na entrada.

**Verificação e evidência:** Percurso entre portas com Marty/Titan e captura em combate; inspeção das bases de cobertura.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.03](stories-cenarios/scn-03-03.md)

### Story SCN-03.03: Montar o Armazém 7 com vãos compreensíveis

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** explorar um armazém com passagens claras,
**para** distinguir piso seguro, salto e cobertura.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR11, SCN-UX02.

**Escopo e tarefas:**

- [ ] Criar módulos de nave, baia de carga, vão e passarela.
- [ ] Definir sockets de estoque e áreas reservadas.
- [ ] Manter segredos e conexões como dados relocáveis.

**Acceptance Criteria:**

**AC1 — Dado** kit de madeira do porto, **quando** montar o armazém, **então** vigas, tábuas e ferragens mantêm escala e continuidade.

**AC2 — Dado** canal/vão declarado, **quando** montar sua variante, **então** a borda representa a queda e existe rota alternativa quando o objetivo não exige salto.

**AC3 — Dado** props de estoque, **quando** distribuir nos sockets, **então** não tapam portas, alas ou área de aterrissagem.

**AC4 — Dado** passarela conectada, **quando** percorrê-la, **então** arte, suporte e superfície caminhável coincidem.

**Verificação e evidência:** Teste de travessia, salto/contorno e spawn em alas; captura com colisões.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.04](stories-cenarios/scn-03-04.md)

### Story SCN-03.04: Montar o Mercado com áreas de combate tranquilas

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** reconhecer um mercado portuário sem piso poluído,
**para** ler inimigos e caminhos entre bancas.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR07, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir banca, drenagem e chão por composição.
- [ ] Definir conjuntos decorativos e destrutíveis separados.
- [ ] Reservar corredores entre bancas para atores permitidos.

**Acceptance Criteria:**

**AC1 — Dado** perfil de mercado, **quando** montar as bancas, **então** cestos, redes e drenagem ficam associados às bancas e bordas.

**AC2 — Dado** piso central, **quando** aplicar desgaste, **então** poças e escamas não preenchem cada célula nem ocultam ataques.

**AC3 — Dado** banca destrutível, **quando** quebrá-la, **então** colisão e aparência mudam juntas sem duplicata incorporada ao fundo.

**AC4 — Dado** hazard de tentáculo, **quando** ativá-lo, **então** ele se distingue das poças decorativas antes de causar dano.

**Verificação e evidência:** Comparação com piso antigo e teste de quebra/água visual versus hazard.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.05](stories-cenarios/scn-03-05.md)

### Story SCN-03.05: Criar a Oficina como espaço seguro de serviço

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** alcançar vendedor, bancada e robô facilmente,
**para** preparar a expedição sem colisões confusas.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR07, SCN-UX05.

**Escopo e tarefas:**

- [ ] Produzir bancada, suporte de ferramentas e baias.
- [ ] Converter pontos absolutos de loja/mecha para âncoras locais.
- [ ] Definir zona segura e regra de ocupação.

**Acceptance Criteria:**

**AC1 — Dado** role shop, **quando** montar a Oficina, **então** entradas, vendedor e ponto de interação ficam acessíveis.

**AC2 — Dado** Titan presente, **quando** entrar/sair do robô, **então** o espaço reserva seu volume e pelo menos uma saída válida para o piloto.

**AC3 — Dado** decoração de manutenção, **quando** distribuir ferramentas, **então** ela fica em bancadas e estoque, não no eixo de interação.

**AC4 — Dado** pool de encontros, **quando** avaliar a sala segura, **então** combate e perigos não são adicionados por sorteio genérico.

**Verificação e evidência:** Teste de compra existente, interação e embarque/desembarque; captura com Titan.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.06](stories-cenarios/scn-03-06.md)

### Story SCN-03.06: Compor o Último Gerador com espaço de desafio

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** entender qual máquina ativa o desafio,
**para** circular e reagir durante o encontro.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR14, SCN-UX05.

**Escopo e tarefas:**

- [ ] Criar conjunto máquina/canaletas e áreas de circulação.
- [ ] Adaptar somente âncoras e apresentação do desafio existente.
- [ ] Produzir estados visuais inativo/ativo/concluído.

**Acceptance Criteria:**

**AC1 — Dado** módulo do gerador, **quando** montá-lo, **então** máquina e cabos apontam para a função sem fechar o contorno.

**AC2 — Dado** desafio existente, **quando** ativá-lo, **então** spawn e portões usam âncoras locais da instância.

**AC3 — Dado** saída ligada à conclusão, **quando** terminar o evento, **então** estado e aparência do acesso correspondem ao resultado.

**AC4 — Dado** luzes da máquina, **quando** ocorrer combate, **então** animação não imita telegraph de dano nem encobre projéteis.

**Verificação e evidência:** Teste do ciclo do desafio e caminhos antes/depois; captura de telegraphs sobre luz.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.07](stories-cenarios/scn-03-07.md)

### Story SCN-03.07: Montar o Depósito de Munição com cobertura funcional

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** identificar estoque, explosivos e abrigo,
**para** tomar decisões táticas claras.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR11, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir baias, coberturas e sockets de explosivos.
- [ ] Cadastrar superfície quebrável e saída de atalho.
- [ ] Conservar leitura de perigo ao reduzir detalhe no chão.

**Acceptance Criteria:**

**AC1 — Dado** kit industrial, **quando** montar baias, **então** munição e carga se agrupam em lugares plausíveis.

**AC2 — Dado** cobertura sólida e sacos de areia, **quando** testar disparos, **então** bloqueio usa geometria consistente com base visível.

**AC3 — Dado** atalho rachado, **quando** posicionar o módulo, **então** o lado externo possui destino/conector válido, não um vazio do mapa.

**AC4 — Dado** explosão em cadeia, **quando** destruir o estoque permitido, **então** os estados visuais e colisões permanecem consistentes.

**Verificação e evidência:** Teste de cobertura/explosão e rejeição de segredo sem destino; captura de combate.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.08](stories-cenarios/scn-03-08.md)

### Story SCN-03.08: Criar o Pátio Ferroviário com trilhos contínuos

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar um espaço ferroviário reconhecível,
**para** usar trilhos e plataformas como orientação.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR07, SCN-UX07.

**Escopo e tarefas:**

- [ ] Produzir segmentos/cantos permitidos e terminais de trilho.
- [ ] Criar plataforma, estoque e travessia modular.
- [ ] Reservar sockets do Guardião da Maré sem reescrever sua IA.

**Acceptance Criteria:**

**AC1 — Dado** módulos ferroviários, **quando** encaixá-los, **então** trilhos terminam em conexão ou fechamento autorado, nunca no meio de uma faixa sem motivo.

**AC2 — Dado** carga e plataformas, **quando** compor uma sala, **então** as travessias laterais e portas permanecem abertas.

**AC3 — Dado** trilho decorativo, **quando** cruzá-lo, **então** não causa dano nem bloqueia sem regra explícita.

**AC4 — Dado** minichefe existente, **quando** relocar sua sala, **então** spawn, área de combate e saída correspondem à instância.

**Verificação e evidência:** Inspeção de pontas de trilho e teste do encontro relocável.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.09](stories-cenarios/scn-03-09.md)

### Story SCN-03.09: Adaptar a Capela ao catálogo modular

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar um espaço do culto integrado ao porto,
**para** perceber a mudança de atmosfera sem perder orientação.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR07, SCN-UX06.

**Escopo e tarefas:**

- [ ] Reutilizar partes compatíveis da arte existente e regenerar juntas inadequadas.
- [ ] Remover dependência de bounds absolutos para a nova instância.
- [ ] Manter o conteúdo narrativo em sockets locais.

**Acceptance Criteria:**

**AC1 — Dado** a placa atual da Capela, **quando** decompô-la para autoria, **então** altar, piso, bordas e objetos com interação ficam identificados separadamente.

**AC2 — Dado** capela em outra posição, **quando** instanciar a composição, **então** efeitos, NPC e passagens acompanham a instância.

**AC3 — Dado** runas e velas, **quando** compor a sala, **então** a concentração simbólica está no altar e áreas narrativas, com caminho legível.

**AC4 — Dado** módulo vizinho não cultista, **quando** conectar as salas, **então** a transição altera atmosfera gradualmente sem espalhar props cultistas pelo pool global.

**Verificação e evidência:** Teste de relocation e NPC; capturas de entrada, altar e saída com efeitos reduzidos.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.10](stories-cenarios/scn-03-10.md)

### Story SCN-03.10: Montar o Doque Seco com profundidade segura

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** ler as bordas da área de reparo naval,
**para** circular entre andaimes e fossos sem quedas ambíguas.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR11, SCN-UX01.

**Escopo e tarefas:**

- [ ] Produzir bordas, apoios e andaimes conectáveis.
- [ ] Declarar fossos e áreas de contorno.
- [ ] Testar art/colisão em lados opostos da mesma borda.

**Acceptance Criteria:**

**AC1 — Dado** módulos de doca, **quando** montar o espaço, **então** faces do fosso e piso têm profundidade coerente com a câmera.

**AC2 — Dado** andaimes de primeiro plano, **quando** passar atrás deles, **então** a política de oclusão mantém ator e perigos legíveis.

**AC3 — Dado** rotas até saídas, **quando** validar com volumes de ator, **então** há contorno permitido sem exigir salto de uma máquina incapaz.

**AC4 — Dado** peça de borda ausente, **quando** validar template, **então** a publicação falha em vez de mostrar vazio caminhável.

**Verificação e evidência:** Caminhos Marty/Titan, captura da profundidade e rejeição de peça ausente.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.11](stories-cenarios/scn-03-11.md)

### Story SCN-03.11: Criar a Adega Inundada com três leituras de água

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** distinguir umidade, água atravessável e queda,
**para** explorar sem aprender perigos por acidente.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR07, SCN-UX06.

**Escopo e tarefas:**

- [ ] Produzir kit molhado e limites da água.
- [ ] Mapear classe visual para hazard ou piso, sem inferência por cor.
- [ ] Separar reflexos, objetos e navegação.

**Acceptance Criteria:**

**AC1 — Dado** três classes de água, **quando** montar a sala, **então** cada uma possui borda/movimento/contraste próprios e regra física explícita.

**AC2 — Dado** passagem seca obrigatória, **quando** sortear decoração, **então** barris e destroços não interrompem a rota.

**AC3 — Dado** baú acessível, **quando** posicionar sua âncora, **então** jogador pode interagir de piso válido.

**AC4 — Dado** reflexos animados, **quando** reduzir efeitos, **então** limites perigosos continuam visíveis.

**Verificação e evidência:** Percurso completo e teste de baú; captura estática e com animação reduzida.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.12](stories-cenarios/scn-03-12.md)

### Story SCN-03.12: Construir o Contrabando como segredo alcançável

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** descobrir uma sala escondida com entrada coerente,
**para** ser recompensado pela exploração.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR11, SCN-FR14.

**Escopo e tarefas:**

- [ ] Produzir estoque escondido e estados fechado/aberto.
- [ ] Cadastrar papel secret e regra de conexão em vez de coordenadas fixas.
- [ ] Manter recompensas essenciais fora de sorteios secretos.

**Acceptance Criteria:**

**AC1 — Dado** secret room selecionada, **quando** conectá-la, **então** há parede/porta secreta ligada a destino real e espaço para abrir.

**AC2 — Dado** parede intacta, **quando** consultar minimapa e navegação, **então** a sala não é revelada nem atravessável prematuramente.

**AC3 — Dado** método de abertura disponível, **quando** abrir passagem, **então** arte, colisão, descoberta e retorno se atualizam juntos.

**AC4 — Dado** segredo opcional não selecionado, **quando** gerar andar, **então** a progressão essencial e recompensas garantidas continuam possíveis.

**Verificação e evidência:** Teste abrir/retornar e captura antes/depois; verificação de ausência sem bloquear campanha.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-03.13](stories-cenarios/scn-03-13.md)

### Story SCN-03.13: Preparar a arena fixa do Almirante para qualquer montagem

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** chegar a uma arena memorável e clara,
**para** concentrar atenção no chefe.

**Dependências:** SCN-02.06.

**Requisitos:** SCN-FR06, SCN-FR14, SCN-UX03.

**Escopo e tarefas:**

- [ ] Auditar placa atual contra a direção aprovada e corrigir só o necessário.
- [ ] Converter BOSS_ARENA_RECT/BOSS_SAFE_CENTER e pontos absolutos para instância.
- [ ] Declarar boss como papel único e preparar estados da saída.

**Acceptance Criteria:**

**AC1 — Dado** a composição existente do boss, **quando** adaptar à nova interface, **então** área de luta, entradas e centro seguro são definidos por âncoras locais.

**AC2 — Dado** instância deslocada, **quando** iniciar o encontro, **então** chefe, câmera, projéteis ambientais e extração se alinham ao novo local.

**AC3 — Dado** ataques do chefe, **quando** exibir telegraphs, **então** piso, emblemas e efeitos não disputam a mesma leitura.

**AC4 — Dado** chefe derrotado, **quando** liberar saída, **então** o ponto de extração está acessível e a arena não reaparece como sala comum.

**Verificação e evidência:** Teste de arena relocada usando combate existente, câmera e extração; capturas dos ataques mais densos.

**Contexto de implementação:** docs/PLANO_CENARIOS.md; docs/LORE.md; scripts/docks_map.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-04: Expedições variadas com salas autoradas

Grafo, salas, corredores e interiores variam de forma válida usando módulos autorados por bioma.

[Arquivo de trabalho SCN-04.01](stories-cenarios/scn-04-01.md)

### Story SCN-04.01: Adaptar os exemplos GDQuest ao contrato do jogo

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** gerar salas e ligações na bancada,
**para** avaliar algoritmos sem substituir a simulação existente.

**Dependências:** SCN-01.04.

**Requisitos:** SCN-FR09, SCN-NFR02, SCN-NFR09.

**Escopo e tarefas:**

- [ ] Executar os demos na versão local e registrar incompatibilidades.
- [ ] Extrair lógica útil para interfaces próprias, conservando avisos.
- [ ] Comparar algoritmo simples, MST e necessidades de portas/roles.

**Acceptance Criteria:**

**AC1 — Dado** uma revisão identificada do repositório GDQuest, **quando** importar trechos necessários, **então** commit, arquivos, licença MIT e alterações ficam registrados.

**AC2 — Dado** BasicDungeonGenerator e MST de referência, **quando** executar o experimento, **então** saída contém salas/conexões identificáveis, não só pixels soltos.

**AC3 — Dado** posicionamento por RigidBody do demo, **quando** avaliar repetição, **então** ele não é adotado como prova de determinismo; a montagem final usa algoritmo discreto estável.

**AC4 — Dado** demo com assets externos, **quando** selecionar o conteúdo adotado, **então** arte CC BY é excluída ou creditada separadamente, sem substituir nossos biomas.

**Verificação e evidência:** Relatório curto com revisão, comandos, resultado e decisão de algoritmo; duas saídas de demonstração no contrato SCN.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.02](stories-cenarios/scn-04-02.md)

### Story SCN-04.02: Gerar o grafo de uma expedição com ramificações

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** receber um percurso novo com alternativas,
**para** explorar sem perder acesso ao objetivo.

**Dependências:** SCN-04.01, SCN-01.02.

**Requisitos:** SCN-FR10, SCN-FR14.

**Escopo e tarefas:**

- [ ] Definir regras por bioma para roles, quantidade, distância e ciclos.
- [ ] Gerar grafo determinístico antes da geometria.
- [ ] Emitir relatório de caminho principal, opcionais e relações de bloqueio.

**Acceptance Criteria:**

**AC1 — Dado** perfil de geração e seed, **quando** criar o grafo, **então** há entrada única, chefe único e caminho válido entre ambos.

**AC2 — Dado** bioma com minichefe e pista obrigatórios, **quando** sortear papéis, **então** eles constam do grafo em ordem compatível com progressão.

**AC3 — Dado** configuração de ramificações/ciclos, **quando** gerar o grafo, **então** limites mínimos/máximos são respeitados ou a configuração é rejeitada com causa.

**AC4 — Dado** mesma seed e entrada ordenada, **quando** gerar em execuções distintas, **então** IDs e arestas coincidem sem depender da ordem de Dictionary.

**Verificação e evidência:** Fixtures de grafo e testes de roles/alcance/ciclos; não confundir um nó opcional com objetivo obrigatório.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.03](stories-cenarios/scn-04-03.md)

### Story SCN-04.03: Posicionar templates sem sobreposição

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** percorrer salas de formatos variados,
**para** ter mapas diferentes com geometria confiável.

**Dependências:** SCN-04.02, SCN-02.06.

**Requisitos:** SCN-FR08, SCN-FR10, SCN-NFR01.

**Escopo e tarefas:**

- [ ] Implementar encaixe discreto com ordenação e desempate estáveis.
- [ ] Usar occupancy/footprints incluindo alas e margens de arte.
- [ ] Registrar candidatos recusados e limite configurável de busca.

**Acceptance Criteria:**

**AC1 — Dado** grafo e templates de tamanhos distintos, **quando** posicionar módulos, **então** footprints e margens reservadas não se sobrepõem.

**AC2 — Dado** conectores de alturas/larguras diferentes, **quando** avaliar uma ligação, **então** ela exige adaptador cadastrado ou outro template compatível.

**AC3 — Dado** tentativa de rotação de pintura com luz direcional, **quando** validar transformação, **então** a rotação é recusada salvo versão de arte explicitamente permitida.

**AC4 — Dado** busca sem solução, **quando** esgotar limite, **então** o resultado é falha estruturada, sem andar parcialmente publicado.

**Verificação e evidência:** Teste de L/T, sala grande, módulo deslocado e caso impossível; mapa de ocupação inspecionável.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.04](stories-cenarios/scn-04-04.md)

### Story SCN-04.04: Construir corredores coerentes entre salas

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar conexões claras entre ambientes,
**para** sentir continuidade mesmo com layout aleatório.

**Dependências:** SCN-04.03, SCN-02.05.

**Requisitos:** SCN-FR10, SCN-FR11, SCN-UX02.

**Escopo e tarefas:**

- [ ] Implementar traçado e reserva espacial com largura real.
- [ ] Criar associação entre geometria e peças retas/curvas/junções.
- [ ] Registrar conectores fechados e possíveis portas de combate.

**Acceptance Criteria:**

**AC1 — Dado** duas portas válidas, **quando** traçar corredor, **então** centros, largura útil e altura conectam sem atravessar footprint de outra sala.

**AC2 — Dado** curva ou junção, **quando** selecionar módulo, **então** piso, parede, sombra e coluna usam peças compatíveis com o bioma.

**AC3 — Dado** corredores que cruzariam sem junção permitida, **quando** validar traçado, **então** o gerador desvia ou rejeita, sem criar conexão escondida.

**AC4 — Dado** salas adjacentes de materiais diferentes, **quando** conectá-las, **então** um adaptador autorizado fecha a emenda e preserva largura dos atores.

**Verificação e evidência:** Teste de cruzamento recusado, esquina e adaptador; capturas em movimento com personagem e Titan.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.05](stories-cenarios/scn-04-05.md)

### Story SCN-04.05: Variar interiores por composição funcional

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar variações de cobertura e decoração,
**para** repetir o bioma sem repetir exatamente a sala.

**Dependências:** SCN-04.04.

**Requisitos:** SCN-FR08, SCN-NFR08, SCN-UX03.

**Escopo e tarefas:**

- [ ] Definir variantes e agrupamentos com peso/limite de repetição.
- [ ] Separar streams de composição visual e gameplay.
- [ ] Validar interiores antes de publicar a instância.

**Acceptance Criteria:**

**AC1 — Dado** template já colocado, **quando** sortear variante compatível, **então** footprint, portas e âncoras obrigatórias permanecem válidos.

**AC2 — Dado** sockets de cobertura/props, **quando** preencher o interior, **então** caminhos reservados, spawns e interação não são ocupados.

**AC3 — Dado** bioma e tags de função, **quando** filtrar o pool, **então** nenhum prop de outra era surge sem overlay temporal explicitamente permitido.

**AC4 — Dado** mesma seed de sala, **quando** mudar a ordem de geração de salas distantes, **então** a composição daquela instância permanece igual.

**Verificação e evidência:** Teste de pools, variação entre seeds e estabilidade por sala; contato visual de variantes de duas famílias.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.06](stories-cenarios/scn-04-06.md)

### Story SCN-04.06: Validar progressão espacial e portas/chaves

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** conseguir terminar toda fase publicada,
**para** não perder a run por um bloqueio gerado.

**Dependências:** SCN-04.05.

**Requisitos:** SCN-FR11, SCN-FR14.

**Escopo e tarefas:**

- [ ] Validar grafo e navegação geométrica após montagem, não apenas vizinhança de retângulos.
- [ ] Reutilizar regras clear_at/height_at/capacidades da simulação.
- [ ] Emitir caminho-testemunha e erro com seed, sala e coordenada.

**Acceptance Criteria:**

**AC1 — Dado** andar materializado com fechaduras, **quando** simular progressão, **então** a chave ou condição está acessível antes do bloqueio que ela abre.

**AC2 — Dado** salto, alturas, fossos e portões, **quando** calcular alcançabilidade, **então** o caminho respeita capacidades reais de cada ator permitido.

**AC3 — Dado** spawns, loja, baús e extração, **quando** validar o andar, **então** todos possuem posição segura e aproximação para interação.

**AC4 — Dado** segredo ou objetivo opcional inalcançável, **quando** validar antes do início, **então** o andar é rejeitado ou o opcional é removido por regra explícita e o conjunto é revalidado.

**Verificação e evidência:** Fixtures com chave atrás da própria porta, saída bloqueada, Titan preso e spawn no fosso; todos recusados.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.07](stories-cenarios/scn-04-07.md)

### Story SCN-04.07: Recuperar falhas de geração de forma limitada

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** iniciar a partida mesmo quando uma combinação falha,
**para** não ficar preso em carregamento infinito.

**Dependências:** SCN-04.06.

**Requisitos:** SCN-NFR03, SCN-FR20.

**Escopo e tarefas:**

- [ ] Definir budgets e política de retry com seeds derivadas registradas.
- [ ] Cadastrar fallback por bioma com mesmo contrato de estado.
- [ ] Exibir erro legível e limpar apenas dados transitórios da tentativa falha.

**Acceptance Criteria:**

**AC1 — Dado** configuração com limite de tentativas/tempo, **quando** forçar caso impossível, **então** a busca encerra nos limites configurados.

**AC2 — Dado** falha após tentativas, **quando** acionar fallback, **então** um layout previamente validado do bioma é materializado e o motivo fica registrado.

**AC3 — Dado** fallback ausente ou inválido, **quando** iniciar a run, **então** a interface permite voltar/repetir sem salvar um mundo incompleto.

**AC4 — Dado** arte descartada ou asset faltante, **quando** montar catálogo publicável, **então** o erro é detectado antes do combate e não troca silenciosamente o bioma.

**Verificação e evidência:** Teste de timeout, retries esgotados e fallback inválido; logs sem loops e sem perda do save anterior.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-04.08](stories-cenarios/scn-04-08.md)

### Story SCN-04.08: Iniciar expedições com mapa totalmente procedural

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** jogar uma fase nova a cada seed,
**para** obter variedade real de percurso com a arte aprovada.

**Dependências:** SCN-04.07, SCN-03.01, SCN-03.13.

**Requisitos:** SCN-FR10, SCN-FR13, SCN-NFR02.

**Escopo e tarefas:**

- [ ] Ligar geração ao carregamento existente em main/simulation.
- [ ] Resolver coordenadas de pontos de interesse por instância.
- [ ] Manter modo legado somente para diagnóstico/fallback, com motivo rastreável.

**Acceptance Criteria:**

**AC1 — Dado** o fluxo NOVA EXPEDIÇÃO, **quando** começar a run, **então** o modo normal usa grafo/montagem gerados antes de liberar controle.

**AC2 — Dado** duas seeds de demonstração distintas, **quando** comparar manifestos, **então** posição/seleção de salas ou conexões mudam de fato, não só os props.

**AC3 — Dado** Doca e boss como composições fixas, **quando** montar o andar, **então** suas artes internas permanecem íntegras com conectores ligados às áreas variáveis.

**AC4 — Dado** andar válido, **quando** publicar a simulação, **então** render, navegação, portas e encontros leem o mesmo manifesto e a geração não roda durante combate.

**Verificação e evidência:** Duas partidas com seeds diferentes e uma repetida, capturas do mapa e caminhada até boss em modo de teste; regressão de combate existente.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; fontes GDQuest do índice. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-05: Viajar e retomar a mesma expedição

Mudanças de bioma, descoberta, save e coop preservam o mundo materializado.

[Arquivo de trabalho SCN-05.01](stories-cenarios/scn-05-01.md)

### Story SCN-05.01: Mostrar o mapa real e sua descoberta

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** consultar salas que realmente existem nesta run,
**para** planejar meu percurso sem informação incorreta.

**Dependências:** SCN-04.08.

**Requisitos:** SCN-FR13, SCN-UX08.

**Escopo e tarefas:**

- [ ] Trocar busca por coordenadas/IDs fixos por instâncias.
- [ ] Relacionar ícones de função aos pontos de interesse.
- [ ] Persistir estado de descoberta no contexto do andar.

**Acceptance Criteria:**

**AC1 — Dado** um andar gerado, **quando** abrir minimapa/mapa, **então** footprints, corredores e ícones correspondem às instâncias atuais.

**AC2 — Dado** salas não descobertas e segredo intacto, **quando** consultar mapa, **então** eles obedecem à regra de névoa e não revelam conteúdo por ID antigo.

**AC3 — Dado** entrada em uma ala, **quando** atualizar descoberta, **então** ela pertence à sala correta e não cria descoberta de vizinhos.

**AC4 — Dado** transição de andar, **quando** abrir o mapa, **então** a descoberta é associada ao novo floor_instance_id sem colisão com IDs anteriores.

**Verificação e evidência:** Teste de descoberta por ala, sala repetida com IDs distintos e segredo; captura de mapa parcial.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/main.gd; scripts/combat_hud.gd; tests/dynamic_map_test.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-05.02](stories-cenarios/scn-05-02.md)

### Story SCN-05.02: Vincular encontros e recompensas às instâncias

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** limpar salas e receber recompensas corretas,
**para** não repetir batalhas por erro de identificação.

**Dependências:** SCN-05.01.

**Requisitos:** SCN-FR13, SCN-FR14.

**Escopo e tarefas:**

- [ ] Vincular combat_zones, spawns, drops e gates ao ID de instância.
- [ ] Reutilizar budgets/loot do Epic 2 sem duplicar sistema.
- [ ] Separar flags essenciais e decoração incidental.

**Acceptance Criteria:**

**AC1 — Dado** duas instâncias da mesma família, **quando** entrar e limpar uma, **então** somente seus portões/encontro mudam de estado.

**AC2 — Dado** sala limpa, **quando** sair e retornar, **então** inimigos não repopulam fora de regra explícita já existente.

**AC3 — Dado** minichefe/boss obrigatório, **quando** concluir o encontro, **então** evento, pista e saída são emitidos uma única vez para a instância.

**AC4 — Dado** quest ou recurso essencial, **quando** sortear extras da sala, **então** o objetivo essencial continua garantido independentemente do loot RNG.

**Verificação e evidência:** Teste de duas instâncias iguais, sala limpa e recompensa duplicada; logs de eventos idempotentes.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/main.gd; scripts/combat_hud.gd; tests/dynamic_map_test.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-05.03](stories-cenarios/scn-05-03.md)

### Story SCN-05.03: Transitar entre biomas sem perder a run

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar uma saída e chegar ao próximo ambiente,
**para** sentir continuidade na expedição.

**Dependências:** SCN-05.02.

**Requisitos:** SCN-FR12, SCN-FR14, SCN-UX08.

**Escopo e tarefas:**

- [ ] Criar interface de transição por destino/era/bioma em dados.
- [ ] Reusar dono da run e definir commit atômico da troca.
- [ ] Conectar identidade visual/sonora de entrada e saída.

**Acceptance Criteria:**

**AC1 — Dado** saída liberada, **quando** interagir, **então** RunDirector existente ou adaptador autorizado escolhe destino e materializa andar antes do spawn.

**AC2 — Dado** nova entrada, **quando** concluir carregamento, **então** atores aparecem em zona segura com efeitos antigos removidos e câmera reposicionada.

**AC3 — Dado** transição solicitada duas vezes, **quando** processar eventos, **então** ocorre uma única mudança, sem duplicar custo/recompensa.

**AC4 — Dado** geração do destino falha, **quando** tratar erro, **então** o andar anterior permanece recuperável e a run não é marcada como concluída.

**Verificação e evidência:** Teste de ida, falha, duplo acionamento e estados preservados; captura dos dois lados da transição.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/main.gd; scripts/combat_hud.gd; tests/dynamic_map_test.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-05.04](stories-cenarios/scn-05-04.md)

### Story SCN-05.04: Salvar e restaurar o mundo materializado

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** continuar exatamente a expedição interrompida,
**para** não receber outro mapa ao carregar.

**Dependências:** SCN-05.03.

**Requisitos:** SCN-FR13, SCN-NFR01, SCN-NFR05.

**Escopo e tarefas:**

- [ ] Estender schema versionado com manifesto e alterações por instância.
- [ ] Integrar migração ao Epic 1 já existente, sem segunda fonte de estado.
- [ ] Preservar IDs e compatibilidade de assets necessários ao save.

**Acceptance Criteria:**

**AC1 — Dado** run com salas abertas, destruídos e perigos alterados, **quando** salvar/carregar, **então** manifesto, posições, portas, descoberta e estado de objetos são restaurados.

**AC2 — Dado** catálogo mudou desde o save, **quando** carregar, **então** a política versionada resolve conteúdo compatível ou informa incompatibilidade sem regenerar silenciosamente.

**AC3 — Dado** save legado do mapa fixo, **quando** migrar, **então** ele continua no layout legado correspondente e pode ser concluído.

**AC4 — Dado** gravação interrompida, **quando** reabrir, **então** save válido anterior continua disponível; arquivo temporário não substitui o bom.

**Verificação e evidência:** Round-trip de sessão e fixtures de save legado, catálogo divergente e escrita interrompida.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/main.gd; scripts/combat_hud.gd; tests/dynamic_map_test.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-05.05](stories-cenarios/scn-05-05.md)

### Story SCN-05.05: Sincronizar o mapa no coop autoritativo

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** jogar o mesmo cenário que meu parceiro,
**para** não ver portas ou obstáculos em lugares diferentes.

**Dependências:** SCN-05.04.

**Requisitos:** SCN-FR13, SCN-NFR05.

**Escopo e tarefas:**

- [ ] Transportar manifesto inicialmente ou por mudança de andar, evitando reenviar arte/geometria completa a cada frame.
- [ ] Reutilizar ENet/snapshots e a política atual de reconexão.
- [ ] Adicionar hash e handshake de versão sem prometer física determinística de peers.

**Acceptance Criteria:**

**AC1 — Dado** host com andar gerado, **quando** convidado conectar, **então** host envia manifesto/versões e estado necessário antes de liberar movimento.

**AC2 — Dado** cliente com catálogo incompatível, **quando** validar entrada, **então** a sessão não prossegue com geometria divergente e informa o problema.

**AC3 — Dado** parede quebrada ou transição, **quando** replicar estado, **então** ambos mostram a mesma mudança de instância sem regeneração local independente.

**AC4 — Dado** pacote atrasado ou parceiro desconectado, **quando** continuar, **então** o host mantém autoridade e a IA substituta navega no mapa vigente.

**Verificação e evidência:** Teste com duas instâncias locais, conexão tardia, transição e quebra; registrar limitações de teste fora da LAN.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/main.gd; scripts/combat_hud.gd; tests/dynamic_map_test.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-05.06](stories-cenarios/scn-05-06.md)

### Story SCN-05.06: Aplicar atmosfera por bioma com transição legível

**Estado:** planned. **Horizonte:** A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** perceber a identidade do lugar pelo ambiente,
**para** sentir mudança de região sem perder leitura do combate.

**Dependências:** SCN-05.03.

**Requisitos:** SCN-FR07, SCN-UX06, SCN-NFR04.

**Escopo e tarefas:**

- [ ] Definir perfis de iluminação, partículas/água e referências sonoras.
- [ ] Usar transições controladas e budgets de efeitos.
- [ ] Integrar redução de efeitos à configuração existente.

**Acceptance Criteria:**

**AC1 — Dado** mudança de biome_id, **quando** entrar na área, **então** paleta de luz, ambiência e efeitos vêm do perfil correto.

**AC2 — Dado** bioma anterior descarregado, **quando** inspecionar efeitos ativos, **então** não restam névoa, reflexos ou som em coordenadas antigas.

**AC3 — Dado** opção de efeitos reduzidos, **quando** ativá-la, **então** efeitos decorativos diminuem sem apagar limites perigosos e sinais essenciais.

**AC4 — Dado** explosão e telegraph simultâneos, **quando** avaliar captura, **então** efeitos do bioma não ocultam o sinal obrigatório do combate.

**Verificação e evidência:** Capturas normal/reduzida e transição de dois perfis; medir custo frente ao baseline.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; scripts/main.gd; scripts/combat_hud.gd; tests/dynamic_map_test.gd. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-06: Ferroviário, Adega e Santuário com identidade própria

Setores podem formar andares distintos sem virar apenas recolorações das Docas.

[Arquivo de trabalho SCN-06.01](stories-cenarios/scn-06-01.md)

### Story SCN-06.01: Definir perfis de Ferroviário, Adega e Santuário

**Estado:** planned. **Horizonte:** B; setores atuais entregues em A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** distinguir os setores ao longo da run,
**para** perceber progressão ambiental e espacial.

**Dependências:** SCN-05.03, SCN-01.03.

**Requisitos:** SCN-FR01, SCN-FR07, SCN-UX07.

**Escopo e tarefas:**

- [ ] Registrar perfis e decidir em dados se são setores ou andares da era 1941.
- [ ] Definir matriz de compatibilidade e transições permitidas.
- [ ] Estabelecer quantidade mínima de templates por perfil antes de publicação.

**Acceptance Criteria:**

**AC1 — Dado** nomes da cadeia arquitetural, **quando** registrar os perfis, **então** cada um possui materiais, arquitetura, regras de salas e atmosfera próprios.

**AC2 — Dado** setor existente versus andar independente, **quando** configurar o papel, **então** o mesmo nome não duplica automaticamente uma era ou chefe obrigatório.

**AC3 — Dado** comparação dos três perfis, **quando** retirar sua cor dominante, **então** formas e arranjo de espaço ainda os diferenciam.

**AC4 — Dado** bioma ainda sem kit suficiente, **quando** selecionar catálogo publicável, **então** ele não aparece como andar completo.

**Verificação e evidência:** Fichas comparativas e validação de perfil incompleto; definição de andares tratada como decisão de produção, não fato já implementado.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-06.02](stories-cenarios/scn-06-02.md)

### Story SCN-06.02: Gerar um setor ferroviário com continuidade de trilhos

**Estado:** planned. **Horizonte:** B; setores atuais entregues em A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** explorar uma rede ferroviária coerente,
**para** ter variedade de caminhos sem trilhos desconectados.

**Dependências:** SCN-06.01, SCN-03.08, SCN-04.08.

**Requisitos:** SCN-FR07, SCN-FR10.

**Escopo e tarefas:**

- [ ] Expandir kit em lote de até três templates: plataforma, cruzamento e baia.
- [ ] Cadastrar compatibilidade de trilhos independente de porta de pedestres.
- [ ] Integrar o perfil ao gerador já validado.

**Acceptance Criteria:**

**AC1 — Dado** perfil ferroviário, **quando** gerar setor, **então** trilhos possuem continuidade ou terminais autorados em todas as conexões.

**AC2 — Dado** ramificação de combate, **quando** encaixar sala lateral, **então** o acesso de pedestres mantém largura sem exigir caminhar por obstáculo.

**AC3 — Dado** duas seeds, **quando** comparar setores, **então** mudam conexões/seleção de módulos mantendo gramática ferroviária.

**AC4 — Dado** fim do catálogo compatível, **quando** gerar, **então** o sistema usa fallback ferroviário e registra a falha.

**Verificação e evidência:** Duas seeds válidas, validação de terminais e percurso completo; medir repetição de templates.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-06.03](stories-cenarios/scn-06-03.md)

### Story SCN-06.03: Gerar um setor alagado com rota seca garantida

**Estado:** planned. **Horizonte:** B; setores atuais entregues em A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar adegas inundadas,
**para** reconhecer riscos sem depender de uma habilidade não disponível.

**Dependências:** SCN-06.01, SCN-03.11, SCN-04.08.

**Requisitos:** SCN-FR07, SCN-FR11.

**Escopo e tarefas:**

- [ ] Criar até três templates de adega, passagem seca e reservatório periférico.
- [ ] Definir nível/continuidade de água por conector.
- [ ] Usar validador para distinguir percurso essencial de exploração opcional.

**Acceptance Criteria:**

**AC1 — Dado** perfil alagado, **quando** gerar setor, **então** rota essencial respeita atores permitidos e não exige natação inexistente.

**AC2 — Dado** áreas de água contíguas, **quando** juntar módulos, **então** linha de maré e classes físicas não contradizem a emenda.

**AC3 — Dado** salas com baús/pistas, **quando** montar, **então** há posição válida de aproximação e retorno.

**AC4 — Dado** efeitos reduzidos, **quando** observar o setor, **então** perigos mantêm leitura por forma e borda.

**Verificação e evidência:** Teste de capacidades, emendas de água e retorno; captura do setor completo.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-06.04](stories-cenarios/scn-06-04.md)

### Story SCN-06.04: Gerar o Santuário com foco ritual e rotas claras

**Estado:** planned. **Horizonte:** B; setores atuais entregues em A.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** chegar a uma área de culto progressivamente mais intensa,
**para** entender seu centro narrativo sem perder orientação.

**Dependências:** SCN-06.01, SCN-03.09, SCN-04.08.

**Requisitos:** SCN-FR07, SCN-FR12, SCN-FR14.

**Escopo e tarefas:**

- [ ] Criar até três templates: limiar, nave ritual e ramificação de relicário.
- [ ] Definir intensidade de atmosfera por profundidade com limite de contraste.
- [ ] Cadastrar transição e hooks narrativos sem novos roteiros de diálogo.

**Acceptance Criteria:**

**AC1 — Dado** perfil de Santuário, **quando** gerar setor, **então** salas periféricas conduzem ao foco ritual definido por role.

**AC2 — Dado** motivos da Ordem, **quando** distribuir arte, **então** eles aparecem em pontos deliberados e não como ruído em todo piso.

**AC3 — Dado** passagem da Adega ao Santuário, **quando** conectar, **então** materiais e nível de piso usam módulo de transição próprio.

**AC4 — Dado** história obrigatória, **quando** selecionar variante, **então** sua âncora permanece alcançável e não depende de sala secreta sorteada.

**Verificação e evidência:** Duas montagens com foco ritual legível e teste de evento essencial.

**Contexto de implementação:** docs/ARQUITETURA_ROGUELIKE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-07: Explorar o Japão de Vincent

O cenário sustenta a comunidade, o conflito entre clãs e a despedida de Vincent.

[Arquivo de trabalho SCN-07.01](stories-cenarios/scn-07-01.md)

### Story SCN-07.01: Definir e produzir o kit visual do Japão

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** reconhecer a era de Vincent pela arquitetura,
**para** sentir um lugar distinto das Docas.

**Dependências:** SCN-01.05, SCN-05.06.

**Requisitos:** SCN-FR15, SCN-FR04, SCN-UX07.

**Escopo e tarefas:**

- [ ] Criar ficha do Japão com referências e proposta de materiais, evitando misturar estilos sem justificativa.
- [ ] Produzir lote piloto de até quatro peças com ferramenta de arte escolhida.
- [ ] Registrar origem, escala e mapa de uso.

**Acceptance Criteria:**

**AC1 — Dado** a lore sobre guerras entre clãs, **quando** definir a direção, **então** recorte de época/local e referências arquiteturais são registrados como decisão de conteúdo.

**AC2 — Dado** kit piloto, **quando** produzir madeira, bases de pedra, cobertura e limiar, **então** proporções e luz combinam entre si e com os personagens.

**AC3 — Dado** comparação com Docas, **quando** revisar a composição, **então** formas de telhado, pátio e fechamento diferem, não apenas a paleta.

**AC4 — Dado** asset futurista/portuário, **quando** validar pool, **então** ele é rejeitado salvo fratura temporal explicitamente cadastrada.

**Verificação e evidência:** Prancha com ator e confronto visual entre kits; decisão de recorte registrada antes do lote final.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-07.02](stories-cenarios/scn-07-02.md)

### Story SCN-07.02: Criar entrada e travessias do Japão

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** chegar e atravessar construções da era,
**para** entender os limiares e as diferenças de piso.

**Dependências:** SCN-07.01, SCN-04.08.

**Requisitos:** SCN-FR15, SCN-UX01, SCN-UX02.

**Escopo e tarefas:**

- [ ] Autorar dois templates modulares: chegada e passagem entre pátios.
- [ ] Definir origens, níveis e oclusão das coberturas.
- [ ] Validar acessos para os atores permitidos pela era.

**Acceptance Criteria:**

**AC1 — Dado** dois templates de chegada/travessia, **quando** encaixá-los, **então** soleiras, passagens cobertas e mudanças de nível respeitam conectores.

**AC2 — Dado** telhado ou viga diante do caminho, **quando** passar por baixo, **então** ator continua legível pela política de oclusão.

**AC3 — Dado** spawn de entrada, **quando** carregar setor, **então** há espaço seguro e visão de uma saída utilizável.

**AC4 — Dado** bioma sem terreno aquático declarado, **quando** sortear peças, **então** nenhuma ponte sobre água é acrescentada como obrigação arbitrária.

**Verificação e evidência:** Caminhada de ambos os lados e capturas com cobertura frontal; entrada procedural, não terceira imagem fixa obrigatória.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-07.03](stories-cenarios/scn-07-03.md)

### Story SCN-07.03: Criar pátios de combate japoneses

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** lutar entre pátios e estruturas de madeira,
**para** ter arenas com ritmo próprio e espaço de reação.

**Dependências:** SCN-07.02.

**Requisitos:** SCN-FR15, SCN-FR08, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir três templates: pátio aberto, pátio com galeria e área de treino, como propostas visuais.
- [ ] Reservar coberturas e spawns por função.
- [ ] Revisar pixel density do chão e telhados.

**Acceptance Criteria:**

**AC1 — Dado** três templates de combate, **quando** montar variantes, **então** cada um tem silhueta espacial distinta e conectores validados.

**AC2 — Dado** varandas/pilares, **quando** compor coberturas, **então** as bases coincidem com colisões e não escondem a área inteira.

**AC3 — Dado** combate próximo e à distância de teste, **quando** percorrer a sala, **então** há rota de aproximação e desvio sem corredor único acidental.

**AC4 — Dado** decoração de jardim/pátio, **quando** distribuir, **então** não ocupa aterrissagem nem imita projétil ou pickup.

**Verificação e evidência:** Capturas com inimigos de teste explicitamente marcados e validação dos três templates.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-07.04](stories-cenarios/scn-07-04.md)

### Story SCN-07.04: Construir os espaços da comunidade e despedida

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar a comunidade que Vincent protege,
**para** entender por que ele precisa ajudá-la antes de partir.

**Dependências:** SCN-07.03.

**Requisitos:** SCN-FR15, SCN-FR14.

**Escopo e tarefas:**

- [ ] Autorar área da comunidade e área de despedida.
- [ ] Definir hooks de estado narrativo e zonas seguras.
- [ ] Integrar eventos disponíveis; testar contratos futuros com fixtures identificadas.

**Acceptance Criteria:**

**AC1 — Dado** dois templates narrativos, **quando** montar a comunidade, **então** há âncoras de defesa, NPCs e despedida que não mudam para locais inacessíveis.

**AC2 — Dado** resgate essencial, **quando** gerar grafo, **então** seu espaço aparece pela regra de história, não por sorteio de sala rara.

**AC3 — Dado** defesa em andamento, **quando** ativar o estado visual, **então** rotas civis e de jogador são reconhecíveis e saídas seguem contrato.

**AC4 — Dado** evento encerrado, **quando** retornar ao espaço, **então** não dispara resgate/recompensa outra vez.

**Verificação e evidência:** Teste de âncoras e estados antes/depois; não declarar roteiro/resgate implementado se depender do backlog narrativo.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-07.05](stories-cenarios/scn-07-05.md)

### Story SCN-07.05: Compor arenas do minichefe e chefe do Japão

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** enfrentar os guardiões desta era em espaços próprios,
**para** sentir progressão até o conflito principal.

**Dependências:** SCN-07.04.

**Requisitos:** SCN-FR15, SCN-FR14, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir arena de minichefe e arena principal, sem inventar nome/lore de chefe.
- [ ] Separar fundo fixo opcional e objetos de estado.
- [ ] Definir footprint necessário para futuros ataques.

**Acceptance Criteria:**

**AC1 — Dado** papéis de minichefe e chefe, **quando** montar duas arenas, **então** há área útil, portas e centro de combate independentes da decoração.

**AC2 — Dado** chefe ainda sem kit final, **quando** dimensionar arena, **então** contrato de espaço/ataques fica documentado e o cenário é testado com volumes provisórios identificados.

**AC3 — Dado** portões fechando, **quando** iniciar evento, **então** nenhum parceiro fica preso fora sem regra de reunião válida.

**AC4 — Dado** vitória, **quando** liberar saída, **então** há rota até a pista/resgate e extração.

**Verificação e evidência:** Teste de portas, volumes e saída; captura de legibilidade com projéteis de teste.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-07.06](stories-cenarios/scn-07-06.md)

### Story SCN-07.06: Validar o catálogo procedural do Japão

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** explorar combinações coerentes desta era,
**para** ter variedade com identidade preservada.

**Dependências:** SCN-07.05, SCN-05.05.

**Requisitos:** SCN-FR15, SCN-FR10, SCN-FR20.

**Escopo e tarefas:**

- [ ] Cadastrar pesos, frequência, perfis e transições do Japão.
- [ ] Executar lote de validação e capturas representativas.
- [ ] Listar dependências de personagens/IA/narrativa separadamente do aceite ambiental.

**Acceptance Criteria:**

**AC1 — Dado** catálogo de nove templates das histórias anteriores, **quando** gerar lote de seeds, **então** todos os templates obrigatórios e ligações passam pelo validador.

**AC2 — Dado** rotas de defesa/despedida, **quando** validar missão, **então** elas preservam a ordem narrativa configurada.

**AC3 — Dado** salas repetidas, **quando** avaliar montagem, **então** limites de repetição e separação configurados são respeitados.

**AC4 — Dado** IA/resgate finais ainda não integrados, **quando** publicar catálogo de cenário, **então** ele fica validado para produção, mas a era não é liberada ao jogador como campanha completa.

**Verificação e evidência:** Manifestos, contact sheet e relatório de cenários; gate de lançamento da era explicitamente distinto.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-08: Atravessar o reino do Mago de Ferro

O cenário medieval conduz à fonte das vozes e comporta o encontro com Elias.

[Arquivo de trabalho SCN-08.01](stories-cenarios/scn-08-01.md)

### Story SCN-08.01: Definir e produzir o kit do reino medieval

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** reconhecer o reino de Elias,
**para** sentir sua monumentalidade e influência das fraturas.

**Dependências:** SCN-01.05, SCN-05.06.

**Requisitos:** SCN-FR16, SCN-FR04, SCN-UX07.

**Escopo e tarefas:**

- [ ] Criar ficha do reino e suas regras de intrusão tecnológica.
- [ ] Produzir quatro peças piloto e confirmar escala dos arcos.
- [ ] Cadastrar paleta, contraste e restrições de props.

**Acceptance Criteria:**

**AC1 — Dado** lore do Mago de Ferro, **quando** definir direção, **então** referências do reino e presença excepcional do mecha ficam registradas.

**AC2 — Dado** kit piloto de pedra, madeira, metal e arco, **quando** montá-lo, **então** materiais não copiam o galpão de 1941 com outra cor.

**AC3 — Dado** fontes sobrenaturais, **quando** compor luz, **então** elas são focos locais e mantêm fundo tranquilo para ataques.

**AC4 — Dado** objeto industrial moderno, **quando** validar pool, **então** somente tecnologia da expedição/fratura explicitamente autorizada pode aparecer.

**Verificação e evidência:** Prancha com Marty e volume do mecha; aprovação técnica de proporções e recorte visual.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-08.02](stories-cenarios/scn-08-02.md)

### Story SCN-08.02: Criar acesso e passagens do reino

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar portais de pedra e desníveis,
**para** compreender uma fortaleza sem obstáculos invisíveis.

**Dependências:** SCN-08.01, SCN-04.08.

**Requisitos:** SCN-FR16, SCN-UX01, SCN-UX02.

**Escopo e tarefas:**

- [ ] Produzir chegada muralhada e galeria com conexão de nível.
- [ ] Definir recortes de abóbada e sombras de contato.
- [ ] Cadastrar larguras e capacidades permitidas.

**Acceptance Criteria:**

**AC1 — Dado** dois templates de chegada/passagem, **quando** montar o setor, **então** arcos, soleiras e escadas conectam níveis declarados.

**AC2 — Dado** abóbada dianteira, **quando** passar sob ela, **então** oclusão não esconde a saída inteira.

**AC3 — Dado** volume de robô permitido, **quando** validar o percurso, **então** portais têm largura suficiente ou a restrição de robô é explícita antes da entrada.

**AC4 — Dado** escada selecionada, **quando** subir, **então** a altura visual coincide com o perfil físico.

**Verificação e evidência:** Percurso de ida/volta, teste de volume e captura da escada.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-08.03](stories-cenarios/scn-08-03.md)

### Story SCN-08.03: Criar câmaras de combate do reino

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** lutar em pátios e salões distintos,
**para** ter escolhas espaciais compatíveis com o combate.

**Dependências:** SCN-08.02.

**Requisitos:** SCN-FR16, SCN-FR08, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir lote de três templates com arquitetura consistente.
- [ ] Separar cobertura estrutural e decoração periférica.
- [ ] Definir sockets de máquina apenas na área apropriada.

**Acceptance Criteria:**

**AC1 — Dado** três templates de combate, **quando** montar variantes, **então** pátio, salão e ala de máquinas têm footprints e circulação próprios.

**AC2 — Dado** colunas de pedra, **quando** compor sala, **então** sua escala não domina o quadro nem cria labirinto por excesso.

**AC3 — Dado** ataques de teste, **quando** observar o piso, **então** ornamentos e símbolos não parecem telegraphs ativos.

**AC4 — Dado** espaço necessário ao mecha, **quando** reservar áreas, **então** props sorteados não ocupam giro, entrada ou saída.

**Verificação e evidência:** Testes de ocupação e capturas de combate em três layouts.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-08.04](stories-cenarios/scn-08-04.md)

### Story SCN-08.04: Construir o percurso até a fonte das vozes

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar sinais da influência sobre Elias,
**para** entender o objetivo ambiental do confronto.

**Dependências:** SCN-08.03.

**Requisitos:** SCN-FR16, SCN-FR14.

**Escopo e tarefas:**

- [ ] Produzir antecâmara de pistas e câmara da fonte.
- [ ] Definir âncoras e estados do dispositivo narrativo.
- [ ] Conectar contratos de destruição/selamento do backlog de Elias.

**Acceptance Criteria:**

**AC1 — Dado** dois templates narrativos, **quando** montar o percurso, **então** as pistas conduzem à câmara da fonte por conexões válidas.

**AC2 — Dado** objeto que representa a fonte, **quando** associar evento, **então** estado ativo/inativo tem diferença visual clara sem depender de cor.

**AC3 — Dado** fonte essencial, **quando** gerar a fase, **então** ela nunca fica em ramo secreto opcional.

**AC4 — Dado** efeitos de vozes/fratura reduzidos, **quando** jogar, **então** o objetivo continua identificável e acessível.

**Verificação e evidência:** Fixture de fonte ativa/inativa e prova de rota essencial; conteúdo narrativo final é dependência separada.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-08.05](stories-cenarios/scn-08-05.md)

### Story SCN-08.05: Compor arenas do guardião e do Mago de Ferro

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** enfrentar Elias dentro do mecha em um espaço adequado,
**para** ver seus ataques e alcançar a solução do confronto.

**Dependências:** SCN-08.04.

**Requisitos:** SCN-FR16, SCN-FR14.

**Escopo e tarefas:**

- [ ] Produzir duas arenas com volumes de combate documentados.
- [ ] Separar cenário de fonte, chefe e recompensa.
- [ ] Definir transformação visual pós-confronto sem alterar caminho inadvertidamente.

**Acceptance Criteria:**

**AC1 — Dado** arena principal, **quando** posicionar o volume máximo do mecha, **então** há áreas válidas de ação, entrada e saída sem encostar no cenário decorativo.

**AC2 — Dado** fonte de vozes ligada à resolução, **quando** definir sockets, **então** a posição é alcançável conforme o contrato do encontro.

**AC3 — Dado** arena de minichefe, **quando** conectar ao grafo, **então** ela possui papel próprio e não duplica a câmara principal.

**AC4 — Dado** vitória/resgate, **quando** mudar estado ambiental, **então** o espaço de recuperação é seguro e o mecha permanece entidade separada de Elias.

**Verificação e evidência:** Teste com volumes/ataques de fixture e estados antes/depois; integração real do chefe exigida para liberar a era.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-08.06](stories-cenarios/scn-08-06.md)

### Story SCN-08.06: Validar o catálogo procedural medieval

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** explorar combinações do reino,
**para** ter variedade sem interromper o caminho até Elias.

**Dependências:** SCN-08.05, SCN-05.05.

**Requisitos:** SCN-FR16, SCN-FR10, SCN-FR20.

**Escopo e tarefas:**

- [ ] Publicar BiomeDef medieval e limites de repetição.
- [ ] Verificar geometrias de mecha e transições.
- [ ] Registrar dependências externas de IA e resgate.

**Acceptance Criteria:**

**AC1 — Dado** nove templates do reino, **quando** gerar seeds, **então** conectores, portais e capacidades passam no validador.

**AC2 — Dado** fonte e arena, **quando** avaliar progressão, **então** estão na relação de dependência definida pelo encontro.

**AC3 — Dado** props de outra era, **quando** montar catálogo, **então** são recusados fora dos overlays autorizados.

**AC4 — Dado** kit de Elias incompleto, **quando** publicar cenário validado, **então** o acesso de campanha permanece condicionado ao conteúdo jogável real.

**Verificação e evidência:** Lote de manifestos, capturas e relatório de progressão; sem afirmar campanha pronta apenas com cenário.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-09: Infiltrar o laboratório de Íris

Ambientes de contenção e fuga apresentam Íris, prisioneiros e Spectre com caminhos claros.

[Arquivo de trabalho SCN-09.01](stories-cenarios/scn-09-01.md)

### Story SCN-09.01: Definir e produzir o kit do laboratório avançado

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** reconhecer uma instalação de pesquisa de outra era,
**para** perceber sua organização e ameaça próprias.

**Dependências:** SCN-01.05, SCN-05.06.

**Requisitos:** SCN-FR17, SCN-FR04, SCN-UX07.

**Escopo e tarefas:**

- [ ] Criar ficha de materiais, sinalização e estados limpo/contaminado.
- [ ] Produzir lote piloto de painel, vidro, piso e porta.
- [ ] Registrar transparência e política de colisão do vidro.

**Acceptance Criteria:**

**AC1 — Dado** a lore de Íris e Spectre, **quando** definir kit, **então** há distinção entre pesquisa, contenção e serviço.

**AC2 — Dado** quatro peças piloto, **quando** montar uma sala, **então** painéis, vidro, piso e iluminação seguem escala única.

**AC3 — Dado** luzes de status, **quando** configurar os estados, **então** alarme/interação são distinguíveis por forma ou padrão além de cor.

**AC4 — Dado** materiais de oficina de 1941, **quando** avaliar referências, **então** não são reutilizados como identidade principal do laboratório.

**Verificação e evidência:** Prancha de estados com personagem, ensaio de contraste e colisão do vidro.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-09.02](stories-cenarios/scn-09-02.md)

### Story SCN-09.02: Criar acessos e passagens de serviço

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** infiltrar e atravessar setores do laboratório,
**para** encontrar rotas sem portas enganosas.

**Dependências:** SCN-09.01, SCN-04.08.

**Requisitos:** SCN-FR17, SCN-UX02, SCN-UX05.

**Escopo e tarefas:**

- [ ] Autorar acesso técnico e passagem entre setores.
- [ ] Definir estados de porta e sockets de controle.
- [ ] Conectar condições a eventos existentes sem implementar minigame novo.

**Acceptance Criteria:**

**AC1 — Dado** entrada e corredor de serviço, **quando** encaixar dois templates, **então** portas, juntas de piso e parede são contínuas.

**AC2 — Dado** porta cenográfica, **quando** montá-la, **então** sua apresentação não imita a de uma porta interativa liberada.

**AC3 — Dado** porta com autorização, **quando** trocar estado, **então** arte, colisão e ícone correspondem ao mesmo estado.

**AC4 — Dado** passagem estreita, **quando** validar elenco permitido, **então** a geração evita bloqueio de ator necessário à missão.

**Verificação e evidência:** Teste de porta em cada estado e travessia com atores permitidos.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-09.03](stories-cenarios/scn-09-03.md)

### Story SCN-09.03: Criar salas de combate e contenção

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** combater em salas de pesquisa distintas,
**para** usar cobertura sem confundir cenário e perigo.

**Dependências:** SCN-09.02.

**Requisitos:** SCN-FR17, SCN-FR08, SCN-UX03.

**Escopo e tarefas:**

- [ ] Produzir três templates e conjuntos de bancada/contêiner.
- [ ] Separar cobertura destrutível, vidro e fundo.
- [ ] Cadastrar hazards somente quando houver regra de gameplay correspondente.

**Acceptance Criteria:**

**AC1 — Dado** três templates, **quando** montar áreas de pesquisa, contenção e manutenção, **então** cada sala tem gramática própria mantendo o kit comum.

**AC2 — Dado** vidro visível, **quando** testar colisão e tiro, **então** o material obedece à classe declarada, sem transparência implicar passagem.

**AC3 — Dado** feixe decorativo, **quando** revisar o cenário, **então** ele não usa a mesma sinalização de um hazard ativo.

**AC4 — Dado** objetos de bancada, **quando** variar decoração, **então** centro e áreas de esquiva continuam livres.

**Verificação e evidência:** Testes de vidro/cobertura e capturas com projéteis; matriz visual de decorativo versus perigoso.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-09.04](stories-cenarios/scn-09-04.md)

### Story SCN-09.04: Construir o setor de Íris, prisioneiros e Spectre

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar as pessoas e a instalação de pesquisa,
**para** entender a fuga e os experimentos pela organização do espaço.

**Dependências:** SCN-09.03.

**Requisitos:** SCN-FR17, SCN-FR14.

**Escopo e tarefas:**

- [ ] Produzir setor de prisioneiros e baia de experimento.
- [ ] Reservar caminhos de fuga e pontos de interação.
- [ ] Definir hooks com narrativa/Spectre sem mudar seu kit.

**Acceptance Criteria:**

**AC1 — Dado** dois templates narrativos, **quando** montar o setor, **então** cela/área de prisioneiros e baia do Spectre têm âncoras distintas.

**AC2 — Dado** sequência de fuga, **quando** ativar seus estados, **então** a rota dos prisioneiros e a do jogador não terminam em perigo inevitável.

**AC3 — Dado** Íris essencial à história, **quando** gerar o grafo, **então** seu setor aparece como obrigatório pela progressão, não por raridade.

**AC4 — Dado** resgate já registrado, **quando** retornar, **então** a composição usa estado posterior sem duplicar personagens ou recompensas.

**Verificação e evidência:** Teste de âncoras, rotas e estados antes/depois usando fixtures quando a quest real ainda não existir.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-09.05](stories-cenarios/scn-09-05.md)

### Story SCN-09.05: Compor arenas de contenção do laboratório

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** enfrentar minichefe e chefe em salas controladas,
**para** ler ataques mesmo com equipamentos ativos.

**Dependências:** SCN-09.04.

**Requisitos:** SCN-FR17, SCN-FR14, SCN-UX06.

**Escopo e tarefas:**

- [ ] Produzir duas arenas com luz e equipamento separados.
- [ ] Definir footprints dos futuros chefes sem inventar identidade narrativa.
- [ ] Implementar estados ambientais pelos contratos de encontro.

**Acceptance Criteria:**

**AC1 — Dado** duas arenas de encontro, **quando** montá-las, **então** máquinas periféricas deixam área de combate contínua.

**AC2 — Dado** alarme e ataques simultâneos, **quando** avaliar contraste, **então** telegraphs de combate permanecem prioritários.

**AC3 — Dado** fechamento da contenção, **quando** iniciar luta, **então** P1/P2 são reunidos conforme regra de encontro, sem aprisionamento externo.

**AC4 — Dado** encerramento, **quando** liberar saída, **então** há caminho até fuga/extração conforme o grafo.

**Verificação e evidência:** Capturas de alerta/normal/reduzido e teste de portas/saída com volumes de fixture.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-09.06](stories-cenarios/scn-09-06.md)

### Story SCN-09.06: Validar o catálogo procedural do laboratório

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** explorar layouts novos de pesquisa e fuga,
**para** manter objetivos e sinalização compreensíveis.

**Dependências:** SCN-09.05, SCN-05.05.

**Requisitos:** SCN-FR17, SCN-FR10, SCN-FR20.

**Escopo e tarefas:**

- [ ] Configurar perfil, pesos e conectores do laboratório.
- [ ] Validar estados de portas e rotas de fuga.
- [ ] Registrar dependências externas e qualidade por template.

**Acceptance Criteria:**

**AC1 — Dado** nove templates do laboratório, **quando** gerar o lote, **então** não há softlock de portas ou confusão entre setores.

**AC2 — Dado** estados limpo/contaminado, **quando** variar composição, **então** eles não alteram colisão sem variante geométrica correspondente.

**AC3 — Dado** ordem de resgate e fuga, **quando** validar progressão, **então** eventos obrigatórios preservam a sequência configurada.

**AC4 — Dado** IA/quests ainda incompletas, **quando** publicar catálogo, **então** a era continua indisponível como aventura completa.

**Verificação e evidência:** Manifestos de seeds, capturas de estados e relatório de rota garantida.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-10: Defender a comunidade de Letícia

Uma região antiga com identidade definida permite defesa e o encontro com Letícia.

[Arquivo de trabalho SCN-10.01](stories-cenarios/scn-10-01.md)

### Story SCN-10.01: Definir a região antiga e produzir seu kit piloto

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar uma comunidade com identidade própria,
**para** perceber o mundo que Letícia aprendeu a proteger.

**Dependências:** SCN-01.05, SCN-05.06.

**Requisitos:** SCN-FR18, SCN-FR04, SCN-UX07.

**Escopo e tarefas:**

- [ ] Elaborar ficha de lugar, forma de ocupação e materiais plausíveis, identificando escolhas novas.
- [ ] Resolver a direção antes de gerar o lote de produção.
- [ ] Produzir kit piloto com ferramentas disponíveis e registrar referências.

**Acceptance Criteria:**

**AC1 — Dado** a lore que não fixa lugar/época exatos, **quando** propor a direção, **então** geografia, clima, ocupação e referências materiais ficam documentados como proposta nova.

**AC2 — Dado** a aparência de Letícia, **quando** selecionar referências, **então** não se deduz automaticamente país, povo ou arquitetura de sua aparência.

**AC3 — Dado** a direção de produção escolhida, **quando** criar quatro peças piloto, **então** moradia, piso, limite e marco seguem materiais e escala comuns.

**AC4 — Dado** comparação com Japão e reino medieval, **quando** revisar o kit, **então** organização da comunidade e silhuetas distinguem esta região.

**Verificação e evidência:** Ficha de decisão e prancha com personagem; sem publicar ambientação ainda indefinida como cânone.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-10.02](stories-cenarios/scn-10-02.md)

### Story SCN-10.02: Criar chegada e caminhos da região antiga

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar o entorno da comunidade,
**para** entender abrigo, passagem e risco.

**Dependências:** SCN-10.01, SCN-04.08.

**Requisitos:** SCN-FR18, SCN-UX01, SCN-UX02.

**Escopo e tarefas:**

- [ ] Produzir chegada e caminho comunitário conforme ficha definida.
- [ ] Declarar conectores de terreno e regiões de oclusão.
- [ ] Validar capacidades disponíveis antes do resgate.

**Acceptance Criteria:**

**AC1 — Dado** a direção geográfica definida, **quando** autorar dois templates, **então** entrada e caminho de ligação usam terreno e construções compatíveis.

**AC2 — Dado** vegetação/rocha/cobertura prevista no kit, **quando** posicionar na borda, **então** não esconde limites caminháveis ou todos os ataques.

**AC3 — Dado** desnível existente, **quando** compor passagem, **então** ele tem subida/contorno claros e física correspondente.

**AC4 — Dado** capacidade especial de Letícia ainda bloqueada, **quando** validar a rota essencial, **então** Marty consegue completar o acesso sem precisar resgatá-la antes.

**Verificação e evidência:** Percurso com Marty básico e inspeção de altura/oclusão; sem presumir natação ou salto novo.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-10.03](stories-cenarios/scn-10-03.md)

### Story SCN-10.03: Criar espaços de defesa com circulação humana

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** defender áreas onde a comunidade vive,
**para** entender a função dos lugares durante o combate.

**Dependências:** SCN-10.02.

**Requisitos:** SCN-FR18, SCN-FR08, SCN-UX03.

**Escopo e tarefas:**

- [ ] Autorar três templates de defesa com funções determinadas pela ficha de lugar.
- [ ] Reservar zonas civis, combate e retorno.
- [ ] Separar decoração fixa de barricadas que mudam com o estado.

**Acceptance Criteria:**

**AC1 — Dado** três templates de defesa, **quando** montar variantes, **então** cada espaço possui função comunitária identificável e zona de combate.

**AC2 — Dado** props cotidianos, **quando** sortear, **então** eles se agrupam perto de seu uso e não cobrem rotas de evacuação.

**AC3 — Dado** criaturas da fissura, **quando** reservar spawns, **então** não aparecem sobre civis/atores sem aviso previsto no encontro.

**AC4 — Dado** caminho de retorno, **quando** validar variante, **então** nenhuma cobertura sorteada fecha a única saída.

**Verificação e evidência:** Teste de spawns e rotas em três templates; captura de defesa sem excesso de elementos.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-10.04](stories-cenarios/scn-10-04.md)

### Story SCN-10.04: Construir encontro com Letícia e espaço da pista

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** encontrar Letícia atuando pela comunidade,
**para** compreender sua escolha de partir e a pista do ataque.

**Dependências:** SCN-10.03.

**Requisitos:** SCN-FR18, SCN-FR14.

**Escopo e tarefas:**

- [ ] Autorar espaços narrativos a partir da ficha local.
- [ ] Cadastrar âncoras de Letícia, comunidade, pista e saída.
- [ ] Definir apresentação antes/depois sem escrever todo diálogo da quest.

**Acceptance Criteria:**

**AC1 — Dado** dois templates narrativos, **quando** montar, **então** há espaço de encontro/organização e de descoberta da pista.

**AC2 — Dado** rota principal, **quando** gerar a fase, **então** Letícia e a pista essencial não ficam atrás de sorteio de segredo.

**AC3 — Dado** evento pós-defesa, **quando** mudar estado, **então** a comunidade permanece presente e o cenário não sugere abandono sem resolução.

**AC4 — Dado** nova visita, **quando** restaurar estado, **então** não duplica resgate nem apaga o que já foi concluído.

**Verificação e evidência:** Teste dos estados e acessibilidade; contratos com narrativa explicitados.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-10.05](stories-cenarios/scn-10-05.md)

### Story SCN-10.05: Compor arenas da ameaça à comunidade

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** enfrentar minichefe e chefe relacionados à região,
**para** sentir conclusão da ameaça local.

**Dependências:** SCN-10.04.

**Requisitos:** SCN-FR18, SCN-FR14.

**Escopo e tarefas:**

- [ ] Produzir duas arenas com margens de combate.
- [ ] Reservar fissura e estados de ameaça em camadas separadas.
- [ ] Definir conexões ao percurso de defesa e retorno.

**Acceptance Criteria:**

**AC1 — Dado** duas arenas, **quando** produzir o conjunto, **então** usam a arquitetura/terreno definidos e não reaproveitam uma arena portuária recolorida.

**AC2 — Dado** fissura como foco visual, **quando** compor o fundo, **então** a ameaça fica legível sem esconder o espaço de luta.

**AC3 — Dado** chefes sem especificação final, **quando** testar arena, **então** volumes e margens provisórios são registrados, sem declarar balanceamento concluído.

**AC4 — Dado** vitória, **quando** abrir caminho, **então** o jogador consegue retornar à comunidade e ao objetivo narrativo.

**Verificação e evidência:** Teste de entrada/saída e projeção de ataques de fixture; revisão de escala local.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-10.06](stories-cenarios/scn-10-06.md)

### Story SCN-10.06: Validar o catálogo da região antiga

**Estado:** planned. **Horizonte:** B.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** explorar combinações coerentes e defender a comunidade,
**para** ter uma era completa em sua organização espacial.

**Dependências:** SCN-10.05, SCN-05.05.

**Requisitos:** SCN-FR18, SCN-FR10, SCN-FR20.

**Escopo e tarefas:**

- [ ] Publicar perfil e restrições de catálogo.
- [ ] Verificar progressão de capacidades e retorno à comunidade.
- [ ] Registrar lacunas de conteúdo sem bloquear a validação ambiental.

**Acceptance Criteria:**

**AC1 — Dado** nove templates da região, **quando** gerar seeds, **então** a identidade de materiais e regras de terreno se mantém.

**AC2 — Dado** grafo de defesa e encontro, **quando** validar, **então** atores alcançam objetivos sem depender do kit de Letícia antes do resgate.

**AC3 — Dado** elemento ainda não definido na ficha, **quando** entrar no catálogo, **então** ele é rejeitado ou volta à autoria, sem preenchimento aleatório.

**AC4 — Dado** defesa/chefes ainda provisórios, **quando** publicar cenários, **então** o acesso de campanha depende das entregas jogáveis externas.

**Verificação e evidência:** Manifestos, capturas e relatório de dependências da era.

**Contexto de implementação:** docs/LORE.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-11: Voltar ao Refúgio e alcançar o clímax

Acessos do hub e cenários do Arauto/R'lyeh sustentam a progressão e o selamento.

[Arquivo de trabalho SCN-11.01](stories-cenarios/scn-11-01.md)

### Story SCN-11.01: Organizar acessos às eras no Refúgio

**Estado:** planned. **Horizonte:** A para hub; B para clímax.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** escolher destinos pelo hub,
**para** entender o que está disponível e o que falta descobrir.

**Dependências:** SCN-05.03.

**Requisitos:** SCN-FR19, SCN-UX05, SCN-UX08.

**Escopo e tarefas:**

- [ ] Definir portas/terminais por EraDef e condições existentes de desbloqueio.
- [ ] Reconciliar placas, ícones e espaço de aproximação.
- [ ] Manter estações do hub separadas de templates de combate.

**Acceptance Criteria:**

**AC1 — Dado** hub de nave/metrô existente, **quando** adaptar acessos, **então** sua identidade autoral é preservada fora da geração procedural de fases.

**AC2 — Dado** era bloqueada, **quando** olhar/interagir com acesso, **então** estado visual e mensagem correspondem à disponibilidade real.

**AC3 — Dado** destino liberado, **quando** viajar, **então** o conector de entrada correto é resolvido sem coordenadas fixas herdadas.

**AC4 — Dado** retorno ou morte, **quando** chegar ao hub, **então** spawn seguro e estações existentes permanecem acessíveis.

**Verificação e evidência:** Teste de destino disponível/bloqueado, retorno e interação; captura com sinalização real.

**Contexto de implementação:** docs/LORE.md; docs/REFUGIO_0_5.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-11.02](stories-cenarios/scn-11-02.md)

### Story SCN-11.02: Criar transições visuais entre épocas

**Estado:** planned. **Horizonte:** A para hub; B para clímax.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** perceber claramente que atravessei uma fratura,
**para** entender o destino mantendo continuidade da run.

**Dependências:** SCN-11.01, SCN-05.06.

**Requisitos:** SCN-FR12, SCN-FR19, SCN-UX08.

**Escopo e tarefas:**

- [ ] Produzir assinatura visual de fratura compartilhada e variações de entrada por perfil.
- [ ] Reutilizar controle atômico de SCN-05.03.
- [ ] Evitar vídeo obrigatório ou serviço online para executar a viagem.

**Acceptance Criteria:**

**AC1 — Dado** uma transição autorizada, **quando** viajar, **então** o tratamento de luz/som e a entrada pertencem ao destino.

**AC2 — Dado** duas eras com materiais incompatíveis, **quando** conectar via fratura, **então** não há corredor físico que misture kits sem justificativa.

**AC3 — Dado** carregamento ou retorno interrompido, **quando** recuperar a sessão, **então** ator não fica entre dois andares e a origem válida continua recuperável.

**AC4 — Dado** efeitos reduzidos, **quando** viajar, **então** a transição mantém informação de destino sem exigir flashes intensos.

**Verificação e evidência:** Capturas normal/reduzida e teste de interrupção; mudança de destino claramente identificada.

**Contexto de implementação:** docs/LORE.md; docs/REFUGIO_0_5.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-11.03](stories-cenarios/scn-11-03.md)

### Story SCN-11.03: Construir o caminho e arena do Arauto

**Estado:** planned. **Horizonte:** A para hub; B para clímax.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** chegar ao penúltimo confronto,
**para** perceber a convergência do ritual.

**Dependências:** SCN-11.02, SCN-04.08.

**Requisitos:** SCN-FR19, SCN-FR14.

**Escopo e tarefas:**

- [ ] Produzir conjunto de aproximação, limiar ritual e arena.
- [ ] Definir overlay temporal permitido e orçamento de detalhes.
- [ ] Cadastrar hooks do penúltimo confronto.

**Acceptance Criteria:**

**AC1 — Dado** perfil do clímax, **quando** montar até três módulos de aproximação, **então** referências das eras aparecem como intrusões deliberadas, não sorteio irrestrito de assets.

**AC2 — Dado** arena do Arauto, **quando** instanciar, **então** entradas, área útil e foco do ritual têm âncoras claras.

**AC3 — Dado** vitória no encontro, **quando** ativar passagem, **então** o estado visual muda e libera a conexão final uma única vez.

**AC4 — Dado** chefe ainda não implementado, **quando** validar ambiente, **então** a arena usa volumes/estados de fixture e permanece marcada como cenário, não fase final pronta.

**Verificação e evidência:** Validação de grafo e transição; captura com escala de ameaça e piso legível.

**Contexto de implementação:** docs/LORE.md; docs/REFUGIO_0_5.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-11.04](stories-cenarios/scn-11-04.md)

### Story SCN-11.04: Construir R'lyeh com uma pista de combate confiável

**Estado:** planned. **Horizonte:** A para hub; B para clímax.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** enfrentar a manifestação cósmica sem perder orientação,
**para** sentir escala monumental com controle claro.

**Dependências:** SCN-11.03.

**Requisitos:** SCN-FR19, SCN-UX03, SCN-UX06.

**Escopo e tarefas:**

- [ ] Produzir fundo/placa de arena e camadas monumentais via ferramenta mais adequada.
- [ ] Definir pista física e pontos de ritual independentemente da pintura.
- [ ] Preparar estados pré-ritual/ativo/selado sem desenvolver IA do boss.

**Acceptance Criteria:**

**AC1 — Dado** fundo de R'lyeh e arena, **quando** compor, **então** geometria impossível fica visualmente fora do caminho físico ou tem regra explicitamente testada.

**AC2 — Dado** manifestação de Cthulhu, **quando** usar volumes de referência, **então** escala não obstrui todas as zonas de reação.

**AC3 — Dado** pontos de selamento, **quando** posicionar, **então** todos têm aproximação e leitura compatíveis com câmera e coop.

**AC4 — Dado** camadas animadas intensas, **quando** reduzir efeitos, **então** pontos, saídas e telegraphs permanecem visíveis.

**Verificação e evidência:** Percurso entre pontos e teste de oclusão com volumes; comparação de efeitos normal/reduzido.

**Contexto de implementação:** docs/LORE.md; docs/REFUGIO_0_5.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-11.05](stories-cenarios/scn-11-05.md)

### Story SCN-11.05: Validar retorno e cenário após o selamento

**Estado:** planned. **Horizonte:** A para hub; B para clímax.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** concluir o confronto e retornar ao Refúgio,
**para** ver a consequência da vitória sem estado quebrado.

**Dependências:** SCN-11.04, SCN-05.04.

**Requisitos:** SCN-FR19, SCN-FR14.

**Escopo e tarefas:**

- [ ] Conectar estados ambientais a eventos reais ou fixtures identificadas.
- [ ] Definir destino e posição segura de retorno.
- [ ] Testar resolução idempotente e persistência.

**Acceptance Criteria:**

**AC1 — Dado** evento de vitória final, **quando** aplicar estado ambiental, **então** a passagem é selada conforme lore, sem representar a morte definitiva de Cthulhu.

**AC2 — Dado** salvar após resolução, **quando** carregar, **então** cenário, saída e flag final permanecem consistentes.

**AC3 — Dado** pontos de ritual acionados em coop, **quando** concluir, **então** evento terminal não se duplica nem deixa o convidado em mapa antigo.

**AC4 — Dado** retorno ao Refúgio, **quando** encerrar transição, **então** o estado de campanha vem do sistema de progressão e o cenário só o apresenta.

**Verificação e evidência:** Teste de estados/retorno/save e registro das dependências de campanha; não liberar clímax antes da integração de chefes.

**Contexto de implementação:** docs/LORE.md; docs/REFUGIO_0_5.md; docs/PLANO_LORE.md. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.


## Epic SCN-12: Jogar cenários legíveis, fluidos e verificáveis

Cada lote de cenários passa por validação funcional, visual e de desempenho reproduzível.

[Arquivo de trabalho SCN-12.01](stories-cenarios/scn-12-01.md)

### Story SCN-12.01: Executar validação de geração em lote por bioma

**Estado:** planned. **Horizonte:** A e B por lote.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** receber mapas válidos com frequência conhecida,
**para** não encontrar falhas raras que interrompam a run.

**Dependências:** SCN-04.08, SCN-05.02.

**Requisitos:** SCN-FR20, SCN-FR11, SCN-NFR01, SCN-NFR03.

**Escopo e tarefas:**

- [ ] Criar comando headless de lote com corpus fixo e casos impossíveis.
- [ ] Exportar resumo e exemplos mínimos das falhas.
- [ ] Executar por catálogo ativo, repetindo quando ele ou o gerador mudar.

**Acceptance Criteria:**

**AC1 — Dado** um catálogo candidato a publicação, **quando** gerar pelo menos 1000 seeds fixadas por perfil habilitado, **então** cada saída publicada é válida ou usa fallback validado, sem estado parcial.

**AC2 — Dado** seed que falha, **quando** registrar o caso, **então** versões, catálogo, manifesto parcial, motivo e contagem de tentativas permitem reprodução.

**AC3 — Dado** dois processos e mesma entrada, **quando** comparar resultados, **então** hashes de manifesto ordenado coincidem.

**AC4 — Dado** resultados do lote, **quando** revisar distribuição, **então** há contagem de layouts únicos, repetição de templates, tempos e taxa de fallback; limites de aceite ficam registrados antes de liberar o catálogo.

**Verificação e evidência:** Relatório por biome_id/version e lista de seeds; validação geométrica não é confundida com avaliação estética.

**Contexto de implementação:** tests/scenery_test.gd; tests/scenario_layout_test.gd; tests/simulation_test.gd; tools/test_network.ps1. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-12.02](stories-cenarios/scn-12-02.md)

### Story SCN-12.02: Revisar qualidade visual e identidade por bioma

**Estado:** planned. **Horizonte:** A e B por lote.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** ver cenários bonitos e coerentes em qualquer montagem,
**para** reconhecer caminhos e ameaças rapidamente.

**Dependências:** SCN-12.01, SCN-02.06, SCN-05.06.

**Requisitos:** SCN-FR20, SCN-NFR06, SCN-NFR07, SCN-UX01, SCN-UX02, SCN-UX03, SCN-UX04, SCN-UX05, SCN-UX06, SCN-UX07, SCN-UX08.

**Escopo e tarefas:**

- [ ] Montar contact sheets por bioma, junção e resolução suportada.
- [ ] Revisar atores, projéteis, oclusão, interação e contraste.
- [ ] Manter lista de aprovação por template/versão e motivo de rejeição.

**Acceptance Criteria:**

**AC1 — Dado** cada família/conector publicado, **quando** capturar ao menos uma montagem representativa e uma densa, **então** não há costura, pixel incompatível ou geometria visual contraditória.

**AC2 — Dado** Farol e outros desníveis, **quando** revisar sem rótulos, **então** direção da subida e face alta ficam reconhecíveis.

**AC3 — Dado** capturas de biomas com cor reduzida, **quando** comparar, **então** materiais/silhuetas/organização ainda diferenciam regiões e sinais essenciais.

**AC4 — Dado** problema encontrado, **quando** fechar revisão, **então** o template é corrigido ou retirado do pool publicável, com evidência registrada.

**Verificação e evidência:** Capturas do jogo e checklist preenchido por família; automatização estrutural não substitui inspeção visual.

**Contexto de implementação:** tests/scenery_test.gd; tests/scenario_layout_test.gd; tests/simulation_test.gd; tools/test_network.ps1. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-12.03](stories-cenarios/scn-12-03.md)

### Story SCN-12.03: Medir fluidez, carregamento e memória

**Estado:** planned. **Horizonte:** A e B por lote.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** jogar sem travadas causadas pelo cenário,
**para** manter precisão de movimento e combate.

**Dependências:** SCN-12.01, SCN-05.06.

**Requisitos:** SCN-FR20, SCN-NFR03, SCN-NFR04.

**Escopo e tarefas:**

- [ ] Definir hardware, resolução e cena/carga de referência com limites de memória/carregamento.
- [ ] Medir e otimizar culling, placas, carregamento e descarte de recursos.
- [ ] Registrar budgets e alternativas de qualidade por perfil.

**Acceptance Criteria:**

**AC1 — Dado** máquina de referência de lançamento documentada, **quando** executar percurso representativo com combate e coop, **então** frame time P95 atende à meta de 16,7 ms ou o perfil é reduzido antes do aceite.

**AC2 — Dado** geração de andar, **quando** medir, **então** tempos P50/P95/máximo e falhas são registrados separadamente do frame time de combate.

**AC3 — Dado** dez trocas de andar, **quando** observar memória, **então** não há crescimento persistente sem limite de cache documentado.

**AC4 — Dado** geração/arte em execução normal, **quando** desconectar serviços externos, **então** o jogo continua; ferramentas de geração de arte não são dependências runtime.

**Verificação e evidência:** Relatório medido no hardware identificado, sem declarar compatibilidade de hardware não testado; limites pendentes impedem aceite, não são números inventados.

**Contexto de implementação:** tests/scenery_test.gd; tests/scenario_layout_test.gd; tests/simulation_test.gd; tools/test_network.ps1. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-12.04](stories-cenarios/scn-12-04.md)

### Story SCN-12.04: Testar exploração, coop e progressão em partidas completas

**Estado:** planned. **Horizonte:** A e B por lote.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** atravessar uma expedição do início à saída,
**para** ter confiança no percurso e na leitura de cada sala.

**Dependências:** SCN-12.02, SCN-12.03, SCN-05.05.

**Requisitos:** SCN-FR20, SCN-NFR05, SCN-NFR06.

**Escopo e tarefas:**

- [ ] Preparar roteiro curto com subida, dash, salto, segredo, loja, boss e retorno.
- [ ] Executar modalidades disponíveis e distinguir teste automatizado de playtest humano.
- [ ] Registrar problemas por gravidade e template, sem declarar teste físico de controle não realizado.

**Acceptance Criteria:**

**AC1 — Dado** três seeds selecionadas por perfil ativo: normal, densa e com muitos desvios, **quando** jogar em solo, parceiro e coop local, **então** objetivos e saídas são alcançados sem aprisionamento.

**AC2 — Dado** host/convidado, **quando** percorrer uma seed e transitar, **então** mapa, gates, destrutíveis e descoberta não divergem.

**AC3 — Dado** jogador sem conhecer o layout, **quando** observar escadas/entradas, **então** registro de playtest identifica hesitações e caminhos enganosos em vez de pressupor legibilidade.

**AC4 — Dado** falha de percurso ou leitura, **quando** concluir lote, **então** ela vira correção com seed/template/captura antes de liberar a família afetada.

**Verificação e evidência:** Relatório de partidas, seeds e modalidades; questões de percepção exigem observação humana para aceite final.

**Contexto de implementação:** tests/scenery_test.gd; tests/scenario_layout_test.gd; tests/simulation_test.gd; tools/test_network.ps1. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

[Arquivo de trabalho SCN-12.05](stories-cenarios/scn-12-05.md)

### Story SCN-12.05: Empacotar catálogos e documentar a autoria de novos biomas

**Estado:** planned. **Horizonte:** A e B por lote.

**Como** jogador (ou autor do cenário nas ferramentas de produção),
**quero** receber uma versão que contém todos os cenários necessários,
**para** jogar offline e permitir expansão sem quebrar eras anteriores.

**Dependências:** SCN-12.04.

**Requisitos:** SCN-FR20, SCN-NFR02, SCN-NFR08, SCN-NFR09.

**Escopo e tarefas:**

- [ ] Criar checklist de exportação de recursos dinâmicos e catálogos.
- [ ] Documentar contrato, pipeline PixelLab/Higgsfield, validação e promoção de template.
- [ ] Preservar só versões necessárias à política de saves; não apagar fontes ou trabalho paralelo.

**Acceptance Criteria:**

**AC1 — Dado** build exportada com perfis ativos, **quando** executar fora do editor e offline, **então** texturas, sons, shaders e templates necessários estão incluídos.

**AC2 — Dado** catálogo com recurso fora do pacote, **quando** validar exportação, **então** o erro identifica o arquivo antes da distribuição.

**AC3 — Dado** novo autor de conteúdo, **quando** seguir o guia, **então** consegue adicionar um template de teste, validá-lo e retirá-lo sem editar condicionais por bioma.

**AC4 — Dado** arte e código de terceiros usados, **quando** verificar pacote, **então** avisos/licenças e origens correspondem ao conteúdo realmente incluído.

**Verificação e evidência:** Smoke test do export offline e manual de autoria com exemplo; release final depende do restante do jogo, não só destes cenários.

**Contexto de implementação:** tests/scenery_test.gd; tests/scenario_layout_test.gd; tests/simulation_test.gd; tools/test_network.ps1. Ler também o índice e os contratos comuns. Confirmar nomes/pontos de extensão no checkout antes de alterar código.

**Fora de escopo:** mudar combate/kit de personagens, economia ou lore sem história correspondente; arte ausente não autoriza substituir este bioma pelo kit de outro.

## Conclusão da revisão

Planejamento concluído: 76 histórias em 12 épicos. Consulte o [índice navegável](stories-cenarios/README.md) e a [cobertura por requisito e limites da validação](validacao-cenarios.md). Todos os estados permanecem `planned`; nenhum critério foi marcado como atendido em runtime. Dependências de conteúdo futuro e decisões de direção são resolvidas nas histórias correspondentes antes de seu aceite.
