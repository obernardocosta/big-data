---
name: criar-lab
description: Como criar um novo lab prático com README conceitual, passo a passo, dry-run de validação sem custo e troubleshooting.
---

# Skill: criar um novo lab

Use esta skill quando o instrutor pedir um novo lab prático. Siga as regras de
`.kiro/steering/labs.md` e `.kiro/steering/didatica.md`.

## Estrutura a criar

```
disciplinas/<disciplina>/labs/lab-NN-nome/
  README.md
  passo-a-passo.md
  dry-run.sh
  troubleshooting.md
```

## README.md (modelo)

Seções, nesta ordem:

1. **Por que estamos fazendo isso** — a dor de negócio / conceito.
2. **O que você aprende aqui** — objetivos de aprendizado.
3. **Pré-requisitos** — conta/perfil AWS, região, tipo de usuário, serviços.
4. **Custo estimado** — em destaque se houver custo.
5. **Tempo estimado** — o timebox.
6. **Resultado esperado** — o que o aluno deve conseguir ao fim.
7. **Ponto de parada seguro** — onde parar se o tempo acabar.
8. **Limpeza** — como remover recursos para não gerar cobrança.
9. **O que isso prova** — amarração de volta ao conceito do slide.

## dry-run.sh (modelo)

- `#!/usr/bin/env bash` + `set -euo pipefail`.
- Só chamadas somente-leitura (`sts get-caller-identity`, `list*`, `describe*`,
  `get*`). Nunca `create`/`run`/`put` que gere custo.
- Checar: CLI instalada, credencial válida, região esperada, usuário IAM (se o
  lab exigir), permissões/quotas relevantes.
- Imprimir ✅/❌ por checagem e sair !=0 se faltar algo.
- Qualquer teste que crie recurso pago fica atrás de uma flag `--provision`
  desligada por padrão.

## passo-a-passo.md

- Cada etapa importante tem um "porquê" curto (regra da didática).
- Comandos AWS CLI de preferência (reproduzível), com alternativa no console
  quando fizer sentido.

## troubleshooting.md

- Erros comuns e correção: quota insuficiente, região errada, usuário root,
  permissão negada, serviço indisponível na região. Inclua o que fazer se o
  serviço estiver fora do ar (plano B), aprendizado do incidente da AWS/GPU.
