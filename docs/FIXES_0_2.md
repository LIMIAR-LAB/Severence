# Correções após o primeiro playtest

O primeiro teste do usuário revelou falhas que os testes isolados da versão 0.1 não cobriam.

| Relato | Causa | Correção |
|---|---|---|
| Bala parada | `step_bullets` só era chamado no modo expedição | Atualização de projéteis em todos os modos, inclusive refúgio |
| Sem inimigos para testar | Entrada padrão em refúgio sem inimigos | Botão principal abre arena com cinco inimigos e ondas automáticas |
| IA só segue | Refúgio sem alvos e raio de aquisição restrito | Arena com alvos, busca ampliada, aproximação ativa e checagem de linha de tiro |
| Movimento lento | Velocidades 195/220px/s | 300/320px/s; Titan de 125 para 190px/s |
| Sem dash perceptível | Multiplicava velocidade mas deslocamento era zero sem direção pressionada | Impulso com direção memorizada, fallback para direção do corpo, rastro e recarga visível |
| Corpo não vira ao andar | Renderizador sempre usava mira do mouse | Direção corporal própria; caminhada orienta o corpo, tiro/golpe orientam para a mira |

Validação: 14 regressões de combate, 7 verificações com entrada injetada na cena completa, 26 testes anteriores e teste de rede entre duas instâncias passaram. Captura do renderizador mostra IA atirando, inimigos e projéteis na arena. Não equivale a aprovação subjetiva do ritmo/controle pelo usuário nem a teste externo de internet.
