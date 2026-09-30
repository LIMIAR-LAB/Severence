# Revisão de robustez do contrato público — 30/09/2026

**Nota de evidência:** a primeira execução abaixo foi observada e comunicada ao coordenador. Uma segunda execução do runner coincidiu com a correção da base e sobrescreveu os logs de nomes fixos: `results.json` e logs na raiz desta pasta agora registram erro de parse em room_contract.gd:88 (item_path), não os resultados iniciais. O runner foi corrigido para gravar cada nova execução em subdiretório com timestamp. Não interpretar os logs atuais como comprovação das contagens históricas abaixo. Reteste aguardando liberação da base.

Execução real: Godot 4.7.2.stable.official.ed1daf0bf, 28 processos independentes. Dois controles válidos passaram. Das 26 mutações inválidas, 12 produziram SCRIPT ERROR e 14 foram aceitas sem erro. Não se trata de validação aprovada. Todos os processos retornaram exit 0; o log e o resultado semântico são indispensáveis.

Arquivos da base não foram editados. Hashes SHA256 antes/depois coincidem no results.json. RoomContract: `5DDA61BA979B410D6C8E027941AE60C097EAE317BEE4659207748AD94685E14C`; BiomeCatalog: `0A256BDAD024DDBF7DB7089DFE0000B3702E60938CBCA257BFF5868AAC060DBC`. Findings referem-se a essa revisão, não a alterações posteriores da base.

## P1 — Erro de script pode deixar entrada inválida passar

Reprodutor mínimo RoomContract: `var t = Rooms.fixture(); t.connectors[0].width = "wide"; Rooms.instantiate(t,"x",Vector2.ZERO)`. Operação width<=0 falha em room_contract.gd:40, validate retorna array vazio e instantiate devolve ok:true. Ver room_width_string.log.

Reprodutor mínimo BiomeCatalog: `var rows = Biomes.load_records(); rows[0].materials = null; Biomes.validate(rows)`. Chamada .get em Nil falha em biome_catalog.gd:22 e retorna errors=[]; consumidor que considera lista vazia válida aceita entrada. Mesmo efeito com template_pool string e fallback_templates null. Ver biome_materials_null.log, biome_pool_string.log, biome_fallback_null.log.

Proposta: primeira passagem de schema com testes de tipo antes de operadores/chamadas/acesso; ao identificar tipo errado, adicionar erro com caminho e não executar validação semântica daquele objeto. Campos obrigatórios presentes não garantem tipo correto. Evitar depender de erro de script como mecanismo de rejeição.

## P2 — Campos consumidos por instantiate não são todos validados

`t.points_of_interest=[{"id":"bad"}]` passa validate, mas instantiate falha ao acessar position (linha78). `ramps=[{"axis":"x","low":0,"high":10}]` passa validate e falha sem rect. `raised=[7]` também passa e falha na tradução. Outros tipos errados abortam validate: footprint=null, connectors=[7], layers=[null], spawn sem position e obstacle sem rect.

Proposta: validar coleções opcionais quando presentes, cada item e todos campos consumidos; exigir Rect2/Vector2 finitos, dimensões positivas, eixo x/y, low/high numéricos. Só traduzir depois de validação integral. Retorno inválido deve conter ok:false/errors e nunca dados parciais.

## P2 — Valores semanticamente inválidos aceitos silenciosamente

RoomContract aceita template_id vazio, connector.id vazio, connector.height="high", spawn.radius=-11, layer.depth="invalid" e origin Vector2(INF,0)/Vector2(NAN,0). Origem não finita contamina todas as coordenadas materializadas.

Proposta: IDs string não vazia e únicos por coleção; height numérica finita; radius numérico finito não negativo; depth ground/foreground; origin.is_finite antes de traduzir. Testar também coordenadas/extensões não finitas e transformações declaradas.

## P2 — Schema de bioma incompleto

BiomeCatalog aceita connector_rules=null, room_roles=7, version="one", biome_id=42 (coerção via str), era_id="", atmosphere=null e connector_rules.minimum_width=-1.

Proposta: validar tipos e versão suportada explicitamente; IDs não vazios sem coerção; arrays de IDs/roles, objetos materials/atmosphere/connector_rules; largura positiva finita e campos de regra suportados. Não adicionar publicação de conteúdo nem inventar novos biomas nesta correção.

## Reprodução e reteste

Na raiz: `& tests/scenarios_prototype/run_public_contract_probes.ps1`. Modo de caracterização sempre grava logs; não equivale a teste aprovado. Com `-Strict`, retorna 1 enquanto existir erro de script, resultado ausente ou aceitação divergente do esperado. Um processo por caso e --quit-after 2 limitam efeitos de erro. Fontes são hashadas antes/depois para detectar edição concorrente.

Caso individual: Godot --headless --path . --quit-after 2 --script tests/scenarios_prototype/public_contract_probe.gd -- room_width_string. Cases estão no match do probe; cada mutação parte da fixture original.

Após correção pela base: rerodar -Strict, confirmar controles aceitos, 26 casos rejeitados com diagnóstico e ausência de SCRIPT ERROR. Esta bateria é focada e não exaustiva; não mede desempenho ou navegação física. SCN-04.03 continua bloqueada.
