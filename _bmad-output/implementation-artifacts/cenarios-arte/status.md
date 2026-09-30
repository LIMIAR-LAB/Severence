# Frente Arte — pré-produção Farol/Docas

**Estado atual:** junções oeste/leste/norte aceitas como piloto visual estático em 12 capturas, com pequenas diferenças de amostragem do piso entre origens ainda a avaliar em movimento. Evidência em `connectors-review-r1/review.json`.  piloto material aceito com ressalvas; lote concreto SCN-02.02 entregue ao coordenador em `art/scenarios/scn-production/farol-docas-v01/stairs/manifest.json`. Face44, treads oeste/leste e composições nativas inspecionados. 40 capturas de integração arquivadas em três rodadas. Última rodada r3: aceite visual estático do piloto com correção isolada de sombra/anel; oito pares de origens idênticos foraUI. Correção ainda não aplicada no renderer compartilhado; movimento/combate e catálogo não aceitos. SCN-03 não liberado. As seções abaixo preservam o histórico de bloqueios e decisões; as entradas mais recentes prevalecem sobre estados antigos.

Atualizado em 30/09/2026. Skill aplicada: `gds-agent-game-designer` (Samus Shepard). Escopo autorizado: apenas `art/scenarios/scn-production/` e esta pasta. SCN-02 não concluído; SCN-01.05 e inspeção em jogo pendentes. Nenhum runtime ou status de história alterado.

## Evidência verificada

- Conceito e rejeições anteriores lidos e imagem inspecionada: `art/concept/cenario-direcao-v1/`. Manter pedra azulada, piso quieto e luz localizada; remover escadaria monumental e portas decorativas enganosas.
- `scripts/docks_map.gd:33–36`: patamar 800×360 em (2250,4000), rampas laterais 200×360 em x=2050 e 3050. Conjunto físico 1200×360; sala baseline 1700×1300.
- `scripts/simulation.gd:654`: altura contínua das rampas 0..44; patamar 44. Proposta visual inicial: quatro pisos de 50 unidades por lance e quatro espelhos de 11; não muda a simulação.
- `scripts/world_view.gd`: ator é desenhado com pés em p−(0,height), enquanto topo elevado legado usa retângulo sem essa projeção. Divergência enviada ao coordenador; não corrigida por esta frente.
- Coordenador confirmou bancada com Marty e Titan reais, quadro Titan 176×176; nenhuma comparação de sprite substitui validação em movimento.

## Entregas concretas

- Medidas e proposta de projeção: `art/scenarios/scn-production/farol-docas-v01/geometry.provisional.json`. É estudo, não contrato compartilhado.
- PixelLab building kit, square_topdown, tile nominal 64, materiais pedra/madeira/ferro, seed 440201, ID `4803f5b5-6c5c-419d-bb2f-5cb3d70b0bc8`: concluído. Uma chamada gerou automaticamente 80 formas; apenas sete amostras relevantes foram baixadas para `art/scenarios/scn-production/farol-docas-v01/kit/` e inspecionadas. Piso/paredes/madeira são candidatos de material; escadas automáticas 42/43 ficam excluídas do piloto. Outras 73 formas não avaliadas.
- Canvas exportado: 102×124 em cada amostra; área útil do piso: (19,62,64,48). Não aplicar resize para 64×64. Alpha real confirmado (0..255), PNGs não vazios e hashes SHA-256 registrados em `image-audit.json`.
- PixelLab Pro escada/patamar, 688×384, seed 440202, ID `78aaeca8-6702-49e3-8f2b-846c24c0ae54`: concluído e **rejeitado por geometria**. Repetiu lances extras do conceito, preservado em `stair-study-v01-rejected.png`. É proibido esticar para 1200×360.
- Uma única tentativa adicional sem referência de composição: ID `00c68d17-0c59-454c-a375-846d6c7926c4`, 256×320, seed 440203. Concluída e **rejeitada por orientação/volume**: faixas horizontais sugerem norte/sul; não há subida lateral ou face 44 verificável. Preservada em `stair-study-v02-rejected.png`; alpha 0..255 e canvas 256×320 conferidos. Nenhuma nova geração encomendada. Prompt completo em `stair-retry-request.json`.
- Prancha local `art/scenarios/scn-production/farol-docas-v01/index.html`: amostras, recortes, comparação de escala Marty/Titan e estudo rejeitado. **Não é captura do jogo e a renderização HTML não foi inspecionada**: navegador bloqueou protocolo de arquivo local; nenhuma tentativa de contornar o bloqueio. Os PNGs originais foram inspecionados individualmente.
- Ficha de autoria em `_bmad-output/implementation-artifacts/cenarios-arte/ficha-visual.md`; prompts exatos em `generations.json`; metadados do fornecedor em `kit-provider-result.txt`; seleção e motivos por peça em `review.json`.
- Verificação local: nove PNGs existentes, JSONs legíveis e fontes reais de Marty/Titan disponíveis. Nada foi promovido ao catálogo.

