# Docas de 1941 — mapa fixo 0.11

O mapa **não é gerado**: está desenhado em `scripts/docks_map.gd` (salas, corredores, obstáculos, decoração, baús e posições de inimigos). A seed só sorteia o tipo de inimigo em cada ponto e pequenos desvios de posição.

## Salas (≈ 6× a área anterior; cada uma maior que a tela)

| # | Sala | Destaques |
|---|---|---|
| 01 | Desembarque (1200×800, tábuas) | cabeços de amarração, contêiner, chave |
| 02 | Pátio dos Guindastes (1600×1100) | 4 bases de guindaste, 2 contêineres, trilhos, sacos de areia |
| 03 | Armazém 7 (1300×900, tábuas) | pilhas de caixas em corredores, **canal para saltar**, baú |
| 04 | Oficina | comerciante, Titan estacionado |
| 05 | O Último Gerador | desafio opcional de 55s |
| 06 | Depósito de Munição (1500×1200) | laço com o Gerador, sala mais cheia (inimigos pesados) |
| 07 | Balcão do Farol | **balcão elevado com duas rampas** |
| 08 | Capela do Culto | altar, bancos, velas, tapete, baú |
| 09 | O Almirante das Profundezas (2000×1500 + alas) | 4 colunas de cobertura, **cápsula de extração** |
| ? | Contrabando | aberta golpeando a parede rachada no Depósito de Munição |

## Mapa e minimapa (estilo Enter the Gungeon)

- Minimapa no canto superior direito acompanha o Marty.
- **TAB, M ou clique no minimapa** abre o mapa completo: salas visitadas acesas com nome, não visitadas apagadas, ícones de baú, oficina, desafio, cápsula, chefe, chave e Titan.

## Cápsula de extração

Câmara de upgrade branca e dourada com tubo de vidro no alto da arena do chefe. Selada (apagada) até o Almirante cair; depois acende, com pilar de luz, anéis subindo e partículas.

## Dificuldade

- Inimigos com ~50% mais vida, cadência ~40% maior e projéteis mais rápidos/fortes (cultista às vezes atira 2, soldado dispara leque de 6). Almirante: 600 de vida e ataques mais rápidos.
- Inimigos só acordam ao ver o Marty (linha de visão) ou ao levar tiro, para as salas grandes não virarem uma avalanche.
- **Enrage do Almirante:** depois de 150s de combate ativo contra o chefe, a cadência de todos os ataques dele encolhe para 60% (furor permanente pelo resto da luta) — evita que uma equipe passiva trave a luta indefinidamente. Aviso via mensagem na tela quando o furor começa (`scripts/simulation.gd`: `BOSS_ENRAGE_TIME`, `BOSS_ENRAGE_SCALE`, `enrage_scale()`).

## Armadura

Ômega agora dura **5s** e recarrega **60s** (começa carregando ao entrar na expedição). Baús recarregam na hora.

## Tela

Janela padrão 1600×1000 (a interface continua em 1280×800 e escala) e câmera da expedição mais aberta (zoom 0,82) — mostra mais sala de cada vez.

## Arte nova (`tools/make_docks_art.py` → `assets/environment/docks/`)

Piso de tábuas, parede lateral de tijolos (substitui o cinza liso), 3 contêineres, base de guindaste, cabeço, gerador, altar, banco, caixa de munição, caixa de peixe, velas, poça, âncora, rachadura, cápsula e chave/moeda sem fundo preto. A água agora é desenhada na proporção correta (antes estava esticada).
