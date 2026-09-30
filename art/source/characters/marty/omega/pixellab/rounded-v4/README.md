# Omega compacta v4

- Conceito aprovado: `../../omega-samurai-rounded-concept-v4.png` (imagem integrada; prompt em `../../omega-samurai-rounded-concept-v4.prompt.md`).
- Fonte em escala nativa: `../../omega-samurai-rounded-native-v4.png` (96×96, transparência).
- Oito direções: personagem PixelLab `036c6e2f-d296-478d-acd5-c3597bdbc3e3`, gerado da fonte nativa. O export original e seus metadados estão em `export/`.
- `omega-rounded-v4-eight-directions-preview.png` mostra as oito direções em ampliação 3×; `omega-rounded-v4-actions-final-preview.png` mostra as ações principais nas oito direções.
- `ai-frames/idle/` contém quatro quadros animados por direção. `ai-frames/melee/` contém as poses brutas e o script seleciona apenas os quadros sem espada ou arco incorporados. As vistas leste e noroeste/nordeste usam espelhamento ou poses limpas para evitar a segunda lâmina.
- `generated/` contém as sete folhas finais. `tools/build_marty_omega_rounded_v4.py` reproduz o conjunto: `run` desliza a partir da flutuação animada (sem passos); `jump`, `evade`, `hurt` e `defeat` mantêm a armadura completa e a mesma silhueta/pivô.
- O jogo carrega cópias das folhas em `assets/characters/marty/omega/rounded_v4/`; a espada continua em camada separada e aparece apenas nos quadros de corte.
- Durante o dash, o renderer desenha uma pós-imagem da própria armadura e um anel de teleporte ciano, que somem quando a esquiva termina.

Os grupos PixelLab são `a7a4c5e1-42af-4551-8806-c618e36aa598` (flutuação), `dbff014c-0f49-43cd-88a3-2ba0db9d4f5c` (deslizamento), `11d0b0fc-8eb3-49e7-be52-998fcf928aad` (golpe) e `5fc229ea-d2a5-4824-9068-8444a8e6f3d5` (salto). Os resultados brutos estão no `omega-rounded-v4-complete-export.zip`. O deslizamento bruto foi rejeitado por sugerir passos; o salto bruto foi rejeitado por esticar membros em algumas direções. Só as poses inspecionadas alimentam a folha final.
