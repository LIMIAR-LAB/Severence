# Armas e energia do Ômega — 04/10/2026

Mosquete, Tesla e arpoador receberam novas imagens detalhadas, com fundo transparente. As mesmas imagens aparecem na mão, no HUD e no chão. O tamanho usado para desenhar e a posição da empunhadura/cano são explícitos; o tamanho original de mais de 1.900 pixels não se transforma em arma gigante no cenário. As armas anteriores mantêm seu tamanho visual.

## Munição

| Arma | Ao encontrar: antes → agora | Reserva máxima atual |
|---|---:|---:|
| Mosquete | 4 → 20 | 60 |
| Tesla | 18 → 90 | 180 |
| Arpoador | 6 → 30 | 90 |
| Bazuca | 6 → 30 | 90 |

Drops de foguetes passam de 2 para 10; a recompensa de bazuca do baú especial passa de 3 para 15. Munição já salva é conservada, inclusive reservas maiores que o teto; reabastecer não reduz o saldo existente. Blaster, escopeta e submetralhadora dos uniformes continuam com munição infinita.

## Ômega

O comando que antes acionava a espada agora emite esferas grandes de energia azul pela mão. O combo conserva impacto próximo de 38/38/64, reflexão e acesso ao segredo; a terceira esfera é maior e perfura mais alvos. As esferas têm diâmetro visual de 54 pixels (76 no finalizador), rastro, luz pulsante e arcos animados. Um mesmo ataque não aplica novamente o dano da esfera a um inimigo já atingido pela emissão próxima. Paredes bloqueiam a emissão e o projétil.

A animação de corte e a espada desenhada foram substituídas por postura de emissão e brilho na mão. Duração, recarga, velocidade, escudo, armas equipadas, voo e poderes especiais do Ômega permanecem. Os IDs antigos são conservados para compatibilidade, mas os textos passam a dizer Energia Ômega.

## Arte e reprodução

Imagens geradas pela ferramenta integrada **image_gen** e copiadas para o projeto, com originais preservados:

- `assets/weapons/mosquete_hd.png`
- `assets/weapons/tesla_hd.png`
- `assets/weapons/arpoador_hd.png`
- `assets/weapons/omega_orb_hd.png`

Prompts registrados em `output/weapon-energy/image-prompts.json`. Os pedidos especificam silhueta lateral voltada à direita, madeira/metal/cobre e detalhes cianos para as armas; plasma azul com filamentos elétricos e sem círculos concêntricos para a esfera. Recorte de margens é feito em execução, preservando os PNGs gerados. Nenhum serviço externo é necessário para jogar.

## Verificação

Passaram as suítes `weapon_energy`, `omega`, `omega_flight` (30 verificações), `run_weapons`, `independent_weapons`, `review_gameplay_story` (37) e `missions_p7`, em projeto com dados de usuário isolados. Cobrem cargas/tetos, munição salva, oito direções de arma, esfera sem dano duplicado, cobertura e proteção/voo do Ômega.

Capturas reais renderizadas em `output/weapon-energy/captures`, com três armas na mão/HUD/chão, golpes sem textura gigante e esferas em direções diferentes, incluindo escala normal. Os contadores nas capturas das armas mostram uma carga a menos porque o disparo foi acionado para verificar a saída pelo cano.

O teste antigo `update_017` mantém uma falha na expectativa de hitbox inimiga equivalente a 80% do desenho, fora das alterações de armas desta entrega; sua verificação de recompensa ampliada passou. Não houve teste físico de controle nem validação entre redes externas. Alterações de NPCs, dano mínimo e outros trabalhos simultâneos pertencem a outras frentes e não são atribuídas a esta entrega.

A revisão independente também corrigiu contato da borda das esferas através de paredes finas, dimensões de faca/chave inglesa com arma HD equipada e o atributo exibido do finalizador (64). Os testes correspondentes passaram na rodada final, junto de omega e run_weapons. A importação isolada registrou aviso do plugin DialogueManager ao examinar diretórios; execução e capturas do jogo não apresentaram esse erro.
