# Ficha visual provisória — Farol / Docas 1941

## Linguagem

Pedra azulada dessaturada, madeira portuária envelhecida, ferro escuro oxidado. Luz direcional superior esquerda. Âmbar fica restrito a pontos funcionais, sem iluminar portas falsas. Piso de combate quieto; fissuras, limo e pregos agrupados, sem símbolos mágicos espalhados. Vista ortográfica superior oblíqua, norte para cima e eixos arquitetônicos horizontais/verticais; rejeitar losangos isométricos.

O conceito `cenario-direcao-v1` fornece somente linguagem visual. As duas escadarias em dois lances e o farol central não definem o footprint de produção.

## Escala e camadas

- Proposta de ambiente: 1 pixel de textura por unidade de mundo, sem interpolação e sem esticamento desigual. Piso piloto 64×64; a escala final depende da bancada com sprites reais.
- Marty padrão: fonte `assets/characters/marty/padrao/pixellab/idle.png`, células 96×96, origem dos pés (48,94). Renderer atual aplica escala visual 1,12; quadro visual 107,52×107,52. Não confundir quadro com altura visível da silhueta.
- Titan: fonte `assets/mech/titan_mk2_walk.png`, células 176×176, origem nominal (88,164); renderer também aplica 1,12, quadro visual 197,12×197,12. Não equivale ao raio de colisão.
- Altura física do piloto: 44. Projeção proposta separa deslocamento da superfície de escala do personagem. Desenhar superfície e pés sobre a mesma projeção, a ser estabilizada pela base.
- Camadas: piso baixo; topo e pisos das escadas; face e sombras de contato; estruturas periféricas; primeiro plano com política de oclusão. Luz/prop acionável não deve ficar gravado no piso.
- Um módulo completo ocupa 1200×360 no chão, com patamar 800×360 e duas rampas 200×360. Canvas projetado proposto 1200×404, origem 44 pixels acima da origem física. Parte norte da sala deve continuar livre.

## Regras de conexão

Materiais não determinam colisão. Piso e tampo ficam livres até a borda caminhável; moldura, corrimão e sombra não atravessam entradas. Para a primeira bancada, quatro espelhos de 11 e quatro pisos de 50 por subida representam visualmente uma inclinação contínua de 44/200. Essa representação precisa ser testada com os pés em movimento; se causar flutuação, reautorizar a discretização visual com a base.

Escadas oeste→leste e leste→oeste exigem autoria e iluminação coerente. Não espelhar/rotacionar uma peça para publicar outra orientação sem revisão. O estudo de acesso único gerado em 256×320 é menor que o footprint completo: mesmo se aprovado esteticamente, não autoriza importação esticada.

## Revisão antes de promover

Verificar imagem não vazia, tamanho, canal alpha real, bordas/costuras e repetição, perspectiva, orientação da subida, altura da face, pés, sombras e limite alto. Comparar com Marty e Titan reais, à escala de jogo, nas duas posições de mundo. A revisão de PNG não valida corrida, dash, salto, coop, tiros, conexão norte ou oclusão. Apenas integração e captura no jogo podem encerrar SCN-02.
