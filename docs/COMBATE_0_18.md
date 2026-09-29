# Combate 0.18 — ataques legíveis e esquadrões

## Ciclo e leitura

Inimigos comuns alternam ready → warning → attack → recover. O aviso dura
0,55 s; o ataque até 0,7 s e a recuperação 1,4 s (Soldado inclui deslocamento até cobertura + 0,7 s). Até três inimigos preparam
ou executam ataques por jogador ativo. Recuperação, morte ou perda de alvo
liberam a reserva. Chefes e Warden preservam seus ciclos próprios e não
consomem esse limite. A mira do Arpoador trava ao iniciar a linha; as demais
acompanham o jogador durante o aviso e travam antes do ataque.

- Cultista: orbita a média distância; orbe curvo divide em quatro após 0,8 s.
- Arpoador: passos intermitentes, recuo de curta distância, linha e arpão a
  560 px/s. Impacto/expiração pode deixar estaca por 3,5 s, sem ocupar jogador
  ou porta. A estaca participa da colisão, nunca da geometria permanente.
- Soldado Possuído (brute): leque de seis tiros sequenciais, acelerando até
  620 px/s; busca lado protegido de sacos de areia alcançáveis em linha reta
  até 360 px. Abaixado ao chegar. Sem cobertura válida, recua/orbita.
- Rastejante: aproximação sinuosa e salto de até 220 px sobre área marcada,
  respeitando paredes. Deixa ácido por 2,5 s. Pequeno: bote de até 110 px.
- Bomber: zigue-zague; anuncia parado antes de explodir. Morto, deixa aviso
  de 0,65 s. A explosão de raio 90 causa 22 de dano e encadeia barris.
- Guard: marcha lenta (60 px/s), defesa frontal calculada na colisão varrida
  da bala; flanco e melee funcionam. Arremessa ácido em arco com círculo de
  pouso visível durante 0,9 s; não causa dano durante o voo.

## Esquadrões e elites

O gerador fixa as classes dos pontos da população inicial de cada sala, incluindo
Guard e Bomber. Salas limpas não repopulam; ondas repetidas pertencem apenas à
arena de treinamento. A seed mantém variação de posição/tempos e 16% de chance de elite
nas salas elegíveis. Uma elite recebe exatamente um modificador: escudo
(ciano), rastro (verde) ou explosão ao morrer (laranja, aviso de 0,75 s).
Entrada, loja, salas seguras, boss, Warden e pequenos não recebem elites.
Capela e labirinto continuam sem encontros. Movimentos comuns não invadem
salas seguras vizinhas. Geração/validação: tools/build_docks_map.py.

## Estado e limites

Novos campos de inimigo: combat, combat_t, target_id, locked, launch, burst,
burst_t, cover, crouched, jump_height, elite, trail_t. Defaults permitem ler
estados anteriores. Projéteis aceitam age, curve, accel, split_at, arc,
from/to/flight, trail/trail_next, stake. Filhos entram após iteração, não se
subdividem; projéteis expirados não atingem ninguém.

combat_zones (até 64) e harpoons (até 24) são temporários, sincronizados nos
snapshots e limpos nas trocas de modo, assim como pending_spawns. Ácido/rastro
usam raio efetivo de 80%, cooldown de 0,4 s e respeitam paredes e invulnerabilidade.
Rastro anuncia por pelo menos 0,5 s. Explosões de elites/Bomber respeitam paredes
para atingir jogadores e reutilizam explode para reação em cadeia dos barris.

## Escala visual

Corpos +12%, incluindo Marty, uniformes, armadura, fusão, Titan e Spectre.
Uma transformação ao redor dos pés inclui arma e mãos; cenário e zoom não
mudam. Projéteis comuns +15%; colisões preservadas, menores que o visual.
Avisos ficam no plano do chão; salto/arco mostram altura sem mover a hitbox.
Bomber e Guard usam seus atlas 4×4 existentes; não foram geradas novas artes.

## Verificação

27 scripts *_test.gd passaram; registros test-output/018-*.log.
combat_framework_test.gd cobre reservas/cancelamento, divisão única, curva,
aceleração, expiração, arco, salto bloqueado, estacas, elites, snapshots,
limpeza, seed e salas seguras. Testes antigos de disparo imediato foram
adaptados para aguardar o aviso. Validador do mapa passou.
ENet local real: tools/test_network.ps1 passou na segunda execução, com conexão,
movimento remoto e snapshots comprimidos. Primeira execução sem erros mas
sem marcador de snapshot (log depende de frame divisível por 60).
Não foi exercitada conexão pela internet/NAT. Galeria visual reproduzível:
tests/combat_framework_preview.gd → test-output/combat018-gallery.png.

No jogo: iniciar solo/coop, circular Guard para atingir costas, esquivar da
linha do Arpoador, observar tiros divididos, esperar recuperação do Soldado e
sair dos círculos do Rastejante. Testar Bomber perto de barris e trocar para
Refúgio durante riscos ativos para conferir limpeza.

Revisão adicional: corrigidos salto entrando em sala segura, altura residual ao
perder alvo e escala do dano de ácido. Framework agora tem 27 verificações;
testes de inimigos e regressões 0.17 reexecutados sem falhas. Duas revisões
independentes ficaram pendentes por limite de uso; tarefa permanece em revisão.

Revisões pendentes concluídas: cancelamento de alvo durante ataque em coop e tempo de chegada à cobertura corrigidos, com regressões automatizadas.
