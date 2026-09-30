# Ações dos monstros das Docas

Estas seis folhas transparentes foram geradas com a ferramenta interna `imagegen`, usando os atlas PixelLab existentes em `assets/enemies/` como referências visuais. Cada folha tem oito linhas (sul, sudeste, leste, nordeste, norte, noroeste, oeste, sudoeste) e duas colunas (ataque e morte). As poses do bombardeiro mostram preparação e carcaça após a explosão.

O pedido de geração preservou a identidade, paleta e direção de cada monstro e exigiu poses separadas, fundo transparente e sem cenário. `tools/build_enemy_action_sheets.py` recorta e dimensiona as folhas em células de 160 × 128 pixels para uso no jogo. Os PNGs desta pasta são as saídas originais; os atlas finais ficam em `assets/enemies/*_actions_v1.png`.
