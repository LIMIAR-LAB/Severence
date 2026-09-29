---
title: 'Menu de pausa ilustrado com retorno ao título'
type: 'feature'
created: '2026-09-29'
status: 'done'
baseline_commit: '83fcdf2'
context: []
---

<frozen-after-approval reason="pedido do usuário nesta conversa">

## Intent

**Problem:** O menu de pausa atual é um painel liso que destoa da arte do jogo e oferece só Continuar e Salvar. Falta uma ação clara para voltar ao menu inicial.

**Approach:** Gerar uma moldura de interface no PixelLab com a linguagem visual já usada em Fraturas do Tempo e aplicá-la à pausa, mantendo títulos e botões funcionais como controles Godot. Adicionar Voltar ao menu com salvamento automático da partida offline antes de sair.

## Boundaries & Constraints

**Always:** Preservar os fluxos existentes de Continuar, Salvar, Carregar e controle. A arte gerada serve de decoração; texto e área clicável são nós reais. Retorno offline deve deixar a partida carregável. Mostrar erro e permanecer na pausa se não conseguir salvar.

**Ask First:** Nenhuma decisão pendente dentro deste pedido.

**Never:** Trocar a arte do título, a tela de equipamento ou o atlas do jogo; voltar ao título por Esc/Start/B sem clicar no botão próprio; salvar a sessão do convidado online.

## I/O & Edge-Case Matrix

| Cenário | Entrada / estado | Resultado esperado | Erro |
| --- | --- | --- | --- |
| Pausa offline | Jogador abre o menu | Moldura PixelLab, Continuar, Salvar e Voltar ao menu visíveis | — |
| Voltar offline | Clique em Voltar ao menu | Save atualizado e título aberto; Carregar Jogo retoma a partida | Falha de save mantém a pausa e informa o problema |
| Voltar online | Anfitrião ou convidado clica em Voltar ao menu | Conexão encerrada e título aberto | Não grava save de sessão online |
| Continuar | Clique ou Esc/Start/B | Menu fecha e jogo continua | — |

</frozen-after-approval>

## Code Map

- `scripts/terminal_ui.gd` — construção da pausa, foco e callbacks.
- `scripts/main.gd` — salvamento de sessão, estado da partida e rede.
- `tests/save_game_flow_test.gd` — fluxo de salvamento, carregamento e pausa.
- `assets/ui/pause/` — moldura e fonte geradas pelo PixelLab.

## Tasks & Acceptance

**Execution:**
- [ ] `assets/ui/pause/` — guardar arte PixelLab para a moldura da pausa.
- [ ] `scripts/terminal_ui.gd` — montar o menu com arte, três botões reais e mensagens de estado legíveis.
- [ ] `scripts/main.gd` — fornecer retorno seguro ao título para partida offline e online.
- [ ] `tests/save_game_flow_test.gd` — verificar volta, salvamento, retomada e falha de gravação.

**Acceptance Criteria:**
- Given partida offline, when Voltar ao menu is clicked, then title opens and Carregar Jogo resumes the latest state.
- Given a failed offline save, when Voltar ao menu is clicked, then pause remains open with an error.
- Given an online match, when Voltar ao menu is clicked, then the connection closes and no session save is written.
- Given a controller, when pause opens, then the first action has focus and all three buttons are reachable.

## Spec Change Log

## Verification

**Commands:**
- `godot --headless --path . --script tests/save_game_flow_test.gd` — zero falhas.
- `godot --headless --path . --script tests/controller_input_test.gd` — zero falhas.

**Manual checks:**
- Captura da pausa em 1600×1000 mostra texto legível, botão de saída e arte alinhada ao cenário.



## Suggested Review Order

**Fluxo de saída**

- Salva com verificação de gravação antes de abrir o título.
  [`main.gd:542`](../../scripts/main.gd#L542)

- Mantém o arquivo anterior se a nova gravação falhar.
  [`main.gd:528`](../../scripts/main.gd#L528)

**Interface**

- Exibe a moldura PixelLab e três ações reais sobre o jogo.
  [`terminal_ui.gd:234`](../../scripts/terminal_ui.gd#L234)

- Escurece todo o visor e preserva a navegação pelo controle.
  [`terminal_ui.gd:82`](../../scripts/terminal_ui.gd#L82)

**Verificação**

- Exercita salvar, voltar, carregar e falha de gravação.
  [`save_game_flow_test.gd:15`](../../tests/save_game_flow_test.gd#L15)

- Confere foco e alcance das três ações no controle.
  [`controller_input_test.gd:22`](../../tests/controller_input_test.gd#L22)

