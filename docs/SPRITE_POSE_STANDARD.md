# Padrão de sprites dos personagens

Este documento define o contrato para criar e integrar a arte dos personagens de
**Severence — Ecos do Tempo**. Ele vale para toda arte nova e orienta a migração
gradual dos atlas antigos.

## Decisão principal

### Coerência com o jogo existente

O visual já integrado é a referência principal. Imagens externas orientam o conceito, mas não substituem a direção de arte. Antes de criar uma forma, abrir e comparar os sprites atuais: proporção cabeça/corpo, silhueta, tamanho em pixels, contorno, paleta, iluminação e animações. Depois, conferir a forma dentro do jogo, lado a lado com Marty e os inimigos, em escala real. Retratos, ícones e efeitos devem acompanhar o mesmo padrão. Testes de funcionamento não substituem essa inspeção visual.

Para transformações de energia do Marty, preservar seus pivôs, dimensões e poses existentes é preferível a inserir um novo corpo realista. Brilho deve preservar a leitura dos pixels e não esconder o contorno.

Cada personagem jogável deve ter sua própria pasta, sua própria referência visual
e suas próprias folhas de animação. Personagens diferentes não devem dividir um
atlas gigante.

Dentro da pasta de um personagem, cada ação fica em uma folha separada. Isso
permite gerar, revisar e substituir uma animação sem alterar as outras. Roupas e
formas alternativas continuam vinculadas ao personagem, mas ficam em subpastas
próprias para evitar folhas grandes demais.

Estrutura-alvo:

```text
art/source/characters/
├── marty/
│   ├── reference/
│   ├── padrao/
│   ├── espiao/
│   ├── mecanico/
│   └── omega/
├── leticia/
├── vincent/
├── elias/
└── iris/

assets/characters/
├── marty/
│   ├── padrao/
│   │   ├── idle.png
│   │   ├── walk.png
│   │   ├── jump.png
│   │   ├── evade.png
│   │   └── attack.png
│   └── ...
├── leticia/
├── vincent/
├── elias/
└── iris/
```

Os nomes acima são o destino da organização. Os arquivos existentes em
`assets/marty/` e `assets/mech/` continuam funcionando durante a migração; não é
necessário mover tudo antes de produzir a próxima animação.

## Conjunto mínimo de animações

Todo personagem jogável precisa ter, antes de sua arte ser considerada completa:

| Ação | Mínimo recomendado | Regra visual |
| --- | ---: | --- |
| Parado | 2 quadros | Respiração ou movimento sutil, sem deslizar os pés. |
| Andar ou correr | 4 quadros | Ciclo legível e contínuo em velocidade normal de jogo. |
| Pular | 4 fases | Impulso, subida/ápice, queda e pouso. A altura real vem do código. |
| Esquiva | 4 fases | Preparação, deslocamento, transição e recuperação. |
| Ataque principal | 3 ou mais quadros | Antecipação, impacto/disparo e recuperação. |
| Receber dano | 2 quadros | Reação clara sem mudar a escala do corpo. |
| Derrota | 4 ou mais quadros | Encerramento legível e coerente com o personagem. |

### Pulo

O sprite mostra a pose do personagem; o código controla altura, velocidade e
trajetória. Todas as fases mantêm o mesmo pivô horizontal e espaço suficiente na
célula para que cabeça, pés, cabelo, capa e acessórios não sejam cortados.

### Rolamento, dash ou equivalente

Todos os personagens precisam de uma animação de esquiva, mas não precisam usar o
mesmo movimento:

- Marty usa rolamento nas roupas comuns e uma fissura/teleporte na Armadura Ômega;
- Letícia pode usar uma esquiva acrobática ou um avanço rápido;
- Vincent pode usar um passo veloz de samurai;
- Elias pode deslocar-se por magia ou energia temporal;
- Íris pode usar uma manobra curta apoiada por tecnologia;
- personagens grandes ou pesados podem usar impulso, investida ou propulsão em vez
  de uma cambalhota que não combine com sua massa.

