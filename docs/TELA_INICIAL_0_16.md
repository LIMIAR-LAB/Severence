# Tela inicial — cenário animado em tela cheia

O fundo da tela inicial é o vídeo em pixel art enviado pelo usuário (loop de 8 s, 24 fps). Somente a
parte cinematográfica é reenquadrada e ampliada uniformemente: a sidebar pintada é cortada na fonte,
sem máscara ou painel colocado por cima. O logotipo vivo ocupa o canto superior esquerdo e toda a
navegação pertence a um único deck horizontal na base, seguindo o conceito
`art/concept/tela-inicial-conceito-v2.png`.

## Arquivos (`assets/ui/title/`)

| Arquivo | O que é |
|---|---|
| `title_loop.ogv` | O vídeo em Ogg Theora (o formato de vídeo que o Godot toca), 1344×752, 24 fps, sem áudio. |
| `title_still.png` | Quadro parado (mediana do vídeo). Aparece por baixo e no modo headless dos testes. |
| `btn_N.png` / `btn_N_sel.png` | Recortes legados, mantidos apenas como fonte histórica; não são usados pela interface. |

O deck tem cinco ações. **NOVA EXPEDIÇÃO** inicia o fluxo de personagem; **CONTINUAR** volta à
partida ativa ou, quando não há partida ativa, carrega a última expedição salva. **ONLINE**,
**OPÇÕES** e **SAIR** formam a fileira secundária. **OPÇÕES** também dá acesso ao Arquivo do Refúgio
sem acrescentar uma sexta ação ao deck. O estado de rede e a indicação de coop local ficam
na mesma estrutura, sem criar outro painel de menu.

## Botões

| Botão | Ação |
|---|---|
| CONTINUAR | Volta à expedição ativa ou carrega o save; fica indisponível sem ambos. |
| NOVA EXPEDIÇÃO | Escolha solo / parceiro IA. |
| ONLINE | Hospedar ou entrar por IP. |
| OPÇÕES / SAIR | Como antes. |
| COOP LOCAL APÓS ESCOLHER PERSONAGEM | Aviso discreto no rodapé; a escolha aparece no fluxo de personagem. |

O estado da rede é sempre texto vivo no rodapé, inclusive `OFFLINE`, e textos longos são limitados à
área reservada. Foco, hover, pressionado e desativado usam o mesmo conjunto de estilos.

## Regenerar

```
python3 tools/make_title_screen.py <video.mp4>
```

O utilitário legado ainda pode gerar o `.ogv` e o quadro parado; os recortes de botões que ele produz
não devem ser ligados novamente à interface. Precisa de ffmpeg com libtheora. Teste:
`tests/title_screen_test.gd`. Captura: `-- --capture-ui-main`.
