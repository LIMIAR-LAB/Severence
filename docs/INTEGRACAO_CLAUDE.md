# Integração pendente — trabalho do Claude (para o Codex / próxima rodada)

Enquanto o Codex restaura os arquivos 0.12 (`simulation.gd`, `main.gd`, `world_view.gd`, `combat_hud.gd`,
`terminal_ui.gd`, `docks_map.gd`, testes), o Claude **só cria arquivos novos**. Este documento lista os
pontos de ligação a aplicar DEPOIS da restauração. Não sobrescrever arquivos inteiros: editar só estes trechos.

## Regras de convivência

1. Um arquivo existente tem um dono por vez. Enquanto o Codex estiver restaurando/editando, o Claude não toca nos arquivos da lista acima.
2. O Claude edita no lugar (trechos), nunca envia o arquivo inteiro, e confere a data de modificação antes de gravar.
3. Arquivos novos do Claude: `scripts/summon_fx.gd`, `scripts/display_settings.gd`, `tests/summon_fx_test.gd`, `tools/preview_summon_fx.gd`, `tools/make_weapons_v2.py`, `art/summon-fx-preview.gif`, `art/weapons-v2-preview.png`.

## A) Cápsula Temporal (hexágono laranja) ao invocar/recolher robô — `scripts/summon_fx.gd`

Genérico: vale para qualquer robô. Robô novo = 1 linha em `ROBOT_SPRITES` (textura, região do quadro parado, tamanho)
ou `SummonFX.register_robot("nome", "res://...png", Rect2(...), Vector2(...))`. Nenhuma animação específica é necessária.

Prévia: `art/summon-fx-preview.gif`. Teste: `tests/summon_fx_test.gd`.

**simulation.gd** (`summon_robot`):
```gdscript
const SummonFX = preload("res://scripts/summon_fx.gd")   # topo do arquivo
# Titan invocado (onde hoje há effects.append({"kind": "summon", ...})):
effects.append(SummonFX.summon_effect(a.id, a.p - Vector2(0, 30), titan_pos, "titan"))
# Titan recolhido (antes de mech.deployed = false):
effects.append(SummonFX.recall_effect(a.id, a.p - Vector2(0, 30), mech.p, "titan"))
# Spectre: igual, com s.p / pos e "spectre".
```
**world_view.gd**:
```gdscript
const SummonFX = preload("res://scripts/summon_fx.gd")
# ao montar a lista de desenháveis, não desenhar o robô enquanto a cápsula não soltar:
if sim.mech.deployed and not SummonFX.robot_hidden(sim.effects, "titan"): drawable.append(...mech...)
# (idem para o Spectre, com owner)
# no laço de efeitos:
elif fx.kind in ["robot_summon", "robot_recall"]: SummonFX.draw_auto(self, fx)
```
Opcional: som de "clique" na abertura (t≈0,38s) e no fechamento (t≈0,6s); tremor de câmera leve no choque final.

## B) Opções de vídeo 0.12 — `scripts/display_settings.gd` (arquivo novo, intacto)

Reaplicar sobre a versão restaurada (ver `docs/VIDEO_0_12.md`):
- `project.godot`: `window/stretch/aspect="expand"`.
- `main.gd`: `const DisplaySettingsScript = preload(...)`; `var display := DisplaySettingsScript.new()`; `display.apply(get_tree())` logo após `load_settings()`; salvar/carregar `"display": display.to_dict()` em settings.json; zoom da expedição = `display.camera_zoom()`; `minimap_rect()` = `Rect2(ui_size().x - 194, 14, 180, 112)` para o clique no minimapa.
- `combat_hud.gd`: `dx = vp.x - 1280`, `dy = vp.y - 800`; `draw_set_transform` para ancorar minimapa (dx,0), robô (0,dy), recursos (dx,dy), dica (dx/2,dy); mapa completo usa `get_viewport_rect()`.
- `terminal_ui.gd`: fundo escuro + `center_stage()` no `size_changed`; tela OPÇÕES com abas VÍDEO/ÁUDIO/CONTROLES (`build_video_options`, `option_row`, `apply_video`).

## C) Armas v2 — já aplicado nos PNGs (`tools/make_weapons_v2.py`)

Só um ajuste de código em `world_view.gd` (`draw_blade`): remover o fator `* (1.15 if energy else 1.0)` da escala, porque a Lâmina Ômega nova já é maior.

## D) Carregamento de scripts sem cache do editor

Preferir `const X = preload("res://scripts/x.gd")` a `class_name` para scripts novos (evita "Identifier not declared" quando o projeto roda sem reimportar).
