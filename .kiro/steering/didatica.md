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
- Atividade ou desafio em sala **nomeia cada item** que o aluno vai usar (ex.:
  os estados `TransformarGlue`, `RodarCrawler`… numa tabela com # e nome) e diz
  em uma frase **o que entregar** e **como saber que acertou**. Nunca "faça os
  itens 1 e 2" sem dizer quais são. Gabarito vai nas notas do instrutor.

## Demo ao vivo -> aluno no console -> script

A sequência de aprendizagem de cada lab é: o instrutor faz **ao vivo** (o slide de
demo lista exatamente o que ele fará), o aluno repete lendo o passo a passo e
clicando no **console**, e o **script** recolhido fica de reforço.

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
6. **Slides em branco**: nunca dois `---` seguidos antes de `routeAlias`/layout (o
   primeiro já é o separador); o parser do Slidev não pode achar slide vazio.
7. **Referências a labs nos slides**: sempre como link clicável para a pasta no
   GitHub (`https://github.com/obernardocosta/big-data/tree/main/disciplinas/<disciplina>/labs/lab-NN-nome`),
   nunca só o caminho em texto. O site do Pages publica só os slides.
8. **Dados**: todo dado usado em lab vem de `obernardocosta/data`
   (ver `labs.md`); `grep` por URLs de terceiros (`raw.githubusercontent.com`
   de outros donos) deve voltar vazio.
9. **Steering e skills**: se a mudança altera uma convenção, atualizar
   `.kiro/steering/` e `.kiro/skills/` no mesmo commit.
10. **Privacidade**: nenhum CSV de turma, nota, entrega de aluno ou gabarito
   no repositório público. Isso vive em `obernardocosta/big-data-privado`.
   `git status` antes de commitar para conferir.
11. **Markdown dentro de HTML**: todo `<div>` com markdown dentro (link,
   negrito) tem **linha em branco** depois da tag de abertura e antes do
   `</div>`; sem isso o Slidev mostra o `[texto](url)` cru. `grep` por linhas
   `[...](http...)` coladas num `<div ...>` deve voltar vazio.
12. **Cabe no slide**: diagrama, tabela ou vídeo alterado é conferido no slide
   renderizado (`npx slidev export <aula>.md --format png`), não só no build.
   Nada pode vazar pela borda nem sobrar meia tela vazia.

## Separação visual dos slides

Capas (aula, lab, trabalho final) e mudanças de assunto são escuras; o conteúdo
segue claro. Capa: `layout: section` + `class: capa` (quase preto, filete ciano).
Divisão interna: só `layout: section` (slate escuro). O estilo vive em
`disciplinas/<disciplina>/slides/style.css` (mesma estrutura; cada disciplina tem seu azul: GDBD ardósia + ciano, PDN azul royal). Nunca use
`section` para slide de conteúdo.

## Regra de ouro: tudo que o aluno vai usar tem link

Todo dado, repositório, ferramenta, console, documentação, preço ou leitura
citado em slide ou lab é um **link clicável** (`[texto](url)`), nunca URL solta
nem só o nome. Isso vale para: dataset (link para o `obernardocosta/data`),
fonte original (ex.: openfootball), repositório de exemplos, página de preços e
console da AWS. Em blocos de código, o comando já usa a URL completa. Dentro do
checklist de consistência: `grep` por `https?://` fora de `](` deve voltar só
comandos em blocos de código.

**Vídeos** que o instrutor vai mostrar tocam **no próprio slide**:
`<Youtube id="..." width="640" height="360" />` dentro de
`<div class="flex justify-center">`, com o link clicável do vídeo (e da fonte,
ex.: AWS Architecture Blog) logo abaixo, como plano B se a rede bloquear o
embed. O slide anterior avisa, alinhado à direita: "▶ Veja o vídeo … na próxima
página →". Dê um `routeAlias` ao slide do vídeo (ex.: `nielsen`) para abrir direto.

## Idioma

Todo material voltado ao aluno é em português do Brasil.