A mecânica pode compartilhar duração e invulnerabilidade, mas a arte deve comunicar
o peso, a personalidade e o poder de cada personagem. A direção da animação vem da
direção real do deslocamento, e não da mira.

## Direções e perspectiva

O padrão dos personagens jogáveis é o sistema de cinco vistas para movimento em
oito direções:

1. frente;
2. diagonal de frente;
3. lado;
4. diagonal de costas;
5. costas.

As direções para a esquerda podem reutilizar as vistas correspondentes por
espelhamento horizontal, desde que roupas, símbolos, próteses ou equipamentos
assimétricos não fiquem visualmente incorretos. Quando a assimetria for importante,
desenhar também as vistas esquerdas.

## Tamanho, escala e pivô

Os personagens não precisam ter a mesma altura nem usar células do mesmo tamanho.
A diferença de porte faz parte da identidade visual e deve continuar perceptível no
jogo.

| Porte | Referência inicial de célula | Uso esperado |
| --- | ---: | --- |
| Pequeno | 64×64 ou 80×80 | drones, criaturas pequenas e formas compactas |
| Humano | 96×96 | Marty e demais personagens humanos, salvo necessidade visual |
| Grande | 128×128 | personagens altos, largos ou com acessórios extensos |
| Muito grande | 176×176 ou maior | Titan, mechas e criaturas de grande porte |

Esses números são referências, não uma obrigação de redimensionar o personagem.
Antes de começar uma folha, registrar no arquivo de referência do personagem:

- tamanho da célula;
- altura visual aproximada em pixels;
- pivô no centro dos pés;
- linha de contato com o chão;
- área segura para cabelo, capa, arma e efeitos;
- escala usada no jogo.

Todos os quadros do mesmo personagem e forma devem conservar o pivô. Personagens
maiores recebem células maiores; não devem ser comprimidos até parecerem do mesmo
tamanho que Marty. A colisão é definida pelo jogo e não deve ser deduzida do
tamanho do PNG.

Efeitos que ultrapassam muito a silhueta — tiros, lâminas, explosões, magia e
rastros de dash — ficam em camadas separadas sempre que possível. Isso evita células
enormes e mantém o corpo reutilizável.

## Referência visual por personagem

Antes de gerar todas as animações, aprovar uma imagem de referência do personagem
com frente, diagonal, lado e costas. Essa referência fixa:

- proporções e altura;
- rosto, cabelo e silhueta;
- roupas e cores;
- materiais e iluminação;
- acessórios permanentes;
- intensidade do contorno e densidade da pixel art.

As animações seguintes devem usar essa referência. Uma nova folha não pode
reinterpretar o rosto, a roupa ou o porte do personagem sem uma decisão de design
registrada.

## Processo de produção

1. Criar e aprovar a referência visual de um personagem.
2. Registrar tamanho de célula, pivô e escala.
3. Produzir `idle` e `walk` para validar identidade e movimento.
4. Produzir `jump` e `evade` em folhas separadas.
5. Produzir ataques, dano e derrota.
6. Integrar no Godot e testar no tamanho real do jogo.
7. Só então iniciar o próximo personagem ou uma nova roupa completa.

Para geração por imagem, trabalhar em lotes pequenos: uma ação e uma vista por vez
quando a pose for complexa. Reutilizar a referência aprovada e alterar apenas o
movimento solicitado.

## Critérios de aceite

Uma folha só pode entrar no jogo quando:

- pertence à pasta correta do personagem e da forma/roupa;
- tem fundo transparente e não contém texto, grade ou cenário;
- mantém o personagem reconhecível em todos os quadros;
- preserva escala, pivô e contato com o chão;
- não corta partes do corpo ou acessórios;
- apresenta mudanças reais entre os quadros;
- funciona nas direções exigidas, incluindo espelhamento quando permitido;
- fica legível no zoom e na velocidade normais do jogo;
- não mistura personagens diferentes no mesmo arquivo;
- foi testada em movimento, pulo, esquiva e ataque no Godot.

## Situação dos atlas atuais

