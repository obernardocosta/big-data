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

## Dados dos labs: sempre do nosso repositório

Nenhum lab baixa dado de fonte de terceiros. Todo dataset fica versionado, em
formato raw, no repositório
[obernardocosta/data](https://github.com/obernardocosta/data),
e os labs e dry-runs apontam para a URL
`https://raw.githubusercontent.com/obernardocosta/data/main/<caminho>`.

- Dataset novo: copiar para o repo de dados (`tema/dataset/versao/`), com
  `README.md` (origem, licença, SHA-256, data) e só então usar no lab.
- O `dry-run.sh` testa essa URL (HTTP 200).
- Ao mudar um dataset ou lab, retestar todo bloco que consome o dado
  (download + geração do CSV) antes de commitar.

## Formato do passo a passo: console primeiro, script recolhido

Todo `passo-a-passo.md` segue este formato (piloto: GDBD Lab 01):

1. **Demo ao vivo antes do lab**: o slide da prática é seguido de um slide
   "Demo ao vivo" que descreve, em passos, o que o instrutor vai fazer no console.
2. **Cada passo** tem: **Porquê**, **No console** (objetivo, caminho de menu,
   valores a preencher), **Como saber que deu certo** e, recolhido, o script:

   ```html
   <details>
   <summary>⚡ Prefere o terminal (AWS CLI) ou está sem tempo? Clique para ver o script</summary>

   (bloco bash)

   </details>
   ```
3. **Exceção**: passos de preparação sem equivalente simples no console (gerar
   CSV, política IAM longa, esperar cluster) mantêm o **script como caminho
   principal**, dizendo por quê.
4. **Fim do passo a passo**: seção "Encontrou um problema neste lab?" com link
   para abrir issue (template `problema-no-lab.yml`, label `lab`).
5. As instruções de console vêm da documentação oficial da AWS e **precisam ser
   revisadas pelo instrutor no console** antes da aula (nomes de menu mudam).

## Regras adicionais do formato (decididas pelo instrutor)

- **O `dry-run.sh` é só do instrutor.** O aluno nunca roda dry-run. Nenhum texto
  voltado ao aluno (passo-a-passo, README, troubleshooting, texto visível dos
  slides) pede para rodar o dry-run. Ele só aparece nas notas do instrutor
  (`<!-- ... -->`), na agenda e nos docs internos (`.kiro/`, README da raiz).
- **Limpeza com link direto.** Onde o passo a passo manda limpar, use link
  absoluto para a seção: `[**Limpeza** do README deste lab](https://github.com/obernardocosta/big-data/blob/main/disciplinas/<disciplina>/labs/<lab>/README.md#limpeza)`.
- **A Limpeza do README também é console primeiro**, com o script recolhido em
  `<details>`, igual aos passos.
