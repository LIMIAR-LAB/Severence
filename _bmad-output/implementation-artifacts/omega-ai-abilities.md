# IA usa habilidades Ômega

Problema: ai_input nunca enviava special, usava alcance de 65 para combate próximo e podia priorizar embarcar no Titan mesmo já transformado. O raio canalizado exige manter special a cada quadro.

Correção em scripts/simulation.gd: decisão específica da forma Ômega após transformação, raio com linha de visão dentro do alcance e sustentação durante canalização, golpes até 120 unidades, aproximação por teleporte durante recarga do raio, retorno à sombra segura quando um projétil ameaça. Pouso respeita piso, obstáculos, perigos, ponte e proximidade do líder. IA não embarca automaticamente em Titan enquanto armadura está ativa. Reanimação continua prioritária; comandos passam pelas funções normais do personagem, incluindo recargas, dano e efeitos.

Validação: tests/omega_ai_abilities_test.gd, 15 casos, zero falhas (dano real, canalização, parede, combo/esfera, teleporte/sombra, recargas, perigos, resgate e forma normal). tests/review_gameplay_story_test.gd: 37 verificações, zero falhas.
