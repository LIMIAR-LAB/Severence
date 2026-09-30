# Titan e Spectre 0.15 — linguagem visual

> Registro histórico da versão 0.15. A arte atual da fusão cobre também a
> cabeça de Marty; veja [Sprites do Spectre e da fusão](./SPRITES_SPECTRE_FUSION.md).

## Titan-01

O Titan é uma máquina de guerra temporal, não uma armadura aberta. A cabine foi substituída por uma cabeça blindada fechada: capacete arredondado verde-oliva, viseira escura, dois olhos ciano e uma grade de boca metálica. Ele usa o mesmo desgaste industrial e a energia ciano que aparecem no equipamento de Marty.

- Atlas: `assets/mech/titan_v3.png`
- Grade: 10 × 5; células de 176 × 176 px.
- Linhas: frente, frente em três quartos, lado, costas em três quartos e costas.
- Colunas 0–4: parado e passada. Colunas 5–9: pilotado, turbo e canhão.
- Função em jogo: veículo pesado pilotável; a cabeça nunca abre para mostrar Marty.

## Spectre

Spectre é um polvo mecânico de exploração recuperado pela expedição. O corpo combina latão escurecido, válvulas de rádio, núcleo/olho ciano, oito tentáculos curtos e fumaça violeta do vazio temporal. Ele é pequeno, claramente abaixo da altura de Marty, e flutua ao segui-lo.

- Atlas: `assets/mech/spectre_octopus_v2.png`
- Grade: 4 × 4; células de 128 × 128 px.
- Colunas: parado, dois movimentos de flutuação e disparo de energia/"tinta" ciano.
- Função em jogo: acompanha Marty, atira e fornece sua energia durante a fusão.

## Fusão com Marty

A fusão não troca Marty por um monstro. O polvo se abre em matéria simbiótica: tentáculos violeta-preto envolvem ombros, braços e botas, o núcleo aparece no peito e o rosto, goggles e jaqueta de Marty continuam visíveis. O resultado é rápido e ameaçador, mas ainda legível como o protagonista.

- Atlas: `assets/marty/spectre_fusion_v2.png`
- Grade: 4 × 4; células de 160 × 160 px.
- O render continua usando `facing` para escolher a linha e ação/movimento para escolher a coluna.

## Regra de arte

Os três atlas usam pixel art sem interpolação, fundo transparente e luz ciano para tecnologia temporal. Violeta aparece somente no Spectre e na simbiose, marcando a influência cósmica sem confundir os dois aliados com inimigos.
