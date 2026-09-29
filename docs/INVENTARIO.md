# Inventário e equipamento

O menu de Equipamento usa cinco abas: Inventário, Robôs, Armaduras, Equipados e Status. `data/inventario.json` descreve os itens; `inventory_data.gd` valida e consulta o catálogo; `inventory_state.gd` mantém pilhas, capacidade, seleção, filtro e slots. A interface apenas apresenta esse estado.

Existem dois contextos intencionalmente separados. Antes de iniciar, **Equipamento** prepara o loadout persistente que será levado. Durante a partida, **Inventário da Missão** é aberto pela pausa e projeta o loadout levado junto com chaves, moedas, fragmentos, combustível e energia existentes naquela tentativa. Esses recursos temporários são lidos diretamente da simulação e nunca são inseridos em `InventoryState.stacks`.

## Regras de dados

- IDs são estáveis e desconhecidos são descartados ao carregar.
- Uma pilha ocupa uma vaga, respeita `max_pilha` e nunca é alterada parcialmente quando a operação falha.
- Itens equipáveis apontam para um `loadout_id` existente. Uniformes/armas, Titan, Spectre e Ômega continuam autoritativos em `equipamento.json` e na simulação.
- Itens marcados como `prototipo` aparecem no catálogo, mas não podem ser usados nem equipados. A UI explica o motivo.
- Chaves, moedas, combustível do Titan e baterias do Spectre pertencem à tentativa atual e não ocupam o inventário persistente.

## Persistência e rede

Progresso e saves de expedição novos usam versão 2. Versão 1 continua aceita e recebe um inventário padrão sanitizado. O inventário viaja no snapshot autoritativo; qualquer pedido de loadout recebido pela rota de rede continua validado pelo host em `simulation.gd`. O menu de equipamento é pré-expedição no fluxo atual; durante uma partida, o atalho abre a pausa. O convidado não grava progresso local nem aplica ids fora das regras existentes.

## Limitações atuais

Kit de reparo, sucata temporal, fragmento cronal e chave do Marty são protótipos de conteúdo. Eles demonstram pilhas, filtros e item especial, mas não criam cura, economia ou efeitos de combate. Os ícones desses itens e dos recursos temporários ainda são provisórios: usam deliberadamente assets internos rastreáveis até a produção do pacote final, sem material externo não licenciado.

