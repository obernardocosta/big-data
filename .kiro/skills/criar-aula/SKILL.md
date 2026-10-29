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
3. Cada slide é separado por `---`. Use `##` para o título do slide.
4. Para o slide da prática, não cole link do Google Docs: aponte para o lab
   versionado em `labs/lab-NN-nome/` (link relativo) e cite o tempo (timebox).
5. Adicione o `src` do novo arquivo no `index.md`, na ordem das aulas.
6. Valide com `npx slidev build disciplinas/<disciplina>/slides/index.md`.

## Regras de estilo do slide

- Português do Brasil.
- Um conceito por slide; títulos curtos.
- Blocos de código com a linguagem marcada (```sql, ```bash, ```python).
- Notas do apresentador em `<!-- ... -->` ao fim do slide quando útil.
- Diagramas em Mermaid quando ajudar (arquitetura, DAG, fluxo).
