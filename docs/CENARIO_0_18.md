# Cenário 0.18: salas não-quadradas e sujeira procedural no piso

Duas bases reaproveitáveis em qualquer mapa novo, sem precisar de arte extra.

## Salas com alas (não são mais só um retângulo)

Uma sala pode ganhar retângulos extras encostados numa borda livre — vira um L, T etc. O jogo
já tratava piso e parede como uma LISTA de retângulos (salas + corredores), então bastou marcar
qual sala é dona de cada retângulo extra; a fronteira entre eles nunca ganha parede porque o lado
de fora já é piso (a mesma lógica que já abria as portas dos corredores).

- `tools/build_docks_map.py`: `ROOM_EXTRA` (dict sala → lista de retângulos) + helper `extra(sala, x, y, w, h)`.
  Usadas nesta versão: `cranes` (baía à direita), `rails` (baía à direita), `market` (reentrância à
  esquerda), `warehouse` (baía embaixo). Rode `python3 tools/build_docks_map.py` depois de mexer.
- `scripts/simulation.gd`: `floors` inclui as alas; `room_contains(room, p, margin)` substitui
  `room.r.has_point(...)` em todo lugar que precisa saber se alguém está "dentro da sala"
  (travar portão, `room_at`, puxar quem ficou de fora).
- `scripts/dock_scenery.gd`: `floor_kind` e `style_of_rect` reconhecem as alas e usam o piso/estilo
  da sala dona (parede, fachada, etc. saem iguais ao resto da sala).

Para dar uma ala a uma sala nova: chame `extra("id_da_sala", x, y, w, h)` encostando numa borda
livre do retângulo principal (sem sobrepor outra sala/corredor/água) e rode o gerador — ele já
valida alcance a pé e com o Titan.

## Sujeira procedural no piso

`dock_scenery.gd:draw_floor_grunge()` — por cima do piso já desenhado, cada célula de 64 px sorteia
(hash determinístico pela posição, sem estado) uma mancha de umidade, uma rachadura ou cascalho
miúdo. ~16% das células recebem algo; o resto fica limpo para não virar bagunça visual.

- Cor muda por material (piso de madeira x pedra/paralelepípedo).
- Pula salas com `floor_set` (Oficina, Mercado, Capela) — a arte delas já tem manchas/buracos
  próprios e virou "poluída" quando testamos no 0.16 (ver `docs/CENARIO_0_16.md`).
- Chamada em `world_view.gd`, logo depois de `draw_floors`. Funciona em qualquer piso/mapa novo
  automaticamente — não precisa registrar nada por sala.

## Como testar
```
godot --headless --path . --script tests/scenery_016_test.gd
```
(a suíte inteira roda igual: `for t in tests/*.gd`). Capturas manuais: qualquer `--capture-docks-v04`
já mostra a sujeira e as alas nas salas listadas acima.

## Próximos passos possíveis
- Dar alas a mais salas (Capela, Depósito de Munição, Doque Seco têm espaço livre do lado).
- Gerar folhas de arte de decal (manchas/rachaduras desenhadas por IA) para variar mais o visual,
  plugando como as folhas de `tools/prepare_*.py` — o sistema procedural fica como base e a arte
  nova entraria como variante extra sorteada junto.
