# Farol — proposta geométrica de composição nativa

Não é arte final nem aceite de SCN-02.02. Os dois estudos rejeitados permanecem excluídos. Nenhuma nova geração, edição de imagem ou alteração de runtime foi feita nesta rodada.

## Montagem testável

Dados completos em `art/scenarios/scn-production/farol-docas-v01/stairs-native-composition.proposal.json`. Origem física (2050,4000), conjunto 1200×360, canvas 1200×404 com origem 44 acima do chão. Patamar 800×360 em x=200; face frontal 800×44. As duas escadas usam 200×360 e orientação autorada, sem espelho ou rotação de textura.

Propõe-se substituir os quatro degraus largos preliminares por oito faixas de 25 unidades. Alturas dos pisos a partir da entrada: 0, 6, 11, 17, 22, 28, 33 e 39; a chegada ao patamar tem 44. Os oito incrementos alternam 6/5, totalizando 44. Isso é hipótese para bancada; não altera a altura contínua 44/200 da simulação. A aproximação visual fica a menos de 6 unidades da altura física, em vez de até 11 no estudo preliminar. Essa diferença ainda pode parecer flutuação e precisa de avaliação em movimento.

Cada faixa de piso usa pedra na escala nativa: seções de 25×48, sete repetições e uma seção final de 25×24 completam a profundidade 360. Cortes escolhem pixels da fonte 64×48, sem reamostragem. Manter a fase de textura ancorada no módulo, não reiniciar o mesmo desenho a cada faixa; isso evita duplicar a mesma rachadura em oito colunas. A proposta de recortes exige uma pequena composição autorada antes de virar `plate`; não presumir que o contrato atual recorta polígonos ou controla fase por faixa.

O contorno sul da escada sobe em pequenos patamares. As faces laterais do sul preenchem somente entre y=360−altura e y=360. Sob a projeção `(x,y−altura)`, espelhos orientados oeste/leste ficam quase de perfil: não desenhar largas faces frontais entre faixas como se fossem degraus norte/sul. A leitura deve vir do contorno, lábios estreitos, sombra de contato e continuidade na chegada. Isso explica por que a simples rotação de escadas norte/sul não resolve o problema.

## Peças que faltam autorar

Uma pequena família de faces de pedra nativas 64×44: trecho regular, variação de junta e término. A pedra/paleta podem seguir o kit; a arte de 68 pixels não pode ser achatada. Criar sombreamento superior esquerdo e base discreta, sem luminosidade de porta. Nos extremos, os pedaços são recortados ao tamanho útil; a face 800×44 usa doze trechos de 64 mais término de 32, sem escala desigual. Avaliar repetição antes de aprovar essa montagem.

As faces parciais das escadas podem usar recortes altos de 6..39 pixels de uma família coerente, com origem/base comuns e juntas revisadas. Não inventar uma pilha de paralelepípedos que pareça muro em vez de subida. A borda externa deve continuar aderida ao perfil de cada degrau. Uma futura placa completa precisa ser nativa 1200×404 ou dividida em placas nativas correspondentes às regiões, respeitando a validação de densidade do contrato.

## Percurso para verificar

Na origem local, avaliar oeste em x=0,25,50,75,100,125,150,175,200 e leste em x=1200,1175,1150,1125,1100,1075,1050,1025,1000, sempre em y=180. A altura física é `44*x/200` no oeste e `44*(1200-x)/200` no leste; verificar também um ponto antes/depois de cada junta. Testar y=40 e y=320 para identificar problemas no contorno norte/sul. Origem duplicada sugerida (4000,7000): todos os dados devem apenas transladar.

Capturar sem texto RAMPA, com Marty/Titan reais, câmera de jogo, sombra e pés visíveis; subir e descer, dash e salto. O pass/fail de legibilidade não pode vir somente das coordenadas. A região norte da sala inteira deve continuar aberta. O catálogo SCN-03 permanece fechado até os gates de SCN-02.
