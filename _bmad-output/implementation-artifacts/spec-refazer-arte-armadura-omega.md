---
title: 'Refazer a arte da Armadura Ômega'
type: 'bugfix'
created: '2026-09-30'
status: 'done'
baseline_commit: b6fd2a7373ae196b7f1f2b9a9386d3da693431d9
context:
  - '{project-root}/docs/SPRITE_POSE_STANDARD.md'
  - '{project-root}/docs/PADRAO_SPRITES_MARTY_0_19.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** As folhas atuais da Armadura Ômega misturam a armadura completa com quadros do Marty sem capacete ou sem armadura, variam de proporção entre direções e não oferecem poses corporais convincentes para o combo da espada. O resultado foge do padrão visual aprovado e fica quebrado durante corrida, salto e combate.

**Approach:** Reconstruir a Ômega a partir de uma nova referência visual agressiva e angular — cavaleiro futurista marfim e dourado, visor e núcleo ciano, juntas escuras e capa curta roxa — gerada pelo MCP do PixelLab e aprovada pelo usuário antes das animações. Todas as folhas serão normalizadas para a grade atual, integradas e avaliadas no tamanho real do jogo, com um conjunto `melee` desenhado especificamente para empunhar a Lâmina Ômega com domínio.

## Boundaries & Constraints

**Always:** Antes das folhas, apresentar uma única arte-base da Ômega ao usuário e pausar até aprovação explícita. A silhueta deve ser agressiva, atlética e facetada, sem placas arredondadas ou aparência de brinquedo. Capacete fechado e armadura completa em todos os quadros; oito direções próprias na ordem sul, sudeste, leste, nordeste, norte, noroeste, oeste e sudoeste; célula 112×112; pés e escala estáveis; fundo transparente; identidade marfim/dourado/ciano/roxo constante. Manter a espada, o rastro, impactos e a onda final em camadas separadas. Preservar duração, dano, combo, colisão e tempos de jogo.

**Ask First:** Alterar a silhueta aprovada, paleta, quantidade de quadros, tamanho da célula, funcionamento do combo ou substituir a espada atual por outra direção artística.

**Never:** Reutilizar Marty sem armadura; deixar rosto ou cabelo expostos; misturar uniformes; incorporar cenário, texto ou grade aos PNGs; voltar a colar mãos do atlas legado sobre o corpo Ômega; aceitar células cortadas, vazias ou com escala inconsistente.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Movimento | Ômega parada, correndo, saltando ou em dash nas oito direções | A mesma armadura completa permanece reconhecível, ancorada e contínua | Rejeitar e regenerar a ação/direção inconsistente |
| Combo | Primeiro, segundo e terceiro golpes em qualquer direção | Antecipação, corte e recuperação leem como manejo treinado; mão acompanha a lâmina separada | Ajustar pose e âncora, sem colar arte legada |
| Dano/derrota | Marty recebe dano ou cai | Armadura continua fechada e coerente até o último quadro | Nenhuma transição para o Marty desarmadurado |

</frozen-after-approval>

## Code Map

- `art/source/characters/marty/omega/pixellab/reference/` -- referência aprovada de identidade e oito rotações.
- `art/source/characters/marty/omega/` -- fontes finais geradas e prévia consolidada para auditoria visual.
- `assets/characters/marty/omega/pixellab/` -- sete folhas consumidas pelo jogo.
- `tools/import_marty_omega_pixellab.py` -- normalização, validação de grade e empacotamento das folhas.
- `scripts/world_view.gd` -- seleção de ação/quadro, pivô, escala, âncoras e camada da espada.
- `tests/marty_actions_test.gd` -- contrato estrutural e regressões da integração Ômega.

## Tasks & Acceptance

