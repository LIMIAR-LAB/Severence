# Proposta de atlas e camadas — contrato v1

Estado: preparação isolada; piloto SCN-02 ainda não liberado. Nenhum registro no catálogo, runtime ou contrato compartilhado foi alterado. Baseline consultada, com horário e SHA-256 por arquivo: `art/scenarios/scn-production/farol-docas-v01/baseline-atlas-review.json`. Hash de commit sozinho não substitui o hash dos arquivos em checkout concorrente.

## Recursos concretos

Cinco arquivos `AtlasTexture` em `art/scenarios/scn-production/farol-docas-v01/atlas/` apontam para os PNGs originais. Apenas selecionam regiões; não há repintura, resize ou duplicação de imagem. `filter_clip=true` limita a leitura às regiões. A política nearest continua responsabilidade da textura/canvas no renderer.

| Recurso | Fonte | Região x,y,w,h | Uso proposto |
| --- | --- | --- | --- |
| stone-floor.tres | tile_0.png | 19,62,64,48 | Piso mineral candidato |
| wood-floor.tres | tile_44.png | 19,62,64,48 | Piso de madeira candidato |
| wall-north.tres | tile_1.png | 19,14,64,68 | Parede norte para revisar |
| wall-south.tres | tile_3.png | 19,42,64,68 | Parede voltada ao sul, borda ao norte do estudo |
| wall-west.tres | tile_4.png | 19,14,26,48 | Lateral isolada; encaixe pendente |

O kit veio com canvas 102×124; colocar os PNGs inteiros em mode=tile criaria vazios transparentes e espaçamento incorreto. AtlasTexture deve fornecer a dimensão útil ao `texture.get_size()` usado pela prévia. A compatibilidade de carregamento/importação ainda precisa ser verificada no Godot.

## Proposta consumível pela integração

`layers.proposal.json` contém um fragmento de três camadas com os campos do contrato v1: `id`, `rect`, `texture`, `mode`, `depth`. Retângulos JSON são arrays explicitamente documentados para conversão a Rect2; não foi criado outro carregador ou contrato paralelo.

Piso mineral 576×288 e madeira 576×288 formam patch 1152×288. Uma faixa de parede sul ocupa (0,-68,1152,68), sem fingir que essa parede corresponde ao desnível 44 do Farol. A amostra verifica leitura e repetição depois da liberação; não é sala jogável e não define conectores.

`material` foi omitido deliberadamente. No renderer consultado, `material=floor` troca `layer.texture` por `profile.materials.floor`; isso ocultaria justamente o material candidato que queremos comparar.

Somente `translate` é permitido. `depth` usa apenas `ground` e `foreground`; não inventar shadow, structure ou y-sort como valores suportados. Ordem de lista organiza as camadas de solo. Primeiro plano fica vazio nesta proposta: o contrato consultado não resolve oclusão por pés. Colisões seguem os dados da base e não surgem da textura.

## Slots do Farol que ainda não são camadas publicáveis

Origem local física do conjunto: (2050,4000) na baseline. Projeção proposta, ainda pendente da base: topo em (200,-44,800,360), face frontal em (200,316,800,44); cada lance tem envelope 200×404 porque cobre profundidade física 360 mais elevação 44. O envelope retangular não é sua máscara caminhável.

Não existe face nativa de 44 aprovada neste lote. A parede de 68 não deve ser comprimida. As escadas automáticas do kit são excluídas. O estudo integrado foi rejeitado. Slots futuros em `layers.proposal.json` são anotações sem textura e ficam fora de `layers`; não passar essas anotações ao contrato como se fossem recursos válidos.

Após SCN-01.05: integração pelo coordenador, carregamento de AtlasTexture, montagem à escala real com Marty/Titan, verificação de costura/repetição, pés/altura/sombra e duas origens traduzidas. Nenhuma captura de jogo foi produzida por esta proposta.

Rechecagem ao final detectou alteração concorrente em `room_contract.gd` para SHA-256 `5dda61ba979b410d6c8e027941ae60c097eae317bee4659207748ad94685e14c`. A leitura atual confirma nova validação de densidade para `mode=plate`, usando `world_units_per_pixel` com padrão 1,0. As três camadas propostas usam `tile`; os slots de placas continuam incompletos e separados. Uma futura placa de face 800×44 precisa corresponder a essa densidade, sem esticamento automático.
