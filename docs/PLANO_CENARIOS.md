# Plano de composição dos cenários das Docas

## Objetivo

Cada sala deve comunicar seu caminho, sua cobertura e seu perigo à primeira vista. Objetos pequenos devem reforçar a identidade da sala, sem formar um labirinto acidental no centro do combate.

## Regras visuais e de jogo

- **Centro legível:** manter os eixos de entrada, saída e combate abertos. Distribuir cobertura grande em posições deliberadas, com passagens dos dois lados.
- **Pilares como estrutura:** usar o pilar de pedra e ferro criado no PixelLab, alto e indestrutível, para marcar a forma do espaço. Sua base corresponde à colisão de 220 × 160 px; a silhueta sobe 420 px acima dos pés.
- **Fossos como decisão de movimento:** colocar buracos largos no chão, com borda contrastante e rota contornável. Eles usam a mesma regra de queda dos vãos existentes.
- **Objetos pequenos nas bordas:** caixas, barris comuns e equipamentos soltos ficam nos depósitos, oficinas e cantos. Barris explosivos agrupados continuam como risco tático reconhecível.
- **Textura na escala nativa:** placas de sala que precisariam de ampliação acima de 1,5× cedem lugar aos novos tiles PixelLab de 64 px: pedra, metal e madeira. Corredores usam metal. A arena do chefe e a capela mantêm seus tratamentos próprios.
- **Paredes coerentes:** fachadas e paredes internas usam peças de pedra e ferro do kit PixelLab, na mesma paleta dos pilares. As paredes continuam respeitando as aberturas e colisões já definidas.

## Aplicação atual

| Área | Estrutura | Perigo | Objetos preservados |
| --- | --- | --- | --- |
| Pátio dos Guindastes | Dois pilares grandes | Fosso central | Guindastes e contêineres em faixas de carga; explosivos junto ao estoque |
| Pátio Ferroviário | Dois pilares grandes | Fosso na faixa de combate | Contêineres agrupados nas bordas dos trilhos |
| Depósito de Munição | Dois pilares grandes | Fosso entre linhas de cobertura | Munição ao fundo, carga ao sul e sacos de areia junto aos pilares |
| Mercado | Duas bancas ao norte | Poça de tentáculos ao sul | Cestos junto às bancas e caminho central livre |
| Oficina | Bancadas na parede, estoque ao sul | Sem perigo novo | Acesso livre ao vendedor e ao mecha |
| Armazém, doca e adega | Estoque em grupos junto às estruturas | Perigos próprios | Corredores e passagens mais legíveis |
| Gerador e Farol | Pilares existentes ampliados | Perigos próprios | Objetos associados à função de cada sala |
| Capela e chefe | Composição própria preservada | Perigos próprios | Identidade de cada encontro |

O ajuste fica em `scripts/scenario_layout.gd`, aplicado ao iniciar a expedição. Ele seleciona os objetos de cada sala e preserva a decoração de parede, trilhos e sinais de perigo. `scripts/docks_map.gd` continua sendo o mapa-base gerado; a composição não se perde quando esse mapa for regenerado.

Os arquivos PixelLab estão em `assets/environment/docks12/pixellab/`. O pilar veio do objeto `be0df7c3-f3d8-421a-8e17-f16601eb2bbb`, os 16 pisos do conjunto `f2836e8b-26b7-46ad-bbec-8fdd4e21e9c6` e as paredes do kit `41a737eb-36f4-4e4a-aadb-d8203666cc0e`. Os pisos 0–7 são pedra, 8–11 metal e 12–15 madeira.

## Critérios de revisão

1. Nenhum objeto ocupa um fosso ou bloqueia sua rota de contorno.
2. Personagens e inimigos não surgem dentro de fossos.
3. A navegação encontra caminho entre os lados das três salas alteradas.
4. O piso não depende de ampliar arte pequena até perder definição.
5. A câmera mostra, em cada encontro, a relação entre entrada, pilares e perigo.
6. Pontos de compra, missão e mecha permanecem acessíveis.
