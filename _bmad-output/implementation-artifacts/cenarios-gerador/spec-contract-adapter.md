---
title: Adaptação isolada SCN-04 ao contrato v1
status: done
created: 2026-09-30
---

## Escopo autorizado
Coordenador liberou adaptação em diretórios exclusivos ao RoomContract v1 e SeedManifest. Criar binding de IDs/perfis, instanciar fixtures com portas reais e rejeitar incompatíveis. Não montar o andar, alterar runtime ou estados das histórias.

## Implementação
`tools/scenarios/prototype/contract_adapter.gd` usa as APIs reais de scripts/scenarios. IDs de nós viram instance_id; roles permanecem explícitos; mapeamento exige biome_id/era_id e regras de conectores. Catálogo é test_only, ordenado e fingerprintado com conteúdo/versão/elegibilidade. Seed local usa derive compartilhado. Seleção de portas exige normal oposta, tipo aceito, altura igual e largura mínima. Uma porta nunca é reutilizada.

Origens opcionais só exercitam translate do contrato, não posicionamento procedural. Ausência de solução é rejeição diagnosticada, sem tentativas ou fallback disfarçado. Seleção gulosa não promete encontrar toda atribuição possível de portas.

## Aceite da preparação
Dado grafo válido e catálogo fixture, quando adaptar, então IDs, roles e arestas são preservados e portas pertencem às instâncias. Dado incompatibilidade, quando adaptar, então devolve errors sem rooms parciais. Dado mesma entrada em dois processos, quando serializar pela API compartilhada, então hashes coincidem.

## Evidência
`tests/scenarios_prototype/contract_adapter_test.gd`: 50 seeds ferroviárias, ordem do catálogo/conectores, portas transformadas, unicidade, esgotamento, incompatibilidade e fingerprint de conteúdo. Arte intencionalmente ausente destas fixtures; nenhum aceite visual ou de montagem.

`run_contract.ps1` executou dois processos Godot 4.7.2: 50 seeds/processo, zero falhas, hash d63b8938a3ce6597a45fdc78ffdef91db218f03ad07c0854edb147dd09698f33 igual. done refere-se apenas a esta adaptação isolada, não ao aceite das histórias na run.

## Revisão
Três revisões independentes (contrato/edge, acceptance e blind diff). Corrigidos IDs de grafo ausentes/vazios, tipos de regras e origens; adicionados testes. Arrays de nós/arestas também são ordenados antes de compor envelope. A seleção gulosa foi mantida como limitação explícita: não há promessa de completude de busca nesta adaptação, e esgotamento produz rejeição estruturada. Montador/recuperação futuros precisam tratar isso.

## Ordem de leitura
1. [API e limites](../../../tools/scenarios/prototype/README.md).
2. [Adapter](../../../tools/scenarios/prototype/contract_adapter.gd).
3. [Testes](../../../tests/scenarios_prototype/contract_adapter_test.gd).
4. [Relatório](contract-adapter-tests.json).
