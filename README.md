# Severence — Ecos do Tempo

Protótipo de desenvolvimento em Godot 4.7.2 para Windows, consolidado em 03/10/2026. Marty, Refúgio, Docas de 1941, geração modular, combate, parceiro IA, coop local/online e relatório de expedição estão implementados. As demais eras e os quatro amigos jogáveis continuam planejados.

A revisão atual corrige persistência/rede, captura e combate; acrescenta diário de pistas, melhora a leitura do HUD/projéteis e oferece ajustes de tremor, flashes, música e efeitos. **Ômega permanece forte:** duração de 300 s, recarga de 60 s e velocidade de 430 px/s, mantendo escudo, dano e voo. Veja [entrega e limites da revisão](docs/REVISAO_IMPLEMENTADA_2026-10-03.md). Os documentos numerados 0.x e o [histórico](docs/HISTORICO_CLAUDE.md) registram versões anteriores.

## Jogar

Abra `Jogar.cmd`. Ele prefere `build/Severence.exe`, quando disponível; caso contrário procura Godot por `GODOT_EXE`, PATH, pastas locais ou Downloads do usuário. Não reimporta todos os recursos a cada abertura. No primeiro uso do projeto, importa os recursos automaticamente; a atualização manual também está disponível com `tools/launch_game.ps1 -Import`.

`tools/launch_game.ps1 -ResolveOnly` mostra o executável escolhido sem abrir o jogo. `-PreferEngine` ignora um build existente para executar o projeto em desenvolvimento.

Alternativa: importe `project.godot` no Godot e pressione **F5**. Não há dependências npm, API ou login para jogar. A chave de geração de imagens não é utilizada nem incluída no jogo.

No menu, escolha **NOVA EXPEDIÇÃO**. Selecione **Marty** na tela de personagens; as demais silhuetas são vagas bloqueadas para personagens futuros. Escolha **Solo**, **Parceiro IA** ou **Coop Local (2 jogadores)**, configure uniforme, armadura e robô na tela de equipamento e pressione **IR AO REFÚGIO**. No refúgio, suba a escadaria até o portal **DOCAS / 1941** e pressione **E**. Com um controle no coop local, ele controla o P2; Marty usa teclado e mouse.

Durante a partida, pressione **Esc** ou **Start** para abrir a pausa e escolha **SALVAR JOGO**. O **INVENTÁRIO DA MISSÃO** é a ação destacada no topo da pausa; no teclado, **B** abre essa tela diretamente tanto durante a partida quanto a partir da pausa. Dentro do inventário, **B**, **Esc** ou **Voltar** retorna à pausa sem retomar a partida. Na próxima abertura, **CARREGAR JOGO** no título retoma a sessão, inclusive posição, mapa, recursos e modo de coop. O arquivo da sessão fica em `user://expedition.save`, pareado por revisão com `progress.json`, que guarda o perfil permanente. Offline, ambos também são salvos automaticamente e no fechamento normal. Checkpoints antigos sem revisão ou divergentes são recusados com explicação; perfil e desbloqueios são preservados, mas é necessário iniciar uma nova expedição. O salvamento da sessão está disponível para Solo, Parceiro IA e Coop Local; partidas online não oferecem esse botão. A escolha de uniforme continua antes da partida.

**C** invoca/recolhe o robô selecionado; **G** funde/separa o Spectre; **E** entra/sai do Titan. Invocações respeitam espaço, recarga e integridade: recolher não cura. Spectre acompanha e atira, ou se funde a Marty para absorver dano e aumentar velocidade e poder de fogo. A armadura continua binária.

## Controles

| Ação | Marty / jogador online | P2 no mesmo teclado | Controle |
|---|---|---|---|
| Movimento | WASD | Setas | Analógico esquerdo |
| Mira | Mouse | IJKL | Analógico direito |
| Tiro | Clique esquerdo | Enter | Gatilho direito |
| Corpo a corpo | Clique direito ou F | Ponto | X / botão oeste |
| Salto, inclusive diagonal | Espaço + direção | Barra / + direção | A / botão sul |
| Dash (também funciona parado) • no Titan: segurar = TURBO | Shift | Vírgula | B / botão leste |
| Interagir, reanimar, entrar/sair do robô | E | Ctrl | Y / botão norte |
| Vestir a Armadura Ômega (300 s, recarga 60 s) | R | O | LB |
| Mapa completo | Tab ou minimapa; M fora do coop local | — | — |
| Alternar IA / coop local | F2 | — | — |
| Menu/pausa offline | Esc | — | Start / Options |
| Alternar arma básica / arma da expedição (inclusive vazia) | Q | U | RB |
| Invocar / recolher robô | C | N | Direcional para cima |
| Fundir / separar Spectre | G | M | Direcional para baixo |
| Trocar robô selecionado | V | H | Direcional para esquerda |
| Poder da forma | T | P | Direcional para direita |
| Missões e diário | N, fora do coop local; também na pausa | Pela pausa | Start → Missões |
| Inventário da Missão | B | — | Start → ação destacada |

