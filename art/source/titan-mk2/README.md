# Titan-01 Mk II — sprites em jogo

O visual segue a proposta PixelLab em `art/source/pixellab/titan_mk2_new/`. As três
fontes desta pasta foram criadas com a ferramenta integrada de geração de imagens
e empacotadas por `tools/import_titan_mk2.gd`. Execute o importador no Godot para
recriar os atlas em `assets/mech/`.

| Fonte | Atlas | Uso |
| --- | --- | --- |
| `walk-source.png` | `titan_mk2_walk.png` | Cinco vistas, repouso e quatro passos. |
| `cockpit-source.png` | `titan_mk2_cockpit.png` | Escotilha frontal fechando e abrindo. |
| `marty-board-source.png` | `marty_board_titan.png` | Marty padrão aproximando-se e subindo no cockpit. |

O renderer espelha as vistas laterais para completar oito direções. A folha de
embarque do Marty padrão também serve na saída com os quadros em ordem inversa.
As demais roupas, a armadura e o Echo conservam a representação anterior durante
essa transição até terem arte própria.

## Briefings usados

1. **Caminhada:** preservar exatamente o Titan-01 Mk II da referência, em pixel
   art transparente; cinco linhas (frente, frente diagonal direita, lado direito,
   costas diagonal direita, costas), cinco colunas (repouso e quatro fases de
   passos alternados), escala e base dos pés consistentes, peças inteiras e
   separadas; sem piloto, cenário, texto ou efeitos.
2. **Cockpit:** preservar a mesma identidade em seis quadros frontais: fechado,
   placas separando, meia abertura, aberto com assento vazio, aberto, fechado.
   Cabeça e visor permanecem fechados; fundo transparente; sem piloto ou texto.
3. **Marty:** preservar cabelo, óculos e roupa azul e branca da referência em
   cinco quadros vistos de trás: parado, passo elevado, mãos alcançando a borda,
   escalada e tronco entrando. Apenas o personagem, sem robô, cenário ou texto.
