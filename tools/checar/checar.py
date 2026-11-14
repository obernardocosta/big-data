#!/usr/bin/env python3
"""Checagens mecânicas do checklist de consistência (.kiro/steering/didatica.md).

Roda sem rede e em segundos. Usado pelo pre-commit (.githooks/pre-commit) e por
`npm run checar`. Sai com código 1 listando cada problema (arquivo:linha).

Cobre os itens que dá para checar sem julgamento:
  6  - nunca dois `---` seguidos (slide vazio no Slidev)
  7  - lab citado em slide é link para o GitHub, não caminho em texto
  8  - dado de lab só de obernardocosta/data (sem raw.githubusercontent de terceiros)
  11 - markdown dentro de <div> precisa de linha em branco após a tag
  10 - nenhum CSV de turma/nota/entrega versionado (privacidade)
Os demais (terminologia, links 200, "cabe no slide", steering atualizado) exigem
julgamento ou rede e continuam no checklist.
"""
import glob
import os
import re
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(RAIZ)

problemas = []


def erro(arquivo, linha, msg):
    problemas.append(f"{arquivo}:{linha}: {msg}")


def linhas_fora_de_codigo(texto):
    """Gera (n, linha) ignorando blocos ``` e comentários <!-- -->."""
    em_codigo = False
    em_comentario = False
    for n, linha in enumerate(texto.split("\n"), 1):
        s = linha.strip()
        if s.startswith("```"):
            em_codigo = not em_codigo
            continue
        if em_codigo:
            continue
        if em_comentario:
            if "-->" in s:
                em_comentario = False
            continue
        if s.startswith("<!--") and "-->" not in s:
            em_comentario = True
            continue
        yield n, linha


slides = sorted(glob.glob("disciplinas/*/slides/*.md"))
conteudo = sorted(
    glob.glob("disciplinas/**/*.md", recursive=True)
    + glob.glob("disciplinas/**/*.sh", recursive=True)
    + glob.glob("disciplinas/**/*.py", recursive=True)
)

for f in slides:
    texto = open(f, encoding="utf-8").read()
    todas = texto.split("\n")

    # 6: dois --- seguidos
    for i in range(1, len(todas)):
        if todas[i].strip() == "---" and todas[i - 1].strip() == "---":
            erro(f, i + 1, "dois '---' seguidos: o Slidev cria um slide vazio")

    anterior = ""
    for n, linha in linhas_fora_de_codigo(texto):
        # 11: markdown colado na abertura do <div>
        if re.match(r"\s*<div[^>]*>\s*$", anterior) and re.search(
            r"\]\(|\*\*|`", linha
        ):
            erro(f, n, "markdown logo após <div>: deixe uma linha em branco (senão aparece cru)")
        # 7: lab citado como caminho em texto
        if re.search(r"(?<![/\w])labs/lab-\d\d[\w-]*", linha) and "github.com/obernardocosta/big-data" not in linha:
            erro(f, n, "lab citado sem link: use [..](https://github.com/obernardocosta/big-data/tree/main/disciplinas/<disc>/labs/<lab>)")
        anterior = linha

# 8: dados de terceiros
for f in conteudo:
    for n, linha in enumerate(open(f, encoding="utf-8", errors="ignore"), 1):
        for m in re.finditer(r"raw\.githubusercontent\.com/([\w.-]+)/", linha):
            if m.group(1) != "obernardocosta":
                erro(f, n, f"dado de terceiro ({m.group(1)}): copie para obernardocosta/data")

# 10: privacidade (só arquivos que vão para o commit)
try:
    staged = subprocess.run(
        ["git", "diff", "--cached", "--name-only", "--diff-filter=AM"],
        capture_output=True, text=True, check=True,
    ).stdout.split()
except Exception:
    staged = []
for f in staged:
    if re.search(r"(turma|nota|notas|entrega|gabarito)[^/]*\.(csv|xlsx)$", f, re.I):
        erro(f, 1, "parece dado de aluno/gabarito: isso vai no repo privado big-data-privado")

if problemas:
    print("❌ Checklist de consistência: corrija antes de commitar\n")
    print("\n".join(problemas))
    print(f"\n{len(problemas)} problema(s). Regras em .kiro/steering/didatica.md (checklist).")
    sys.exit(1)
print("✅ Checklist mecânico ok (itens 6, 7, 8, 10, 11).")
