---
title: 'netfox: predição/reconciliação no coop online'
type: 'feature'
created: '2026-09-26'
status: 'ready-for-dev'
baseline_commit: '962b1d0'
context: ['{project-root}/README.md']
---

<frozen-after-approval reason="human-owned intent">

## Intent

**Problem:** O coop online hoje é 100% autoritativo no host, sem predição nem
interpolação: o cliente manda input por RPC (`submit_input`), o host processa a simulação
inteira e devolve um snapshot comprimido (`receive_state.rpc(var_to_bytes(sim.snapshot())
.compress(...))`, `scripts/main.gd` ~355). O próprio README admite: "Não há
predição/reconciliação de rede: latência elevada ainda pode causar atraso perceptível."

**Approach:** Instalar o addon **netfox** (grátis, MIT, oficial da loja do Godot) e usar
SÓ as peças de timing/interpolação primeiro (menor risco), avaliando rollback/predição
completa como uma segunda fase — não substituir de uma vez o modelo host-autoritativo que
já funciona e está testado (`tools/test_network.ps1`, `--network-host-test` /
`--network-client-test` em `main.gd`).

## Boundaries & Constraints

**Always:** Preservar a autoridade do host — a simulação (`Expedition`) continua sendo
calculada só no host; isso já está testado e documentado (README: "simulação autoritativa
no anfitrião"). Preservar `tools/test_network.ps1` e os testes automatizados de rede
(`--network-host-test`, `--network-client-test`) funcionando. Preservar o formato de
`submit_input`/`receive_state` como está, a menos que a migração para netfox seja completa
e testada ponta a ponta (não uma mistura dos dois sistemas). Preservar solo e coop local
(sem rede) sem qualquer dependência de netfox — eles não usam `MultiplayerPeer`.

**Ask First:** Migrar de ENet puro para o transporte que o netfox recomenda, se for
diferente (confirmar compatibilidade com `ENetMultiplayerPeer` antes de trocar). Qualquer
mudança na porta (`24871`) ou no formato dos dados salvos.

**Never:** Adicionar dependência de um serviço de matchmaking/relay externo (fora do escopo
desta spec — isso seria GodotSteam ou `netfox.noray`, uma spec separada). Quebrar a
compatibilidade com o teste local de duas instâncias (`127.0.0.1`) que é hoje a única
validação real de rede do projeto.

## I/O & Edge-Case Matrix

| Estado / entrada | Resultado | Limite |
|---|---|---|
| Latência simulada baixa (mesma rede) | Movimento do parceiro remoto mais suave que hoje | Sem regressão de sincronismo host/cliente |
| Latência simulada alta (netfox tem toggle de simulação) | Interpolação disfarça o atraso; ainda sem input prediction completa nesta fase | Documentar claramente o que ainda não está resolvido |
| Cliente desconecta | Host assume a IA como hoje (`peer_disconnected`) | Sem mudança de comportamento |
| Solo / coop local | Sem qualquer código do netfox no caminho | `MultiplayerPeer` nulo, nada muda |
| Teste automatizado de rede (`--network-host-test`/`--network-client-test`) | Continua passando | `tools/test_network.ps1` sem falhas |

</frozen-after-approval>

## Code Map

- `addons/netfox/`: pacote core (timing, interpolação); instalar via loja do Godot ou
  https://github.com/foxssake/netfox. **Não** instalar `netfox.extras`/`netfox.noray`
  nesta fase — fora de escopo.
- `scripts/main.gd`: `host_game()`/`join_game()` (~163-179), `submit_input`/`change_loadout`/
  `robot_action`/`receive_state` (RPCs, ~204-256), `_physics_process` (envio/recepção do
  snapshot, ~309-357).
- `scripts/simulation.gd`: `snapshot()`/`apply_snapshot()` (~1372-1380) — formato atual dos
  dados de rede; ponto de referência para o que precisa continuar funcionando.
- `tools/test_network.ps1`, argumentos `--network-host-test`/`--network-client-test` em
  `main.gd`: validação de rede existente, hoje só local (duas instâncias na mesma máquina).

## Tasks & Acceptance

**Execution:**
- [ ] Instalar `addons/netfox/` (core apenas); habilitar o plugin.
- [ ] Ler a documentação de `NetworkTime`/interpolação do netfox
  (https://foxssake.github.io/netfox/latest/) e decidir, por escrito em
  `docs/REDE_NETFOX.md` (novo), qual das duas rotas seguir:
  - **Rota A (menor risco):** usar só `NetworkTime` para sincronizar o relógio entre host e
    cliente, e trocar a interpolação visual do ator remoto (hoje o cliente só desenha a
    última posição recebida do snapshot) por um `TickInterpolator`/interpolação manual entre
    dois snapshots, suavizando o movimento sem tocar no protocolo de `submit_input`.
  - **Rota B (maior escopo):** adotar `RollbackSynchronizer` para os atores, migrando de
    "host manda snapshot completo" para "host + cliente rodam a mesma simulação com
    correção", como o addon foi desenhado para funcionar. Isso exige repensar
    `submit_input`/`receive_state` por completo.
  Esta spec cobre só a **Rota A**; a Rota B fica registrada como próxima etapa possível,
  não implementada agora.
- [ ] Implementar a Rota A: interpolar a posição/aim dos atores remotos no cliente entre o
  snapshot anterior e o atual (em vez de aplicar o snapshot direto), usando o tempo do
  netfox para saber "quanto tempo passou" de forma consistente.
- [ ] Adicionar um modo de simulação de rede ruim (o netfox tem esse toggle) só em builds de
  teste/debug, para validar visualmente a suavização sem precisar de duas redes reais.
- [ ] Rodar `tools/test_network.ps1` e os testes `--network-host-test`/`--network-client-test`
  e confirmar que continuam passando.
- [ ] Rodar a suíte completa headless (`tests/*_test.gd`), 0 falhas esperadas — o netfox não
  deve ser referenciado de dentro de `simulation.gd` (ele é só apresentação/timing do lado
  de `main.gd`).
- [ ] `docs/REDE_NETFOX.md`: o que foi feito (Rota A), o que ainda falta (Rota B, relay/NAT,
  que continuam como limitação conhecida — não prometer o que não foi implementado).

**Acceptance Criteria:**
- Given duas instâncias locais (`127.0.0.1`), when um jogador se move, then o outro vê o
  movimento mais suave que a versão anterior, sem teleporte perceptível entre snapshots.
- Given o netfox desabilitado/ausente, when o jogo abre, then coop online continua
  funcionando exatamente como na 0.16 (fallback).
- Given `tools/test_network.ps1`, when executado, then passa sem erro.
- Given a suíte headless completa, when executada, then 0 falhas.
- Given o README, when atualizado, then descreve com precisão o que mudou (interpolação) e
  o que continua sem predição real (rollback completo), sem prometer mais do que foi feito.

## Spec Change Log

## Design Notes

Link do addon: https://godotengine.org/asset-library/asset/2375 (repo:
https://github.com/foxssake/netfox). Documentação: https://foxssake.github.io/netfox/latest/.

Esta é a spec de maior risco das três (luz/clima, LimboAI, netfox) porque toca o único
sistema que já tem teste de integração real (`tools/test_network.ps1`) e é o que mais dói
se regredir silenciosamente (ninguém percebe dessincronia de rede rodando sozinho). Por
isso o escopo foi deliberadamente cortado para a Rota A (interpolação) nesta primeira
etapa — a Rota B (rollback completo) é tentadora mas precisa da Rota A provada em produção
antes.

## Verification

Importar com o addon habilitado; rodar `tools/test_network.ps1` e os testes de rede
automatizados; rodar a suíte completa headless. Depois, testar manualmente com duas
instâncias na mesma máquina (host + `127.0.0.1`) e, se possível, entre duas máquinas na
mesma rede local, comparando a suavidade do movimento remoto antes/depois.