Os atlas atuais foram criados antes deste contrato e permanecem como legado:

| Entidade | Situação atual | Direção futura |
| --- | --- | --- |
| Marty | Várias roupas ainda compartilham `marty_anim_v3.png` | Separar por roupa e por ação durante a renovação da arte. |
| Titan | Usa células maiores, adequadas ao seu porte | Manter escala própria e separar as ações futuras. |
| Spectre | Usa folhas próprias de oito direções para flutuação e disparo | Manter porte menor que Marty e efeitos em camadas separadas. |
| Inimigos | Espécies compartilham atlas de produção antiga | O padrão por personagem é obrigatório primeiro para os jogáveis. |

A migração deve ser gradual. Nenhum atlas funcional precisa ser removido apenas por
estar no formato antigo; ele é substituído quando sua nova versão estiver aprovada,
integrada e testada.

## Marty Padrão — conjunto PixelLab

O Marty Padrão é a primeira migração completa para este contrato. A referência é o
personagem PixelLab `812c6637-c0c0-461a-bce5-22da22348ad7`, criado a partir do
modelo aprovado em `art/source/characters/marty/padrao/reference/rotations/`.

As fontes exportadas ficam em
`art/source/characters/marty/padrao/pixellab/`. O arquivo de produção usado pelo
jogo é convertido por `tools/import_marty_pixellab.py` em oito folhas separadas:

| Ação | Quadros | Arquivo de jogo |
| --- | ---: | --- |
| Parado/respiração | 4 | `assets/characters/marty/padrao/pixellab/idle.png` |
| Corrida | 8 | `assets/characters/marty/padrao/pixellab/run.png` |
| Pulo | 9 | `assets/characters/marty/padrao/pixellab/jump.png` |
| Esquiva com giro frontal | 6 | `assets/characters/marty/padrao/pixellab/evade.png` |
| Corpo para disparo/recuo | 3 | `assets/characters/marty/padrao/pixellab/shoot.png` |
| Ataque corpo a corpo | 6 | `assets/characters/marty/padrao/pixellab/melee.png` |
| Dano | 6 | `assets/characters/marty/padrao/pixellab/hurt.png` |
| Derrota | 7 | `assets/characters/marty/padrao/pixellab/defeat.png` |

Cada folha usa células 96×96 e oito linhas nesta ordem: sul, sudeste, leste,
nordeste, norte, noroeste, oeste e sudoeste. Todas as oito vistas são próprias;
não espelhar horizontalmente, pois a ombreira, a manopla e a mochila são
assimétricas. Armas, projéteis e clarões continuam em camadas separadas no jogo.

## Marty — Armadura Ômega

A Armadura Ômega é um estado do mesmo personagem no PixelLab, identificado por
`b41db246-47d5-4914-a111-a6bd644abc2b`. Ela usa células de produção 112×112 e é
desenhada um pouco maior no jogo para preservar o peso das ombreiras, manoplas,
botas e capa. As oito direções são próprias e seguem a mesma ordem do Marty
Padrão.

| Ação | Quadros | Arquivo de jogo |
| --- | ---: | --- |
| Parado/energia do núcleo | 4 | `assets/characters/marty/omega/pixellab/idle.png` |
| Corrida pesada | 8 | `assets/characters/marty/omega/pixellab/run.png` |
| Salto | 8 | `assets/characters/marty/omega/pixellab/jump.png` |
| Dash por fissura temporal | 7 | `assets/characters/marty/omega/pixellab/evade.png` |
| Movimento corporal do combo | 6 | `assets/characters/marty/omega/pixellab/melee.png` |
| Dano | 6 | `assets/characters/marty/omega/pixellab/hurt.png` |
| Derrota | 8 | `assets/characters/marty/omega/pixellab/defeat.png` |

O capacete permanece fechado e a armadura completa em todos os quadros. A espada
de energia aparece somente durante o combo; a onda do terceiro golpe e os efeitos
de impacto continuam separados do corpo. A esquiva usa a animação de fissura em
vez do rolamento das roupas comuns.
