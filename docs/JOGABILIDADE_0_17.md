# Jogabilidade 0.17 — Docas de 1941

## O que mudou

- Warden e inimigos marcados `miniboss` deixam um baú dourado no local da morte.
  Abre com E, sem chave, e equipa a próxima arma da sequência pistol → smg →
  shotgun → omega somente no jogador que abriu. No topo: 3 materiais, 2 chaves
  e cura. O baú paga uma vez; armas recuperadas duram a expedição.
- Armazém 7 é sala maze, sem criaturas ou reforços. Paredes internas criam uma
  passagem sinuosa, com baú na saída. Espinhos, dardos e vapor usam ciclos de
  4 s: 2,2 s seguros, 0,8 s de aviso e 1 s ativo. Dardos atingem nas faixas
  visíveis. Saltar evita o dano, como nas poças antigas.
- Capela é sala story, sem combate. O pescador em (850,4400) conversa com E
  e pede para limpar a Adega Inundada. Voltar depois de visitá-la e eliminar
  os inimigos rende 4 materiais, 2 chaves e cura, uma única vez.
  A missão é compartilhada pela equipe e salva em story_quest, com default 0.
- Almirante reposiciona na fase 1, avança na fase 2 e mergulha na fase 3.
  Todo movimento tem aviso de 0,7 s. Destino e percurso respeitam colisões;
  no mergulho, o corpo some e a ondulação mostra o deslocamento submerso.
- Equipamento usa escala contínua proporcional; menus seguem a janela.
  Capturas respeitam a resolução solicitada sem reaplicar o fullscreen salvo.
- Zoom normal 1,22; perto 1,4; longe 0,68. Mantida escala dos personagens.
  Tiros comuns do jogador têm hitbox mínima de 6 e visual de 7,5 px.
  Inimigos: visual +40%, hitbox 80% do visual, contorno escuro e núcleo claro.

## Onde editar

- tools/build_docks_map.py: fonte do mapa, paredes, salas, perigos e baús.
- scripts/simulation.gd: open_reward, story_interact, trap_phase, boss_motion.
- scripts/world_view.gd e dock_scenery.gd: avisos, NPC, baú e projéteis.
- scripts/terminal_ui.gd e display_settings.gd: escala e zoom.
- scripts/main.gd: persistência da missão; snapshots incluem a fila de falas.

## Como testar

Rode `python tools/build_docks_map.py` para validar caminhos e rota do Titan.
Rode os testes headless, especialmente tests/update_017_test.gd, enemies_test.gd,
dynamic_map_test.gd e equipment_ui_test.gd.

Capturas em test-output/update017-*: labirinto, Capela, equipamento em 1280×800,
1600×1000 e 1920×1080, menu principal e opções. No jogo, mate o Warden,
abra o baú sem chaves, converse com o pescador e teste o retorno após a Adega.
A arte do NPC reutiliza o Espião com tint azul. Armadilhas usam desenho do cenário.
