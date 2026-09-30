# Revisão do protótipo — 2026-09-30

Três revisões independentes: blind hunter (somente diff), edge cases, acceptance auditor. Sem defeito confirmado na construção do grafo dentro do escopo provisório.

Correções aplicadas ao harness:
- Perfis vazios ou entradas malformadas não indexam cegamente a primeira entrada; falham com diagnóstico.
- Hashes usam a API pública `Generator.canonical`, incluindo precisão numérica completa.
- Relatórios incluem versão Godot e gerador; runner compara versões e hashes entre processos.
- Acrescentados IDs de arestas, contagem real de ramos, configurações inválidas, rejeição sem dados parciais, zero ramos e seeds extremas.

Verificação após correções: `tests/scenarios_prototype/run.ps1`, exit 0, 5000 seeds por processo, dois processos, hashes iguais.

Limites residuais de cobertura: tamanho máximo combinado de todos os limites, isomorfismo dos grafos, comprimentos reconstruídos dos ramos e posições esquemáticas não têm provas exaustivas. Integração/portas/geometria não fazem parte desta preparação. SCN-04.01/02 não marcadas concluídas.

## Adaptação posterior ao contrato v1
Novo lote de três revisões: corrigida rejeição de IDs ausentes/vazios, campos de regras com tipo inválido e origens inválidas. Testes novos verificam connector IDs exclusivos, catálogo/conectores/grafo reordenados, conteúdo no fingerprint e incompatibilidades. Dois processos × 50 seeds passaram via run_contract.ps1. Seleção gulosa pode rejeitar solução existente; limitação documentada e sem alegação de busca completa. Dados dos templates devem seguir tipos do contrato RoomTemplate; esta camada não substitui o parser/validador completo do catálogo.
