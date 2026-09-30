# Acceptance Auditor Review Prompt

Audit these inputs:

- Diff: `C:\Users\tsmar\AppData\Local\Temp\robot-switch-hud-marty-omega-review.diff`
- Approved spec: `C:\Users\tsmar\OneDrive\Documentos\ChatGPT\Jogo Steam\_bmad-output\implementation-artifacts\spec-robot-switch-hud-marty-omega.md`
- Sprite standard: `C:\Users\tsmar\OneDrive\Documentos\ChatGPT\Jogo Steam\docs\SPRITE_POSE_STANDARD.md`
- Marty standard: `C:\Users\tsmar\OneDrive\Documentos\ChatGPT\Jogo Steam\docs\PADRAO_SPRITES_MARTY_0_19.md`

You may read the repository and tests. Audit every acceptance criterion and frozen rule, including multiplayer authority, owned-only selection, mutual exclusion of active robots, resource preservation, HUD states, 1.4-second Omega timing, sprite pivots/filtering, and existing-save reconciliation. Distinguish concurrent unrelated workspace changes from this story.

Return only a JSON array of concrete findings with `location`, `trigger_condition`, `guard_snippet`, and `potential_consequence`. An empty array is valid. Do not spawn subagents.
