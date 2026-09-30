# Revisão de connection_error e reteste após texture_resource

30/09/2026. Somente leitura/testes; nenhum contrato/runtime editado.

## Retestes da base
- `run_public_contract_probes.ps1 -Strict`: exit0, 34 casos, 2 controles válidos/32 mutações rejeitadas, zero Script Error. Hashes RoomContract/BiomeCatalog antes/depois iguais. Evidência: `../robustness/20260930-104656-888/results.json`.
- `run_contract.ps1`: 50 seeds × 2 processos, zero falhas, hash canônico inalterado `d63b8938a3ce6597a45fdc78ffdef91db218f03ad07c0854edb147dd09698f33`. Cópias dos relatórios no mesmo diretório timestamp acima.
- Esta bateria reutiliza fixtures existentes e não comprova diretamente o novo decode PNG sem import. Aceite de artwork nativo continua nas suítes da base; não foi fabricada nova arte para testar esta rota.

## Achados confirmados — FarolModule.connection_error

Fonte `scripts/scenarios/farol_module.gd:70`–74. Evidência real: [results.json](20260930-104751-991/results.json), 18 processos, hash FarolModule estável antes/depois.

**P1 — Normal ausente ou string gera erro de script e retorna compatível.** O laço valida presença somente de width/height/type/material_family. Linha73 acessa a.normal e nega b.normal sem tipo/presença. Casos missing_normal e string_normal produzem SCRIPT ERROR, mas retorno String padrão vazio faz o chamador considerar compatível. Reprodutor: copiar conectores válidos e apagar a.normal; ou b.normal="left". Logs separados na pasta timestamp.

**P2 — Igualdade não valida domínio.** Nove casos inválidos foram aceitos sem erro: duas normais ZERO; normais diagonais opostas; width0, width-1, width="wide"; heightINF, height="high"; type vazio; material_family vazio. Em todos os campos mutados os dois lados receberam o mesmo valor. A função verifica igualdade/oposição, não validade de cada conector.

Controles: par válido aceito; missing_width e cinco incompatibilidades individuais foram corretamente rejeitados (largura, altura, tipo, material, normal no mesmo sentido). Total18 casos:1 válido,6 rejeições corretas,9 aceitações inválidas silenciosas,2 erros de script com retorno vazio.

## Correção mínima sugerida à base
Adicionar preflight dos dois endpoints antes de comparar: normal presente Vector2 cardinal e finita; width numérico finito>0; height numérico finito; type/material_family String não vazia. Erro deve sempre retornar diagnóstico não vazio com endpoint/campo. Depois conservar comparações atuais; não relaxar mismatches existentes.

Se a função deliberadamente aceitar apenas endpoints já validados por RoomContract, documentar essa pré-condição e garantir a passagem de ambos pela validação em todo chamador. Ainda assim material_family é extensão e requer verificação local; a API pública não deveria transformar erro de script em sucesso. Testar os casos adversariais preservados antes da promoção SCN02.05.

## Limites para SCN02.05
Esta checagem é compatibilidade declarativa, não valida união física: não examina posição/coincidência de bordas, área útil da passagem, sobreposição, ocupação, textura/emenda, largura por ator ou continuidade de altura ao longo de uma conexão construída. Não registrar essas ausências como defeito se forem responsabilidade do montador, mas exigir evidência separada de junção real para aceite02.05. Igualdade de material_family não demonstra emenda visual. SCN04.03 permanece bloqueada.

## Follow-up — corrigido pela base

Coordenador aplicou preflight e executou novamente os18 casos. Resultado conferido nesta frente em [20260930-104954-323/results.json](20260930-104954-323/results.json):1 controle válido aceito,17 inválidos rejeitados com diagnóstico, zero Script Error e todos resultados presentes. Hash antes/depois idêntico: `7C89D5BDFF654C070BE54558AFF04C315A2E0A488F40DF7100A3485156DBB208`.

Os achados P1/P2 acima ficam **corrigidos para os casos reproduzidos**, mantendo-se o registro original e seus logs. Seis suítes base verdes foram comunicadas pelo coordenador; não foram reexecutadas nesta anotação. Limites físicos/visuais de SCN02.05 permanecem; SCN04.03 não liberada. Nenhum runtime editado por esta frente.
