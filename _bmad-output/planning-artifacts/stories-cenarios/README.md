# Histórias de geração dos cenários

76 histórias em12épicos. Escopo completo retomado pelo usuário. Docas procedural já integrado ao fluxo normal, com 14 salas e conexões/distribuição variáveis por seed; SCN-04 em revisão de integração. SCN-01/02 permanecem em review documental. Outras salas/biomas e gates não demonstrados continuam pendentes. Não interpretar isto como conclusão do backlog.

[Plano completo e contratos](../epics-cenarios.md) · [Verificação do backlog](../validacao-cenarios.md)

A direção vigente é geração completa de salas e corredores, com módulos autorados por bioma. Doca/Desembarque e boss podem conservar arte interna fixa. Refúgio permanece hub.

Os arquivos individuais abaixo são a fonte de trabalho de cada história. O plano consolidado registra esta versão do backlog; alterações futuras devem atualizar ambos. Não interpretar `planned` como implementado, validado em jogo ou aprovado visualmente.

## SCN-01 — Prévia reproduzível de um cenário por bioma

A equipe abre um cenário real com identidade, geometria e seed inspecionáveis. Horizonte: A.

| História | Dependências |
| --- | --- |
| [SCN-01.01 — Abrir uma bancada de cenários com baseline preservado](scn-01-01.md) | Nenhuma |
| [SCN-01.02 — Reproduzir a seleção de cenário por seed](scn-01-02.md) | SCN-01.01 |
| [SCN-01.03 — Carregar a identidade de um bioma por dados](scn-01-03.md) | SCN-01.02 |
| [SCN-01.04 — Instanciar uma sala autorada com arte e geometria alinhadas](scn-01-04.md) | SCN-01.03 |
| [SCN-01.05 — Inspecionar uma sala com diferentes personagens e câmeras](scn-01-05.md) | SCN-01.04 |

## SCN-02 — Farol bonito e escadas compreensíveis

O jogador atravessa o primeiro conjunto final de arquitetura com profundidade e caminhos legíveis. Horizonte: A.

| História | Dependências |
| --- | --- |
| [SCN-02.01 — Produzir o kit piloto de pedra, madeira e ferro](scn-02-01.md) | SCN-01.05 |
| [SCN-02.02 — Desenhar o módulo baixo de escada e patamar](scn-02-02.md) | SCN-02.01 |
| [SCN-02.03 — Integrar camadas e profundidade do Farol](scn-02-03.md) | SCN-02.02 |
| [SCN-02.04 — Alinhar escadas, colisão e circulação](scn-02-04.md) | SCN-02.03 |
| [SCN-02.05 — Criar conectores de entrada sem emendas](scn-02-05.md) | SCN-02.04 |
| [SCN-02.06 — Publicar o Farol como módulo reutilizável](scn-02-06.md) | SCN-02.05 |

## SCN-03 — Docas completas e coerentes

As 14 áreas existentes viram famílias de módulos coerentes, combinadas segundo papéis de cada run. Horizonte: A.

| História | Dependências |
| --- | --- |
| [SCN-03.01 — Preparar a Doca de desembarque como entrada fixa encaixável](scn-03-01.md) | SCN-02.06 |
| [SCN-03.02 — Compor o Pátio dos Guindastes por módulos](scn-03-02.md) | SCN-02.06 |
| [SCN-03.03 — Montar o Armazém 7 com vãos compreensíveis](scn-03-03.md) | SCN-02.06 |
| [SCN-03.04 — Montar o Mercado com áreas de combate tranquilas](scn-03-04.md) | SCN-02.06 |
| [SCN-03.05 — Criar a Oficina como espaço seguro de serviço](scn-03-05.md) | SCN-02.06 |
| [SCN-03.06 — Compor o Último Gerador com espaço de desafio](scn-03-06.md) | SCN-02.06 |
| [SCN-03.07 — Montar o Depósito de Munição com cobertura funcional](scn-03-07.md) | SCN-02.06 |
| [SCN-03.08 — Criar o Pátio Ferroviário com trilhos contínuos](scn-03-08.md) | SCN-02.06 |
| [SCN-03.09 — Adaptar a Capela ao catálogo modular](scn-03-09.md) | SCN-02.06 |
| [SCN-03.10 — Montar o Doque Seco com profundidade segura](scn-03-10.md) | SCN-02.06 |
| [SCN-03.11 — Criar a Adega Inundada com três leituras de água](scn-03-11.md) | SCN-02.06 |
| [SCN-03.12 — Construir o Contrabando como segredo alcançável](scn-03-12.md) | SCN-02.06 |
| [SCN-03.13 — Preparar a arena fixa do Almirante para qualquer montagem](scn-03-13.md) | SCN-02.06 |

