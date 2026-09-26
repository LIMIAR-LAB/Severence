# Equipamento 0.9 — Uniformes, Armadura e Robô

Você sempre escolhe **1 uniforme** e sempre leva **1 armadura**. O robô (Titan ou Spectre) é escolhido à parte.
A tela de equipamento aplica cada clique na hora (não existe mais APLICAR / INVOCAR / FUNDIR) e o painel da direita descreve o item clicado.

## Uniformes (sempre vestidos)

| Uniforme | Arma | Velocidade | Golpe (F / botão direito) | Dano recebido | Extra |
|---|---|---|---|---|---|
| **Padrão** | Blaster — 16 por tiro, 0,22s | 320 | 26 (coronhada) | 100% | equilibrado |
| **Mecânico** (+força) | Escopeta de rebite — 6 chumbos de 9 | 290 | **46** (chave inglesa) | **85%** | mais lento |
| **Espião** (+velocidade) | Submetralhadora — 7 a cada 0,085s | **385** | 20 (faca) | 110% | dash recarrega 2× mais rápido; inimigos só percebem de perto |

Trocar: tela de equipamento ou a vitrine do Refúgio (E percorre Padrão → Mecânico → Espião). O Espião usa o visual do disfarce de Londres.

## Armadura Ômega (temporária)

- **R** veste: transformação (aura, pilar de luz, onda de choque) → **12s** ativa → se desfaz sozinha → **18s** de recarga. R durante o efeito guarda antes do tempo (recarga cheia).
- No início de cada expedição ela leva 5s para carregar. **Baús recarregam** a armadura na hora.
- Enquanto ativa: **−60% de dano**, velocidade 350, dash mais rápido e a arma vira a **Lâmina Ômega**:
  combo de 3 cortes (38 / 38 / 64); o 3º é mais largo e solta uma **onda crescente** que atravessa até 5 inimigos. Cortes refletem tiros inimigos.
- HUD: barra da armadura no topo (pronta / tempo restante / recarga).
- O parceiro IA também veste a armadura quando há inimigos por perto.

## Robôs

- **Titan**: C invoca perto de você, E entra/sai para pilotar.
- **Spectre**: C invoca (acompanha e atira), G funde com Marty (+velocidade e dano; a energia do Spectre absorve os golpes). A fusão não mexe mais na armadura.

## Arte nova

- `assets/weapons/omega_sword.png`, `sword_smear.png` (3 quadros do rastro), `b_wave.png` (onda), `wrench.png`, `knife.png`.
- `assets/marty/marty_anim.png` ganhou 3 colunas de golpe (preparo, corte, finalização) para todos os uniformes e a Ômega.
- `assets/mech/spectre.png` recortado de novo da tela de equipamento (o antigo estava cortado).
- Testes: `tests/omega_test.gd` (20 verificações: transformação, combo de espada, duração/recarga, armas por uniforme).

## 0.10 — Titan v2 e ajustes

- **Titan v2** (`tools/prepare_titan_v2.py` → `assets/mech/titan_v2.png`): o boneco do piloto sumiu; o cockpit virou uma **viseira** de vidro (escura quando vazio, faixa ciano acesa quando pilotado). **8 direções** (diagonais geradas girando em perspectiva as vistas de frente/costas) e **passada pesada**: 4 quadros, afunda e achata a cada pisada, poeira e tremor de câmera.
- **Turbo do Titan**: segurar **Shift** pilotando = 420 px/s com propulsores; gasta a barra amarela sob o Titan (≈2,4s) e recarrega sozinha.
- **Tela de equipamento**: armaduras em fileira própria (escolha 1; Ômega + 2 vagas bloqueadas para as próximas). Clicar na armadura mostra a descrição mas **não troca a imagem do personagem**.
- **Com a armadura ativa não dá para trocar de uniforme/arma** (menu e vitrine recusam).
- **Ômega mais rápida**: 430 px/s (Espião 385) e dash recarrega em 0,3s.

## 0.12 — Armas v2

`tools/make_weapons_v2.py` redesenha as armas em pixel art maior (≈1,5×) com rampas de luz/sombra, contorno automático e detalhes:
Blaster (célula de energia ciano, aletas no cano), Escopeta de rebite (cano duplo, coronha de madeira, rebites e abraçadeira de latão),
Submetralhadora de tambor (compensador ranhurado, empunhadura frontal), Lâmina Ômega (cabo branco com fitas douradas, guarda com gema, lâmina com núcleo branco e halo),
chave inglesa e faca. Prévia: `art/weapons-v2-preview.png`.