Com um controle no coop local, ele controla o P2 e o teclado/mouse controla Marty. Com dois controles, cada um controla um personagem. Mapeamento implementado, mas ainda precisa de teste físico com os controles do usuário. Teclado compartilhado está sujeito ao limite de teclas simultâneas do dispositivo.

As teclas do Marty/P1 são remapeáveis em OPÇÕES → CONTROLES: clique na ação e pressione a nova tecla (Esc cancela; teclas em uso ou reservadas são recusadas). Os binds ficam salvos em `settings.json`. Teclas do P2, mouse e controle ainda são fixos.

O salto comum evita ameaças do chão, como ácido e tentáculos, e cruza vãos sinalizados; tiros e explosões continuam perigosos. Ômega e Azul mantêm a proteção aérea existente. O dash percorre até 180px em 0,2s, tem recarga de 0,6s e usa a direção do movimento; parado, usa a direção do corpo. O HUD mostra sua disponibilidade. A animação visual do rolamento dura 0,36s para tornar as poses legíveis; deslocamento e proteção continuam limitados aos 0,2s originais. A velocidade a pé depende do uniforme; Ômega/Azul usam 430 px/s e o Titan 190 px/s. Os valores do equipamento vêm das constantes da simulação. O corpo vira para onde anda; ao atirar ou golpear, vira para a mira. Escadas são rampas de elevação com colisão de bordas. Armas de fogo têm mira em 360 graus, enquanto o corpo usa oito direções de arte. A movimentação aceita qualquer direção. O ataque próximo usa arco frontal; com armadura também reflete projéteis próximos.

## Primeiro percurso

1. Entre nas docas pelo portal do refúgio. O mapa completo abre com Tab/M e mostra só o que já foi descoberto.
2. No **01 Desembarque**, pegue a chave. Ao entrar numa sala com inimigos os portões fecham até ela ficar limpa. Cada sala tem uma população inicial e não repopula depois de limpa; os encontros seguintes continuam nas outras salas.
3. Siga pelo **02 Pátio dos Guindastes** e **03 Armazém 7** (salte o canal ou use a passarela). Caixas e barris quebram; os **barris vermelhos explodem** e encadeiam — use-os contra os inimigos, mas cuidado, eles também ferem o Marty.
4. Na **05 Oficina**, o comerciante vende uma chave e cura por 15 moedas (estoque único). O **Titan-01** fica ali: canhão pesado, bomba (R) e soco.
5. O **06 Último Gerador** inicia o desafio opcional: sete guardiões em 55 segundos.
6. Há uma **parede rachada** no topo do **07 Depósito de Munição**: um golpe corpo a corpo abre a passagem para o Contrabando.
7. Pelo **09 Balcão do Farol** (ou pelo **11 Doque Seco**) chega-se à arena do **Almirante das Profundezas**. Derrote-o e use a cápsula de extração.
10. Todos começam com **3 corações**. A bancada do refúgio (melhoria de vida) está congelada até definirmos a progressão.

Dinheiro e chaves reiniciam por tentativa. Fragmentos, vitórias, melhorias e armadura desbloqueada são salvos em `user://progress.json`, dentro da pasta de dados do Godot para este jogo. Em rede, esta primeira versão salva o progresso do anfitrião; progressão própria do convidado ainda não foi implementada. O perfil local do convidado é restaurado ao desconectar e nunca é substituído pelo estado do anfitrião.

## Robô e parceiro IA

Marty e o parceiro podem ocupar a máquina, mas nunca simultaneamente. Desembarcar mantém sua integridade; saídas bloqueadas não teletransportam o piloto. No protótipo, a destruição provoca ejeção de emergência com proteção curta. Não existe perda permanente do robô entre tentativas.

O parceiro **Echo** é um substituto de desenvolvimento, com o atlas do Marty identificado em dourado; não é um novo personagem definitivo do universo. Ele segue caminhos válidos, atira, tenta esquivar, reanima Marty e pode usar um robô próximo durante o combate. Sua inteligência e equilíbrio ainda são básicos. Vincent terá arte e habilidade próprias em uma etapa seguinte.

## Coop online

O anfitrião escolhe **Hospedar online**. O convidado digita o IP do anfitrião e escolhe **Entrar**. Na mesma máquina, use `127.0.0.1`; na mesma rede, o IP local. A implementação usa ENet, porta **UDP 24871**, simulação autoritativa no anfitrião e estados comprimidos. O convidado controla o P2. Quando ele sai, a IA assume.

