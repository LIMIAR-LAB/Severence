# Reteste final — contrato v1

30/09/2026. Godot 4.7.2.stable.official.ed1daf0bf.

- `run_public_contract_probes.ps1 -Strict`: exit 0. 34 casos: dois controles válidos aceitos, 32 mutações inválidas rejeitadas, zero Script Error e nenhum resultado ausente.
- `run_contract.ps1`: exit 0. 50 seeds em cada um de dois processos; zero falhas e mesmo hash canônico `d63b8938a3ce6597a45fdc78ffdef91db218f03ad07c0854edb147dd09698f33`.
- As seis pendências do reteste anterior foram rejeitadas corretamente.

Evidência dos probes finais preservada em [20260930-102409-222](20260930-102409-222/results.json): results.json com hashes de fontes antes/depois e logs individuais. Ambos os arquivos permaneceram estáveis nessa execução. Nenhuma edição na base feita por esta frente.

A execução imediatamente anterior [20260930-102307-236](20260930-102307-236/results.json) também passou, mas RoomContract mudou durante a bateria; por isso a mesma bateria foi repetida, sem ampliar o lote. As cópias dos dois relatórios do binding estão nessa pasta anterior; o binding foi executado antes da confirmação final de estabilidade dos probes.

Este resultado cobre os casos da bateria existente. Não é auditoria exaustiva de SeedManifest ou dos casos adicionais que a base corrigiu; não foi aberto novo lote. Contrato continua v1, formato preservado. Montagem física permanece não validada e SCN-04.03 bloqueada até a dependência/liberação correspondente.

Lote encerrado conforme instrução do coordenador.
