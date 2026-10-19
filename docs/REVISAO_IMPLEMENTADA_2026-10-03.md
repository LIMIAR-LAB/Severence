# Revisão implementada — 03/10/2026

A primeira expedição recebeu correções de persistência, cooperativo, combate, apresentação e narrativa. Ômega conserva duração de 300 segundos, recarga de 60 segundos, velocidade 430, escudo adicional de três corações, dano, armas e proteção aérea. Outras eras e os quatro amigos jogáveis continuam no planejamento.

## O que mudou

- **Saves e cooperativo:** convidado restaura seu estado local ao sair; snapshots atrasados não substituem o perfil; comandos breves sobrevivem até o próximo passo do anfitrião. Perfil e checkpoint usam a mesma revisão. Saída pelo menu e pela janela compartilham a proteção de salvamento.
- **Combate:** IA troca armas vazias e prioriza reanimação. Robôs atordoados permanecem capturáveis; a IA não gasta robobolas. Captura não repete consumo/recompensa. Tesla conserva suas 18 cargas; mosquete não herda a explosão do Titan. Cobertura bloqueia respingos, inclusive dano/empurrão de barris e propagação entre objetos.
- **Gameplay:** salto comum evita ameaças do chão, não tiros e explosões. Ômega/Azul mantêm a proteção aérea. Primeiro confronto e rotas existentes têm orientação. Tempo de armadura e tempo no ar ficam no resumo como segundos somados dos jogadores, para futuros testes de equilíbrio.
- **História:** Coral explica sua dissidência; primeira vitória liga a Ordem ao ataque à nave e recupera mensagem de Letícia. Missões e diário conservam pistas dos quatro amigos. Titan segue a primeira vitória; chassi Spectre segue o Gerador, distinto do original desaparecido com Íris. Desbloqueios anteriores permanecem.
- **Visual e conforto:** projéteis com silhuetas próprias, HUD mais compacto, diálogo e recursos sem sobreposição, diário rolável com foco por controle. Música/efeitos têm volumes independentes; tremor e flashes têm intensidade configurável. Abertura pode pausar; navegar pelos botões não pula o vídeo.
- **Controles:** N abre o diário fora do coop local. No coop local N/M continuam sendo invocação/fusão do P2; diário pelo menu, mapa por Tab/minimapa. Armas novas também podem ser selecionadas pelo convidado.
- **Ferramentas:** Jogar.cmd resolve o motor sem caminho de usuário fixo e importa no primeiro uso. Preset Windows fornecido. Testes recebem perfil separado antes dos autoloads e limite de duração.

## Compatibilidade dos saves

**Checkpoints antigos sem revisão compatível não podem ser retomados.** O jogo explica a recusa e pede nova expedição. Recursos, inventário e desbloqueios permanentes são preservados; os arquivos antigos não são apagados. A proteção também recusa checkpoint antigo se houver interrupção entre as duas gravações. Não há recuperação automática dessa tentativa, mas o progresso permanente não volta atrás.

## Verificação

Testes executados em diretórios exclusivos `SeverenceTests`, sem usar o perfil real:

| Grupo | Resultado / evidência |
|---|---|
| Perfil/rede, saída, controle, save e apresentação | Passaram; perfil/rede com 21 verificações; `output/isolated-tests/ba4f36507ae64972999657f2672a83f8` |
| Simulação, captura, gameplay/história e apresentação | Passaram; simulação 28 verificações; `output/isolated-tests/a3e7a852cc8a42cf9f0cb26c99fbdf5a` |
| Ômega, voo e arpoador | Passaram; voo 30 verificações; `output/isolated-tests/330871dda265435da0c35e615dbb3517` |
| Intro com navegação e apresentação com isolamento | Passaram; `output/isolated-tests/e1ae9b155ee34f2583e29fa8adc84f4c` (falha da fixture P2 corrigida no lote acima) |
| Explosões/captura/história e novos inimigos | Passaram; regressão com 37 verificações; `output/isolated-tests/c4281fcfadf24f139b8d6af7035e5323` |
| Framework de combate e armas de expedição | Passaram; `output/isolated-tests/01def1a44f46411b9af2c6980b7a6990` (expectativa antiga do Guard corrigida no lote acima) |
| Áudio, intro e apresentação | Passaram; `output/isolated-tests/dc1f99d41b0f423594506fba3bacf181` |
| Equipamentos, combate, lore, missões, rotas e armas independentes | Suítes específicas passaram nas etapas de implementação; logs em `output/isolated-tests` |

Oito capturas renderizadas estão em `output/review-improvements/presentation`. Foram inspecionados diário e HUD, inclusive com interface ampliada. A resolução do executável pelo launcher foi conferida com `-ResolveOnly`; não foi produzido nem validado um build distribuível.

Três revisões independentes avaliaram defeitos, casos extremos e critérios de aceite. Encontraram isolamento direto dos testes visuais, navegação da intro, saída pelo menu e respingos de barris; correções e regressões foram acrescentadas. Testes antigos de rampa no Farol foram atualizados para o módulo plano publicado; extração agora verifica a animação antes do retorno. A expectativa antiga de morte do Guard com 100 de dano foi ajustada para conferir dano contra seus 150 de vida existentes.

## Pendências e limites

- `enemy_motion_test` ainda aponta diferença no primeiro quadro `fish/attack/north-east`. Código/teste são idênticos ao snapshot anterior e a arte não foi alterada nesta revisão. A regressão funcional do arpão passa.
- Não houve teste humano de equilíbrio, controle físico ou conexão entre redes externas nesta entrega.
- Exportação Windows, Steam/relay, demais eras, resgates e novos personagens jogáveis precisam de trabalhos próprios.
- Alterações ficaram no diretório de trabalho; não foi feito commit abrangendo o trabalho anterior nem publicação remota.
