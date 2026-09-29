# Marty — Fraturas do Tempo

Versão de teste 0.14, construída em Godot 4.7.2 para Windows. É um protótipo funcional do núcleo do MVP, não uma campanha concluída ou a arte final dos cenários. Esta versão atualiza Marty, docas e HUD com base nas referências fornecidas; veja `docs/ART_0_4.md`. A 0.5 transforma o Refúgio • Fora do Tempo no cenário ilustrado do conceito v1; veja `docs/REFUGIO_0_5.md`. A 0.6 aplica os sprites do conceito v1: 4 visuais do Marty, os 4 inimigos das Docas e o chefe O Almirante das Profundezas; veja `docs/SPRITES_0_6.md`. A 0.9 separa **Uniformes** (Padrão, Mecânico, Espião — cada um com arma e atributos próprios) da **Armadura Ômega** (temporária, com espada); veja `docs/EQUIPAMENTO_0_9.md`. A 0.13 recria as Docas como um mapa fixo e grande (13 salas + secreta), com paredes, portões, névoa, props destrutíveis, barris explosivos em cadeia e reforços; veja `docs/CENARIO_0_13.md`. A 0.14 traz a nova tela de Equipamento (retratos, STATUS com os números reais, Ômega lendária), navegação por controle no menu e vida inicial fixa em 3 corações; o resumo de tudo está em `docs/HISTORICO_CLAUDE.md`. O loop de expedição agora inclui uma tela pós-run com estatísticas, nota e falecimento contextual; veja `docs/RUN_SUMMARY.md`.

## Jogar

Abra `Jogar.cmd` nesta pasta. Ele usa o Godot instalado em `C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`.

Alternativa: importe `project.godot` no Godot e pressione **F5**. Não há dependências npm, API ou login para jogar. A chave de geração de imagens não é utilizada nem incluída no jogo.

No menu, escolha **NOVA EXPEDIÇÃO**. Selecione **Marty** na tela de personagens; as outras cinco silhuetas são vagas bloqueadas para personagens futuros. Escolha **Solo**, **Parceiro IA** ou **Coop Local (2 jogadores)**, configure uniforme, armadura e robô na tela de equipamento e pressione **IR AO REFÚGIO**. No refúgio, suba a escadaria até o portal **DOCAS / 1941** e pressione **E**. Com um controle no coop local, ele controla o P2; Marty usa teclado e mouse.

Durante a partida, pressione **Esc**, **Start** ou **B** para abrir a pausa e escolha **SALVAR JOGO**. Na próxima abertura, **CARREGAR JOGO** no título retoma a sessão, inclusive posição, mapa, recursos e modo de coop. O arquivo da sessão fica em `user://expedition.save`, separado de `progress.json`, que guarda os desbloqueios. O salvamento da sessão está disponível para Solo, Parceiro IA e Coop Local; partidas online não oferecem esse botão. O menu de pausa tem **CONTINUAR** e **SALVAR JOGO**; a escolha de uniforme fica antes da partida.

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
| Vestir a Armadura Ômega (12s, recarga 18s) | R | O | LB |
| Mapa completo | Tab, M ou clique no minimapa | — | — |
| Alternar IA / coop local | F2 | — | — |
| Menu/pausa offline | Esc | — | — |

Com um controle no coop local, ele controla o P2 e o teclado/mouse controla Marty. Com dois controles, cada um controla um personagem. Mapeamento implementado, mas ainda precisa de teste físico com os controles do usuário. Teclado compartilhado está sujeito ao limite de teclas simultâneas do dispositivo.

As teclas do Marty/P1 são remapeáveis em OPÇÕES → CONTROLES: clique na ação e pressione a nova tecla (Esc cancela; teclas em uso ou reservadas são recusadas). Os binds ficam salvos em `settings.json`. Teclas do P2, mouse e controle ainda são fixos.

