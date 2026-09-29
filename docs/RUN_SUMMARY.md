# Resumo pós-run

Implementado em 2026-09-29 como a primeira superfície do Epic 4: a morte ou a
extração agora captura o resultado da expedição antes de devolver a simulação ao
Refúgio. A tela apresenta tempo, progresso, abates, recompensas, desempenho,
nota e uma nota de falecimento contextual.

## Fluxo

1. `Expedition.start_run()` zera `run_stats`.
2. Combate registra abates, dano causado/recebido, maior sequência, baús e origem
   do golpe fatal.
3. Derrota ou extração chama `finish_run(outcome)`, que produz
   `last_run_summary`, incrementa `summary_seq` e só então executa `make_hub()`.
4. `main.gd` percebe a nova sequência, salva a metaprogressão e abre `summary`.
5. O jogador inicia outra expedição ou fecha o relatório e permanece no Refúgio.

Arena de teste continua reiniciando imediatamente. Em rede, o host é autoritativo;
o resumo viaja no snapshot e o convidado não pode iniciar a próxima run.

## Dados e fórmulas

- Progresso: até 80 pontos pelas salas visitadas, 10 pelo chefe e 10 pela extração.
- Nota: progresso + até 20 por abates + até 12 por eficiência de tempo
  (o bônus se esgota aos 24 minutos) + desafio opcional + segredo + vitória.
- Recompensas exibidas usam apenas dados existentes: sucata efetivamente ganha
  (sem o saldo inicial), fragmentos ganhos, baús abertos, núcleo recuperado e
  total persistente de conclusões.
- O texto de falecimento é escolhido de forma determinística por
  `seed + fatal_source + fatal_attack`, mantendo host e convidado idênticos.
- Saves antigos continuam válidos; campos ausentes recebem defaults seguros.

## Divisão dos assets

PixelLab fornece ornamentação autoral e os quatro ícones de loot. Fontes e IDs
ficam em `art/source/pixellab/run-summary/`. A folha retornou palavras nos botões
apesar do briefing sem texto; essas regiões são preservadas apenas como fonte e
descartadas pelo builder.

`tools/build_run_summary_assets.py` cria os arquivos normalizados em
`assets/ui/run_summary/`, além de moldura/button fallbacks e um atlas de oito
ícones semânticos desenhados deterministicamente. Todo texto, nota, valor,
estado de foco e área clicável é um Control real do Godot.

Reconstrução:

```powershell
python tools\build_run_summary_assets.py
```

Captura da tela real:

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture-ui-summary
```

## Validação

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/run_summary_test.gd
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/run_summary_ui_test.gd
```
