# Marty Padrão — arma somente no disparo

## Problema

A arma permanecia desenhada como uma camada separada em quase todas as ações do novo Marty. Em repouso ela parecia flutuar à frente do personagem e, durante o ataque corpo a corpo, contradizia a animação desarmada.

## Comportamento esperado

- O Marty Padrão exibe a arma somente enquanto executa a animação `shoot`.
- `idle`, `run`, `jump`, `evade`, `melee`, `hurt` e `defeat` não exibem a camada da arma.
- A posição da arma durante o disparo acompanha os oito rumos da mira e o corpo mais alto do novo atlas.
- Durante a transformação Ômega, a camada fica oculta para não misturar a arma de uma roupa com o sprite da outra.
- As roupas que ainda usam o atlas legado mantêm o comportamento existente.

## Verificação

O teste de ações do Marty cobre a regra de visibilidade, as oito âncoras do novo atlas, o caso de transformação e a preservação da âncora legada. Ele também continua validando as folhas de oito direções.
