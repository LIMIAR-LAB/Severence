# Farol — proposta concreta de paredes e cantos

Revisão 3 (inclui passagem secreta sul): substitui integralmente a proposta inicial1700×900, incompatível com o footprint real. Confirmado em scripts/docks_map.gd:18; corrigido após teste da Base. Entrega candidata para integração 02.05/06. Origem local (0,0), footprint 1700×1300. Escadas e conectores existentes preservados; 21 PNGs conferidos por hash. Nenhuma geração de cenário.

## Geometria e peças

Manifesto: `art/scenarios/scn-production/farol-docas-v01/walls/manifest.json`. Onze camadas plate nativas, em unidades por pixel 1:1, apenas translação. Recortes reutilizáveis: faces norte/sul 64×68, bordas oeste/leste 26×48 e cantos 26×68. Peças compostas já têm exatamente o tamanho do rect: não escalar. Faces extraídas do kit existente; borda leste e acabamento dos cantos compostos deterministicamente com a mesma paleta, sem espelhar imagem.

| Peça | Rect local x,y,w,h |
|---|---|
| Face norte | 0,-68,1500,68 |
| Canto noroeste | -26,-68,26,68 |
| Oeste superior | -26,0,26,500 |
| Oeste inferior | -26,700,26,600 |
| Ombreira nordeste | 1700,-68,26,68 |
| Leste superior | 1700,0,26,500 |
| Leste inferior | 1700,700,26,600 |
| Face sul esquerda | 0,1300,940,68 |
| Face sul direita | 1068,1300,632,68 |
| Canto sudoeste | -26,1300,26,68 |
| Canto sudeste | 1700,1300,26,68 |

Altura de face visual: 68; espessura lateral: 26. Altura caminhável continua 0 e patamar existente continua 44. A face de 68 não define uma superfície elevada, obstáculo ou rampa. O lado sul adota fachada exterior em corte, sem projetar parede sobre os pés. Esse tratamento é intencional e precisa ser mantido ao integrar.

## Ordem, aberturas e colisão

Desenhar piso e conectores primeiro, depois estas camadas ground na ordem do manifesto, depois atores e face existente da escada conforme ordenação já implementada. Não marcar material=floor. Não recortar as paredes ao footprint caminhável: estão integralmente fora dele. O renderer deve incluir a margem exterior no culling visual.

Oeste/leste: passagem y=500..700, largura200. Norte: passagem x=1500..1700, largura200. São intervalos de borda, não centros de textura. Nenhuma peça ou colisão nova cobre esses intervalos. Não duplicar bordas dos conectores.

No canto norte, NÃO instalar um canto nordeste convencional nem lintel: ambos poderiam atravessar a porta que chega a x1700. Face norte termina em1500; ombreira externa está em1700..1726. A parede lateral segue ao sul a partir de y0. Continuação ao norte de y=-68 pertence ao corredor vizinho; não é gerada por esta entrega.

Não são necessários novos obstáculos: a união caminhável de sala e corredores deve manter sua colisão de fronteira. Não expandir o footprint para incluir decoração. Se o runtime não bloqueia saída dessa união, o proprietário deve resolver a fronteira separadamente; o manifesto não presume que isso já foi validado.

## Verificação e limites

Verificado: onze PNGs com dimensões iguais aos rects; zero interseções geométricas entre paredes e união caminhável; 21 PNGs de escadas/conectores intactos. Preview geral e detalhe norte inspecionados visualmente. Arquivos em walls/perimeter-native-preview.png e walls/north-corner-detail.png. São composição local e recorte 1:1, sem atores, não capturas de jogo.

Pendente com Base: inspeção com Marty/Titan junto às paredes e portas; câmera contínua/culling exterior; continuação do corredor norte; confirmação de fronteira física; integração de luz/tint. Nenhum aceite global 02.05/06, catálogo ou SCN-03 concedido por esta proposta.


## Passagem secreta sul preservada — revisão 3

Fonte conferida: `scripts/docks_map.gd:88`, SHORTCUTS[0] Rect2(2740,5000,128,800), local(940,1300,128,800). Abertura128 em x940..1068, y1300. Conector auxiliar separado, type=shortcut, centro(1004,1300), normal(0,1), height0; três walk gates inalterados. Face sul inteira retirada do manifesto. Duas placas novas são pixel a pixel iguais aos recortes correspondentes da face anterior; a fase direita começa em1068 mod64=44. PNG antigo permanece apenas como referência histórica, não deve ser integrado. União de verificação e preview incluem corredor segredo completo. Detalhe em walls/south-shortcut-detail.png inspecionado. O estado de bloqueio/abertura do segredo continua responsabilidade do runtime existente.
