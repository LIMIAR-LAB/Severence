# Investigation: queda de FPS na luta do boss (Almirante)

## Hand-off Brief

1. **What happened.** A simulação custa ~6–9ms por frame **em qualquer sala** (orçamento de 60fps = 16.6ms). A luta do boss adiciona brood (até 10 adds), 30–200 projéteis e zonas de combate sobre esse custo já marginal — e ainda há o custo de render por cima. Não é um bug específico do boss; é a soma estourando o frame budget na sala mais populosa.
2. **Where the case stands.** Concluded — causa raiz medida e decomposta (Confirmed).
3. **What's needed next.** Implementar as otimizações na ordem abaixo (maior ganho: cache de `recover_enemy_room`, `room_threats` em passe único, grid espacial para `floors` em `clear_at`).

## Case Info

| Field            | Value |
| ---------------- | ----- |
| Ticket           | N/A |
| Date opened      | 2026-10-01 |
| Status           | Concluded |
| System           | Windows, Godot 4.7.2, medido via headless `tests/_dbg_boss_perf.gd` e `tests/_dbg_sizes.gd` |
| Evidence sources | benchmarks headless, `scripts/simulation.gd` |

## Problem Statement

"quando chego no boss tudo fica bem lento" — queda de FPS na Sala 12.

## Medição (Confirmed — headless, máquina do dev)

`sim.step(1/60)` por cenário:

| Cenário | enemies | avg | max |
| ------- | ------- | --- | --- |
| Sala de spawn (mapa vivo) | 56 | 5.86–9.29ms | ~14ms |
| Sala do boss (mapa vivo) | 60 | 6.25ms | 15.3ms |
| Só o boss vivo | 17 | 3.04ms | 10.5ms |
| Estágio 3 (rajadas 26 orbes) | 23 | 3.75ms | 12.6ms |
| sem inimigos + floors=1 rect | 0 | **0.41ms** | — |

Custo unitário por subsistema (média por chamada):

| Subsistema | custo | chamadas/frame | total/frame |
| ---------- | ----- | -------------- | ----------- |
| `step_gates` | **1.84ms** | 1× | **~1.84ms** |
| ├ `recover_enemy_room` dentro dele | 0.019ms | ×56 | ~1.06ms |
| ├ `room_threats` (filter λ sobre enemies) | ~0.15ms | ~5× | ~0.7ms |
| `recover_enemy_room` em `step_enemies` | 0.019ms | ×56 | **~1.06ms** |
| `ai_input` (Echo) | 0.26ms | 1× | ~0.26ms (até 0.75 com `line_of_fire`) |
| `step_hazards` | 0.046ms | 1× | ~0.05ms |
| inimigos ativos (move/attack/LOS) | ~20µs por `clear_at` | centenas | restante do total |

`clear_at` = 0.020ms por chamada — dominado pelo loop `floors` (62 rects × 5 offsets ≈ 310 point-in-rect). `line_of_fire(600px)` = 0.75ms (50× clear_at interno). `path_direction` tem cache (barato). `water_at` 0.004ms. `room_at` 0.001ms.

## Confirmed Findings

### Finding 1: `recover_enemy_room` roda 2× por frame por inimigo, ~19µs cada

**Evidence:** `scripts/simulation.gd:821` (dentro de `step_gates`, loop sobre todos os enemies) e `scripts/simulation.gd:2285` (dentro do loop de `step_enemies`).

**Detail:** cada chamada → `enemy_room_position_valid` → 5× `room_contains` + `clear_at`. Para 56–60 inimigos ≈ **2.1ms/frame** só nisso — inclusive para inimigos parados, não alertados, a milhares de px do jogador.

### Finding 2: `room_threats` aloca um filter λ por sala por frame

**Evidence:** `scripts/simulation.gd:811-813`, chamado em `step_gates` (`:827`, `:842`) por sala não-clearada.

### Finding 3: `clear_at` faz scan linear de `floors` (62 rects × 5 offsets)

**Evidence:** `scripts/simulation.gd:1009-1013`. Floors são estáticos por run — candidato perfeito para grid espacial igual ao `ob_grid` (`:892-904`).

### Finding 4: o boss em si não é patológico — é o acúmulo