## SCN-04 — Expedições variadas com salas autoradas

Grafo, salas, corredores e interiores variam de forma válida usando módulos autorados por bioma. Horizonte: A.

| História | Dependências |
| --- | --- |
| [SCN-04.01 — Adaptar os exemplos GDQuest ao contrato do jogo](scn-04-01.md) | SCN-01.04 |
| [SCN-04.02 — Gerar o grafo de uma expedição com ramificações](scn-04-02.md) | SCN-04.01, SCN-01.02 |
| [SCN-04.03 — Posicionar templates sem sobreposição](scn-04-03.md) | SCN-04.02, SCN-02.06 |
| [SCN-04.04 — Construir corredores coerentes entre salas](scn-04-04.md) | SCN-04.03, SCN-02.05 |
| [SCN-04.05 — Variar interiores por composição funcional](scn-04-05.md) | SCN-04.04 |
| [SCN-04.06 — Validar progressão espacial e portas/chaves](scn-04-06.md) | SCN-04.05 |
| [SCN-04.07 — Recuperar falhas de geração de forma limitada](scn-04-07.md) | SCN-04.06 |
| [SCN-04.08 — Iniciar expedições com mapa totalmente procedural](scn-04-08.md) | SCN-04.07, SCN-03.01, SCN-03.13 |

## SCN-05 — Viajar e retomar a mesma expedição

Mudanças de bioma, descoberta, save e coop preservam o mundo materializado. Horizonte: A.

| História | Dependências |
| --- | --- |
| [SCN-05.01 — Mostrar o mapa real e sua descoberta](scn-05-01.md) | SCN-04.08 |
| [SCN-05.02 — Vincular encontros e recompensas às instâncias](scn-05-02.md) | SCN-05.01 |
| [SCN-05.03 — Transitar entre biomas sem perder a run](scn-05-03.md) | SCN-05.02 |
| [SCN-05.04 — Salvar e restaurar o mundo materializado](scn-05-04.md) | SCN-05.03 |
| [SCN-05.05 — Sincronizar o mapa no coop autoritativo](scn-05-05.md) | SCN-05.04 |
| [SCN-05.06 — Aplicar atmosfera por bioma com transição legível](scn-05-06.md) | SCN-05.03 |

## SCN-06 — Ferroviário, Adega e Santuário com identidade própria

Setores podem formar andares distintos sem virar apenas recolorações das Docas. Horizonte: B; setores atuais entregues em A.

| História | Dependências |
| --- | --- |
| [SCN-06.01 — Definir perfis de Ferroviário, Adega e Santuário](scn-06-01.md) | SCN-05.03, SCN-01.03 |
| [SCN-06.02 — Gerar um setor ferroviário com continuidade de trilhos](scn-06-02.md) | SCN-06.01, SCN-03.08, SCN-04.08 |
| [SCN-06.03 — Gerar um setor alagado com rota seca garantida](scn-06-03.md) | SCN-06.01, SCN-03.11, SCN-04.08 |
| [SCN-06.04 — Gerar o Santuário com foco ritual e rotas claras](scn-06-04.md) | SCN-06.01, SCN-03.09, SCN-04.08 |

## SCN-07 — Explorar o Japão de Vincent

O cenário sustenta a comunidade, o conflito entre clãs e a despedida de Vincent. Horizonte: B.

| História | Dependências |
| --- | --- |
| [SCN-07.01 — Definir e produzir o kit visual do Japão](scn-07-01.md) | SCN-01.05, SCN-05.06 |
| [SCN-07.02 — Criar entrada e travessias do Japão](scn-07-02.md) | SCN-07.01, SCN-04.08 |
| [SCN-07.03 — Criar pátios de combate japoneses](scn-07-03.md) | SCN-07.02 |
| [SCN-07.04 — Construir os espaços da comunidade e despedida](scn-07-04.md) | SCN-07.03 |
| [SCN-07.05 — Compor arenas do minichefe e chefe do Japão](scn-07-05.md) | SCN-07.04 |
| [SCN-07.06 — Validar o catálogo procedural do Japão](scn-07-06.md) | SCN-07.05, SCN-05.05 |

## SCN-08 — Atravessar o reino do Mago de Ferro

O cenário medieval conduz à fonte das vozes e comporta o encontro com Elias. Horizonte: B.

