---
title: 'Rebuild the Cult Chapel as one coherent chapel-dock space'
type: 'feature'
created: '2026-09-30'
status: 'done'
baseline_commit: '61ca44f586371900532ed636a550582a5ea91ae6'
context:
  - 'docs/CENARIO_0_16.md'
  - 'docs/architecture.md'
  - 'docs/LORE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The chapel currently reads as a landscape illustration pasted over a different room: the sanctuary ends at a hard seam, the north/east/south corridors do not match its doors or centerline, painted furniture disagrees with collision, and the story NPC is a tinted Marty sprite outside normal depth sorting.

**Approach:** Rebuild the whole chapel footprint as a single “Chapel-Dock of the Rift” composition. Keep the sanctuary as the focal point, but extend its stone, ritual carpet, dock timber, iron fittings, water damage, and violet corruption through the nave, side relic areas, and all three entrances. Author the art and collision contract together, then replace the NPC with a dedicated fisherman sprite integrated into the same scene.

## Boundaries & Constraints

**Always:** Keep the existing room, side-area, and corridor rectangles so global progression remains stable; preserve usable north, east, and south routes for Marty, enemies, and Titan; keep the chest, quest, save/network state, discovery fog, and story reward behavior; render crisp nearest-neighbor pixel art below actors and effects; make every visible solid object match an explicit collision footprint; keep the central procession route readable; retain a seamless ambient loop for the rift, altar, candles, and occult light.

**Ask First:** Removing one of the three map connections; changing quest rewards or progression; moving the chapel or adjacent rooms; changing camera zoom; replacing the fisherman with a different narrative character.

**Never:** Reuse Marty as the NPC; leave raw rectangular seams between sanctuary and procedural floor; bake the interactive NPC, chest, actors, or stateful door into the background; infer collision from opaque image pixels; create invisible blockers or walkable painted walls/void; alter unrelated rooms.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|---------------|----------------------------|----------------|
| Chapel discovered | Camera enters any chapel floor or connector | One continuous environment appears across sanctuary, nave, side relic areas, and the three thresholds | Missing animation frame uses the unified static plate |
| Traversal | Marty, enemy, or Titan crosses north/east/south | Painted doorway, walkable floor, collision, and navigation agree | Build/test fails if any route or required clearance closes |
| NPC interaction | Quest is available, ready to turn in, or complete | Dedicated fisherman is depth-sorted, readable, and shows the correct prompt/marker state | Existing quest state and reward remain authoritative |
| Art unavailable | Unified plate cannot load | Legacy chapel remains visible and playable without suppressing its props | Log the missing asset and do not apply unified-only hiding |

</frozen-after-approval>

## Code Map

- `assets/environment/docks12/chapel/unified/` -- full-room static master, twelve cropped animation overlays, fisherman frames, and collision-review overlay.
- `tools/build_chapel_unified.py` -- exports the master plus deterministic cropped overlays and a visual collision/portal review image.
- `tools/build_docks_map.py` -- owns chapel furniture footprints, wall boundaries, safe anchors, and the unchanged corridor geometry.
- `scripts/dock_scenery.gd` -- loads and draws the unified plate and suppresses only visuals baked into it.
- `scripts/world_view.gd` -- renders the fisherman in normal Y order and draws state-aware interaction presentation.
- `scripts/simulation.gd` -- reads the revised safe NPC anchor while preserving quest logic.
- `scripts/combat_hud.gd` -- hides or changes the chapel quest marker when the quest is complete.
- `tests/chapel_unified_test.gd` -- validates assets, collision alignment, portals, navigation radii, NPC state, fallback, and isolation.

## Tasks & Acceptance

**Execution:**
- [x] `assets/environment/docks12/chapel/unified/` -- generate a full-height pixel-art environment and dedicated fisherman that match the approved docks palette and perspective -- remove the collage effect and cloned-protagonist NPC.
- [x] `tools/build_chapel_unified.py` -- produce one static master, twelve stable 800×900 overlays, and collision/portal review from approved sources -- prevent frame drift without retaining twelve full-size textures in VRAM.
- [x] `tools/build_docks_map.py` and `scripts/docks_map.gd` -- replace chapel blockers with footprints authored against the final plate; keep all corridor rectangles; place chest, spawn, and NPC anchors only in verified walkable space -- eliminate visible walk-throughs and invisible blocks.
- [x] `scripts/dock_scenery.gd` and `scripts/world_view.gd` -- draw the complete room without T-shaped seams, preserve gameplay layering, and Y-sort the dedicated NPC -- unify the space at runtime.
- [x] `scripts/simulation.gd` and `scripts/combat_hud.gd` -- keep quest behavior intact while making the NPC position and marker state coherent -- improve presentation without changing progression.
- [x] `tests/chapel_unified_test.gd` -- cover frame/fallback behavior, painted-footprint tolerances, safe anchors, portal widths, and separate path checks for radii 11, 14, 15, and 23 -- guard gameplay and visual alignment.

