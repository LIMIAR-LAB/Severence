# Comerciante animado — 2026-10-03

Atlas com seis poses originais em3colunas×2linhas: assets/npcs/merchant_hunchback_idle_v1.png,1536×1024,alpha transparente confirmado. Geração/edição com image_gen integrado a partir do comerciante aprovado. Sprite anterior preservado.

scripts/merchant_visuals.gd controla ciclo de negociação a6fps com pausa inicial, mão da relíquia levantando, capuz inclinando e mão livre convidando. Âncoras dos pés medidas por quadro compensam pequenas diferenças de registro do atlas; nenhuma deformação global de escala é usada. world_view.gd usa o ciclo na ordenação por profundidade existente, com fallback para imagem anterior. Tempo usa relógio da simulação; pausa junto ao jogo. Interação/loja/save permanecem com lógica existente.

Verificação: tools/preview_merchant_animation.gd capturou20frames reais no motor; seis poses visitadas, textura carregada, exit0. Prévia output/merchant-animation/merchant-idle.gif. Capturas inspecionadas, sem retângulo de fundo; pés compensados por pose. Sem novos agentes ou commit.

Prompt usado: Using the supplied character as the EXACT identity reference, create a production-ready animation sprite sheet for his idle merchant bargaining gesture. SIX FULL-BODY FRAMES arranged in a precise uniform grid of THREE COLUMNS and TWO ROWS, equal-sized cells. Transparent background everywhere; no labels, no grid lines, no ground shadows. This is the SAME huge hunchback hooded merchant in every frame, SAME clothes/pouches/lantern/grin, same scale, same perspective, same feet baseline and feet x coordinates inside each cell. Both feet must stay planted in the exact same place in all frames. Leave equal padding around every sprite. Read frames left-to-right top row then bottom row. Frame1 neutral holding amber relic near face and other palm open. Frame2 lean shoulders slightly forward, tilt hood toward relic, relic hand rising a little. Frame3 raise relic hand clearly by one head quarter, nod hood down, other hand curled slightly inward beckoning. Frame4 relic hand highest near hood rim, hood tilts sideways, beckoning hand turns palm toward buyer. Frame5 lower relic toward original position, straighten head slightly, other hand opens outward again. Frame6 close to neutral but shoulders settling, ready to loop to frame1. Small but clearly visible continuous gestures, NOT six unrelated designs. Avoid body-scale changes, walking, duplicate appendages, cut off hands or feet, extra items, changing costume, frame labels. Maintain original high-quality crisp hand-painted pixel-art shading. Each character entirely inside its equal cell; exact3x2atlas alignment mandatory.

Passe final: remoção do fundo preservando as seis poses, grade3×2, dimensões1536×1024e alinhamento. Alpha validado diretamente: pixels de fundo=0; personagem≈253/254.

## Revisão: maior fluidez e amplitude

A pedido do usuário, o modo de seis poses foi substituído por articulação contínua da arte original aprovada. Malha de28×36células move mãos, cabeça, tronco e barra da roupa independentemente, seguindo ciclo periódico de3,2s; a luz acompanha a relíquia. Não há alternância abrupta entre imagens ou escala global pulsante. Pés fixos pela máscara inferior. Atlas anterior preservado como fonte histórica.

Teste merchant_motion_test.gd: zero falhas, deslocamento da mão≈28px, passos temporais limitados, ciclo contínuo e triângulos sem inversão no corpus de193amostras. Captura real do motor:64amostras distintas, carregamento confirmado e exit0. Prévia: output/merchant-animation/merchant-fluid.gif. Sem novas imagens ou alteração da lógica da loja nesta revisão.

## Correção: retirar distorção do mercador

O balanço local por malha foi removido: deslocamentos sobrepostos esticavam a arte, mesmo sem inverter triângulos. O sprite aprovado agora recebe apenas rotação rígida suave em torno dos pés e deslocamento vertical de até 1,2 px. Não há escala, cisalhamento nem deformações locais. A luz da relíquia acompanha exatamente a mesma transformação. A arte PNG permanece intacta.

Validação: merchant_motion_test.gd terminou com zero falhas; agora também compara distâncias entre rosto, mãos e pés ao longo do ciclo, verifica área constante, continuidade e apoio próximo ao chão. Movimento da mão de aproximadamente 3,36 px neste balanço discreto.
