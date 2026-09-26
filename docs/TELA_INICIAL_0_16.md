# Tela inicial 0.16 — vídeo em loop

O fundo da tela inicial agora é o vídeo em pixel art enviado pelo usuário (loop de 8 s, 24 fps), com o
painel do menu já desenhado nele. Substitui `assets/ui/menu.png` + `scripts/menu_background.gd`
(que continua como reserva caso os arquivos do vídeo faltem).

## Arquivos (`assets/ui/title/`)

| Arquivo | O que é |
|---|---|
| `title_loop.ogv` | O vídeo em Ogg Theora (o formato de vídeo que o Godot toca), 1344×752, 24 fps, sem áudio. |
| `title_still.png` | Quadro parado (mediana do vídeo). Aparece por baixo e no modo headless dos testes. |
| `btn_N.png` / `btn_N_sel.png` | Placa normal e acesa de cada botão (0 CONTINUAR … 6 SAIR). |

No vídeo o CONTINUAR vem sempre aceso. As placas cobrem os botões do vídeo: a normal do CONTINUAR é
refeita no estilo apagado dos outros, e a acesa de cada botão usa a moldura ciana do CONTINUAR com o
ícone e o texto daquele botão. O jogo acende só o botão com hover/foco.

## Botões

| Botão | Ação |
|---|---|
| CONTINUAR | Volta para a expedição em andamento (desativado e escurecido sem expedição). |
| NOVA EXPEDIÇÃO | Escolha solo / parceiro IA. |
| ONLINE | Hospedar ou entrar por IP. |
| EXPEDIÇÃO DIRETA | Expedição com seed. |
| EQUIPAMENTO | Tela de Equipamento. |
| OPÇÕES / SAIR | Como antes. |
| COOP LOCAL • 2 JOGADORES | Linha discreta abaixo do SAIR (o desenho não tem esse botão). |

O "OFFLINE" é do vídeo; outros estados da rede (HOST, ONLINE…) são escritos por cima.

## Regenerar

```
python3 tools/make_title_screen.py <video.mp4>
```

Gera o `.ogv`, o quadro parado e as placas, e imprime `TITLE_BUTTONS` para `scripts/terminal_ui.gd`.
Precisa de ffmpeg com libtheora. Teste: `tests/title_screen_test.gd`. Captura: `-- --capture-ui-main`.
