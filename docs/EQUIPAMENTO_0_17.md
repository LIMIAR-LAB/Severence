# Equipamento 0.17 — UI modular e desbloqueios

A tela de EQUIPAMENTO é montada em camadas pelo motor: a moldura é só o fundo, e ícones, cards, textos,
números, barras e seleção são nós separados, controlados por dados. Substitui o layout v3 (0.16).

## Arquivos

| Arquivo | O que é |
|---|---|
| `data/equipamento.json` | Um registro por item: id, categoria, nome, subtítulo, arma, descrição curta e completa, raridade, ícone, ícone bloqueado, card, `desbloqueado_no_inicio`, regra de `desbloqueio` e `atributos`. Também a lista dos 6 atributos do STATUS. |
| `scripts/equipment_data.gd` | Lê o JSON; combina uniforme + robô + armadura; converte valores em segmentos da barra e texto. |
| `scripts/equipment_screen.gd` | A tela: moldura + camadas. Todas as caixas foram medidas na moldura (espaço 1344×752). |
| `assets/ui/equipamento/equip_moldura.png` | Moldura sem os destaques ciano pintados (1ª linha do UNIFORME e aba MARTY) e sem as linhas-guia. A seleção é do jogo. |
| `assets/ui/equipamento/icones/*.png` | Ícones recortados da folha, com o fundo cinza removido e no tamanho do slot. Os bloqueados do Mecânico, Espião e Spectre (que não vinham na folha) são gerados no mesmo estilo. `frame_selecao`/`frame_lendario` têm o miolo transparente e são usados como NinePatch. |
| `assets/ui/equipamento/cards/*.png` | Cards da vitrine em 360×360 (desenhados 1:1). |
| `art/source/equipamento/` | Originais enviados (moldura, folha de ícones, cards 1024×1024). |
| `tools/make_equipamento_assets.py` | Regenera tudo de `assets/ui/equipamento/` a partir dos originais. |

## Estados

- **Jogo novo:** só o uniforme Padrão. Sem armadura e sem robô: R e C avisam que nada foi desbloqueado, o Titan não aparece no Refúgio nem nas docas e o parceiro IA também não usa armadura.
- **Slots:** item liberado mostra o ícone; item que existe mas está bloqueado mostra a versão escura com cadeado; vaga sem item mostra `icon_slot_vazio`.
- **Seleção:** item equipado com `frame_selecao`; item em foco pisca; lendário (Ômega) com `frame_lendario`.
- **Vitrine:** card do item em foco; bloqueado fica escurecido com o cadeado em 2x por cima, e a DESCRIÇÃO explica como desbloquear.
- **STATUS:** uniforme + robô + armadura (modificadores `+N`, `=N`, `xN` do JSON). Segmentos da base na cor do atributo, bônus mais claros, perda em vermelho. Com o foco num item liberado, mostra a combinação com ele.
- O desbloqueio fica no save existente (`user://progress.json`, campo `unlocked`) e salva na hora. Saves antigos liberam o que o progresso já garantia (chefe derrotado, expedições concluídas).

## Regras de desbloqueio (editáveis no JSON)

| Item | Regra |
|---|---|
| Padrão | início |
| Titan | entrar na Oficina das docas (sala 05) — ele aparece ali mesmo |
| Spectre | concluir o desafio do Último Gerador (sala 06) |
| Armadura Ômega | derrotar o Almirante e extrair o núcleo |
| Mecânico | 1 expedição concluída |
| Espião | 2 expedições concluídas |

## Removido da tela

INICIAR ARENA, a vaga de pokébola/cápsula e a faixa de atalhos do rodapé. Ficaram só VOLTAR e IR AO REFÚGIO.

## Pixel art

Filtro Nearest em tudo. A tela fica fora do "stage" esticado dos menus e usa escala inteira em pixels reais (1x em 1600×1000 e 1920×1080, 2x a partir de 2688×1504), centrada. Só em janelas menores que 1344×752 ela reduz para caber.

## Testes

`tests/equipment_ui_test.gd` (os dois estados), `tests/equipment_unlock_test.gd` (dados batem com `simulation.gd`, regras de desbloqueio, R/C bloqueados).
Capturas: `-- --new-game --capture-ui-equipment` e `-- --unlock-all --capture-ui-equipment`.