## Próximo passo e bloqueios

A tentativa pendente foi baixada e inspecionada; nenhuma geração deste lote segue ativa. Produção limitada a este lote até revisão. Após liberação SCN-01.05, adaptar ao contrato definitivo e integrar por meio do coordenador; validar pés/face de 44, escalas, contraste, transparência e circulação. SCN-03 depende de SCN-02.06 e permanece pendente. Não há lote novo ou continuação automática garantida após encerrar este turno.

## Adaptação ao contrato v1 — rodada seguinte

- Contrato lido em `cenarios-base/contrato-v1.md` e conferido contra `room_contract.gd`/`room_preview.gd`. Apenas translação e profundidades ground/foreground.
- Cinco recursos AtlasTexture concretos em `art/scenarios/scn-production/farol-docas-v01/atlas/`: pedra, madeira, paredes norte/sul/oeste. Nenhum PNG alterado ou esticado. `atlas-audit.json`: 5/5 regiões dentro da fonte e coincidentes com alpha_bbox; carregamento Godot ainda não executado.
- `layers.proposal.json`: três camadas de estudo de material, sem registrar template; omite material=floor para não disparar substituição pela textura do perfil. Slots futuros Farol separados, incompletos e explicitamente não publicáveis.
- Proposta explicada em `proposta-atlas-camadas.md`. Face 44 e escadas laterais corretas continuam ausentes; não usar parede 68 comprimida nem os estudos rejeitados.
- Baseline de trabalho com horário, commit e hashes por arquivo em `baseline-atlas-review.json`; não é snapshot atômico nem baseline de captura. Comparação ao final registra alterações concorrentes quando detectadas.

## Piloto de materiais liberado — inspeção da captura

- Coordenador informou 39 capturas SCN-01.05 e cinco testes base verdes; essa evidência não foi reexecutada pela frente Arte.
- Inspecionada `cenarios-base/captures/pilot-materials.png` em 1280×800, hash `efc1808118a7ab565d618486cc59021461cd1d7b6893090aef713c8e0855998b`: retângulo branco com Marty visível, sem pedra, madeira ou parede. **Escala/perspectiva/repetição dos materiais não avaliáveis**. Registro em `pilot-materials-review.json`. Coordenador avisado; nenhuma edição na captura/runtime.
- Captura mostra Marty, não Titan; não inferir validação dos dois. A escala indicada pelo capturador é ambiente1:1/Marty1,12, câmera sem zoom explícito no script consultado. Não transferir automaticamente o zoom1,22 das outras capturas para esta imagem.
- Proposta testável `escada-composicao-nativa.md` e `stairs-native-composition.proposal.json`: oito faixas25 por lance, elevações alternadas6/5 até44, piso nativo recortado do kit. Soma de alturas/run/profundidade verificada. Substitui apenas a hipótese geométrica preliminar de quatro degraus, sem alterar simulação ou arte.
- Faces de44 ainda exigem autoria; as duas gerações rejeitadas não foram reaproveitadas como solução. Não houve nova geração. SCN-02.02 e SCN-03 continuam não liberados.
- Próximo passo: receber captura com materiais visíveis, avaliar repetição/escala e comunicar o aceite ou correções; depois autorar faces e validar a composição de escadas pela bancada do coordenador.
- Bloqueio posterior informado pelo coordenador: conflito Git temporário em `scripts/world_view.gd:743` impede compilar o runtime durante merge de outro chat. Base corrigiu retenção de AtlasTexture, mas não há nova captura válida. Frente Arte não altera o conflito nem tenta capturar. Proposta geométrica está entregue; aguarda nova evidência para avaliação dos materiais.

