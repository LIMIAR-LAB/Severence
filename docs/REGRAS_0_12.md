# Regras 0.12 — corações, escudo Ômega, portões e tentáculo

## Vida em corações
- Marty começa com **3 corações**. 1 coração = 10 de vida. (0.14: a vida inicial é sempre 3 corações; a bancada está congelada — ver `HISTORICO_CLAUDE.md`.)
- Golpe comum tira **meio coração**. Golpe pesado tira **1 coração**: arpão, bala de canhão do Almirante, ou qualquer golpe com dano ≥ 20 depois do modificador do uniforme.
- Depois de levar dano, 0,9s de invulnerabilidade.
- Curas: baú, 1 coração; comerciante, 2 corações; desafio opcional, 2 corações; reanimar, 1,5 coração.

## Armadura Ômega
Ao ativar, dá **3 corações temporários de escudo**, que aparecem em ciano no HUD e como um hexágono em volta do Marty. Cada golpe gasta o escudo antes da vida. O escudo some quando a armadura acaba. A antiga redução de 60% de dano saiu.

## Portões e salas trancadas
- Cada ponta de corredor que encosta numa sala tem um **portão grande**: duas torres de tijolo com lanterna.
- **Aberto:** lanternas âmbar, luz dourada e setas animadas no chão apontando a saída.
- **Fechado:** lanternas vermelhas piscando, grade de ferro descida e brilho vermelho.
- Ao entrar numa sala com inimigos, **todos os portões dela fecham** até o último inimigo daquela sala cair. O HUD avisa "PORTÕES FECHADOS" e depois "SALA LIMPA". Um parceiro que ficou no corredor é puxado para dentro.
- Cada sala da expedição usa apenas sua população inicial. Ao derrotar a última ameaça, os portões abrem imediatamente e a sala não repopula; os inimigos das salas seguintes permanecem aguardando o jogador.
- Portões fechados bloqueiam movimento, salto e tiros. Inimigos do desafio opcional não trancam a sala.
- Código: `build_doors`, `step_gates` (`scripts/simulation.gd`) e `draw_gate` (`scripts/dock_scenery.gd`).

## Tentáculo do Desembarque
A poça com tentáculo (Sala 01) é um perigo: pisar nela dá meio coração de dano, o tentáculo chicoteia e empurra para fora. Com alguém perto, os tentáculos se erguem e o chão pulsa em vermelho. **Saltar por cima escapa.** Configuração em `HAZARDS` (`scripts/docks_map.gd`).

Testes: `tests/scenery_test.gd` (portões e tentáculo), `tests/simulation_test.gd` e `tests/omega_test.gd` (corações e escudo).
