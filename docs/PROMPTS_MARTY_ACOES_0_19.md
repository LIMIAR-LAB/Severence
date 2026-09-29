# Prompts de origem — esquiva do Marty 0.19

Ferramenta: ImageGen integrado. Referência visual em todas as gerações: `assets/marty/marty_anim_v3.png`. A geração diagonal da Ômega também usou `art/source/marty-omega-teleport-side-v1.png` como referência de ação. Fontes RGBA originais em `art/source`.

## Rolada comum — lado direito

> Preserve exactly Marty's four approved costume designs, compact chibi proportions, dark pixel outline, cyan accents and elevated game perspective. Create a separate transparent sprite sheet of exactly four columns and four rows: one full-body sprite per cell, equal spacing and generous transparent gutters. Each row repeats the same RIGHT-FACING four-frame forward dodge roll: low crouch launch, tightly tucked forward rotation, inverted shoulder-led roll-through, low recovery with planted foot. Rows: standard brown shearling pilot/cyan goggles, spy dark cap/sunglasses/trenchcoat/red scarf, mechanic white undershirt/olive overalls, Omega closed-helmet white/gold/cyan armor/purple cape. Empty hands; no weapons, tools, text, floor, shadow, grid, motion blur or extra objects. Consistent feet anchor, crisp deliberate pixel clusters, no clipped body or cell bleed.

## Rolada comum — diagonais

> Preserve the same four costumes, timing and four-column/four-row grid as the rightward roll. Forward diagonal: travel toward screen lower-right, elevated 3/4 view showing front and right side. Back diagonal: travel toward screen upper-right, elevated 3/4 view showing BACK of head/jacket/backpack/cape with no front face. Frames: crouch, tucked roll, inverted roll, planted recovery. Transparent, isolated, full-body, empty hands, no props or text, ample gutters, consistent ground anchor, approved pixel-art density and silhouette.

As linhas Ômega geradas por esses estudos de rolada **não são usadas no jogo**; a versão aprovada usa teleporte.

## Teleporte Ômega — lado direito

> Preserve the approved closed-helmet white/gold/cyan Omega armor, cyan chest core, short purple cape and pixel-art proportions. Create a new transparent horizontal four-frame sprite strip, right-facing only, equal cells and ample gutters. Aggressive short-range TELEPORT DASH, not a somersault: 1 crouch and gather cyan/violet energy, 2 body vanishes completely into an angular fracture silhouette, 3 energy streak reaches destination and armor rematerializes, 4 strong braced recovery with fading particles. Empty hands, no weapons, floor, text, grid or background; keep feet anchor and dark outlines.

## Teleporte Ômega — diagonais

> Preserve the same Omega armor and cyan/violet teleport language from the side strip. New transparent sprite sheet, exactly four columns and two rows, equal isolated cells. Row 1 travels diagonally forward-right, front-right 3/4 view. Row 2 travels diagonally back-right, back-right 3/4 view showing back of helmet and purple cape. In BOTH rows: charge, complete disappearance into fracture silhouette, streak and rematerialization, braced recovery. Never draw a physical roll or somersault. Crisp pixel clusters, no weapons, props, floor, text or grid; generous gutters.

O importador separa as células e ajusta cada ação à grade 96 × 96, sem modificar as fontes. Na segunda linha da fonte de teleporte diagonal, descarta 36 px superiores de vazamento da primeira linha antes da normalização.
