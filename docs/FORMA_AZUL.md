# Forma Azul

A segunda transformação fica em **Equipamento → Formas → Forma Azul** e está disponível desde o início, inclusive em perfis antigos. A seleção é salva no equipamento.

- **R / LB:** ativa por 5 minutos; R novamente encerra. Recarga de 60 segundos.
- **F / botão direito / X do controle**, ou **T / direcional direito:** conjura a garra de energia sob o inimigo vivo mais próximo, visível e sem parede no caminho, a até 520 unidades.
- **Garra:** 64 de dano, recarga compartilhada de 1,2 segundo. Sem alvo válido, não gasta a recarga.
- No online, o alcance e a linha de visão determinam os alvos de cada jogador independentemente da câmera do anfitrião.
- **Corpo azul:** mantém proporções e animações do Marty, com seis tons de energia azul, contorno escuro e pequenas partículas; ganha 3 corações de escudo e velocidade 430. Armas de fogo continuam equipadas.
- Para trocar entre Ômega e Azul, encerre a transformação antes de abrir o equipamento. Os ataques específicos da Ômega continuam separados.

A arte usa as oito direções e todas as ações do Marty Padrão, com paleta aplicada em tempo real. A proposta anterior de corpo realista foi retirada do jogo. Captura reproduzível: `tools/capture_blue_form.gd`, saída em `test-output/blue-form/style-comparison.png`, com as duas formas no mesmo cenário.

Validação: `blue_form_test.gd`, `blue_form_ui_test.gd`, `equipment_ui_test.gd`, `mission_inventory_ui_test.gd` e `marty_actions_test.gd`.
