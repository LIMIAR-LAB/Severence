# Padrão de sprites do Marty — 0.19

## Regra única

Todas as roupas usam quadros de **96 × 96 px**, pés apoiados em `y=92`, pivô horizontal em `x=48` e fundo transparente. O renderer posiciona o quadro em `(-48,-92)` relativo ao ponto dos pés. Armas, projéteis e partículas são camadas separadas: mãos vazias na arte do corpo. A mesma regra vale para P1 e P2.

Ordem imutável das roupas nas folhas comuns: `padrao`, `espiao`, `mecanico`, `omega`. A animação deve preservar a silhueta e a altura percebida entre quadros. Nunca alterar o tamanho da célula para uma ação específica; efeitos maiores ficam em outra camada.

## Gramática de movimento

| Ação | Quadros | Direções | Regra |
| --- | --- | --- | --- |
| Parado | 1–2 | frente, diagonal frente, lado, diagonal costas, costas | Oscilação sutil sem deslocar os pés. |
| Andar | 4 | mesmas cinco vistas | Contato esquerdo, passagem, contato direito, passagem. |
| Correr | 4–6 | mesmas cinco vistas | Passadas mais largas e rápidas; sem trocar a escala do corpo. |
| Pular | impulso, ápice, queda, pouso | mesmas cinco vistas | A altura é aplicada pelo código; sprite mantém pivô dos pés. |
| Atirar | 1–2 | mesmas cinco vistas | Corpo sem arma; braço e arma montados por camada. |
| Corpo a corpo | antecipação, golpe, recuperação | mesmas cinco vistas | Mãos vazias; lâmina/efeito separado. |
| Esquiva comum | 4 | lado, diagonal frente, diagonal costas; espelho horizontal | Ação física de rolada. A direção vem de `dash_dir`, não da mira. |
| Esquiva Ômega | 4 | lado, diagonal frente, diagonal costas; espelho horizontal | Fissura ciano/violeta, desaparecimento, reaparição, recuperação. Sem rolamento. |

As cinco vistas base, com espelhamento das vistas intermediárias, cobrem as oito direções. Para a esquiva atual, o lateral atende deslocamento horizontal e as duas diagonais atendem deslocamento diagonal ou vertical. O código pode receber folhas verticais próprias sem alterar o formato de quadro nem os estados de jogo.

## Primeira integração

`marty_anim_v3.png` continua para parado, andar, salto, tiro e espada. Suas colunas de ação ainda são uma base antiga com poses repetidas; as novas folhas de esquiva ficam independentes, sem deslocar os índices do atlas principal. `marty_roll_{side,front_diag,back_diag}_v1.png` atende três roupas comuns; `marty_teleport_{side,diagonal}_v1.png` atende a Ômega. A folha diagonal da Ômega tem frente na linha 0 e costas na linha 1. Cada ação dura os mesmos 0,20 s da esquiva da simulação, quatro quadros de 0,05 s. O movimento diagonal continua normalizado pela simulação.

As fontes aprovadas estão em `art/source/marty-roll-*.png` e `art/source/marty-omega-teleport-*.png`. `tools/import_marty_actions_v1.gd` converte cada célula da fonte para 96 × 96, mantendo proporção e alinhando os pés. Essas imagens foram geradas com o ImageGen integrado usando `marty_anim_v3.png` como referência; os arquivos fonte não são sobrescritos na importação.

## Aceite de próximos atlas

Antes de trocar uma ação antiga: verificar silhueta das quatro roupas em zoom de jogo, alinhamento dos pés, leitura das oito direções, braços conectados, mãos sem arma, nenhuma parte cortada, mudanças visíveis entre quadros e ausência de vazamento entre células. Testar a ação durante tiro, salto, dash, armadura e coop local. Não integrar uma folha só porque ela parece boa ampliada.
