# Cenário 0.16: Oficina, Mercado, Capela, paredes rachadas, portão de tentáculos e ícones do mapa

Seis folhas de sprites novas (geradas por IA, fundo magenta #FF00FF) recortadas e ligadas às Docas.

## O que mudou

| Folha (em `art/source/`) | Peças | Destino | Onde aparece |
|---|---|---|---|
| `workshop_sheet.png` | 4 pisos 64×64 + bancada 96×64, prateleira 64×96, talha 48×96, poça de óleo 64×32, solda 64×64, peças 64×64 | `assets/environment/docks12/workshop/` | Sala 05 Oficina |
| `market_sheet.png` | 3 pisos 64×64 + banca 128×96, rede 96×64, cestos 64×64, barril de gelo 64×64, barco 96×48, lanternas 96×32 | `.../market/` | Sala 04 Mercado |
| `chapel_sheet.png` | 2 pisos 64×64 + vitral 64×96, velas 48×64, estandarte 64×128, tigela 64×64 | `.../chapel/` | Sala 10 Capela (tapete e altar antigos mantidos) |
| `cracked_walls_sheet.png` | `wall_crack_a/b/c` e `_open`, 128×216 | `.../tiles/` | Atalhos 02↔09 e 03↔08 |
| `tentacle_gate_sheet.png` | `tentacle_gate_active/_sealed`, 140×100 (desenhado 2× no corredor) | `.../props/` | Corredores 08→07 e 07→06 |
| `map_icons_sheet.png` | chefe, loja, desafio, baú, trancado, saída, 48×48 | `assets/ui/map_icons/` | Mapa (Tab/M) |

Prévias com as peças prontas e os pisos repetidos 3×3: `art/{workshop,market,chapel,cracked-walls,tentacle-gate,map-icons}-preview.png`. A prévia dos ícones também mostra cada um em 24×24.

### Jogo
- **Pisos por sala:** `ROOM_STYLE[...].floor_set` escolhe o conjunto (`workshop`, `market`, `chapel`). `floor_patch` cobre só uma área; a nave da Capela usa as runas sobre o piso antigo. Em cada célula de 64 px um hash sorteia o piso pelos pesos de `FLOOR_SETS`.
- **Paredes rachadas:** um barril explosivo em cada atalho (Guindastes e Armazém). A variante A, B ou C sai da seed. A parede bloqueia e aguenta tiros. Uma explosão a menos de raio+70 troca pela versão `_open` (entulho), libera a colisão, refaz a navegação e mostra "ATALHO ABERTO".
- **Portão de tentáculos:** ativo, bloqueia a passagem, dá 12 de dano e empurra para trás. Fica selado (seguro, passável) quando o evento ligado termina: `warden` (mini-chefe morto) ou `side` (desafio do gerador concluído).
- **Mapa (Tab/M):** ícones sobre as salas descobertas: chefe (até morrer), loja, desafio, baú, sala trancada e saída (apagada até o chefe cair). 16 px no minimapa e 24 px no mapa cheio.
- Novos destrutíveis: cestos, barril de gelo e peças da oficina. Luzes novas: tigela (violeta), solda (ciano piscando) e lanternas do mercado.
- Todos os sprites usam filtro Nearest e não têm mipmaps (padrão do projeto).

## Onde editar
- **Recorte das folhas:** `tools/sheet_cut.py` concentra o magenta, a franja, as ilhas, o NEAREST, o teste de emenda e a prévia. Cada folha tem seu `tools/prepare_<nome>.py`, com a lista `PIECES` na ordem de leitura (linhas de cima para baixo, esquerda para a direita) e o tamanho-alvo de cada peça.
  - Se a contagem de ilhas não bater, o script para e mostra as caixas. Ajuste `merge` (junta partes próximas) ou `min_area`.
  - Pisos são esticados ao alvo e testados 3×3. Se a emenda passar de 40, o script mescla 2 px das bordas.
- **Posição das peças:** em `tools/build_docks_map.py`, estão em `ROOM_STYLE`, `SHORTCUTS`, `TENTACLE_GATES` e nas listas de props e decorações de cada sala. Depois rode o gerador, que valida o alcance de todas as salas.
- **Pesos dos pisos e props por conjunto:** `FLOOR_SETS` e `SET_PROPS` em `scripts/dock_scenery.gd`.
- **Regras:** estão em `scripts/simulation.gd`.
  - `open_shortcut()` abre a parede.
  - `step_tentacle_gates()` e `tentacle_event_done()` controlam o portão.
  - O `explode()` detecta a parede rachada.
- **Ícones:** `map_icon()` em `scripts/combat_hud.gd`.

## Como regenerar
```
python3 tools/prepare_workshop.py      # idem market, chapel, cracked_walls, tentacle_gate, map_icons
python3 tools/build_docks_map.py
```
Os scripts de recorte precisam de numpy, pillow e **scipy**. O scipy não vem instalado na VM do Cowork; nesta versão eles rodaram no container da nuvem.

## Como testar
```
godot --headless --path . --script tests/scenery_016_test.gd
```
O teste cobre:
- tamanhos das peças e dos ícones;
- conjuntos de piso;
- variantes A, B e C pela seed;
- a parede bloqueando, resistindo a tiros e abrindo com o barril;
- o portão bloqueando, ferindo, empurrando e selando por `warden` e por `side`.

Capturas manuais (xvfb):
```
--capture-docks-v04 --visit-all --no-enemies --at=X,Y --capture-name=NOME [--open-shortcuts] [--seal-gates]
```
- Mercado: 7350,6450
- Oficina: 8950,6450
- Capela: 850,4300
- Parede: 2800,5800
- Portão: 6000,4300

`--no-enemies` mantém o mini-chefe (warden), para o portão continuar ativo.

## Peças fracas (candidatas a gerar de novo)
- `chapel_floor_eye` / `chapel_floor_spiral`: as runas ficam borradas em 64 px e a moldura de cada ladrilho marca a grade.
- `market_floor_*`: os três pisos têm poças ou buracos, então o chão fica carregado. O peso do piso de escamas foi aumentado para amenizar.
- `workshop_welder` / `workshop_parts`: a arte original é larga, então as peças ficam pequenas dentro de 64×64.
