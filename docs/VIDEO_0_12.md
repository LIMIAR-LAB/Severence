# Vídeo e resoluções 0.12 (preparação para Steam)

OPÇÕES agora tem 3 abas: **VÍDEO**, ÁUDIO e CONTROLES. Tudo é salvo em `user://settings.json` e aplicado ao abrir o jogo.

## VÍDEO

| Opção | Valores |
|---|---|
| Resolução (janela) | 1280×720 até 3840×2160, incluindo 16:10 (1280×800 = Steam Deck, 1920×1200, 2560×1600) e ultrawide (2560×1080, 3440×1440). Só aparecem as que cabem no monitor. |
| Modo de tela | Janela • Tela cheia sem borda • Tela cheia exclusiva (tela cheia usa a resolução do monitor) |
| Limite de FPS | 30, 60, 120, 144, 165, 240 ou sem limite |
| VSync | liga/desliga |
| Distância da câmera | Perto • Normal • Longe (vê mais da sala na expedição) |
| Tamanho da interface | 75% a 130% |
| Pixel perfeito | escala inteira (sem borrão; pode deixar faixas pretas) |

## Como funciona

- Base de desenho 1280×800 com `stretch = canvas_items` e `aspect = expand`: em 16:9, 21:9 ou 4:3 **não há faixas pretas** — a sobra da tela mostra mais mundo.
- O HUD se ancora nas bordas reais (minimapa e recursos à direita, robô embaixo à esquerda, armadura no centro) e o mapa completo ocupa a tela toda.
- Menus ficam centralizados com fundo escuro nas sobras.
- Testado em 1024×768 (4:3), 1920×1080 (16:9), 2560×1080 (21:9) e 1600×1000 (16:10).

Código: `scripts/display_settings.gd`. Em testes/capturas, `--resolution LxA` na linha de comando tem prioridade sobre a configuração salva.
