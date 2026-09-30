# Epic SCN-04 Context: Expedições variadas com salas autoradas

## Goal
Build varied seeded expeditions using authored biome modules, preserving mandatory progression and a materialized map shared by simulation, navigation and rendering.

## Stories
- 04.01 GDQuest adaptation
- 04.02 expedition graph
- 04.03 template placement
- 04.04 corridors
- 04.05 interiors
- 04.06 progression validation
- 04.07 bounded recovery
- 04.08 production expedition entry

## Requirements & Constraints
Stable seeds, versions and IDs; independent RNG streams; no physics-based determinism assumption. Unique entry/boss, required clue and miniboss. Distinct biome circulation, not palette-only variations. Preserve existing game and changes by other chats. No runtime external services or Python.

## Technical Decisions
Current work is isolated preparation only. Provisional schema must be adapted to the base contract. Graph reachability does not establish physical navigation, visual quality, save or multiplayer acceptance.

## Cross-Story Dependencies
04.01 needs 01.04; 04.02 also needs 01.02; 04.03 must wait for 02.06; production 04.08 also needs entry and boss modules. Do not promote preparatory evidence to integrated acceptance.
