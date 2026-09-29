# Tela inicial — cenário animado e console unificado

O fundo da tela inicial é o vídeo em pixel art enviado pelo usuário (loop de 8 s, 24 fps). Ele funciona
somente como cenário cinematográfico. O logotipo permanece na arte, mas toda a área de navegação é
um console vivo construído por `scripts/terminal_ui.gd`. Uma máscara opaca cobre os controles antigos
que já estavam pintados no vídeo, impedindo sobreposição de textos e remendos de estado.

## Arquivos (`assets/ui/title/`)

| Arquivo | O que é |
|---|---|
| `title_loop.ogv` | O vídeo em Ogg Theora (o formato de vídeo que o Godot toca), 1344×752, 24 fps, sem áudio. |
| `title_still.png` | Quadro parado (mediana do vídeo). Aparece por baixo e no modo headless dos testes. |
| `btn_N.png` / `btn_N_sel.png` | Recortes legados, mantidos apenas como fonte histórica; não são usados pela interface. |

O console tem um único quadro industrial, fundo opaco e hierarquia consistente. **NOVA EXPEDIÇÃO** é
a ação dominante. **CONTINUAR** e **CARREGAR** compartilham a área de retomada; **ONLINE** e
**EXPEDIÇÃO DIRETA** ficam em “Outras rotas”; **OPÇÕES** e **SAIR** são utilidades discretas. O rodapé
reserva espaço estável para coop local, rede e identificação do protótipo.

## Botões

| Botão | Ação |
|---|---|
| CONTINUAR | Volta para a expedição em andamento (desativado e escurecido sem expedição). |
| NOVA EXPEDIÇÃO | Escolha solo / parceiro IA. |
| ONLINE | Hospedar ou entrar por IP. |
| EXPEDIÇÃO DIRETA | Expedição com seed. |
| CARREGAR | Retoma uma expedição salva; fica indisponível sem save. |
| OPÇÕES / SAIR | Como antes. |
| COOP LOCAL • 2 JOGADORES | Linha discreta abaixo do SAIR (o desenho não tem esse botão). |

O estado da rede é sempre texto vivo no rodapé, inclusive `OFFLINE`, e textos longos são limitados à
área reservada. Foco, hover, pressionado e desativado usam o mesmo conjunto de estilos.

## Regenerar

```
python3 tools/make_title_screen.py <video.mp4>
```

O utilitário legado ainda pode gerar o `.ogv` e o quadro parado; os recortes de botões que ele produz
não devem ser ligados novamente à interface. Precisa de ffmpeg com libtheora. Teste:
`tests/title_screen_test.gd`. Captura: `-- --capture-ui-main`.
