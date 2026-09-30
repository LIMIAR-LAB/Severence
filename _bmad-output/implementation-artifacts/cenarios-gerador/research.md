# Pesquisa GDQuest — SCN-04.01 preparatória

Data: 2026-09-30. Evidência isolada, sem integração nem conclusão da história. Formato `reference-observation-v0`; ainda não é o contrato SCN-01.04.

## Origem e licença

Referência [GDQuest procedural generation](https://github.com/gdquest-demos/godot-4-procedural-generation), revisão [19c98cee16ed18e642b3ce178f4c649d56b334b2](https://github.com/gdquest-demos/godot-4-procedural-generation/commit/19c98cee16ed18e642b3ce178f4c649d56b334b2), data do commit 2026-06-26T12:55:00Z. Consulta GitHub API preservada em `tools/scenarios/prototype/reference/commit-api.json`. Download ZIP fixado na revisão, sem repositório .git aninhado. SHA256 ZIP: `E2B18A3808F71D87E4F6740BB1324F5435D91719DEE1D513EC01D1B9B0312562`.

Diretório-base dos arquivos abaixo: `tools/scenarios/prototype/reference/godot-4-procedural-generation-19c98cee16ed18e642b3ce178f4c649d56b334b2/`.

O arquivo original [LICENSE](https://github.com/gdquest-demos/godot-4-procedural-generation/blob/19c98cee16ed18e642b3ce178f4c649d56b334b2/LICENSE) foi preservado: código MIT, copyright 2020 GDQuest; imagens/áudio CC BY 4.0, atribuição GDQuest and contributors (https://www.gdquest.com/). Arte só está na cópia isolada para executar a referência; nenhuma arte ou código foi importado ao runtime do jogo. Qualquer extração futura de código deve carregar aviso MIT; arte continua excluída do catálogo do jogo.

Arquivos consultados/executados:

- `godot4/basic_dungeon/03_bonus/generator.gd`, `room.gd`, `room_organic.gd`, `utils.gd`, `bonus.gd`, `bonus.tscn`.
- `godot4/basic_dungeon/01_rectangular/rectangular.gd` e `02_and_organic/and_organic.gd` para comparação.
- `godot4/mst_dungeon/mst_dungeon.gd`, `utils.gd`, `room.gd`, `room.tscn`, `mst_dungeon.tscn`.
- `godot4/shared/basic_tileset.tres` e imagens associadas apenas no demo.

Originais não foram editados. Foi acrescentado `godot4/reference_experiment.gd`, harness que chama funções originais e a cena MST, atribui IDs de observação e exporta JSON. Importação Godot criou metadados/cache apenas nesta cópia. O harness não atribui roles de campanha fictícios às salas GDQuest.

## Execução real

Executável: `C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`. Banner observado: `Godot Engine v4.7.2.stable.official.ed1daf0bf`.

A partir da raiz do jogo, definir `$src = 'tools/scenarios/prototype/reference/godot-4-procedural-generation-19c98cee16ed18e642b3ce178f4c649d56b334b2/godot4'` e `$godot = 'C:\Users\tsmar\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'`.

```powershell
& $godot --headless --editor --path $src --import --quit
& $godot --headless --path $src --script res://reference_experiment.gd
& $godot --headless --path $src res://basic_dungeon/03_bonus/bonus.tscn --quit-after 10
```

Logs em `tools/scenarios/prototype/reference/`: `import.log`, `experiment-first.log`, `experiment.log`, `basic-scene.log`. Comandos terminaram com código 0; a cena Basic foi executada sem erros de script no log. Execução foi headless: não é inspeção visual nem teste GL Compatibility.

| Experimento | Resultado observado |
| --- | --- |
| Basic funções originais, RNG externo seed 4101, 15 tentativas | 9 salas com retângulos/IDs e 8 conexões em cadeia; 1357 células primeira execução, 1348 segunda |
| MST função original, cinco pontos fixos | 5 nós e 4 arestas; arquivo `mst-fixed-points.json` |
| Cena MST original, 60 corpos, observação após 10 s | primeira: 60 salas estabilizadas, 19 nós principais, 1497 células; segunda: 60 estabilizadas, 17 nós, 20 arestas e 1671 células |

`basic-observation.json` retém salas e arestas da segunda execução. `mst-scene-observation.json` retém IDs, posições e arestas reais da cena física da segunda execução. A lista de nós MST é a seleção principal; salas secundárias incorporadas por corredores não estão preservadas como nós pelo código original. O tempo de 10 s é janela do observador, não benchmark do tempo de geração.

## Comparação e incompatibilidades

**Basic:** rejeita interseções e liga cada sala aceita à anterior por corredor em L. É simples de adaptar para células inteiras, mas `rooms_max` limita tentativas, não garante quantidade de salas. API pública retorna só células e perde identidade de salas, arestas, portas e roles. `generate()` randomiza seu RNG; além disso cada sala orgânica cria outro RNG com `randomize()`. A diferença real de 1357 para 1348 células com o mesmo RNG externo demonstra que fixar só esse RNG é insuficiente. Ordem, quantidade e retângulos das 9 salas permaneceram iguais nestes dois ensaios.

**MST:** `utils.gd::mst()` implementa Prim sobre posições, começa pelo último ponto (`pop_back`) e modifica o Array recebido. Empates dependem da ordem; o chamador deve ordenar entrada e passar cópia. Código não trata array vazio antes de `pop_back`; validar cardinalidade previamente. A árvore fornece conectividade com N-1 arestas, e a cena adiciona conexões probabilísticas, sem limites explícitos por perfil. Não há garantia de ordem narrativa, portas, chave/fechadura, largura de passagem ou bioma. Posições em float vêm de RigidBody2D, sem prova de repetição entre processos/plataformas.

**Godot 4.7.2:** as cenas/funções executadas importaram e rodaram sem erro de script observado. No código de `room.gd`, `_integrate_forces()` testa `freeze_mode` e contém `set_deferred("mode", ...)`, vestígio suspeito da conversão Godot 3; nesta execução a estabilização aconteceu por sinais normais de sono e não houve erro observado dessa atribuição. Isso é risco identificado por leitura, não falha reproduzida. Não modificar a referência para esconder a limitação.

## Decisão proposta ao protótipo

Adotar geração discreta própria com seed/versionamento explícitos. Construir caminho obrigatório e roles antes das ramificações/ciclos; reservar entrada, pista, minichefe, boss e saída por regra, nunca só probabilidade. Preservar salas, arestas, roles e relação de bloqueios no manifesto, com subfluxos independentes para topologia/seleção/decor. Usar grade/retângulos inteiros e critérios ordenados de desempate; MST pode conectar opcionais se não furar progressão ou portas. Rotear somente entre conectores válidos e reservar áreas caminháveis: estética não decide colisão.

Alternativas: cadeia Basic garante alcance topológico simples, mas pouca variedade e nenhuma semântica; MST puro reduz comprimento de ligações, mas não garante narrativa nem mínimos/máximos de ciclos; grafo por regras + montagem discreta permite invariantes de campanha e perfis por bioma. BSP também evita sobreposições por divisão, mas não foi executado nesta pesquisa e não há alegação de desempenho comparativo.

Biomas devem variar organização/circulação e regras de perfil, além dos nomes/material: eixo ferroviário longitudinal, porto com braços/pátios, industrial com malha, alagado com rotas elevadas, cultista com limiares/processão. Essas são propostas de teste para o protótipo, não arte nem geometria aprovadas.

Pendente: adaptar observações ao contrato SCN-01.04 publicado pelo coordenador, validar salas/portas reais, testar repetibilidade em processos distintos do gerador próprio e integração posterior. Nenhum desses resultados satisfaz sozinho aceite em jogo ou autoriza antecipar SCN-04.03.
