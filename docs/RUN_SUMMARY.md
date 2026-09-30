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

### Sistema visual fiel ao conceito

A apresentação normal usa um canvas lógico de **1672×941**, derivado da
composição aprovada em `art/concept/resumo-pos-run-ux-v1.png`. O canvas é
centralizado e recebe uma única escala uniforme calculada por
`min(viewport/master)`. Assim a medalha continua circular e telas 16:10,
ultrawide ou janelas menores recebem letterbox/pillarbox em vez de distorção.

O shell cinematográfico text-free, o retrato editorial do peixe e o retrato do
núcleo recuperado foram gerados com o ImageGen integrado. Os masters, prompts e
proveniência ficam em `art/source/run-summary-faithful/`. O builder valida o
shell exatamente em 1672×941, rejeita imagens totalmente transparentes e exige
opacidade integral no cenário; depois produz os arquivos de runtime em
`assets/ui/run_summary/faithful/`, incluindo uma silhueta local determinística
para inimigos sem retrato. Os quatro loots continuam sendo as ilustrações do
PixelLab; o builder apenas os normaliza para o novo diretório.

Todos os conteúdos variáveis continuam vivos no Godot: título de vitória ou
derrota, nota, estatísticas, falecimento, causa, seed, recompensas e rótulos dos
botões. O raster contém somente cenário, materiais e superfícies vazias. Se o
shell fiel não puder ser carregado, `build_summary_fallback()` mantém a tela
anterior completamente legível e operável.

Reconstrução:

```powershell
python tools\build_run_summary_assets.py
```

Captura da tela real:

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture-ui-summary
```

Capturas de regressão da apresentação fiel:

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture-ui-summary --capture-name=run-summary-faithful
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --path . -- --capture-ui-summary --capture-summary-victory --capture-name=run-summary-faithful-victory
```

## Validação

```powershell
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/run_summary_test.gd
& 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script tests/run_summary_ui_test.gd
```
