# Verificação do backlog de cenários

Data: 30/09/2026. Escopo: documentos de planejamento, sem execução do jogo.

Resultado: 12 épicos, 76 histórias e 304 critérios de aceite. A cobertura inclui 20 requisitos funcionais, 10 não funcionais e 8 de experiência. As dependências internas apontam apenas para histórias anteriores. Cada história contém objetivo, tarefas, dependências, requisitos, critérios Dado/Quando/Então e evidência exigida.

## Limites da conclusão

Esta revisão conclui a escrita e a conferência do backlog. Não certifica a qualidade dos assets, a integração GDQuest, o desempenho ou uma campanha jogável. Os testes e capturas descritos nas histórias são trabalho futuro. Não houve instalação de addon, nova geração de arte ou alteração de runtime nesta etapa.

Os biomas futuros dependem de conteúdo de combate, personagens e narrativa externo ao backlog. Fixtures permitem validar cenários sem declarar a era concluída. O recorte geográfico da região antiga e a ordem das eras precisam ser definidos durante as respectivas histórias. A aprovação estética não valida geometria.

## Arquitetura e tamanho das entregas

Projeto existente: não criar starter nem transplantar o demo GDQuest. Dados de catálogo são introduzidos quando necessários à bancada; a geração completa chega depois do piloto visual. O Farol pode ser avaliado antes das demais salas; cada era tem seu lote próprio e não depende das eras posteriores.

A repetição de mudanças nos arquivos de simulação e desenho é intencional: bancada, composição visual, montagem e persistência produzem entregas verificáveis distintas. Concentrar os contratos comuns nas histórias SCN-01.04 e SCN-04; novos biomas devem usar catálogos e assets, evitando cópias de regras no núcleo. Cada história de conteúdo limita templates e testes; caso a execução revele escopo maior, dividir preservando IDs e critérios rastreáveis.

## Ordem de trabalho

1. Bancada reproduzível e contrato compartilhado (SCN-01).
2. Piloto visual do Farol e escadas, seguido pelo catálogo Docas (SCN-02/03).
3. Montagem procedural e integração de estado (SCN-04/05).
4. Validar cada lote com SCN-12 antes de publicar; os números dos épicos não adiam QA até o final.
5. Expandir os setores e eras da Parte B conforme suas dependências; hub da Parte A pode avançar sem aguardar as eras.

Antes da produção, a próxima revisão BMAD é `gds-check-implementation-readiness` (IR), seguida de sprint planning. Não foi produzido relatório de prontidão nem alterado sprint-status nesta tarefa.

## Rastreabilidade por requisito

