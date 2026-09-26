---
status: done
route: one-shot
owner: devin
version: "0.18"
---

# Remapeamento de controles (P1 teclado/mouse)

## Intenção

Resolver a limitação já documentada no README ("remapeamento de controles" listado em
"Limites desta entrega"). Deixar o jogador reatribuir as teclas do Marty/P1 na aba
CONTROLES da tela de Opções, persistindo em `user://settings.json`.

## Descoberta importante (mudou o escopo)

O jogo **não usa o InputMap do Godot** — `scripts/main.gd::player_input()` lê tecla física
direto (`Input.is_physical_key_pressed(KEY_D)` etc.), tanto pro P1 quanto pro P2 local e pro
joypad. Isso significa que addons de remap prontos (Maaack's Input Remapping, GATO,
ControlsRemap) não plugam direto — todos esperam ações do InputMap. Optei por NÃO instalar
um addon pra isso: seria uma UI genérica que não bate com o estilo visual próprio do
`terminal_ui.gd` (molduras, cores GOLD/CYAN, navegação por controle já feita à mão), e o
projeto já tem seu próprio padrão de settings (`save_settings`/`load_settings` em
`main.gd`). Implementei um remap mínimo, direto em cima do que já existe.

## Escopo desta etapa

- Só o esquema **primário** (teclado/mouse do P1: WASD, F, Espaço, Shift, E, R, Q, C, G).
- P2 local (setas/IJKL) e joypad **não mudam** nesta etapa — ficam como pendência.
- `Fire`/`Aim` continuam mouse (clique esquerdo / posição do cursor) — não fazem sentido
  remapear.

## Implementação

- `scripts/main.gd`: `key_binds: Dictionary` com os 12 binds remapeáveis, valor default =
  as teclas atuais. `player_input()` passa a consultar `key_binds` em vez das constantes
  `KEY_*` fixas no ramo `use_primary`. `rebind_key()` valida ação, tecla duplicada e teclas
  reservadas (`KEY_BIND_RESERVED`: Esc, Tab, M, B, F2 — lidas direto no `_physics_process`).
  `save_settings()`/`load_settings()` guardam/leem `key_binds` com fallback por campo.
- `scripts/terminal_ui.gd`: aba CONTROLES ganha uma lista de botões "AÇÃO — TECLA atual";
  clicar entra em modo "aguardando tecla" (com `gui_release_focus()` pra não engolir
  Espaço/Enter), a próxima tecla física pressionada substitui o bind — Esc cancela, tecla
  duplicada/reservada avisa "(em uso!)" e não aplica. Botão "RESTAURAR PADRÃO".
- `tests/input_remap_test.gd`: 12 checks — defaults, rebind válido/inválido, tecla
  reservada, ação desconhecida, movimento com a tecla nova, load com arquivo corrompido
  (string/número negativo/reservada/duplicada → default) e reset. Faz backup/restore do
  `settings.json` real.
- `tests/input_scene_test.gd`: continua testando as teclas padrão — não quebrou, já que os
  defaults de `key_binds` são os mesmos valores.

## Pendências / próxima etapa

- P2 local e joypad remapeáveis.
- Se algum dia migrar para InputMap (ex.: pra usar um addon de remap "de verdade"), este
  arquivo documenta por que a decisão foi outra nesta etapa.

## Validação

Suíte headless completa (`tests/*_test.gd`), 0 falhas esperadas. Teste manual: abrir
Opções → Controles, remapear uma tecla, sair e voltar ao jogo, confirmar que a tecla nova
funciona e a antiga não, fechar e abrir o jogo de novo (settings.json) e confirmar que o
bind persistiu.
