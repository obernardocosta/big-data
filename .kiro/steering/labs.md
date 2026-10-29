---
inclusion: always
---

# Convenções de labs (preparação e validação)

Estas regras existem para tratar o feedback de labs que falhavam ao vivo por
quota, configuração ou passo a passo não testado.

## Todo lab tem esta estrutura de pasta

```
labs/lab-NN-nome/
  README.md          # objetivo, conceito, pré-requisitos, resultado esperado, tempo
  passo-a-passo.md   # execução detalhada, com o "porquê" de cada etapa
  dry-run.sh         # valida o ambiente SEM gastar (ver abaixo)
  troubleshooting.md # erros comuns e como resolver (quota, região, permissão)
```

## Regra do dry-run (a mais importante)

Todo lab tem um `dry-run.sh` que o instrutor roda ANTES da aula para validar que
o ambiente está pronto, **sem criar recursos pagos**. O dry-run deve:

- Checar que a AWS CLI está instalada e autenticada (`aws sts get-caller-identity`).
- Confirmar a região esperada.
- Confirmar que o usuário é IAM (não root), quando o lab exigir.
- Verificar permissões/quotas relevantes via chamadas somente-leitura
  (`list`, `describe`, `get`) — nunca `create`/`run`.
- Sair com código 0 se tudo ok; !=0 listando o que falta.
- NÃO provisionar nada que gere custo. Se precisar testar criação de recurso,
  isolar atrás de uma flag explícita (ex.: `--provision`) que por padrão é off.

O objetivo é pegar o problema no dia anterior, barato, e não na frente da turma.

## Pré-requisitos sempre explícitos

O README do lab lista, no topo: conta/perfil AWS, região, tipo de usuário,
serviços envolvidos, custo estimado e tempo. Se o lab tem custo, deixar o número
em destaque (ex.: "Custo aproximado: US$ 1").

## Ponto de parada seguro

Todo lab indica onde parar se o tempo acabar e como limpar os recursos criados
(seção "Limpeza") para evitar cobrança depois da aula.
