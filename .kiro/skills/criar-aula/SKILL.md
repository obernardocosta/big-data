---
name: criar-aula
description: Como adicionar ou atualizar uma aula (deck Slidev) em uma disciplina deste repositório, seguindo a narrativa didática padrão.
---

# Skill: criar uma nova aula (Slidev)

Use esta skill quando o instrutor pedir para criar ou reformular uma aula de uma
disciplina (gdbd ou pdn).

## Onde a aula vive

```
disciplinas/<disciplina>/slides/
  index.md            # deck principal; importa cada aula via "src"
  aula-NN-tema.md     # uma aula por arquivo
  assets/             # imagens
```

O `index.md` concatena as aulas com a sintaxe de import do Slidev:

```md
---
src: ./aula-01-catalogo.md
---
```

## Passos

1. Confirme o número e o tema da aula a partir do material de origem
   (`_fonte/*_extraido.txt`) ou do pedido do instrutor.
2. Crie `aula-NN-tema.md` seguindo a narrativa padrão de `.kiro/steering/didatica.md`:
   problema -> open source -> trazendo para AWS -> serviço gerenciado ->
   prós/contras -> prática -> fechamento.
2a. O primeiro slide da aula (capa) usa o frontmatter
   `layout: section`, `class: capa` e `routeAlias: aula-N`. Mudanças de assunto
   dentro da aula usam só `layout: section`. Ambos ficam escuros via
   `style.css` do deck; slides de conteúdo não usam `section`.
3. Cada slide é separado por `---`. Use `##` para o título do slide.
4. Para o slide da prática, não cole link do Google Docs: aponte para o lab
   versionado com **link clicável** para a pasta no GitHub, no formato
   ``[`labs/lab-NN-nome/`](https://github.com/obernardocosta/big-data/tree/main/disciplinas/<disciplina>/labs/lab-NN-nome)``
   (o Pages publica só os slides, então caminho relativo não abre), e cite o
   tempo (timebox).
5. Adicione o `src` do novo arquivo no `index.md`, na ordem das aulas.
6. Valide com `npx slidev build disciplinas/<disciplina>/slides/index.md`.
7. Rode o **checklist de consistência** de `.kiro/steering/didatica.md`
   (busca cruzada nas demais aulas/labs/agenda, terminologia, tabelas de
   mapeamento sem células vazias e com links, links respondendo 200) antes de
   commitar. A parte mecânica é `npm run checar` (também roda no pre-commit).
8. Se o pedido revelou uma regra nova, atualize este arquivo e o steering no
   mesmo commit.

## Regras de estilo do slide

- Português do Brasil.
- Um conceito por slide; títulos curtos.
- Blocos de código com a linguagem marcada (```sql, ```bash, ```python).
- Notas do apresentador em `<!-- ... -->` ao fim do slide quando útil.
- Diagramas em Mermaid quando ajudar (arquitetura, DAG, fluxo). Diagrama com
  muitos nós em sequência vai na **horizontal** (`flowchart LR`, agrupando
  nós iguais num `subgraph`) para usar a largura do slide; ajuste
  `{scale: ...}` (0.5–0.7 costuma caber) e confira no PNG exportado.
- Markdown dentro de `<div>`: deixe uma **linha em branco** após `<div ...>` e
  antes de `</div>`, senão links e negrito aparecem crus.
- Vídeo: `<Youtube>` centralizado + link clicável abaixo + aviso no slide
  anterior (regra em `.kiro/steering/didatica.md`).
- Atividade em sala: nomeie cada item numa tabela e diga o que entregar e como
  saber que acertou; gabarito nas notas do instrutor.
- Valide o visual com `npx slidev export disciplinas/<disciplina>/slides/aula-NN-tema.md --format png --output /tmp/aula`
  e olhe os slides alterados.
