# Direção visual 0.4

Referências fornecidas pelo usuário: tela de escolha da aventura e sala de desembarque nas docas. "IDE" interpretado como interface do jogo.

## Aplicado

- Tela ilustrada de escolha: solo ou solo + IA, seleção explícita seguida de Equipar e entrar.
- HUD em molduras douradas: retrato, corações proporcionais à vida máxima, recuperação do dash, estado da armadura, arma, parceiro quando ativo, minimapa da geometria real, integridade/recarga do robô, chaves, moedas e fragmentos. O cliente online mostra seus próprios dados.
- Água, piso de pedra, paredes de tijolos, caixotes, lanternas, baús, barril, sacos de areia e corda derivados da referência. Paredes externas respeitam as aberturas dos corredores; cobertura inicial tem colisão na simulação.
- Marty redesenhado com proporções cartunescas, óculos ciano, jaqueta marrom com gola clara e lenço vermelho. Armadura branca/ciano mantém rosto e cabelo visíveis.
- 32 quadros de caminhada e 24 poses de ação, com quatro direções e dois estados de armadura, normalizados em células 64×80 com fundo transparente e pivô nos pés.

## Arquivos e reprodução

Sprites finais: `assets/marty/marty-v2.png`, `assets/marty/actions-v2.png`. Fontes preservadas em `output/imagegen/marty-v2.png` e `output/imagegen/marty-v2-actions.png`. Geração via CLI/API autorizada, modelo gpt-image-2; o fundo magenta foi removido localmente. Prompts completos em `art/source/marty-v2-prompt.txt` e `art/source/marty-v2-actions-prompt.txt`.

`tools/prepare_marty_v2.py` prepara sprites; `tools/prepare_reference_assets.py` extrai os elementos da referência. A geração não é necessária para rodar o jogo.

Capturas reais: `test-output/docks-v04.png` e `test-output/ui-play.png`. Execute Godot com `-- --capture-docks-v04` ou `-- --capture-ui-play` para reproduzir.

## Limites desta etapa

Os inimigos e o comerciante ainda têm desenhos provisórios. O Titan mantém sua arte anterior. O cenário usa peças repetidas extraídas da referência; não é uma reprodução exata do cenário ilustrado. Mapas continuam compostos de salas fixas com encontros, obstáculos e atalhos variáveis por seed.
