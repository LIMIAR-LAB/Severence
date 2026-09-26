# Assets 0.16 — combat juice (impacto, telegraph, dois inimigos, streak)

Gerados por `tools/make_combat_juice_assets.py` (só numpy + pillow, sem rede, determinístico —
mesma convenção de `tools/make_support_assets.py`). Paleta cyan escuro / dourado do jogo, sem
interpolação (nearest-neighbor), como os demais atlases (`marty_anim_v2.png`, `titan_v3.png`,
`spectre_octopus_v2.png`).

**Escopo desta leva: só `assets/`, `art/`, `tools/`, `docs/`. Nenhum script em `scripts/` foi
tocado — a integração no código de renderização fica para depois.**

## Efeitos

| Arquivo | Tamanho | Grade | Descrição |
|---|---|---|---|
| `assets/effects/hit_sparks.png` | 128×32 | 4 quadros de 32×32 (tira horizontal) | Faísca de impacto: núcleo branco cresce e os raios cyan se espalham, esmaecendo no último quadro. |
| `assets/effects/oil_stain.png` | 144×32 | 3 variações de 48×32 (tira horizontal) | Mancha de óleo/tinta no chão, opaca (alpha 255), tom escuro para ficar legível sobre tábuas ou pedra. |
| `assets/effects/aoe_ring.png` | 96×96 | imagem única | Anel vermelho translúcido tracejado (telegraph de bomba/canhão de chefe), com preenchimento fraco no miolo. |

## Inimigos

Grade igual a `assets/enemies/warden.png` (usada como referência de tamanho): folha 1024×1024,
grade 4×4 de células 256×256. Linhas = direção (0 baixo, 1 esquerda, 2 direita — espelho da
esquerda, 3 cima), colunas = quadros (0 parado, 1–2 andando, 3 quadro especial).

| Arquivo | Tamanho | Grade | Descrição |
|---|---|---|---|
| `assets/enemies/bomber.png` | 1024×1024 | 4×4 células de 256×256 | Criatura/barril instável andando, núcleo incandescente laranja visível por rachaduras; coluna 3 é o quadro "aceso" (núcleo mais claro/maior, para o instante antes de explodir). |
| `assets/enemies/guard.png` | 1024×1024 | 4×4 células de 256×256 | Inimigo com escudo metálico grande na frente (linhas 0/3 — frente/costas visto de cima); de perfil (linhas 1/2) o escudo aparece fino, deixando claro que a proteção é só frontal. |

## HUD

| Arquivo | Tamanho | Descrição |
|---|---|---|
| `assets/ui/hud/streak.png` | 24×24 | Medalha/emblema dourado de multiplicador de combo (streak), com estrela central e fitas penduradas. |

## Áudio (sintetizado, best-effort)

Mesma técnica de `tools/make_support_assets.py`: WAV mono 22050 Hz sintetizado por código
(seno/ruído com envelope), sem gravação nem material licenciado.

| Arquivo | Duração | Descrição |
|---|---|---|
| `assets/audio/explosion.wav` | 0,55s | Estrondo grave + ruído, decaimento longo. |
| `assets/audio/slash.wav` | 0,16s | Whoosh agudo curto com glide descendente. |
| `assets/audio/dash.wav` | 0,22s | Rajada de vento filtrada (ruído + média móvel) subindo de tom. |
| `assets/audio/pickup.wav` | 0,18s | Bipe curto ascendente (dois harmônicos), tom "positivo". |
| `assets/audio/enemy_die.wav` | 0,28s | Tom descendente + ruído, tipo "poof" mais curto que a explosão. |
| `assets/audio/fuel_alarm.wav` | 0,48s | 3 bipes curtos de onda quadrada (alarme), com pausas entre eles. |

## Reprodutibilidade

```
python3 tools/make_combat_juice_assets.py
```

Regenera os 6 PNGs e os 6 WAVs de forma determinística (seed fixa `1941`, como o resto do
projeto). Reexecutar sobrescreve os arquivos com o mesmo resultado.
