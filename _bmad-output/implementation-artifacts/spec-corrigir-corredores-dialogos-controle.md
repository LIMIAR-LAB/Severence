---
title: 'Corrigir navegação das Docas e identificação na interface'
type: bugfix
created: '2026-10-03'
status: done
baseline_commit: 87fe42e
context: []
---

## Intent

Corrigir os problemas relatados pelo usuário após alterações externas: corredores aparecem e somem ao norte do Desembarque, inimigos ficam fora da sala e impedem a conclusão, diálogos não mostram retratos, armas não possuem miniaturas e os botões PlayStation são apresentados incorretamente.

## Boundaries & Constraints

Preservar todas as alterações externas e os saves do jogador. Manter a topologia atual quando a correção de descoberta e geometria for suficiente. Usar arte disponível e ícones locais sem consumir créditos de geração. Não excluir inimigos vivos para liberar salas. As correções deste conjunto foram autorizadas pelo relato de problemas na revisão em andamento.

## Code Map

- `scripts/dock_scenery.gd`: descoberta de pisos e corredores materializados.
- `scripts/world_view.gd`: renderização de obstáculos e arma equipada.
- `scripts/simulation.gd`: associação de inimigos às salas, deslocamento e portões.
- `scripts/main.gd`: retratos, moldura de diálogo e entrada de controle.
- `scripts/combat_hud.gd`, `scripts/terminal_ui.gd`: instruções PlayStation.
- `scripts/equipment_screen.gd`, `scripts/weapon_visuals.gd`: imagens e nomes do catálogo completo de armas.

## Tasks & Acceptance

- [x] Corredores: manter pisos já descobertos visíveis e desenhar apenas geometria caminhável materializada; eliminar obstáculos duplicados.
- [x] Inimigos: impedir movimento para fora da sala proprietária e recuperar posições inválidas antigas sem alterar HP; abrir portões somente quando ameaças forem derrotadas.
- [x] Diálogos: colocar retratos disponíveis em moldura própria acima da mensagem e alternar o falante entre NPC e Marty.
- [x] Armas: mostrar sete miniaturas e nomes corretos, com seleção acessível dentro do painel e mesma identificação no mundo.
- [x] Controle: apresentar nomes PlayStation legíveis e impedir que interação/troca de arma também executem soco.
- [x] Verificação: testes de regressão dos sintomas, regressões de combate/rotas e captura visual em perfil temporário separado.

### Acceptance Criteria

- Dado o Desembarque descoberto, ao percorrer o caminho norte e retornar, os pisos revelados permanecem visíveis e pertencem aos pisos da simulação.
- Dado um inimigo vivo associado a uma sala, quando sofre empurrão ou carrega contra o jogador, permanece em piso livre da sala; um inimigo legado fora dela retorna sem ser eliminado.
- Dado um diálogo com prefixo do falante conhecido, ao alternar entre NPC e Marty, a foto muda e não é esticada pelo painel.
- Dadas as sete armas no inventário, ao selecionar qualquer uma, seu nome e miniatura são exibidos e a ação seleciona o identificador correto.
- Dado um controle PlayStation, ao pressionar Triângulo ou R1 sem modificador, ocorre somente interação ou troca de arma; golpes médio/forte usam L2 como modificador.

## Verification

Godot 4.7.2: executar testes de corredor, limites de inimigos, diálogos/controle, miniaturas, combate e rota. Não carregar/gravar progresso real nos testes de interface. Inspecionar visualmente a saída norte e os diálogos com projeto temporário de nome exclusivo.

## Spec Change Log

- A investigação reproduziu 36 desaparecimentos de um piso recortado da capela: a descoberta dependia apenas da posição atual do ator. Preservar a arte autoral e corrigir o vínculo entre corredor original e pisos reais.

## Resultado validado

Passaram os testes de visibilidade de corredores, escala dos destroços, contenção de inimigos, diálogo e controle (21 verificações), miniaturas e HUD de sete armas, combate (15 verificações) e conclusão de corredores. A revisão independente não identificou regressão bloqueante. Capturas de Coral e Marty confirmaram retratos acima da moldura; o projeto temporário usou diretório de progresso separado do jogo real.

Os destroços pequenos usam 30% da escala da arte de decoração, ficam abaixo das entidades e não aumentam ao quebrar. Os portões genéricos usam batentes compactos. A reconstrução de duas rotas horizontais longas está sendo conduzida no chat autorizado pelo usuário: Refazer rotas horizontais e travessia de moto.

### Integração da rota horizontal

O desenho da arena usa o retângulo atual da sala boss, e o véu de legibilidade acompanha sua posição. O aviso de desabamento usa bridge_segments(), respeitando mapas novos e legados. O modo de captura da moto começa no checkpoint e percorre a pista com movimento real. O teste de introdução do chefe passou em perfil isolado: nenhuma apresentação antes da chegada, apresentação única ao entrar, combate suspenso e retomado após a cena. Captura visual da nova ponte: test-output/review-moto-horizontal.png.
