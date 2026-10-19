# Névoa e continuidade das passagens — 04/10/2026

## Névoa de descoberta

O piso provisório azul de salas desconhecidas deixava um recorte brusco contra a madeira detalhada dos corredores. A cobertura visual agora respeita a descoberta, sem mudar a geometria ou o estado persistido. Uma névoa marítima azul-acinzentada, com bordas suaves e movimento lento, cobre as entradas desconhecidas. A pintura inteira da sala e suas alas são reveladas com dissipação de 1,2 segundo.

A névoa é desenhada abaixo de personagens e interface. A textura é produzida uma única vez e reutilizada; a cobertura é limitada pela câmera, com células sobrepostas deduplicadas. Entradas que apenas encostam na sala também recebem o efeito. Salas já descobertas ficam livres da névoa de revelação.

### Evidência

- Capturas reais: `output/discovery-mist/captures/after-north-frontier.png`, `after-north-reveal.png`, `after-north-known.png` e `after-east-unknown.png`; versões anteriores no mesmo diretório.
- Testes aprovados: `discovery_mist`, `corridor_visibility`, `corridor_finish` e `all_corridors_finish` (18 rotas, 16 fragmentos).
- Logs finais da névoa: `output/isolated-tests/909e5032a7564383a655ff5a39cc1b00`.
- Revisões independentes identificaram e levaram à correção da revelação instantânea nas alas, ausência de efeito em entradas encostadas e margem insuficiente de descarte visual. Rechecagem sem novos achados concretos.

Testes e capturas executados em projeto com dados de usuário isolados. Nenhum save real foi modificado para preparar as cenas.

## Saída da capela e grade

A conexão física entre a capela e o Farol já era atravessável. O vazio visual vinha do piso do destino, desenhado apenas após a descoberta. Agora uma prévia de até 320 unidades mostra somente esse piso sob a névoa. O desenho é limitado à largura do corredor e recortado pelos pisos, paredes e fossos reais. A extremidade precisa estar dentro da geometria visível; nenhum inimigo ou objeto é revelado por essa prévia.

A barreira marrom provisória foi substituída por uma grade de ferro ornamentada com detalhes de bronze. A imagem usa transparência e um recorte de margens em execução, preservando o PNG original. A escala e a orientação acompanham a porta existente; fechada, a grade coincide com o bloqueio, e aberta desaparece. O contraste foi aumentado discretamente para leitura sobre a pedra escura.

Arte criada com **image_gen**, integrada em `assets/environment/docks12/gates/iron_gate_hd.png`. Prompt completo e origem em `output/passage-gate/image-prompts.json`.

### Validação final

- Cinco suítes aprovadas: `passage_gate`, `discovery_mist`, `corridor_visibility`, `corridor_finish`, `all_corridors_finish` — logs `output/isolated-tests/cf8ff1d4980148378de87635a520df05`.
- Após os ajustes da revisão, `passage_gate` e `discovery_mist` passaram novamente — logs `output/isolated-tests/34f937451a1e4baaaf78d8b43aa446cc`.
- Travessia aberta testada nos dois sentidos, com raios de personagem e robô; porta fechada bloqueia a passagem. A imagem real e o recorte da grade também são verificados.
- Duas revisões independentes da segunda etapa e aceite visual pelo agente principal. O limite de agentes impediu abrir um terceiro revisor independente; a inspeção de aceite foi realizada diretamente.
- Capturas GPU finais com saída 0 e sem erros: `output/passage-gate/captures/after-chapel-east-unknown.png`, `after-gate-closed-known.png`, `after-gate-open-known.png` e `after-gate-horizontal-closed.png`.

As alterações permanecem locais, sem commit conjunto com os outros trabalhos em andamento.

## Correção estrutural da emenda no corredor norte

O recorte enviado em seguida revelou uma diferença de cerca de 27 unidades entre a borda do deque e o piso traçado na entrada sul da capela. A passagem agora preenche apenas as faixas faltantes dentro do corredor existente. Essa correção é aplicada tanto em novas expedições quanto na restauração de snapshots, sem duplicar pisos. O bloqueio de combate da capela acompanha a faixa reparada para impedir desvios pela lateral.

O contorno, os rebites e as luminárias são desenhados uma vez por rota, sem reiniciar a cada fragmento. A área de uma pintura ainda desconhecida também deixou de recortar um retângulo preto sobre a água. A captura `output/corridor-seam/captures/after-north-frontier.png` mostra madeira, borda e água contínuas no local indicado.

O teste `corridor_seam` verifica a passagem pela lateral com raios 11 e 23, água externa bloqueada, reparo idempotente e ausência de desvio da porta fechada. As regressões de descoberta e corredores passaram, incluindo 18 rotas e 16 fragmentos. Capturas GPU sem erros.


## Revisão de legibilidade após feedback

A névoa sobreposta estava escurecendo o centro dos corredores. Agora a faixa central de 76% da largura conserva o piso legível nas duas direções; a opacidade da névoa nessa faixa é reduzida para 4% de cada camada. A passagem para a névoa lateral tem uma borda suavizada de 40 unidades, calculada pela união dos trechos para não criar cortes entre fragmentos. Essa proteção acompanha somente chão real, recortado contra paredes e fossos, sem ampliar descoberta ou colisão.

A prévia do destino aumentou de 220 para 320 unidades. Os primeiros 150 permanecem claros e o final desaparece com 48 faixas pequenas, reduzindo o salto para o vazio. A densidade geral da névoa também diminuiu.

Validação: quatro suítes aprovadas (discovery_mist, passage_gate, corridor_visibility, all_corridors_finish), com 18 rotas e 16 fragmentos; logs em output/isolated-tests/b02d0961b6f640f1bca77e075ebad502. Capturas GPU sem erros em output/clear-path/captures, incluindo aproximação norte e saída/retorno da capela. A comparação de pixels do centro do corredor está em output/clear-path/visual-check.txt. Sem alterações nas artes ou geometrias realizadas simultaneamente por outras frentes.