O salto evita balas enquanto o personagem está no ar e permite cruzar o vão sinalizado do armazém. O dash percorre até 180px em 0,2s, tem recarga de 0,6s e usa a direção do movimento; parado, usa a direção do corpo. O HUD mostra sua disponibilidade. Marty move-se a 320px/s sem armadura, 300px/s com armadura e 190px/s no Titan. O corpo vira para onde anda; ao atirar ou golpear, vira para a mira. Escadas são rampas de elevação com colisão de bordas. Armas de fogo têm mira em 360 graus, enquanto o corpo usa oito direções de arte. A movimentação aceita qualquer direção. O ataque próximo usa arco frontal; com armadura também reflete projéteis próximos.

## Primeiro percurso

1. Entre nas docas pelo portal do refúgio. O mapa completo abre com Tab/M e mostra só o que já foi descoberto.
2. No **01 Desembarque**, pegue a chave. Ao entrar numa sala com inimigos os portões fecham até ela ficar limpa; algumas salas mandam uma segunda leva de reforços.
3. Siga pelo **02 Pátio dos Guindastes** e **03 Armazém 7** (salte o canal ou use a passarela). Caixas e barris quebram; os **barris vermelhos explodem** e encadeiam — use-os contra os inimigos, mas cuidado, eles também ferem o Marty.
4. Na **05 Oficina**, o comerciante vende uma chave e cura por 15 moedas (estoque único). O **Titan-01** fica ali: canhão pesado, bomba (R) e soco.
5. O **06 Último Gerador** inicia o desafio opcional: sete guardiões em 55 segundos.
6. Há uma **parede rachada** no topo do **07 Depósito de Munição**: um golpe corpo a corpo abre a passagem para o Contrabando.
7. Pelo **09 Balcão do Farol** (ou pelo **11 Doque Seco**) chega-se à arena do **Almirante das Profundezas**. Derrote-o e use a cápsula de extração.
10. Todos começam com **3 corações**. A bancada do refúgio (melhoria de vida) está congelada até definirmos a progressão.

Dinheiro e chaves reiniciam por tentativa. Fragmentos, vitórias, melhorias e armadura desbloqueada são salvos em `user://progress.json`, dentro da pasta de dados do Godot para este jogo. Em rede, esta primeira versão salva o progresso do anfitrião; progressão própria do convidado ainda não foi implementada.

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
- Efeitos sonoros: síntese original pelo mesmo script. Sem música nesta versão.

Não foram usados sprites ou áudio extraídos de Enter the Gungeon, Metal Warriors ou ROMs. As imagens de referência serviram para orientar a geração dos sprites originais.

## Estrutura

- `scripts/simulation.gd`: simulação, navegação, combate, recursos, missão, robô e estados serializáveis.
- `scripts/main.gd`: entrada, UI, câmera, persistência e rede.
- `scripts/world_view.gd`: desenho do mundo, sprites e efeitos.
- `tests/simulation_test.gd`: testes de regras e transições.
- `tools/test_network.ps1`: teste de integração de duas instâncias com movimento remoto e replicação.

## Validação

Executar no PowerShell, na raiz do projeto:

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/simulation_test.gd
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/combat_regression_test.gd
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/input_scene_test.gd
# suíte completa (todos devem terminar com 0 falhas):
Get-ChildItem tests\*_test.gd | ForEach-Object { & 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script "tests/$($_.Name)" }
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test_network.ps1
```

Capturas do renderizador real (abrem uma janela temporária e encerram):

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture-run
```

## Limites desta entrega

O mapa é fixo (13 salas e uma secreta, editadas em `tools/build_docks_map.py`); a seed só varia os tipos de inimigo. As três armas ficam acessíveis por Q para facilitar os testes. Comércio é uma compra simples, não uma loja completa. Apenas Marty é selecionável por enquanto. Não há outras épocas, lobby Steam, balanceamento final, remapeamento do P2/joypad, exportação independente do Godot nem validação humana de uma campanha completa.

Próximos marcos: playtest de movimentação/combate e câmera; navegação mais refinada; arte do cenário e inimigos; Vincent; geração modular mais ampla; transporte online com lobby/relay e teste real entre dois computadores; empacotamento para Windows.
