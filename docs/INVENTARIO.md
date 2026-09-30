# Inventário e equipamento

O menu de Equipamento usa cinco abas: Inventário, Robôs, Ômega, Equipados e Atributos. `data/inventario.json` descreve os itens; `inventory_data.gd` valida e consulta o catálogo; `inventory_state.gd` mantém pilhas, capacidade, seleção, filtro e slots. A interface apenas apresenta esse estado.

Existem dois contextos intencionalmente separados. Antes de iniciar, **Equipamento** prepara o loadout persistente que será levado. Durante a partida, **Inventário da Missão** é aberto pela pausa e projeta o loadout levado junto com chaves, moedas, fragmentos e armas encontradas naquela tentativa. Esses recursos temporários são lidos diretamente da simulação e nunca são inseridos em `InventoryState.stacks`.

## Regras de dados

- IDs são estáveis e desconhecidos são descartados ao carregar.
- Uma pilha ocupa uma vaga, respeita `max_pilha` e nunca é alterada parcialmente quando a operação falha.
- Itens equipáveis apontam para um `loadout_id` existente. Uniformes/armas, Titan, Spectre e Ômega continuam autoritativos em `equipamento.json` e na simulação.
- Itens marcados como `prototipo` permanecem nos saves, mas ficam ocultos na interface.
- Chaves, moedas e fragmentos ganhos desde o início da tentativa, além do combustível ou energia do robô realmente levado, são projeções ao vivo e não ocupam o inventário persistente.

## Persistência e rede

Progresso e saves de expedição novos usam versão 2. Versão 1 continua aceita e recebe um inventário padrão sanitizado. O inventário viaja no snapshot autoritativo; qualquer pedido de loadout recebido pela rota de rede continua validado pelo host em `simulation.gd`. O equipamento pré-expedição prepara os itens; durante a partida, B abre o inventário da missão e B/Esc retorna à pausa. O convidado não grava progresso local nem aplica ids fora das regras existentes.

## Limitações atuais

Kit de reparo, sucata temporal, fragmento cronal e chave do Marty são protótipos de conteúdo. Eles permanecem salvos por compatibilidade, sem aparecer no menu ou criar efeitos de combate. Os recursos temporários visíveis reutilizam arte interna rastreável das docas e do resumo de expedição; combustível e energia continuam usando os retratos dos robôs e só aparecem em Atributos. A interface mostra somente itens com uso na gameplay e não apresenta marcadores técnicos de arte provisória. Ainda falta um pacote autoral dedicado para os quatro protótipos ocultos; essa pendência não afeta a tela atual.

## Sistema visual industrial

A tela compartilhada mantém o canvas lógico de 1344×752 e é centralizada com escala proporcional pelo `terminal_ui.gd`. Em preparação, `refuge_bg.png` aparece sob um véu azul-petróleo; durante a missão, o mesmo shell usa `desembarque_painted_v1.png`. Esses cenários são camadas independentes e podem recortar apenas as bordas em proporções diferentes de 16:9. Nenhuma captura conceitual é usada como fundo interativo.

O chrome modular e os dez pictogramas vetoriais ficam em `assets/ui/equipamento/industrial/`. Painéis, botões, texto, quantidades, foco, barras e seleção continuam sendo nós do motor. A aba Inventário combina filtros iconográficos, grade paginada 5×3, vitrine grande com fallback para o ícone do catálogo, até quatro barras derivadas dos atributos reais e uma faixa de loadout que lê as escolhas autoritativas de uniforme, robô e Ômega.

Os contextos continuam isolados: preparação lê e grava o inventário persistente; missão apenas projeta o equipamento levado e os recursos ao vivo. As cinco abas, as ações EQUIPAR/COMPARAR, os retornos para Refúgio/Pausa e a validação de host não mudaram.


## Ações da missão

Selecione a bazuca e use **EQUIPAR** ou **ARMA BÁSICA** para alternar a arma ativa. A bazuca permanece possuída, selecionável e visível mesmo sem foguetes, mas não dispara; selecionar nunca gera munição. O convidado solicita a troca ao anfitrião, que valida posse e estado. Saia do Titan ou da armadura antes de trocar.

**COMPARAR** apresenta valores atuais → selecionados da simulação. Para a bazuca, mostra dano, intervalo e munição contra a arma básica do uniforme. Recursos automáticos informam sua quantidade; protótipos continuam sem ações fictícias. Abas, filtros e ações aceitam clique, foco de teclado e navegação por controle.

## Atributos e condição atual

Os filtros apresentam uniformes com suas armas, robôs, Ômega e recursos de expedição. O contador informa o total de itens exibidos; não sugere vagas ou capacidade de mochila. Combustível e energia são condição do robô, apresentados em Atributos durante a missão.

Marty, Ômega e o robô têm painéis de referência separados, lidos da simulação. Marty possui três corações base; a Ômega concede escudo temporário somente ativa. A integridade do Titan e a energia do Spectre não aumentam a vida base. A resistência descreve a proteção do uniforme; golpes são convertidos em meio coração ou um coração inteiro.

Durante a missão, a condição atual mostra vida, escudo, duração/recarga Ômega, arma em uso, foguetes, combustível e estado do robô. Os valores atuais se atualizam sem reconstruir a grade continuamente.
