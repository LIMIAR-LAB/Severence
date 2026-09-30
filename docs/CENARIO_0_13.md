# Cenário 0.13: Docas grandes, fixas e dinâmicas

Esta versão recria o mapa em cima da arte 0.12 (`assets/environment/docks12/`, descrita em `CENARIO_0_12.md`) e das regras 0.12 (`REGRAS_0_12.md`: corações, portões e tentáculo).

> Nota histórica: a entrega 0.13 introduziu segundas levas em algumas salas. A regra atual as removeu: cada sala da expedição usa somente sua população inicial.

## Mapa

O mapa é **fixo**: só a seed muda os tipos de inimigo. Ele tem 13 salas e uma sala secreta, cerca de 9 600 × 7 100 px, com laços no estilo Enter the Gungeon.

| # | Sala | Destaques |
|---|---|---|
| 01 | Desembarque | Mockup da Sala 01: píer com estacas e barco, trilhos na diagonal, cais de granito, tentáculo. |
| 02 | Pátio dos Guindastes | 4 guindastes, contêineres e barris explosivos no centro. |
| 03 | Armazém 7 | Labirinto de caixas e canal para saltar. Baú. |
| 04 | Mercado de Peixe | Bancos, cestos, armadilhas de lagosta, braseiros e tentáculo. |
| 05 | Oficina | Comerciante e Titan. |
| 06 | O Último Gerador | Desafio opcional. |
| 07 | Depósito de Munição | Muitos barris explosivos. A parede rachada do topo leva ao Contrabando. |
| 08 | Pátio Ferroviário | Dois trilhos diagonais e vagões/contêineres. |
| 09 | Balcão do Farol | Balcão elevado com rampas. Leva à arena. |
| 10 | Capela do Culto | Altar, círculo ritual, bancos e baú. |
| 11 | Doque Seco | Fosso de água no meio e 2 tentáculos. |
| 12 | O Almirante das Profundezas | Arena do chefe, com duas entradas (Farol e Doque Seco). |
| 13 | Adega Inundada | Barris de óleo, canal, tentáculo. Baú. |
| ? | Contrabando | Sala secreta com baú e fragmento. |

As paredes são geradas pelas bordas das salas, cada uma com seu estilo (`ROOM_STYLE`):
- no topo, fachada de tijolo com lâmpadas, portas e cartazes;
- nas laterais, muro ou píer com estacas;
- embaixo, muro ou cais sobre a água.

Cada corredor vira um portão com torres e lanternas, que tranca a sala enquanto houver inimigos. A névoa mostra só o que já foi descoberto, no jogo e no mapa (Tab/M).

## Dinâmico

- **Caixas, barris, cestos e sacos de areia** quebram com tiros, golpes e explosões e viram destroços. Isso abre caminho e tira a cobertura; tiros inimigos também quebram. Caixas podem soltar moedas.
- **Barris explosivos** (vermelhos) estouram com 150 de raio. Ferem inimigos **e** o Marty (1 coração) e explodem os barris vizinhos em cadeia.
- **Encontros de sala:** cada sala usa uma única população inicial. Quando a última ameaça cai, os portões abrem e a sala não repopula. As ondas repetidas existem apenas na arena de treinamento.
- **Tentáculos:** 8 poças no mapa. Saltar por cima escapa.
- **Água:** cair num canal ou fosso devolve o Marty à borda de onde saltou, com meio coração a menos.
- Luz noturna com postes, janelas, braseiros e símbolos. Explosões iluminam a sala e tremem a câmera.

## Como editar o mapa

O layout está em **`tools/build_docks_map.py`**, que gera `scripts/docks_map.gd`. Não edite o `.gd` à mão.

```
python tools/build_docks_map.py
```

O script valida o layout antes de gravar:
- cada corredor encosta em 2 salas;
- nenhum prop bloqueia a boca de um corredor;
- todas as salas, baús e pontos são alcançáveis a pé;
- o Titan chega do spawn ao chefe;
- nenhum inimigo nasce dentro de um prop (se nascer, é empurrado para o lugar livre mais próximo).

Para adicionar props, use helpers como `ob("crate", x, y)`, `crate_pile`, `barrels(x, y, True)`, `sandbag_wall`, `hazard` e `dec`.

## Testes

- `tests/dynamic_map_test.gd`: tamanho do mapa, portões, caixa destrutível, barril em cadeia, sala sem repopulação, divisão do crawler e queda no fosso.
- `tests/scenery_test.gd`: névoa, arte, Sala 01 atravessável, portões e tentáculo.
- Captura: `-- --capture-docks-v04 --at=3450,6300 --zoom=0.45 --visit-all --capture-name=sul`.
