# Titan 0.12 — canhão pesado, bombas e direções

## Sprites nas diagonais

As linhas "3/4" do `assets/mech/titan_v2.png` não eram vistas diagonais de verdade: eram a frente e as costas achatadas em perspectiva (`tools/prepare_titan_v2.py`), e por isso o robô ficava estranho na diagonal.
Agora `titan_pose()` (`scripts/world_view.gd`) usa só as vistas reais:

- Movimento predominantemente horizontal, **incluindo as 4 diagonais**: vista lateral (espelhada para a esquerda), com o canhão à frente.
- Vertical: frente ou costas.

Para ter 8 direções de verdade falta uma folha nova com as vistas 3/4 (frente-direita e costas-direita) no mesmo estilo de `art/source/mech-atlas-v1.png`.

## Armas

| Ação | Tecla | Efeito |
|---|---|---|
| **Canhão pesado** | Tiro (clique / Enter / gatilho) | Bala grande (raio 14) e lenta (330 px/s), dano 70, cadência de 0,85s. Explode no impacto, em inimigo ou parede: 34 de dano num raio de 80. Recuo com fumaça e tremor de câmera. |
| **Bomba** | R / O / LB (a tecla da armadura; dentro do Titan a armadura não é usada) | Arremessada em arco a 320 px na direção da mira, **por cima de caixas e paredes baixas**. Cai em 0,8s com um marcador de alvo no chão. Explosão com raio de 125 e até 95 de dano (menos na borda). Recarga de 2,6s. |
| Soco | F / clique direito | Igual ao anterior (55 de dano). |
| Turbo | Segurar Shift | Igual ao anterior. |

- HUD do Titan: mostra **R • BOMBA PRONTA** ou a recarga da bomba enquanto você pilota.
- O parceiro IA também lança bombas quando pilota e há inimigo entre 180 e 380 px.
- Valores em `MECH_SHELL` e `MECH_BOMB` (`scripts/simulation.gd`).
- Explosões acendem a camada de luz do cenário.
- **Balanceamento:** `explode()` usa `line_of_fire()` para checar parede/obstáculo entre o ponto da explosão e cada inimigo — o respingo do canhão e a bomba não atravessam paredes finas dos corredores das Docas.

Teste: `tests/titan_weapons_test.gd`. Captura: `-- --capture-arena --pilot --titan-demo --capture-tick=22`.