**Acceptance Criteria:**
- Given a HUD-free capture centered at the chapel, when the whole room is viewed, then no raw seam or unrelated blue procedural floor remains and all three entrances are visually recognizable.
- Given the final collision overlay, when compared with the plate, then every altar, pew, wall, and large prop footprint is within 12 pixels of its painted base and the procession route stays clear.
- Given Marty or Titan inside the chapel, when each travels from the room center beyond the north, east, and south thresholds, then all three trips complete without clipping painted solids or hitting invisible blockers.
- Given the fisherman and either player on opposite sides of his depth line, when rendered, then their overlap follows foot Y and the interaction prompt remains legible without fixing a keyboard key in the label.
- Given any non-chapel room, when rendered or navigated, then its visuals, collision, and timing remain unchanged.

## Spec Change Log

- 2026-09-30: Implemented unified 1600×3300 static plate plus twelve 800×900 overlays, deterministic ambient animation, authored collision contract, dedicated Fisherman, state-aware marker, navigation/fallback tests, review overlay, and runtime captures.

## Design Notes

Use a single full-room master whose walkable architecture is intentionally designed around the unchanged map openings: north as a maintenance sacristy bridge, east as a breached cargo transept, and south as a procession path that bends from the sanctuary axis toward the existing southern corridor. Side rectangles become reliquaries framed by dock machinery and offerings. Animation is derived from stable masks/palette shifts on the approved master so geometry never changes between frames.

The collision review artifact must show painted art, blocker footprints, portal clearance, chest/spawn/NPC anchors, and the central route in distinct colors. It is the source for human visual approval; RGB/alpha pixels are not gameplay collision data.

## Verification

**Commands:**
- `python tools/build_chapel_unified.py` -- expected: static master, deterministic cropped overlays, fisherman frames, and review overlay regenerate without drift.
- `python tools/build_docks_map.py` -- expected: the map validator accepts all rooms, anchors, and chapel routes.
- `godot --headless --path . --script tests/chapel_unified_test.gd` -- expected: assets, collision, portals, NPC states, and all navigation radii pass.
- `godot --headless --path . --script tests/scenery_test.gd` -- expected: discovery and non-chapel scenery regressions pass.
- `godot --path . -- --capture-docks-v04 --visit-all --no-enemies --at=850,4300 --capture-name=chapel-unified-v2` -- expected: one coherent room with correct layering, NPC, thresholds, and no visible seams.

## Suggested Review Order

**Composição e renderização**

- A placa única integra sala, corredores, descoberta e animação sem revelar áreas ocultas.
  [`dock_scenery.gd:216`](../../scripts/dock_scenery.gd#L216)

- Soleiras autorais removem portões procedurais sobrepostos nos dois lados das conexões.
  [`dock_scenery.gd:201`](../../scripts/dock_scenery.gd#L201)

- O gerador exporta master, overlays compactos, Pescador e revisão visual reproduzíveis.
  [`build_chapel_unified.py:196`](../../tools/build_chapel_unified.py#L196)

**Geometria e gameplay**

- Colisões autorais acompanham paredes, altar, bancos e relicários pintados.
  [`docks_map.gd:146`](../../scripts/docks_map.gd#L146)

- A fonte do mapa mantém o gerador alinhado com o contrato executado.
  [`build_docks_map.py:327`](../../tools/build_docks_map.py#L327)

**NPC e interface**

- O Pescador usa sprite dedicado, ordenação por profundidade e prompt contextual.
  [`world_view.gd:381`](../../scripts/world_view.gd#L381)

- O marcador da missão desaparece quando o arco do Pescador termina.
  [`combat_hud.gd:11`](../../scripts/combat_hud.gd#L11)

**Verificação**

- O teste principal cobre arte, rotas, colisões, âncoras, estados e fallbacks.
  [`chapel_unified_test.gd:36`](../../tests/chapel_unified_test.gd#L36)

- A regressão da animação protege duração, dimensões, camadas e cenário legado.
  [`chapel_animated_test.gd:15`](../../tests/chapel_animated_test.gd#L15)



