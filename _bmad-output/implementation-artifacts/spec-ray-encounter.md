---
status: implemented
date: 2026-10-04
---

# Encontro RAY-78

Objetivo: separar o robô recrutável do combate normal dos Guindastes e oferecer uma luta própria após limpar a sala. O identificador interno `golem` permanece compatível com aliados, inventário e saves.

O robô não conta como ameaça para abrir os portões. Antes do encontro, aproximação e dano não o ativam. A sala precisa estar marcada como limpa, sem ameaças normais, e um jogador vivo precisa aproximar-se a até 480 unidades dentro dela. Não há novo bloqueio dos portões durante este encontro opcional.

A luta alterna quatro disparos de canhão, três mísseis com impactos anunciados por um segundo e teleporte com explosão. O destino é procurado atrás do jogador em piso válido da mesma sala, sem paredes ou sobreposição com jogadores. O aviso de 0,7 segundo começa antes do teleporte; o robô aparece 0,24 segundo antes da explosão. Se o local deixar de ser válido, o teleporte é cancelado. O círculo anunciado permanece no local reservado. Danos usam o processamento existente de corações, invulnerabilidade e paredes. Explosões próprias não ferem o robô.

Ao perder a vida, permanece atordoado para captura pelo fluxo existente. Não aceita captura antecipada; saves antigos com um robô já atordoado continuam válidos. Campos do encontro ficam no dicionário do inimigo, preservado pelo snapshot existente. Sem alvo vivo dentro da sala, volta à recuperação, sem perseguir corredores.

Implementação isolada em `scripts/ray_encounter.gd`. Integrações pontuais em `scripts/simulation.gd`: proteção de dano, contagem de ameaças, atualização do inimigo, projéteis de míssil, resolução de áreas e captura. Nenhuma alteração nos aliados ou no balanceamento dos demais inimigos.

Aceite verificado em `tests/ray_encounter_test.gd`: 25 verificações de ativação, imunidade inicial, abertura dos portões, ataques, posição de teleporte, avisos, paredes, invulnerabilidade, snapshot, captura, cancelamento sem piso válido, recompensa sem repetição e compatibilidade com robô derrotado em save antigo. Os testes de armamento Titan (12) e revisão de gameplay/história (37) também passaram. Captura reproduzível em `tools/capture_ray_encounter.gd`, usando simulação temporária e sem escrever no save do usuário. GIF em `test-output/ray-encounter/ray-combat.gif`. O renderer de projéteis em `world_view.gd` usa a arte existente de foguete exclusivamente quando `ray_missile` está presente.
