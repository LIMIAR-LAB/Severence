# Reteste após preflight — 30/09/2026

Evidência preservada: [results.json](20260930-102139-503/results.json), um log por caso no mesmo diretório. 34 processos, zero SCRIPT ERROR, todos retornaram resultado. Dois controles válidos passaram; 26 mutações foram rejeitadas e seis ainda foram aceitas. `-Strict` terminou com exit 1 corretamente.

O preflight corrigiu os erros de script anteriores e a aceitação após erro, incluindo largura string, estrutura de coleção, posição ausente e origem não finita. Room version NaN, IDs principais vazios e pool vazio também foram rejeitados.

## Pendências reproduzidas

| Caso | Mutação mínima | Sugestão |
| --- | --- | --- |
| room_connector_empty_id | fixture.connectors[0].id="" | Exigir IDs aninhados não vazios, além de String |
| room_negative_radius | fixture.spawns[0].radius=-11 | Exigir radius>=0; número finito sozinho não basta |
| room_pixel_scale_zero | fixture.layers[0].world_units_per_pixel=0 | Exigir escala>0 quando presente |
| room_pixel_scale_negative | fixture.layers[0].world_units_per_pixel=-1 | Mesma regra de escala positiva |
| biome_era_empty | records[0].era_id="" | Exigir era_id não vazio; fallback_profile vazio continua válido |
| biome_version_nan | records[0].version=NAN | Exigir is_finite e versão inteira positiva/suportada; NaN<1 é false |

As duas escalas foram testadas na camada tile da fixture. Portanto demonstram aceitação de metadado não positivo; não alegam falha de densidade em placa. A validação para plate é outra rota e não foi confundida com esse resultado.

Binding também reexecutado: run_contract.ps1, 50 seeds em dois processos, zero falhas e hash anterior preservado d63b8938a3ce6597a45fdc78ffdef91db218f03ad07c0854edb147dd09698f33. Evidências contract-adapter-tests.json/contract-adapter-process-2.json. Nenhuma edição na base. SCN-04.03 permanece bloqueada.
