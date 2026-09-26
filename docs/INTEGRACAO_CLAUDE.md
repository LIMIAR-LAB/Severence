# Integração Claude ↔ Codex

Este arquivo guardava os pontos de ligação pendentes da 0.12. Todos já foram aplicados (0.13/0.14).

Regras atuais de convivência:

1. Cada IA trabalha na própria branch (`dev-claude`, `dev-codex`). Nunca commitar direto na `main` nem dar force-push.
2. Antes de mexer num arquivo, conferir se ele mudou (git status / data de modificação). Prefira edições pontuais a gravar o arquivo inteiro.
3. `scripts/docks_map.gd` é gerado por `tools/build_docks_map.py`: edite o script.
4. Rode a suíte `tests/*_test.gd` antes de cada commit.

O histórico completo está em `HISTORICO_CLAUDE.md`.