| Requisito | Histórias |
| --- | --- |
| SCN-FR01 | [SCN-01.03](stories-cenarios/scn-01-03.md), [SCN-06.01](stories-cenarios/scn-06-01.md) |
| SCN-FR02 | [SCN-01.01](stories-cenarios/scn-01-01.md), [SCN-01.04](stories-cenarios/scn-01-04.md) |
| SCN-FR03 | [SCN-01.02](stories-cenarios/scn-01-02.md) |
| SCN-FR04 | [SCN-02.01](stories-cenarios/scn-02-01.md), [SCN-07.01](stories-cenarios/scn-07-01.md), [SCN-08.01](stories-cenarios/scn-08-01.md), [SCN-09.01](stories-cenarios/scn-09-01.md), [SCN-10.01](stories-cenarios/scn-10-01.md) |
| SCN-FR05 | [SCN-01.04](stories-cenarios/scn-01-04.md), [SCN-02.03](stories-cenarios/scn-02-03.md), [SCN-02.05](stories-cenarios/scn-02-05.md) |
| SCN-FR06 | [SCN-02.02](stories-cenarios/scn-02-02.md), [SCN-02.06](stories-cenarios/scn-02-06.md), [SCN-03.01](stories-cenarios/scn-03-01.md), [SCN-03.02](stories-cenarios/scn-03-02.md), [SCN-03.03](stories-cenarios/scn-03-03.md), [SCN-03.04](stories-cenarios/scn-03-04.md), [SCN-03.05](stories-cenarios/scn-03-05.md), [SCN-03.06](stories-cenarios/scn-03-06.md), [SCN-03.07](stories-cenarios/scn-03-07.md), [SCN-03.08](stories-cenarios/scn-03-08.md), [SCN-03.09](stories-cenarios/scn-03-09.md), [SCN-03.10](stories-cenarios/scn-03-10.md), [SCN-03.11](stories-cenarios/scn-03-11.md), [SCN-03.12](stories-cenarios/scn-03-12.md), [SCN-03.13](stories-cenarios/scn-03-13.md) |
| SCN-FR07 | [SCN-01.03](stories-cenarios/scn-01-03.md), [SCN-03.02](stories-cenarios/scn-03-02.md), [SCN-03.04](stories-cenarios/scn-03-04.md), [SCN-03.05](stories-cenarios/scn-03-05.md), [SCN-03.08](stories-cenarios/scn-03-08.md), [SCN-03.09](stories-cenarios/scn-03-09.md), [SCN-03.11](stories-cenarios/scn-03-11.md), [SCN-05.06](stories-cenarios/scn-05-06.md), [SCN-06.01](stories-cenarios/scn-06-01.md), [SCN-06.02](stories-cenarios/scn-06-02.md), [SCN-06.03](stories-cenarios/scn-06-03.md), [SCN-06.04](stories-cenarios/scn-06-04.md) |
| SCN-FR08 | [SCN-02.06](stories-cenarios/scn-02-06.md), [SCN-04.03](stories-cenarios/scn-04-03.md), [SCN-04.05](stories-cenarios/scn-04-05.md), [SCN-07.03](stories-cenarios/scn-07-03.md), [SCN-08.03](stories-cenarios/scn-08-03.md), [SCN-09.03](stories-cenarios/scn-09-03.md), [SCN-10.03](stories-cenarios/scn-10-03.md) |
| SCN-FR09 | [SCN-04.01](stories-cenarios/scn-04-01.md) |
| SCN-FR10 | [SCN-04.02](stories-cenarios/scn-04-02.md), [SCN-04.03](stories-cenarios/scn-04-03.md), [SCN-04.04](stories-cenarios/scn-04-04.md), [SCN-04.08](stories-cenarios/scn-04-08.md), [SCN-06.02](stories-cenarios/scn-06-02.md), [SCN-07.06](stories-cenarios/scn-07-06.md), [SCN-08.06](stories-cenarios/scn-08-06.md), [SCN-09.06](stories-cenarios/scn-09-06.md), [SCN-10.06](stories-cenarios/scn-10-06.md) |
| SCN-FR11 | [SCN-01.04](stories-cenarios/scn-01-04.md), [SCN-02.04](stories-cenarios/scn-02-04.md), [SCN-03.03](stories-cenarios/scn-03-03.md), [SCN-03.07](stories-cenarios/scn-03-07.md), [SCN-03.10](stories-cenarios/scn-03-10.md), [SCN-03.12](stories-cenarios/scn-03-12.md), [SCN-04.04](stories-cenarios/scn-04-04.md), [SCN-04.06](stories-cenarios/scn-04-06.md), [SCN-06.03](stories-cenarios/scn-06-03.md), [SCN-12.01](stories-cenarios/scn-12-01.md) |
| SCN-FR12 | [SCN-05.03](stories-cenarios/scn-05-03.md), [SCN-06.04](stories-cenarios/scn-06-04.md), [SCN-11.02](stories-cenarios/scn-11-02.md) |
| SCN-FR13 | [SCN-04.08](stories-cenarios/scn-04-08.md), [SCN-05.01](stories-cenarios/scn-05-01.md), [SCN-05.02](stories-cenarios/scn-05-02.md), [SCN-05.04](stories-cenarios/scn-05-04.md), [SCN-05.05](stories-cenarios/scn-05-05.md) |
| SCN-FR14 | [SCN-03.01](stories-cenarios/scn-03-01.md), [SCN-03.06](stories-cenarios/scn-03-06.md), [SCN-03.12](stories-cenarios/scn-03-12.md), [SCN-03.13](stories-cenarios/scn-03-13.md), [SCN-04.02](stories-cenarios/scn-04-02.md), [SCN-04.06](stories-cenarios/scn-04-06.md), [SCN-05.02](stories-cenarios/scn-05-02.md), [SCN-05.03](stories-cenarios/scn-05-03.md), [SCN-06.04](stories-cenarios/scn-06-04.md), [SCN-07.04](stories-cenarios/scn-07-04.md), [SCN-07.05](stories-cenarios/scn-07-05.md), [SCN-08.04](stories-cenarios/scn-08-04.md), [SCN-08.05](stories-cenarios/scn-08-05.md), [SCN-09.04](stories-cenarios/scn-09-04.md), [SCN-09.05](stories-cenarios/scn-09-05.md), [SCN-10.04](stories-cenarios/scn-10-04.md), [SCN-10.05](stories-cenarios/scn-10-05.md), [SCN-11.03](stories-cenarios/scn-11-03.md), [SCN-11.05](stories-cenarios/scn-11-05.md) |
| SCN-FR15 | [SCN-07.01](stories-cenarios/scn-07-01.md), [SCN-07.02](stories-cenarios/scn-07-02.md), [SCN-07.03](stories-cenarios/scn-07-03.md), [SCN-07.04](stories-cenarios/scn-07-04.md), [SCN-07.05](stories-cenarios/scn-07-05.md), [SCN-07.06](stories-cenarios/scn-07-06.md) |
| SCN-FR16 | [SCN-08.01](stories-cenarios/scn-08-01.md), [SCN-08.02](stories-cenarios/scn-08-02.md), [SCN-08.03](stories-cenarios/scn-08-03.md), [SCN-08.04](stories-cenarios/scn-08-04.md), [SCN-08.05](stories-cenarios/scn-08-05.md), [SCN-08.06](stories-cenarios/scn-08-06.md) |
| SCN-FR17 | [SCN-09.01](stories-cenarios/scn-09-01.md), [SCN-09.02](stories-cenarios/scn-09-02.md), [SCN-09.03](stories-cenarios/scn-09-03.md), [SCN-09.04](stories-cenarios/scn-09-04.md), [SCN-09.05](stories-cenarios/scn-09-05.md), [SCN-09.06](stories-cenarios/scn-09-06.md) |
| SCN-FR18 | [SCN-10.01](stories-cenarios/scn-10-01.md), [SCN-10.02](stories-cenarios/scn-10-02.md), [SCN-10.03](stories-cenarios/scn-10-03.md), [SCN-10.04](stories-cenarios/scn-10-04.md), [SCN-10.05](stories-cenarios/scn-10-05.md), [SCN-10.06](stories-cenarios/scn-10-06.md) |
| SCN-FR19 | [SCN-11.01](stories-cenarios/scn-11-01.md), [SCN-11.02](stories-cenarios/scn-11-02.md), [SCN-11.03](stories-cenarios/scn-11-03.md), [SCN-11.04](stories-cenarios/scn-11-04.md), [SCN-11.05](stories-cenarios/scn-11-05.md) |
| SCN-FR20 | [SCN-01.01](stories-cenarios/scn-01-01.md), [SCN-01.05](stories-cenarios/scn-01-05.md), [SCN-02.06](stories-cenarios/scn-02-06.md), [SCN-04.07](stories-cenarios/scn-04-07.md), [SCN-07.06](stories-cenarios/scn-07-06.md), [SCN-08.06](stories-cenarios/scn-08-06.md), [SCN-09.06](stories-cenarios/scn-09-06.md), [SCN-10.06](stories-cenarios/scn-10-06.md), [SCN-12.01](stories-cenarios/scn-12-01.md), [SCN-12.02](stories-cenarios/scn-12-02.md), [SCN-12.03](stories-cenarios/scn-12-03.md), [SCN-12.04](stories-cenarios/scn-12-04.md), [SCN-12.05](stories-cenarios/scn-12-05.md) |
| SCN-NFR01 | [SCN-01.02](stories-cenarios/scn-01-02.md), [SCN-04.03](stories-cenarios/scn-04-03.md), [SCN-05.04](stories-cenarios/scn-05-04.md), [SCN-12.01](stories-cenarios/scn-12-01.md) |
| SCN-NFR02 | [SCN-01.01](stories-cenarios/scn-01-01.md), [SCN-04.01](stories-cenarios/scn-04-01.md), [SCN-04.08](stories-cenarios/scn-04-08.md), [SCN-12.05](stories-cenarios/scn-12-05.md) |
| SCN-NFR03 | [SCN-04.07](stories-cenarios/scn-04-07.md), [SCN-12.01](stories-cenarios/scn-12-01.md), [SCN-12.03](stories-cenarios/scn-12-03.md) |
| SCN-NFR04 | [SCN-05.06](stories-cenarios/scn-05-06.md), [SCN-12.03](stories-cenarios/scn-12-03.md) |
| SCN-NFR05 | [SCN-05.04](stories-cenarios/scn-05-04.md), [SCN-05.05](stories-cenarios/scn-05-05.md), [SCN-12.04](stories-cenarios/scn-12-04.md) |
| SCN-NFR06 | [SCN-12.02](stories-cenarios/scn-12-02.md), [SCN-12.04](stories-cenarios/scn-12-04.md) |
| SCN-NFR07 | [SCN-01.05](stories-cenarios/scn-01-05.md), [SCN-02.01](stories-cenarios/scn-02-01.md), [SCN-02.02](stories-cenarios/scn-02-02.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-NFR08 | [SCN-01.03](stories-cenarios/scn-01-03.md), [SCN-04.05](stories-cenarios/scn-04-05.md), [SCN-12.05](stories-cenarios/scn-12-05.md) |
| SCN-NFR09 | [SCN-02.01](stories-cenarios/scn-02-01.md), [SCN-04.01](stories-cenarios/scn-04-01.md), [SCN-12.05](stories-cenarios/scn-12-05.md) |
| SCN-NFR10 | [SCN-02.02](stories-cenarios/scn-02-02.md) |
| SCN-UX01 | [SCN-02.02](stories-cenarios/scn-02-02.md), [SCN-02.04](stories-cenarios/scn-02-04.md), [SCN-03.10](stories-cenarios/scn-03-10.md), [SCN-07.02](stories-cenarios/scn-07-02.md), [SCN-08.02](stories-cenarios/scn-08-02.md), [SCN-10.02](stories-cenarios/scn-10-02.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX02 | [SCN-02.04](stories-cenarios/scn-02-04.md), [SCN-02.05](stories-cenarios/scn-02-05.md), [SCN-03.03](stories-cenarios/scn-03-03.md), [SCN-04.04](stories-cenarios/scn-04-04.md), [SCN-07.02](stories-cenarios/scn-07-02.md), [SCN-08.02](stories-cenarios/scn-08-02.md), [SCN-09.02](stories-cenarios/scn-09-02.md), [SCN-10.02](stories-cenarios/scn-10-02.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX03 | [SCN-01.05](stories-cenarios/scn-01-05.md), [SCN-03.02](stories-cenarios/scn-03-02.md), [SCN-03.04](stories-cenarios/scn-03-04.md), [SCN-03.07](stories-cenarios/scn-03-07.md), [SCN-03.13](stories-cenarios/scn-03-13.md), [SCN-04.05](stories-cenarios/scn-04-05.md), [SCN-07.03](stories-cenarios/scn-07-03.md), [SCN-07.05](stories-cenarios/scn-07-05.md), [SCN-08.03](stories-cenarios/scn-08-03.md), [SCN-09.03](stories-cenarios/scn-09-03.md), [SCN-10.03](stories-cenarios/scn-10-03.md), [SCN-11.04](stories-cenarios/scn-11-04.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX04 | [SCN-01.05](stories-cenarios/scn-01-05.md), [SCN-02.03](stories-cenarios/scn-02-03.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX05 | [SCN-02.03](stories-cenarios/scn-02-03.md), [SCN-02.05](stories-cenarios/scn-02-05.md), [SCN-03.05](stories-cenarios/scn-03-05.md), [SCN-03.06](stories-cenarios/scn-03-06.md), [SCN-09.02](stories-cenarios/scn-09-02.md), [SCN-11.01](stories-cenarios/scn-11-01.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX06 | [SCN-03.09](stories-cenarios/scn-03-09.md), [SCN-03.11](stories-cenarios/scn-03-11.md), [SCN-05.06](stories-cenarios/scn-05-06.md), [SCN-09.05](stories-cenarios/scn-09-05.md), [SCN-11.04](stories-cenarios/scn-11-04.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX07 | [SCN-01.03](stories-cenarios/scn-01-03.md), [SCN-02.01](stories-cenarios/scn-02-01.md), [SCN-03.08](stories-cenarios/scn-03-08.md), [SCN-06.01](stories-cenarios/scn-06-01.md), [SCN-07.01](stories-cenarios/scn-07-01.md), [SCN-08.01](stories-cenarios/scn-08-01.md), [SCN-09.01](stories-cenarios/scn-09-01.md), [SCN-10.01](stories-cenarios/scn-10-01.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |
| SCN-UX08 | [SCN-03.01](stories-cenarios/scn-03-01.md), [SCN-05.01](stories-cenarios/scn-05-01.md), [SCN-05.03](stories-cenarios/scn-05-03.md), [SCN-11.01](stories-cenarios/scn-11-01.md), [SCN-11.02](stories-cenarios/scn-11-02.md), [SCN-12.02](stories-cenarios/scn-12-02.md) |