**Execution:**
- [x] `art/source/characters/marty/omega/omega-reference-v3-pixellab.png` -- apresentar a nova arte-base angular gerada pelo MCP do PixelLab e aguardar aprovação explícita antes de produzir animações.
- [x] `art/source/characters/marty/omega/` -- gerar novamente `idle`, `run`, `jump`, `evade`, `melee`, `hurt` e `defeat` a partir da referência aprovada, em lotes por ação.
- [x] `tools/import_marty_omega_pixellab.py`, `assets/characters/marty/omega/pixellab/` -- validar e normalizar todas as células, preservando grade, transparência, pivô e contagens atuais.
- [x] `scripts/world_view.gd` -- alinhar as oito âncoras da espada às novas poses e impedir o recorte de mão do atlas legado na Ômega.
- [x] `tests/marty_actions_test.gd`, `art/source/characters/marty/omega/pixellab/omega-actions-preview.png` -- ampliar as verificações e produzir uma prévia das sete ações para inspeção.

**Acceptance Criteria:**
- Given qualquer ação e direção da Ômega, when o quadro é renderizado, then Marty aparece integralmente dentro da mesma armadura, sem rosto, cabelo ou uniforme comum visível.
- Given o combo de três golpes, when a animação e a camada da espada são reproduzidas, then as mãos, o corpo e a lâmina formam uma sequência legível de antecipação, impacto e recuperação em todas as direções.
- Given a execução em escala nativa, when as ações são comparadas à referência, then silhueta, paleta, volume, pivô e capa permanecem consistentes sem cortes ou tremores.
- Given o restante do combate, when os novos assets são integrados, then nenhuma regra ou tempo de gameplay muda.

## Spec Change Log

- 2026-09-30: usuário rejeitou a referência v2 por estar arredondada demais e renegociou a direção para uma Ômega mais agressiva e angular, gerada pelo MCP do PixelLab. A referência v3 foi criada em oito direções e aguarda aprovação.
- 2026-09-30: usuário aprovou explicitamente a arte-base v3 `omega-reference-v3-pixellab.png` e o personagem PixelLab `b41db246-47d5-4914-a111-a6bd644abc2b`, liberando a produção das sete ações.

## Design Notes

Manter a paleta e os símbolos centrais da referência anterior, mas endurecer sua linguagem de formas: capacete em cunha, peitoral em V, ombreiras pontudas e membros segmentados. O `melee` precisa mostrar guarda firme, giro de tronco e transferência de peso, enquanto a lâmina continua desenhada pelo renderer. A transformação por fissura permanece energética e não vira rolamento físico.

## Verification

**Commands:**
- `python tools/import_marty_omega_pixellab.py` -- expected: sete folhas válidas, oito direções e nenhuma célula fora da grade.
- `Godot --headless --path . --script tests/marty_actions_test.gd` -- expected: dimensões, direções, âncoras e isolamento da arte Ômega aprovados.
- `Godot --headless --path . --script tests/omega_test.gd` -- expected: combo e regras da armadura sem regressões.

**Manual checks:**
- Inspecionar a prévia consolidada e capturas em escala nativa para todas as ações, com atenção especial ao combo visto de frente, lado, costas e diagonais.

## Suggested Review Order

**Pipeline e proveniência**

- Comece pelos contratos de identidade, grupos aprovados, alpha e normalização 112×112.
  [`import_marty_omega_pixellab.py:47`](../../tools/import_marty_omega_pixellab.py#L47)

- O manifesto registra jobs PixelLab e seleções determinísticas do melee limpo.
  [`manifest.json:1`](../../art/source/characters/marty/omega/pixellab/melee-pixellab/manifest.json#L1)

- O empacotamento publica sete folhas e preview somente após validar o conjunto completo.
  [`import_marty_omega_pixellab.py:292`](../../tools/import_marty_omega_pixellab.py#L292)

**Integração visual**

- Âncoras 8×6 fazem a espada acompanhar cada pose corporal do melee.
  [`world_view.gd:981`](../../scripts/world_view.gd#L981)

- O renderer mantém espada separada e remove a mão legada na Ômega.
  [`world_view.gd:894`](../../scripts/world_view.gd#L894)

- A documentação reúne IDs, overrides e política de seleção dos quadros.
  [`README.md:1`](../../art/source/characters/marty/omega/pixellab/README.md#L1)

**Verificação**

- Testes cobrem grade, movimento, pés, mão legada e 48 âncoras melee.
  [`marty_actions_test.gd:11`](../../tests/marty_actions_test.gd#L11)
