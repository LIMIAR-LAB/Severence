# Almirante: movimento e mini polvos

O chefe caminha e contorna o alvo entre ataques, alterna flancos ao se reposicionar e acelera/desacelera durante os avanços. As manobras não interrompem canhão carregando ou espiral em curso. O desenho acompanha os passos com balanço rígido, preservando a arte. A investida verifica contato no percurso real para ambos os jogadores.

Invocação: primeira onda após 3,5 segundos de combate ativo; 4 mini polvos na primeira fase, 5 na segunda, 6 na última. Intervalos de 8 segundos, reduzidos a 6,5 na fase final. Máximo de 10 vivos/pendentes por chefe. Usa crawler_small existente, com perseguição e animações próprias, 80% do dano comum. Cada nascimento recebe portal de aviso de 1 segundo; candidatos respeitam chão, obstáculos, sala e distância mínima de 105 do jogador. Os invocados e ondas pendentes são retirados ao derrotar o chefe para não impedir a conclusão da arena.

Estados ficam nos dicionários de inimigos e pending_spawns já serializados. Arte, recompensas e save do usuário não foram alterados.

Verificação: boss_brood_motion_test.gd, 12 casos, zero falhas; boss_intro_test.gd, 6 verificações, zero falhas. Captura real tools/preview_boss_brood.gd terminou com saída 0, quatro filhotes presentes e todos em posições válidas. Imagem inspecionada: output/boss-brood/frame-72.png. Sem commit.
