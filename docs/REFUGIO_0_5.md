# Refúgio • Fora do Tempo — versão 0.5

Base: conceito v1 (set/2026) e `art/source/refuge-reference.png`. O refúgio passou de uma sala cinza com círculos para o cenário ilustrado: plataforma de metrô de Londres de 1941 flutuando no vazio cósmico, com destroços da expedição do futuro.

## Como foi montado

- **Cenário pintado em escala 1:1** (`assets/environment/refuge/refuge_bg.png`, 1344×752). A escala da referência bate com a do jogo: Marty (~80 px) e Titan (~176 px) têm o mesmo tamanho nos dois.
- O Marty e o Titan que vinham pintados na referência foram removidos (clonagem do piso + textura de chapas/ladrilhos no hangar). Os personagens e o Titan jogáveis ocupam esses lugares.
- **Colisão invisível**: pisos e obstáculos em `make_hub()` (`scripts/simulation.gd`) seguem o desenho — núcleo, banquinho, postes de lanterna, bloco de pedra e bancada do hangar bloqueiam; o vazio não é caminhável.
- **Oclusão**: o Núcleo Temporal é um recorte à parte (`core_front.png`) ordenado por Y. Marty passa por trás da gaiola giroscópica, que fica translúcida para ele continuar visível.
- **Vazio animado**: estrelas cintilando, nebulosas, engrenagens, tijolos e uma cabine telefônica flutuando em três camadas de parallax (movem-se conforme Marty anda).
- **Animações sobre a arte**: energia ciano girando no portal DOCAS, fissuras violeta mudando no portal bloqueado, pulso do núcleo, scanner da armadura de treino e cintilação das lanternas.

## Pontos de interesse (E)

| Local | Posição | Ação |
|---|---|---|
| Portal DOCAS / 1941 | topo, centro (topo da escadaria) | inicia a expedição |
| Coordenada Perdida | topo, direita | bloqueado — anel rachado com correntes |
| Núcleo Temporal | centro | mostra expedições concluídas e fragmentos |
| Bancada | esquerda | congelada na 0.14 (vida fixa em 3 corações) |
| Armadura de treino | inferior esquerda | alterna COM / SEM armadura |
| Hangar do Titan | direita | Titan estacionado; E perto dele para pilotar; C recolhe/invoca |
| Mural da equipe | inferior centro | conta lembranças recuperadas (1 por expedição concluída, até 4) |

Os rótulos só aparecem quando alguém está perto do ponto, para não poluir a arte.

## Reproduzir

- `python tools/prepare_refuge.py` regenera `refuge_bg.png` e `core_front.png` a partir da referência (requer `opencv-python` e `numpy`).
- Captura: `Godot --path . -- --capture --hub-pos=760,440` grava `test-output/refugio.png`.
- Testes: `Godot --headless --path . -s tests/refuge_test.gd` (19 verificações: todos os pontos alcançáveis a pé, colisão do núcleo e do vazio, respostas das interações, portal inicia a expedição).

## Próximos passos sugeridos

- Um anel próprio por portal desbloqueado (cemitério, fábrica, mansão) — a posição do portal bloqueado já está reservada.
- Mural recebendo fotos novas conforme robôs e companheiros forem recuperados (hoje só a contagem muda).
- Refazer a arte em vista da câmera do jogo (a referência é isométrica); a colisão atual foi desenhada para essa arte e precisará ser revista se ela mudar.
