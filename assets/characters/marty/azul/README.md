# Forma Azul

## Visual atual — revisão de coerência

A Forma Azul usa as mesmas folhas de ação de Marty Padrão (`../padrao/pixellab/`), com célula 96×96, oito direções, pivô e mãos originais. `shaders/blue_form.gdshader` aplica seis tons de azul/ciano somente aos comandos marcados de desenho. Não altera os PNGs nem gera um corpo com outras proporções. `front.tres` e `palette.tres` aplicam a mesma aparência aos menus; o HUD usa o retrato original recolorido. A garra tem contornos escuros, tamanho reduzido e partículas quadradas.

`atlas.png` abaixo é a proposta anterior, rejeitada pelo usuário por divergir do estilo. Está preservada como histórico e não é carregada pelo jogo. Conferência atual: `test-output/blue-form/style-comparison.png`, com Marty Padrão e Forma Azul lado a lado.

## Histórico da proposta descartada

Arte original produzida com a ferramenta integrada `image_gen` em 30/09/2026. O PNG transparente original foi copiado para `atlas.png`, sem recortar ou alterar seus pixels. `front.tres` seleciona a vista frontal para os menus. `scripts/blue_form_art.gd` normaliza a escala das quatro vistas no jogo e anima levitação, aura, conjuração e esquiva.

Prompt final utilizado:

> Use case: stylized-concept. Asset type: transparent game sprite atlas for a top-down 2D action game. Create one square transparent PNG containing exactly FOUR views of the SAME original luminous blue muscular adult male energy humanoid, arranged as a strict 2x2 uniform grid. Each quadrant is its own equal-size sprite cell, all same scale, full bodies visible centered horizontally with feet near cell bottom and generous clear margin. Top-left facing south toward camera; top-right facing east right side profile; bottom-left facing north away from camera; bottom-right facing south-east three-quarter. Bald head, glowing white eyes, muscular stylized superhero anatomy, smooth opaque blue energy bodysuit covering whole body, cyan-white rim light, small white diamond energy core in chest, no explicit anatomy. Arms held slightly away from body with relaxed open hands, legs close together with toes pointing downward in a calm levitating pose. Compact heroic proportions about five heads high, broad shoulders, chunky readable silhouettes, hand-painted crisp pixel-art-like 2D videogame rendering with navy shadows and electric cyan highlights. Restrained tight glow around silhouettes, no large aura, no ground/shadow, no labels, text, grid lines, logos or watermark, no weapons or accessories. True transparent background throughout. This is for the user's second blue luminous transformation with ground claw power.
