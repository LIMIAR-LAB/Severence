# Titan — acabamento traseiro (0.15)

Arte criada com a ferramenta de geração de imagens integrada ao Codex.
Fonte: `titan-rear-refined.png`. Atlas integrado: `assets/mech/titan_v4.png`.

As três primeiras linhas foram preservadas pixel a pixel. Apenas as duas
linhas traseiras receberam placas segmentadas, rebites e mochila mecânica.
O importador `tools/import_titan_refinement.gd` normaliza a imagem para
1760 × 880, com células de 176 × 176 e margens transparentes de seis pixels.

Prompt utilizado:

> Edit target: this exact Titan robot game sprite atlas. Precise object edit for production Godot sprites. Preserve exact 1760x880 canvas, 10 columns by 5 rows of 176x176 cells, all 50 positions, scale, foot anchors, 6px transparent gutters and alpha background. Keep first three rows unchanged. Refine ONLY back armor in bottom two rows: replace smeared blurry inpaint patches on backs of closed heads and torsos with crisp pixel-art olive steel segmented armor plates, dark panel seams, small bolts, defined mechanical spinal housing and orange brass twin backpack thruster tanks. These two rows MUST be rear views, no face, eyes or glowing chest core visible. Preserve each frame's limb pose and effects. Consistent detailed pixel art matching original front rows; sharp metal edge highlights, restrained weathering. No text, no labels, no added sprites, no background, no grid lines. Output whole exact atlas with the same geometry.

Validação: `robot_sprite_atlas_test.gd`, failures=0; transparência conferida;
frente e lateral idênticas ao atlas anterior. A validação automatizada não
substitui a avaliação visual das animações durante a partida.