Para redes diferentes, o anfitrião precisa de conectividade de entrada nessa porta; NAT, CGNAT e firewall podem impedir a conexão. Não há Steam, relay, matchmaking, UPnP ou perfuração de NAT implementados. Não alteramos as configurações do roteador ou do firewall automaticamente. A validação realizada foi entre duas instâncias locais, não entre duas redes reais.

Online não pausa ao abrir o menu. Offline pausa ao perder foco. Não há predição/reconciliação de rede: latência elevada ainda pode causar atraso perceptível.

## Arte

- `assets/marty/marty.png`: 32 quadros de caminhada; quatro direções, quatro fases, dois estados de armadura.
- `assets/marty/actions.png`: 24 poses de tiro, salto e corpo a corpo; quatro direções e dois estados.
- `assets/mech/titan.png`: oito quadros; quatro direções e duas fases.
- `art/source/`: fontes geradas pela API OpenAI / GPT Image 2 e os prompts usados. Os arquivos são concepts de produção inicial e precisam de refinamento manual para animação final.
- `tools/prepare_art.py`: remove o fundo magenta, detecta as bandas reais da imagem e alinha os pés em células transparentes. Não pressupõe que a IA respeitou a grade pedida.
- `art/marty-titan-preview.png`: prévia da arte já processada.
- Terreno e inimigos: arte provisória; cenário desenhado pelo renderizador e piso original gerado por `tools/make_support_assets.py`.
- Áudio: 23 efeitos originais de armas, criaturas e ações, mais duas trilhas instrumentais em loop (refúgio e expedição). Arquivos em `assets/audio/generated/`, gerados por `tools/generate_game_audio.py`; origem e métricas em `art/source/audio/manifest.json`. OPÇÕES → ÁUDIO controla música e efeitos; a pausa reduz a música e interrompe os efeitos.

Não foram usados sprites ou áudio extraídos de Enter the Gungeon, Metal Warriors ou ROMs. As imagens de referência serviram para orientar a geração dos sprites originais.

## Estrutura

- `scripts/simulation.gd`: simulação, navegação, combate, recursos, missão, robô e estados serializáveis.
- `scripts/main.gd`: entrada, UI, câmera, persistência e rede.
- `scripts/world_view.gd`: desenho do mundo, sprites e efeitos.
- `tests/simulation_test.gd`: testes de regras e transições.
- `tools/test_network.ps1`: teste de integração de duas instâncias com movimento remoto e replicação.

## Validação

Use a execução isolada: ela cria outro diretório de dados antes dos scripts, limita a duração e preserva os logs. Não execute testes de gravação contra o perfil de jogo.

```powershell
$engine = & ./tools/launch_game.ps1 -ResolveOnly -PreferEngine
& ./tools/run_isolated_tests.ps1 -Godot $engine.Executable -Scripts @('tests/profile_network_regression_test.gd', 'tests/review_gameplay_story_test.gd', 'tests/presentation_review_test.gd') -TimeoutSeconds 60
```

O antigo `tools/test_network.ps1` ainda usa o diretório normal do projeto: precisa de isolamento antes de uma nova execução. Não há nova validação entre redes externas nesta revisão.

## Exportar para Windows

O preset `Windows Desktop` gera `build/Severence.exe` (x86_64, pacote embutido). Inclui JSON de execução e preserva `tools/scenarios/prototype/layout_generator.gd`, `art/concept` e `art/scenarios`; exclui documentação, testes, saídas e fontes de produção. Abra Projeto → Exportar no Godot e confira os templates 4.7.2. Nesta instalação, os executáveis de template estão numa subpasta `templates`; se o editor não os localizar, selecione `windows_debug_x86_64.exe` e `windows_release_x86_64.exe` nos campos de template personalizado. Nenhuma instalação do usuário foi modificada. O preset foi entregue; um build distribuível ainda precisa ser exportado e validado.

## Limites desta entrega

As Docas combinam topologia procedural por seed com interiores autorais. Armas básicas acompanham o uniforme; armas de expedição consomem munição e a IA troca quando a selecionada fica vazia. Comércio ainda é simples. Apenas Marty é selecionável; sinais dos quatro amigos no diário não significam que eles já foram resgatados ou estão jogáveis.

Ainda faltam outras eras, lobby/relay Steam, remapeamento do P2/joypad, build Windows validado e avaliação humana de uma campanha completa. A revisão encontrou uma inconsistência anterior no atlas do ataque nordeste do peixe, registrada no relatório de entrega. O funcionamento do arpão e o voo Omega passaram nas regressões específicas.