**Evidence:** benchmark C/D — matar todo o resto e deixar o boss em estágio 3 custa 3.75ms. Brood tem teto de 10 adds (`:3221`), `combat_zones` tem teto (`:3440`), balas expiram por `life`.

## Hypothesized Paths

### H1: spawn ilimitado de adds — **Refuted**

Brood limitado a 10 vivos (`simulation.gd:3221`); boss_owner cleanup em `:2345-2347`.

### H2: colisão/queries escalando com entidades — **Confirmed**

Custo por frame ≈ inimigos × queries de colisão × scan linear de floors. Medido: sem inimigos+floors simples → 0.41ms.

### H3: efeitos/luzes não expirados — **Refuted**

`effects` filtrado por `life` todo frame (`:1246-1247`); counts ficaram em 0–8 durante a luta simulada.

### H4: custo de desenho — **Partial / unmeasured**

`world_view._draw()` faz culling por `view`/`seen`, mas headless não mede custo de render. A sala do boss é a maior do mapa (2400×1800) — provavelmente a mais cara de desenhar também. Não confirmado; simulação sozinha já explica frame budget estourado.

## Missing Evidence

| Gap | Impact | How to Obtain |
| --- | ------ | ------------- |
| Frame time de render no boss | separaria CPU-sim de CPU-draw | Godot Profiler (F3 no editor) ou `Performance.get_monitor(TIME_PROCESS)` vs `TIME_NAVIGATION` em janela real |

## Source Code Trace

| Element | Detail |
| ------- | ------ |
| Hot path 1 | `step_gates` → `recover_enemy_room` ×N — `simulation.gd:821` |
| Hot path 2 | `step_enemies` → `recover_enemy_room` ×N — `simulation.gd:2285` |
| Hot path 3 | `clear_at` floors loop — `simulation.gd:1009-1013` |
| Hot path 4 | `room_threats` filter — `simulation.gd:811-813` |
| Secundário | `ai_input` → `line_of_fire` por frame — `simulation.gd:1099` |

## Conclusion

**Confidence: High**

A lentidão no boss é o **frame budget estourando por custo cumulativo de queries de colisão**, não um bug da luta. O `sim.step` custa ~6–9ms em qualquer sala porque (a) `recover_enemy_room` valida cada inimigo 2× por frame com `clear_at` completo, (b) `clear_at` escaneia 62 rects de `floors` linearmente por query, e (c) `room_threats` refiltra todos os inimigos por sala. No boss, +10 adds, 30–200 projéteis e mais zonas empurram o total para >16ms junto com o render — queda visível de FPS.

## Recommended Next Steps

### Fix direction (ordem de impacto)

1. **Dedup + early-out em `recover_enemy_room`:** chamar uma vez por frame por inimigo (remover o loop de `step_gates`), e retornar cedo se `e.p` não mudou desde a última validação e a sala do inimigo já está registrada. Ganho estimado: ~2ms.
2. **`room_threats` em passe único:** em `step_gates`, montar `var threats := {}` iterando `enemies` uma vez (contando por `e.room`), e consultar o dict por sala. Ganho: ~0.5–0.7ms.
3. **Grid espacial para `floors`:** espelhar `ob_grid` — `floor_grid: Dictionary` de `Vector2i → Array[int]` construída em `start_run`; `clear_at` consulta só a célula local. Reduz `clear_at` de ~20µs para ~2–3µs → multiplica em TODAS as queries (movimento de inimigos, balas, actors). Ganho estimado: 3–5ms no pior caso.
4. **Throttle do `line_of_fire` em `ai_input`:** cachear o resultado por ~0.15s como já se faz para inimigos (`los_t`). Ganho: ~0.3–0.7ms.
5. **(Opcional) inimigos muito distantes sem step:** fora de ~1500px de qualquer ator e não-alertados, pular `recover_enemy_room`/LOS inteiramente.

Meta: `sim.step` < 3ms na sala do boss.

### Diagnostic

Se depois das otimizações ainda houver lentidão, medir render: `Performance.get_monitor(Performance.TIME_PROCESS)` numa build em janela durante o boss.

## Reproduction Plan

`tests/_dbg_boss_perf.gd` (já criado): `start_run(1941)` + teleporte pro boss room + step manual com timing. Refazer depois do fix e comparar.