| História | Dependências |
| --- | --- |
| [SCN-08.01 — Definir e produzir o kit do reino medieval](scn-08-01.md) | SCN-01.05, SCN-05.06 |
| [SCN-08.02 — Criar acesso e passagens do reino](scn-08-02.md) | SCN-08.01, SCN-04.08 |
| [SCN-08.03 — Criar câmaras de combate do reino](scn-08-03.md) | SCN-08.02 |
| [SCN-08.04 — Construir o percurso até a fonte das vozes](scn-08-04.md) | SCN-08.03 |
| [SCN-08.05 — Compor arenas do guardião e do Mago de Ferro](scn-08-05.md) | SCN-08.04 |
| [SCN-08.06 — Validar o catálogo procedural medieval](scn-08-06.md) | SCN-08.05, SCN-05.05 |

## SCN-09 — Infiltrar o laboratório de Íris

Ambientes de contenção e fuga apresentam Íris, prisioneiros e Spectre com caminhos claros. Horizonte: B.

| História | Dependências |
| --- | --- |
| [SCN-09.01 — Definir e produzir o kit do laboratório avançado](scn-09-01.md) | SCN-01.05, SCN-05.06 |
| [SCN-09.02 — Criar acessos e passagens de serviço](scn-09-02.md) | SCN-09.01, SCN-04.08 |
| [SCN-09.03 — Criar salas de combate e contenção](scn-09-03.md) | SCN-09.02 |
| [SCN-09.04 — Construir o setor de Íris, prisioneiros e Spectre](scn-09-04.md) | SCN-09.03 |
| [SCN-09.05 — Compor arenas de contenção do laboratório](scn-09-05.md) | SCN-09.04 |
| [SCN-09.06 — Validar o catálogo procedural do laboratório](scn-09-06.md) | SCN-09.05, SCN-05.05 |

## SCN-10 — Defender a comunidade de Letícia

Uma região antiga com identidade definida permite defesa e o encontro com Letícia. Horizonte: B.

| História | Dependências |
| --- | --- |
| [SCN-10.01 — Definir a região antiga e produzir seu kit piloto](scn-10-01.md) | SCN-01.05, SCN-05.06 |
| [SCN-10.02 — Criar chegada e caminhos da região antiga](scn-10-02.md) | SCN-10.01, SCN-04.08 |
| [SCN-10.03 — Criar espaços de defesa com circulação humana](scn-10-03.md) | SCN-10.02 |
| [SCN-10.04 — Construir encontro com Letícia e espaço da pista](scn-10-04.md) | SCN-10.03 |
| [SCN-10.05 — Compor arenas da ameaça à comunidade](scn-10-05.md) | SCN-10.04 |
| [SCN-10.06 — Validar o catálogo da região antiga](scn-10-06.md) | SCN-10.05, SCN-05.05 |

## SCN-11 — Voltar ao Refúgio e alcançar o clímax

Acessos do hub e cenários do Arauto/R'lyeh sustentam a progressão e o selamento. Horizonte: A para hub; B para clímax.

| História | Dependências |
| --- | --- |
| [SCN-11.01 — Organizar acessos às eras no Refúgio](scn-11-01.md) | SCN-05.03 |
| [SCN-11.02 — Criar transições visuais entre épocas](scn-11-02.md) | SCN-11.01, SCN-05.06 |
| [SCN-11.03 — Construir o caminho e arena do Arauto](scn-11-03.md) | SCN-11.02, SCN-04.08 |
| [SCN-11.04 — Construir R'lyeh com uma pista de combate confiável](scn-11-04.md) | SCN-11.03 |
| [SCN-11.05 — Validar retorno e cenário após o selamento](scn-11-05.md) | SCN-11.04, SCN-05.04 |

## SCN-12 — Jogar cenários legíveis, fluidos e verificáveis

Cada lote de cenários passa por validação funcional, visual e de desempenho reproduzível. Horizonte: A e B por lote.

| História | Dependências |
| --- | --- |
| [SCN-12.01 — Executar validação de geração em lote por bioma](scn-12-01.md) | SCN-04.08, SCN-05.02 |
| [SCN-12.02 — Revisar qualidade visual e identidade por bioma](scn-12-02.md) | SCN-12.01, SCN-02.06, SCN-05.06 |
| [SCN-12.03 — Medir fluidez, carregamento e memória](scn-12-03.md) | SCN-12.01, SCN-05.06 |
| [SCN-12.04 — Testar exploração, coop e progressão em partidas completas](scn-12-04.md) | SCN-12.02, SCN-12.03, SCN-05.05 |
| [SCN-12.05 — Empacotar catálogos e documentar a autoria de novos biomas](scn-12-05.md) | SCN-12.04 |



## Estado de execução — 30/09/2026

SCN-01.01–01.05: implementação isolada e evidências disponíveis; estado in-progress porque a revisão global ainda possui falhas externas e robustez em fechamento. Contrato v1 liberado para adaptação isolada SCN-04.01/02. Piloto SCN-02.01 montado em bancada, em avaliação visual. Nenhuma história de geração/era foi declarada integrada.