## Captura corrigida — aceite restrito do piloto SCN-02.01

- Nova imagem 1280×800 inspecionada: `cenarios-base/captures/pilot-materials.png`, SHA-256 `8e1a52ecc09fdb6f888c6a6c5337b80cd9d019ccaec667a1363251069a681fa2`. Materiais visíveis. Relato branco preservado em `pilot-materials-review-white-capture.json`; avaliação atual em `pilot-materials-review.json`.
- **Aceite do piloto de direção material, com revisões antes da produção**: pedra discreta mantém Marty legível; parede tem topo/face e escala coerentes, sem vazios transparentes visíveis. Repetição da pedra/alvenaria presente, porém discreta.
- Madeira mantida apenas como amostra: faixas horizontais e motivos repetidos evidentes. Revisar arranjo/juntas e criar poucas variantes coerentes antes de uso extenso. Marty está somente na pedra; contraste sobre madeira não foi validado.
- Ambiente1:1/Marty1,12; câmera do script consultado com zoom padrão1. Titan ausente. Imagem estática não valida movimento, combate, oclusão ou escadas. Corte entre materiais é bancada, não conexão final aprovada.
- Não publica catálogo, não encerra SCN-02 completo e não altera histórias. Face44 e escadas pendentes. Nenhuma nova geração, imagem alterada ou runtime modificado pela Arte.

## Lote de autoria SCN-02.02 — peças concretas, aguardando bancada

Autorização recebida do chat de origem e contrato `cenarios-base/contrato-escadas-v1.md` do coordenador. Status corrigido de mojibake para UTF-8 preservando as entradas anteriores; nenhuma linha suspeita restante na checagem.

- Diretório: `art/scenarios/scn-production/farol-docas-v01/stairs/`. Interface concreta em `manifest.json`, schema_version1, escala1:1, height44, translate-only.
- `face44-0.png` e `face44-1.png`: 64×44, autoria determinística nativa com paleta observada do kit, três fiadas, cap e sombra baixa; nenhuma compressão de68 para44.
- `floor-stone.png`: recorte lossless64×48 da geração PixelLab já revisada; `tread-west.png` e `tread-east.png`:25×360 com iluminação/borda autoradas separadamente, sem espelho.
- Composições concretas transparentes: `stairs-west-composed.png`/`stairs-east-composed.png`200×404; `landing-top.png`800×360; `landing-face44.png`800×44; `module-native-preview.png`1200×404.
- Autoria reproduzível em `build_assets.py`; auditoria de dimensões/alpha/hashes e revisão em `inspection.json`; prancha ampliada de revisão `face-material-review.png` (não asset runtime).
- Ferramenta PixelLab de composição exata foi tentada; rejeitou antes de render por fonte maior que canvas final. Receita rejeitada preservada. Usada composição determinística autorizada sobre fontes PixelLab existentes, sem nova geração ilimitada ou reaproveitamento de escada rejeitada.
- Inspeção local confirmou duas subidas laterais baixas, face44 e material coerente. Um ajuste fortaleceu lábio oeste fraco; arquivos e hashes atualizados antes do aviso ao coordenador.
- Arquivos enviados ao coordenador para integração imediata e captura. **Pés, projeção, deslocamento de origem, circulação, dash/salto e combate ainda não aceitos por esta entrega de arte. Catálogo SCN-03 não liberado.**

