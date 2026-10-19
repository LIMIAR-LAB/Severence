---
title: 'Consolidar a primeira expedição após a revisão'
type: 'feature'
created: '2026-10-03'
status: 'done'
baseline_commit: '87fe42e55592e2d8944b94ec8e17429994c312af'
context: ['docs/LORE.md']
---

<frozen-after-approval reason="User approved the review improvements, explicitly preserving Omega strength">

## Intent

**Problem:** The review exposed profile corruption paths, unreliable coop actions, unfair capture/combat interactions, illegible projectiles and disconnected first-expedition story beats.

**Approach:** Implement the approved corrections and polish the existing first expedition, with persistent clues, clear routes and comfort controls. Preserve the currently strong Omega. The user's “pode fazer o resto” authorizes this combined scope without another approval checkpoint.

## Boundaries & Constraints

**Always:** Preserve the dirty working tree and current art; keep Omega duration, cooldown, damage, shield, speed, weapon access and flight. Fix its network camera inconsistency without reducing power. Keep Portuguese player-facing copy and controller navigation. Protect real user profiles during testing.

**Ask First:** Destructive changes to user saves or publishing externally.

**Never:** Reduce Omega strength, reset existing unlocks, fabricate playable eras or completed human playtests. Future era expansion remains the roadmap; deliver the existing expedition's concrete improvements now.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|---|---|---|---|
| Guest disconnect | Host snapshot replaces live simulation | Restore local profile before any offline persistence | Failed join also restores local state |
| Old checkpoint | Profile advanced since checkpoint | Never roll profile back or replay consumed meta rewards | Explicit stale-checkpoint handling, currencies never unioned |
| Input burst | Press then release before host tick | Process edge action once | Expired/disconnected input cleared |
| Capture | Stunned robot hit by companions/splash | Remains available for capture | No duplicate capture rewards |
| Dialogue switch | Unfinished Coral conversation then Faísca | Correct speaker and fresh context | Run transitions clear transient conversation |
| Settings | Missing/old settings file | Compatible defaults | Clamp new values |

</frozen-after-approval>

## Code Map

- `scripts/main.gd`: profile/checkpoint/network ownership, settings and HUD integration.
- `scripts/simulation.gd`: combat, capture, mission state, dialogue and narrative rewards.
- `scripts/world_view.gd`, `scripts/combat_hud.gd`: projectile readability and combat presentation.
- `scripts/display_settings.gd`, `scripts/game_audio.gd`, `scripts/terminal_ui.gd`: comfort, independent mix and mission journal.
- `data/equipamento.json`: campaign unlock rules; existing unlocks migrate intact.
- `tests/`, `tools/`: regressions and isolated, bounded test execution.

## Tasks & Acceptance

**Execution:**
- [x] `scripts/main.gd`, tests: separate guest/profile/checkpoint ownership; transactional persistence, stale-checkpoint protection; preserve network edge inputs and repair stale controller test.
- [x] `scripts/simulation.gd`, tests: AI ammo fallback, stunned protection, per-weapon ammo caps, explosion occlusion and separate musket effect; sync mission completion and camera-independent online recall.
- [x] `scripts/simulation.gd`, tests: normal jump distinguishes ground threats from projectiles while retaining armored behavior; improve AI support and existing encounter/route guidance, record useful playtest counters without claiming balance results.
- [x] `scripts/simulation.gd`, `data/equipamento.json`, tests: speaker-owned conversations, Coral dissident explanation and clue reaction, ship-attack evidence, four lost crew signals with first-victory advance, persistent journal and campaign/debug unlock separation.
- [x] `scripts/world_view.gd`, `scripts/combat_hud.gd`: recognizable projectile silhouettes, compact combat details, unobstructed readable dialogue and objective/interaction hierarchy.
- [x] `scripts/display_settings.gd`, `scripts/game_audio.gd`, `scripts/main.gd`, `scripts/terminal_ui.gd`: shake/flash controls, separate music/effects mix, preserve existing interface scaling; improve existing journal presentation.
- [x] `Jogar.cmd`, export/test tooling, documentation: portable launch/export configuration, safe test runner and accurate current implementation notes, followed by independent review.

**Acceptance Criteria:**
- Given a guest with a different local profile, when a network session ends and saves, then host progress never replaces the guest profile.
- Given a stale expedition checkpoint, when Continue is requested, then newer permanent progress remains authoritative and duplicate reward replay is prevented.
- Given an AI companion with an empty expedition weapon, when combat continues, then it uses a usable weapon and avoids stunned capture targets.
- Given a wall between explosion and target, when damage resolves, then the wall blocks splash; the musket does not inherit Titan splash accidentally.
- Given a first victory, when the player reviews missions, then ship-attack evidence and a lost-friend lead remain available despite combat messages or restarting.
- Given a new campaign, when viewing equipment, then earned robots follow their rules while previously owned items remain owned.
- Given comfort settings, when entering gameplay/reloading, then the selected presentation persists without changing simulation outcomes.
- Given the current Omega, when comparing constants and combat regressions, then its existing power remains unchanged.

## Design Notes

Use the existing route fork and mission screen rather than inventing new maps. Story journal entries can derive from persistent story flags, avoiding duplicate save authority. Use the current runtime baseline in `output/review-improvements/baseline` because HEAD predates substantial authorized changes. Implementation passes run sequentially to avoid shared-file races.

## Verification

Run bounded, isolated Godot checks for persistence/network, capture/combat, story, settings/HUD and existing Omega/flight/fish regressions. Review screenshots at normal and enlarged interface scales. Report inconclusive suites and external playtest limits explicitly. Never run save-writing tests against the real user directory.

## Spec Change Log

- Initial scope preserves the user's explicit Omega exception and existing working-tree edits. UI scaling already exists; improve its layout instead of adding duplicate controls.

## Review Outcome

Three independent reviewers completed blind defect, edge-case and acceptance reviews. Four findings were patched: direct visual-test isolation, intro navigation accidentally skipping playback, title exit bypassing paired checkpoint persistence, and barrel splash bypassing cover for actors/props. Focused regressions pass; acceptance reviewer confirmed the final splash patch. A pre-existing fish northeast attack atlas assertion remains recorded in the delivery report. Windows export is configured but not built/validated. No physical-controller, external-network or human balance playtest is claimed. Prior unrelated working-tree changes remain uncommitted.

## Suggested Review Order

**Persistência e saída**

- Revisões emparelham progresso e checkpoint; a saída usa a mesma proteção.
  [main.gd:854](../../scripts/main.gd#L854)

**Combate e história**

- Cobertura protege atores e objetos antes de qualquer remoção de obstáculos.
  [simulation.gd:1465](../../scripts/simulation.gd#L1465)

- Pistas permanentes conectam a primeira vitória aos amigos desaparecidos.
  [simulation.gd:3029](../../scripts/simulation.gd#L3029)

**Apresentação**

- Entradas roláveis conservam leitura e navegação por controle.
  [terminal_ui.gd:480](../../scripts/terminal_ui.gd#L480)

**Verificação e entrega**

- Regressões cobrem captura, cobertura, narrativa e atributos preservados do Omega.
  [review_gameplay_story_test.gd:21](../../tests/review_gameplay_story_test.gd#L21)

- Inicialização portátil reutiliza o motor disponível e importa no primeiro uso.
  [launch_game.ps1:1](../../tools/launch_game.ps1#L1)

