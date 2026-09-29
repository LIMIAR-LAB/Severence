# Deferred Work

## Enemy spawn data cleanup

- `scripts/docks_map.gd` and `tools/build_docks_map.py` still emit an unused `GROUPS` table and describe spawn classes as seed-sampled, while runtime currently consumes the fixed class stored in each `SPAWNS` entry.
- `docs/architecture.md`, `docs/CENARIO_0_13.md`, and `README.md` contain older statements that the seed changes enemy types; reconcile these with the current fixed-class behavior and correct the stale room-count description in `docs/architecture.md`.
