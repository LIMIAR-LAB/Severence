# Docas — chegada horizontal ao Almirante

As novas expedições têm duas rotas paralelas ao norte do mapa existente, evitando cruzamentos com a Adega e seus corredores. A Antessala está em (3200, -1800), ligada ao Farol por um corredor. A Ponte Temporal vai de x=4600 a x=20200, em y=-1600 a -1200; o Mangue Negro segue o mesmo comprimento em y=-900 a -300. A arena começa em x=20200, com chefe em (21400, -1000). Os props da arena acompanham a nova posição.

A moto anda a 780 unidades/s; 15.600 unidades correspondem a 20 segundos de avanço. A partida acrescenta aproximadamente 0,23 segundo e o combate pode acrescentar tempo. Vinte segmentos de 780 unidades desabam a intervalos de um segundo, com dois segundos de carência. Obstáculos ficam nas laterais com pista central livre; oito encontros surgem à frente durante o avanço. Cair repara a ponte, limpa os encontros da tentativa e devolve ao checkpoint. Uma queda fatal mantém o fluxo existente de derrota.

Montar exige o empréstimo de Faísca e Ômega. A ponte recusa entrada a pé; o mangue recusa a moto. Desmontar na ponte fica bloqueado até a chegada física. O mangue tem árvores, perigos, inimigos e RAÍZ-PODRE; seu portão leste permanece fechado durante o combate. Nenhuma outra entrada alcança a arena.

## Integração nos arquivos em edição pelo outro chat

Não foram editados `main.gd`, `world_view.gd`, `dock_scenery.gd` ou os arquivos da UI.

- `main.gd`: `boss_room_entered()` já usa `sim.room_at(actor.p) == boss`, portanto só dispara a cena na arena final. A opção de captura `--bike-demo` ainda usa a posição antiga (4620, 1900); substituir por `sim.run_points.bike_checkpoint`, montar via empréstimo/Ômega e avançar com comandos reais. Não teleportar através da arena. Capturas antigas `--capture-boss` e testes com coordenadas literais devem adotar `sim.run_points.boss`.
- `world_view.gd`: o aviso do segmento prestes a cair deve usar `sim.bridge_segments()` em vez de `sim.DOCKS.BRIDGE_SEGS`, para acompanhar saves legados. O novo quarto `bridge` permite desenhar e descobrir a ponte pelo fluxo normal de salas. Manter recorte de desenho pela câmera porque as duas salas são longas.
- `dock_scenery.gd`: a placa de arena usa `BOSS_ARENA_RECT` fixo e por isso novas arenas usam tiles como fallback. Para preservar a pintura dedicada, selecionar a sala pelo id `boss` e desenhar sua placa no `room.r` atual, respeitando saves antigos.

## Saves

Nenhum arquivo de save em disco é alterado. Os snapshots conservam suas salas, pisos, pontos e timers. A presença da sala `bridge` diferencia o mapa novo; snapshots antigos sem essa sala mantêm a ponte vertical de oito segmentos e o ritmo antigo. `bridge_zone()` e `bridge_segments()` expõem a geometria adequada à expedição carregada.
