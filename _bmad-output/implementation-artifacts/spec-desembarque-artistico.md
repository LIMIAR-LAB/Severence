---
title: Desembarque artístico — sala piloto
status: done
baseline_commit: 0f72c7e
created: 2026-09-29
context: [docs/architecture.md, docs/JOGABILIDADE_0_17.md]
---

## Intent aprovado

Usuário aprovou a proposta de refazer primeiro o Desembarque como amostra de qualidade equivalente ao Refúgio: arte exclusiva, cargueiro, abrigo militar, cais irregular, luz âmbar e água azul. Centro de combate legível, bordas ricas. A aprovação “vamos nessa” refere-se a executar essa sala. Não refazer outros biomas neste incremento.

## Implementação

- Usar assets/environment/docks12/entry/desembarque_painted_v1.png como arte de ambiente real (gerada com image_gen integrado; original preservado). Não usar apenas como conceito.
- Alinhar geometria caminhável às superfícies da arte. Derivar room.r, extra e bloqueios do desenho. Conservar corredores norte para Capela e leste para Guindastes, adaptando conexão se necessário. Garantir caminho largo para Titan, spawns Marty/Echo, chave e inimigos em chão válido.
- Remover props/hazards antigos que colidam ou dupliquem elementos pintados. Manter objetos interativos/destrutíveis poucos e intencionais. Não adicionar colisão invisível no centro vazio nem água caminhável.
- Renderização especial do Desembarque deve substituir piso/parede/decor genéricos dessa sala, respeitar névoa e não cobrir vizinhos. Camadas: ambiente, entidades, efeitos. Evitar dupla iluminação escurecendo arte.
- Mudanças do mapa somente no gerador, regenerar docks_map.gd. Manter salas seguras, combat 0.18, coop e save.
- Documentar bounds da imagem e mapeamento visual/mundo para editar, prompt e origem da arte.

## Aceite

- Dado início de expedição, Marty/Echo surgem sobre piso pintado, não em água/props.
- Dadas saídas norte/leste, Marty e Titan atravessam sem parede invisível ou fachada desenhada no caminho.
- Dada margem de mar/navio/ruína, não se pode atravessar área não caminhável.
- Dadas salas não descobertas, arte da sala permanece oculta; entrada não apaga piso de outra sala.
- Capturas mostram cargueiro, iluminação, abrigo e recortes; área de combate legível no zoom normal e geral.
- Validação do gerador e testes regressivos passam; capturar Desembarque antes/depois e jogo rodando.

## Verificação

Testes de geometria/rotas para sala pintada; suíte Godot headless; captura no ponto inicial e geral da sala. Inspeção visual é obrigatória; não aceitar arte cobrindo personagem, buraco caminhável ou saída desenhada fechada.

## Complemento do usuário
Adicionar fenda temporal no ponto de chegada, com animação de abertura e estado pulsante contínuo, partículas e reflexo ciano/violeta; animação Godot (aparência de loop GIF), sem bloquear movimento ou esconder balas. Visual sincronizado por tick_time da expedição e restrito ao modo run/entrada descoberta.


## Revisão final

Três revisões independentes sem bloqueadores. Gerador validado, 28 testes passaram. Arte e capturas inspecionadas.

## Suggested Review Order

- [Composição e fenda](../../scripts/arrival_art.gd#L1)
- [Geometria fonte](../../tools/build_docks_map.py#L19)
- [Rotas e sincronização](../../tests/arrival_art_test.gd#L1)
