# Versão 0.3 — menus, solo e robôs

- Artes fornecidas aplicadas aos menus principal, online e equipamento.
- Single player sem parceiro, single player com IA, coop local e conexão direta por IP.
- Equipamento: dois estados de armadura, três armas, Titan pilotável e Spectre de apoio/fusão.
- Invocar/recolher preserva dano; fusão usa energia do Spectre e restaura a armadura anterior ao separar.
- Robôs funcionam no modo solo; ausência do parceiro persiste ao morrer e trocar de cenário.
- B equipamento, C invocar/recolher, G fundir/separar, E pilotar. P2: N invocar, M fundir.

Validação: 26 verificações de simulação, 14 regressões de combate, 7 verificações de input e 16 de solo/robôs passaram. Integração ENet testada entre dois processos no mesmo computador: conexão, movimento remoto e snapshots comprimidos. Internet entre máquinas e controles físicos ainda não foram validados. Capturas reais dos menus revisadas no Godot.

Limites: slots bloqueados são ilustrativos; módulos são descrições de capacidades, não inventário modular. Titan é compartilhado; cada jogador ativo possui um Spectre. Arte dos atores e cenários de combate ainda não corresponde integralmente às telas conceituais.
