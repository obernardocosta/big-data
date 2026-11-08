---
inclusion: always
---

# Convenções de didática (como ensinar neste material)

Estas convenções existem para tratar o feedback de que a prática às vezes ficava
desconectada do conceito e de que os labs consumiam tempo demais. Aplique-as em
todo slide e todo lab.

## Narrativa padrão de cada tópico

Todo serviço/tópico segue a mesma espinha, que já é a usada nos slides originais:

1. **Estudo de caso / problema** — qual dor de negócio motiva isso.
2. **Mundo open source** — como o problema é resolvido fora da nuvem
   (ex.: Hive Metastore, PrestoDB, Apache Airflow, Hadoop).
3. **Trazendo para a AWS** — o mapeamento open source -> serviço gerenciado
   (tabela real, com link oficial para cada projeto/serviço).
4. **O serviço gerenciado** — o que é, como cobra, integrações.
5. **Prós e contras / quando usar** — trade-offs explícitos.
6. **Prática (lab)** — aplica o conceito.
7. **Fechamento** — "open source -> serviço AWS" e dúvidas.

## Conectar prática a conceito (regra do feedback)

- Nenhum lab é só "siga os passos". Todo lab abre com **Por que estamos fazendo
  isso** e **O que você aprende aqui**, ligando a execução ao conceito do slide.
- Durante o passo a passo, cada etapa importante tem um **porquê** curto, não só
  o "clique aqui".
- Ao fim do lab, uma seção **O que isso prova** amarra de volta ao conceito.

## Equilíbrio prática x teoria

- Marque o tempo de cada lab (timebox) e respeite-o. Se estourar, o lab tem um
  ponto de parada seguro.
- Prefira um lab bem conduzido a três labs corridos.

## Pontualidade (regra do feedback)

- Começar no horário, tolerância máxima de 10 minutos.
- A partir da aula 2, os primeiros 30 minutos são para dúvidas / terminar a
  atividade anterior, enquanto os alunos vão chegando. Isso não atrasa conteúdo novo.
- Avisar na aula 1 que as aulas começam pontualmente.

## Checklist de consistência (antes de commitar qualquer mudança de conteúdo)

Toda alteração em slide, lab ou agenda passa por esta validação, sem precisar
ser pedida:

1. **Busca cruzada**: `grep` pelos termos alterados (serviços, ferramentas,
   títulos) em `disciplinas/**`, `README.md`, `agenda/` e `.kiro/` para achar
   menções que ficaram desatualizadas ou contraditórias (ex.: outra aula citando
   a ferramenta open source equivalente com outro nome).
2. **Terminologia**: o mesmo conceito tem o mesmo nome em todas as aulas e labs.
3. **Tabelas de mapeamento open source -> AWS**: sem células vazias ("—") e com
   link oficial em cada ferramenta/serviço, para o aluno pesquisar e escrever.
4. **Links**: todos respondem (HTTP 200) e apontam para a página oficial.
5. **Build**: `npx slidev build` do deck afetado passa sem erro.
6. **Referências a labs nos slides**: sempre como link clicável para a pasta no
   GitHub (`https://github.com/obernardocosta/big-data/tree/main/disciplinas/<disciplina>/labs/lab-NN-nome`),
   nunca só o caminho em texto. O site do Pages publica só os slides.
7. **Steering e skills**: se a mudança altera uma convenção, atualizar
   `.kiro/steering/` e `.kiro/skills/` no mesmo commit.

## Idioma

Todo material voltado ao aluno é em português do Brasil.
