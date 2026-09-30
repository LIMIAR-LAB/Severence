# Experimento preparatório SCN-04

Projeto Godot isolado. **Schema provisório, somente grafo; não integrado ao jogo.**

`preload("res://graph_generator.gd").generate(seed_value: int, profile: Dictionary)`
retorna um manifesto com `ok:true`, `version`, `seed` (string decimal),
`profile_id`, `profile`, `rooms`, `edges`, `main_path`, `branch_count` e `cycle_count`.
Erros retornam somente `ok:false,error`. `profiles()` lê `res://profiles.json`.
`canonical(manifest)` serializa chaves ordenadas, preservando precisão numérica.

As arestas são **não direcionadas**. IDs de salas e arestas são únicos e estáveis
na ordem de construção. Toda rota entrada→boss passa pelos separadores clue e
miniboss. Ramos opcionais só conectam a uma âncora dentro de um estágio; ciclos
fecham a extremidade do ramo em sua própria âncora. Assim não atravessam separadores.
O número de ciclos corresponde a `arestas - salas + 1`.

Limites são inteiros finitos entre 0 e 64, mínimo <= máximo; spine_length >= 1,
branch_length_min >= 2 e cycles_max <= branches_min. Esta última regra rejeita
configurações que poderiam produzir mais ciclos que ramos em qualquer seed.
Branches contam cadeias opcionais anexadas, incluindo cadeias fechadas em ciclos.
Um grafo sem ramos e ciclos é válido quando os respectivos limites são zero.

Perfis: portuario concentra ramos em hubs de docas; ferroviario usa espinha longa
com desvios alternados; industrial distribui vários circuitos; alagado usa
ramificações profundas sem ciclos; cultista concentra circuitos em três hubs.
Essas diferenças afetam topologia, comprimento de percursos e circulação.

O RNG é local a cada chamada. Repetibilidade garantida pelo experimento somente
na mesma versão do gerador e Godot; registrar a versão do motor nos resultados.
Nenhuma física, RigidBody, RNG global ou ordenação iterativa de dicionários é usada.
`preview_cell` é uma coordenada esquemática única, não uma implantação espacial:
arestas podem cruzar no desenho. Conectividade não comprova colisões, portas,
acessibilidade das geometrias, orçamento de conteúdo ou qualidade de gameplay.

Licenças e proveniência da referência ficam sob `reference/`. Esta implementação
é independente: nenhum script do demo é usado para gerar estes grafos.
O binding ao contrato SCN-01.04 foi acrescentado abaixo; geração de geometria permanece pendente.

## Binding ao contrato v1 (liberado após o experimento inicial)

`contract_adapter.gd` executa no projeto principal somente como teste headless:
`& tests/scenarios_prototype/run_contract.ps1`.
Não é carregado pela run. Usa RoomContract.instantiate e SeedManifest.derive/canonical
reais; API `adapt(graph, catalog, mapping, run_seed, floor_index, origins={})`.
O mapa explícito de perfil exige biome_id, era_id, minimum_width e connector_types.
Catálogo deve conter templates válidos com eligibility=test_only e roles compatíveis.
Retorna IDs de instâncias e de conectores; incompatibilidade retorna errors sem salas
parciais. Catálogo/portas/nós/arestas são ordenados por ID. Fingerprint cobre todo
conteúdo do catálogo, incluindo versão e elegibilidade. O envelope também conserva
regras de binding, run_seed decimal, versões e grafo materializado.

Fixtures ferroviárias exercitam portas autoradas com largura 200 e regra mínima 160,
sem arte e sem alegar catálogo ferroviário publicado. Origens exercitam tradução;
as salas podem sobrepor-se e nenhum corredor é criado. Normal oposta/altura/tipo/largura
compatíveis são candidatos para conexão futura, não passagem validada.
Seleção é gulosa, rejeita esgotamento; não procura toda solução possível.
`physical_layout_validated` e `physical_connection_validated` permanecem false.
