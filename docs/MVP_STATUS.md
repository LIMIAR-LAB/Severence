# Estado atual — 03/10/2026

A consolidação atual está em [Revisão implementada](REVISAO_IMPLEMENTADA_2026-10-03.md) e no [README](../README.md). Há geração modular, música, diário, persistência com revisão de checkpoint e proteção do perfil do convidado. O preset Windows existe, mas a distribuição exportada ainda precisa de validação. Outras eras e amigos jogáveis seguem planejados.

**Registro histórico:** todo o conteúdo abaixo descreve o estado de 25/09/2026. Os números de testes, pendências e regras abaixo não são o estado atual do código.

---

# Estado — 25/09/2026 (revisado na versão 0.11)

## Decisões incorporadas

- Protagonista: **Marty**.
- Armadura binária: **com / sem**, sem combinação visual de partes.
- Coop local e online são requisitos de base. IA substitui o segundo jogador.
- Robô pilotável permanece no cenário ao sair.
- Refúgio central, expedições por portais para outras épocas/lugares.
- Chaves e baús; comerciante garantido; desafio opcional difícil.
- Arte compacta em pixel art, câmera de cima em três quartos.

## Implementado nesta primeira versão

| Área | Situação | Evidência / limite |
|---|---|---|
| Marty em dois estados | Implementado | Atlas transparente, caminhada e poses de ação, inspeção visual |
| Movimento/salto diagonal/escadas | Implementado | Testes de deslocamento e colisão; poses integradas |
| Tiro/corpo a corpo | Implementado | Testes de aplicação única e varredura de projétil |
| Titan pilotável | Implementado | Testes de assento exclusivo, saída bloqueada e integridade persistente |
| IA do parceiro | Implementação inicial | Caminho A*, mira e combate básicos, revive e embarque |
| Coop local | Implementado | Duas entradas independentes; teste físico de gamepad pendente |
| Rede direta | Implementada e testada em loopback | Duas instâncias, entrada remota e snapshots comprimidos sem erros |
| Internet entre redes | Pendente de validação | Sem relay/lobby; depende de UDP acessível |
| Baús/chaves/loja | Implementado | Testes de gasto único, saldo e estoque |
| Opcional/chefe/retorno | Implementado | Testes de estados e concessão única de recompensa |
| Geração | Parcial | Atalhos/encontros/coberturas por seed; salas mantêm posições fixas |
| Arte de cenário | Sala 01 final (0.12); demais salas com piso/paredes/props novos | `docs/CENARIO_0_12.md`; pilares, altar, bancos, gerador ainda antigos |
| Paredes e névoa de guerra | Implementado (0.12) | `tests/scenery_test.gd` |
| Arte do Titan | Parcial (0.12) | Diagonais usam a vista lateral; falta folha com vistas 3/4 reais (`docs/TITAN_0_12.md`) |
| Armas do Titan | Implementado (0.12) | Canhão pesado com explosão e bomba em arco; `tests/titan_weapons_test.gd` |
| Vincent | Pendente | Echo usa temporariamente sprites de Marty |
| Música | Pendente | Só efeitos sonoros sintetizados |
| Build Windows exportado | Pendente | Jogo roda só via Godot (`Jogar.cmd`) |
| Salvamento convidado | Pendente | Anfitrião salva progresso nesta versão |

## Validação realizada

- Importação e execução no Godot 4.7.2.
- 26 verificações de simulação aprovadas (0.1).
- **Revisão 0.11 (25/09/2026):** os 7 testes headless (`tests/*.gd`) rodados no Godot 4.7.2 → **127 verificações aprovadas, 0 falhas, 0 erros de script**.
- Teste de duas instâncias locais aprovado: conexão, movimento remoto e entrega de estados, sem erros do engine.
- Capturas do refúgio e oficina produzidas pelo renderizador OpenGL e inspecionadas.
- Não foi realizado teste com gamepad físico, redes distintas ou avaliação humana de balanceamento.

Esta é uma base jogável do MVP, não o MVP completo descrito no planejamento original.

## Manutenção — revisão 0.11

- Documentação da Armadura Ômega alinhada ao código (`ARMORS` em `scripts/simulation.gd`): **5s ativa, 60s de recarga, velocidade 430, −60% de dano**, começa a expedição com a recarga cheia. README e `EQUIPAMENTO_0_9.md` diziam 12s/18s.
- `project.godot`: feature de versão atualizada de 4.3 para 4.7 (o projeto já roda no 4.7.2).
- Git: removido o `.git/index.lock` travado. O repositório ainda **não tem nenhum commit** — tudo está como não rastreado.

- **Correção de inicialização:** abrir pelo editor/F5 quebrava com `Identifier "DocksMap" not declared` (cache de `class_name` em `.godot/` desatualizado; o `Jogar.cmd` mascarava porque importa antes). `simulation.gd`, `world_view.gd`, `combat_hud.gd` e `tests/simulation_test.gd` agora usam `const DOCKS := preload("res://scripts/docks_map.gd")`. Validado rodando no Windows via Godot MCP: sem erros, apenas 16 avisos de estilo (variáveis que sombreiam `owner`/`scale`/`size`, divisão inteira em `world_view.gd:105`, ternário com tipos diferentes em `world_view.gd:354`).
- **Godot MCP** (`@coding-solo/godot-mcp`) configurado no app Claude: permite abrir o editor, rodar o jogo e ler a saída de debug direto no Windows.

## Próximos passos sugeridos

1. Primeiro commit do repositório (e, idealmente, um remoto no GitHub como backup).
2. Arte nova do Titan no mesmo padrão dos sprites 0.6.
3. Vincent: conceito, sprites e habilidade própria (substituir o Echo).
4. Música: tema do Refúgio, das Docas e do Almirante.
5. Exportar build Windows (instalar os export templates do Godot 4.7.2).
6. Testes manuais pendentes: gamepad físico e coop online entre duas redes diferentes.
