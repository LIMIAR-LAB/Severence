# Blind Hunter Review Prompt

Review only the unified diff at:

`C:\Users\tsmar\AppData\Local\Temp\robot-switch-hud-marty-omega-review.diff`

Do not read the repository, specification, conversation, Git status, or other files. Apply the adversarial review lens from:

`C:\Users\tsmar\OneDrive\Documentos\ChatGPT\Jogo Steam\.agents\skills\bmad-review\references\lens-adversarial.md`

The diff contains concurrent unrelated workspace changes. Report concrete issues visible in the diff without assuming intent. Return only a JSON array. Every finding must contain `location`, `trigger_condition`, `guard_snippet`, and `potential_consequence`. Do not spawn subagents.