## Primeira integração das escadas — oito capturas revisadas

- Recebidas e inspecionadas west/landing/east/front nas origens1800 e400, câmera0,7. Cópias intactas e hashes em `cenarios-arte/farol-review-r1/`; relatório `review.json`.
- Mantidos como candidatos: duas subidas baixas laterais, face44 nativa, perspectiva/material e alinhamento relativo nas duas origens. Sem lances extras.
- Pés **não aceitos ainda**: Titan encobre Marty; sombra do Titan fica abaixo dos pés no patamar; primeira1800-west sem piso externo, enquanto400-west e seguintes têm piso. Coordenador recebeu pedido de atores separados/projeção da sombra/warmup.
- Leitura do módulo sob tint azul é sutil por piso base com valor próximo; aguardar sondas limpas antes de decidir contraste adicional. Nenhum asset alterado após receber capturas.

## Segunda integração — atores separados, bloqueio de sombra confirmado

- 16 imagens arquivadas intactas e com hashes em `cenarios-arte/farol-review-r2/`. Revisadas8 sondas origem1800,2 representativas origem400 e comparados todos8 pares abaixo do cabeçalho.
- Piso inicial corrigido; oclusão mútua Marty/Titan removida. Face44/lances e forma dos pés sem recorte incorreto nas posições estáticas observadas. Arte mantida estável.
- 6/8 pares de origens idênticos fora do cabeçalho; Marty west/east diferem em1pixel na região do anel. Nenhuma divergência de textura/módulo demonstrada.
- **Contato visual ainda bloqueado por renderer**: sombra/anel de Marty e sombra de Titan no chão físico, corpos elevados. Achado comunicado e confirmado no desenho herdado; não corrigir comprimindo/deslocando peças de arte.
- Aceite restrito de autoria/forma/escala nativa; sem aceite final de pés, animação, combate ou catálogo. Coordenador recebeu relatório e mantém responsabilidade pela correção de projeção.

## Terceira integração — aceite visual estático restrito

- Nova rodada16 capturas corrigidas preservada em `cenarios-arte/farol-review-r3/`, hashes e avaliação em `review.json`; r2 permanece como histórico anterior, não foi sobrescrito.
- Inspeção dos8 probes origem1800 e representativos origem400: sombras/anel agora acompanham pés de Marty/Titan; nenhuma flutuação por deslocamento de44 observada. Face baixa e dois lances laterais coerentes. Sem alteração das peças entre r2 e r3.
- 8/8 pares de origens idênticos pixel-a-pixel abaixo do cabeçalho(y>=80). Escala/geometria da composição mantidas sob translação na evidência estática.
- **Aceite visual estático do piloto de arte, com a correção isolada em `tools/scenarios/base/farol_preview.gd`**. Não equivale a correção do runtime compartilhado, aceite de movimento nas juntas, combate, playtest humano ou publicação de catálogo.
- Reserva separada: barra de HP do Titan ainda usa posição física no código herdado. Contraste dos degraus sob tint azul/câmera0,7 é discreto; não se presume legibilidade de jogador iniciante sem observação.
- Coordenador recebeu aceite restrito e limites. Lote de autoria entregue; nenhuma história/status global foi alterado pela Arte.

## Soleiras e junções SCN-02.05 — autoria nativa independente

