# Pátio dos Guindastes fixo v01

Um candidato gerado. Doca inspecionada; Santuário aprovado inspecionado e usado como referência de imagem na geração. Fonte original e prompt preservados.

Imagem integral 2048×1360 em escala uniforme 2500/2048. Origem ajustada para (2200,5722), alinhando o corredor oeste com a saída original da Doca. Pisos e cobertura traçados conforme a imagem, sem caixa retangular genérica. Acesso norte recebe um pequeno trecho de pedra até o corredor existente. Braços elevados dos guindastes usam polígonos de oclusão extraídos da própria textura. Mobiliário pintado não recebe props duplicados. Portões de combate são dinâmicos.

Novas expedições usam o mapa fixo durante o piloto (fixed-art-pilot-v1). A seleção procedural fica temporariamente suspensa; ela não foi removida. Saves de layouts antigos mantêm posição e geometria antigas, e não recebem esta placa. Nenhum arquivo de save foi gravado por estas ferramentas. Santuário aprovado e imagem da Doca preservados.

Validação: cranes_fixed_test passou em seed42, incluindo portas nos dois sentidos com raios11/23, passagem Doca→pátio, colisões de carga, spawns seguros, caminhos até armazém/ferrovia/chefe, fechamento e reabertura de combate, destruição do atalho e snapshot. procedural_runtime_test passou para o piloto fixo. Capturas reais zoom1,05: _bmad-output/implementation-artifacts/cenarios-base/captures/cranes-fixed-v01, incluindo centro, guindaste, junção Doca, norte, leste e Titan.

Limitações: as salas seguintes ainda mantêm sua arte anterior; o tom do piso novo é mais azulado que o da Doca. Nenhuma terceira sala gerada. Pátio aguarda revisão visual do usuário.
