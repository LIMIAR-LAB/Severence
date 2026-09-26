# Sprites do Marty 0.15 — padrão jogável

## Objetivo

Marty deve ser reconhecível em movimento independentemente do uniforme. As roupas contam uma função de jogo, enquanto a silhueta, a altura dos pés e a leitura da mira permanecem estáveis. A Armadura Ômega é a única exceção de escala: ela parece mais pesada e maior, sem mudar o ponto de colisão nem esconder a direção do personagem.

## Atlas usado pelo jogo

`assets/marty/marty_anim_v2.png` é o atlas ativo. Ele é derivado de `marty_anim.png`, que continua como fonte preservada.

| Propriedade | Regra |
| --- | --- |
| Célula | 96 × 96 px |
| Grade | 10 colunas × 20 linhas |
| Linhas por visual | 5: frente, frente/3-4, lado, costas/3-4, costas |
| Colunas | 0 parado; 1–4 caminhada; 5 tiro; 6 salto/dash; 7–9 golpe |
| Pivô | centro inferior, contato do pé em `(48, 92)` |
| Filtro | nearest-neighbor; nunca interpolar pixel art |
| Direções | 5 vistas desenhadas; esquerda usa espelhamento da vista lateral |

## Visuais

| Chave | Leitura visual | Escala no atlas v2 | Arma | Regra |
| --- | --- | ---: | --- | --- |
| `padrao` | aviador com goggles e luz ciano | 1.05 | blaster | equilibrado |
| `espiao` | casaco escuro, boina e cachecol vermelho | 1.08 | submetralhadora | rápido e furtivo |
| `mecanico` | macacão verde, ferramentas e propulsor | 1.00 | escopeta de rebite | resistente e pesado |
| `omega` | exoesqueleto branco/ciano, ombros grandes | 0.90 | lâmina Ômega | armadura temporária |

A normalização dá aos três uniformes a mesma presença em tela. A Ômega ainda fica cerca de 16% maior que um uniforme comum, o bastante para comunicar proteção sem parecer outro personagem.

## Integração

- `scripts/world_view.gd` seleciona a linha por `sim.outfit_of(a)` e escolhe a coluna por movimento, tiro, salto/dash ou golpe.
- A arma é desenhada separadamente com `draw_weapon()`. Nenhuma arma deve ser pintada na mão dentro do atlas.
- O corpo usa a direção de `facing`; a arma usa `aim`, então Marty pode andar e atirar em direções diferentes.
- Transformação Ômega alterna visualmente entre o uniforme atual e `omega`, mantendo a mesma grade.

## Como regenerar

Após editar a arte de origem, gere o atlas padronizado:

```powershell
python tools/normalize_marty_atlas.py
```

O processo não altera `marty_anim.png`. Para adicionar uma skin, mantenha cinco linhas e dez colunas, registre a chave em `OUTFIT_ROW` de `scripts/world_view.gd`, acrescente a escala no gerador e atualize esta tabela.

## Critérios de revisão

- os quatro visuais ocupam células de 96 × 96;
- os pés tocam a mesma linha em todas as poses normais;
- as colunas de ação não saem da célula;
- o tiro continua legível em cada direção;
- dash, salto e golpe usam a mesma direção visual do corpo;
- não há interpolação, contorno borrado ou fundo opaco.
