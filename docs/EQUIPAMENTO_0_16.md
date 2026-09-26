# Equipamento 0.16 — layout v3

Referência: `art/concept/equipamento-v3-mockup.png` (mockup do usuário). A vaga da pokébola do mockup foi
ignorada de propósito: a fileira de robôs é Titan, Spectre e uma vaga bloqueada.

## Arquivos

| Arquivo | O que é |
|---|---|
| `assets/ui/equipment_v3.png` | Fundo estático 1344×752: molduras de metal escovado com friso de bronze e rebites, trilhas de circuito, palco com borda ciano, rodapé com atalhos. Gerado por `tools/equipment_v3.py`. |
| `assets/ui/portraits_v3/*.png` | Arte do palco (1100×704, proporção do palco): `o_padrao`, `o_mecanico`, `o_espiao`, `armor_omega`, `titan`, `spectre`, `almirante`. Gerada por `tools/make_portraits_v3.py`. |
| `art/source/portraits-v4/*.png` | Cartas 1024×1024 em pixel art enviadas pelo usuário (fonte atual dos retratos). |
| `art/source/portraits-anime-v1.png` | Folha anterior (estilo anime), guardada só como histórico. |

- Da carta sai a moldura de latão e a placa com o nome; a arte inteira fica na altura do palco e as laterais são preenchidas com a própria arte desfocada.
- `almirante.png` fica pronto para uma futura tela de chefe; a tela de Equipamento não usa.

## Código

`scripts/terminal_ui.gd` → `build_equipment()` usa as mesmas caixas de `tools/equipment_v3.py` (espaço 1344×752).
Mexeu no layout de um, mexa no outro. `draw_stats()` foi ajustado para o painel de STATUS mais estreito (286 px).
O v2 (`equipment_v2.png`, `portraits/`, `tools/equipment_concept.py`, `tools/make_portraits.py`) continua no repo, sem uso.

## Regenerar

```
python3 tools/equipment_v3.py
python3 tools/make_portraits_v3.py
```

Teste: `tests/equipment_ui_test.gd`. Captura: `-- --capture-ui-equipment` → `test-output/ui-equipment.png`.