- Autorização do coordenador; nenhuma alteração no lote stairs, runtime ou catálogo. Hashes de todos os PNGs do lote stairs conferidos sem diferença.
- Dados antes da composição em `farol-docas-v01/connectors/specification.json`: largura útil200, altura0, centros locais W(0,600), E(1700,600), N(1600,0), fontes `build_doors`/RoomContract/FarolModule. Ordem atual door-1W,door-0E,door-2N; não confundir largura com profundidade36 do portão legado.
- Peças concretas em `connectors/`: W/E96×216 e N216×96, cada uma separada em floor/border e versão combined. Borda plana8 apenas fora da abertura; paleta/material docks-stone. `build_connectors.py` reproduz composição sem resize/espelho/rotação.
- `manifest.json` contém width/side/height/material_family, retângulos, fase, dimensões, fontes/hashes. Fase de piso ancorada na sala local(0,0), período64×48; corredor vizinho precisa compartilhar/converter fase.
- `contact-sheet.png` inspecionada. `inspection.json`: todas aberturas200, alturas0, zero pixels de borda dentro da abertura, zero discrepâncias de fase. Sem aceite runtime.
- Reserva: conexão norte chega ao canto leste; sua faixa externa direita precisa encaixe/clipping com parede. Coordenador recebeu peças para captura de junções. Não liberar SCN-03 por esta entrega.


## Junções integradas — revisão estática r1

Doze capturas preservadas com hashes em `connectors-review-r1/`: três junções, Marty/Titan, duas origens. Piso contínuo, aberturas sem degrau pintado e canto norte sem vazamento visível. Aceite limitado à arte estática da bancada. Comparação abaixo da UI encontrou pequenas diferenças nos detalhes do piso (delta máximo 14/255); não há invariância pixel a pixel. Causa não diagnosticada; informar a Base para revisão com câmera contínua. Nenhuma repintura solicitada. Travessia aprovada foi informada pela Base, não reexecutada por Arte. Paredes completas, movimento, combate, runtime compartilhado e catálogo seguem fora deste aceite; SCN-03 não liberado.


## Paredes/cantos — proposta concreta 1700×900

Dez camadas nativas entregues em `walls/manifest.json`, com peças reutilizáveis e previews inspecionados. Face visual68, largura lateral26, exterior ao footprint; três aberturas200 preservadas. Canto norte usa ombreira externa sem lintel. Zero interseções com união caminhável e21 PNGs anteriores preservados. Proposta de colisão conserva fronteira existente sem novos obstáculos. Detalhes em `paredes-farol-proposta.md`. Integração/runtime ainda pendentes com Base.


## Correção das paredes — revisão 2, footprint real1700×1300

Proposta inicial1700×900 retirada após falha do teste da Base; havia face sul dentro da sala real. Fonte conferida em `scripts/docks_map.gd:18`. Manifesto/build/PNG/preview/documento atualizados: sul/cantos y1300, laterais inferiores y700 com altura600. Norte/portas preservados. Verificação geométrica independente contra dimensões lidas do legado: zero interseções nas origens(1800,3700) e(400,-500). Preview corrigido inspecionado;21 PNGs de escadas/conectores preservados. Aguardando reteste de integração da Base.


## Paredes revisão 3 — passagem secreta sul

Face sul dividida em [0,1300,940,68] e[1068,1300,632,68], preservando atalho legado128 em x940..1068. Onze camadas; face contínua removida do manifesto. Recortes exatos confirmados contra placa anterior;21 PNGs stairs/connectors preservados. União verificada inclui corredor[940,1300,128,800]; nenhum cruzamento por parede. Preview/detalhe e proposta atualizados, aguardando integração da Base.


## Revisão no renderer real — aceite visual restrito

Cinco capturas estáticas e20 keyframes de4 trajetos inspecionados em `runtime-review-r1/`, cópias intactas com hashes. Nenhum defeito concreto encontrado nas paredes revisão3, canto norte, abertura do atalho sul ou emendas oeste/leste nos pontos mostrados. Nenhuma peça alterada. Relatório da Base registra4 travessias de81 frames, todas crossed,0 falhas e0 amostras de fundo; Arte leu o relatório e inspecionou5 keyframes por trajeto, não reexecutou teste nem assistiu todos324 frames. Aceite restrito à evidência visual apresentada; não inclui travessia Titan, combate, catálogo completo ou SCN-03.
