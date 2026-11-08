#!/usr/bin/env python3
"""Trabalho final (GDBD e PDN): clube do grupo e autoconferencia da entrega.

Subcomandos (publicos, para o aluno):
  clube   <matricula>             mostra o clube do grupo (regra deterministica)
  validar <pasta> --disciplina    confere formato e estrutura da entrega. NAO diz
                                  se as respostas estao certas.

So usa a biblioteca padrao. Os dados vem do repo de dados do curso
(obernardocosta/data); use --dados para apontar um JSON local (modo offline).
A correcao (gabarito) NAO fica neste repositorio.
"""
import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path

URL = ("https://raw.githubusercontent.com/obernardocosta/data/main/"
       "football/premier-league/2024-25/en.1.json")
UUID = re.compile(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")

# chaves esperadas em entrega.json -> respostas
CHAVES = {
    "gdbd": ["jogos", "pontos", "saldo_gols", "pontos_casa", "pontos_fora",
             "maior_vitoria_saldo", "melhor_mes", "maior_sequencia_invicta"],
    "pdn": ["jogos", "vitorias", "gols_pro", "gols_contra",
            "media_gols_por_jogo", "adversario_mais_gols_marcados"],
}

# ---------------------------------------------------------------- dados

def carregar(dados=None):
    """Retorna os jogos ja disputados: (data, mandante, visitante, gm, gv)."""
    if dados:
        raw = json.loads(Path(dados).read_text(encoding="utf-8"))
    else:
        with urllib.request.urlopen(URL, timeout=30) as r:
            raw = json.load(r)
    jogos = []
    for m in raw["matches"]:
        ft = (m.get("score") or {}).get("ft")
        if ft:
            jogos.append((m["date"], m["team1"], m["team2"], ft[0], ft[1]))
    return sorted(jogos)


def clubes(jogos):
    return sorted({j[1] for j in jogos} | {j[2] for j in jogos})


def clube_de(matricula, jogos):
    digitos = re.sub(r"\D", "", str(matricula))
    if not digitos:
        raise ValueError(f"matricula sem digitos: {matricula!r}")
    lista = clubes(jogos)
    return lista[int(digitos) % len(lista)]


def partidas(clube, jogos):
    """Jogos do clube, em ordem cronologica, na otica do clube."""
    out = []
    for data, a, b, ga, gb in jogos:
        if clube not in (a, b):
            continue
        casa = a == clube
        gp, gc = (ga, gb) if casa else (gb, ga)
        pts = 3 if gp > gc else 1 if gp == gc else 0
        out.append({"data": data, "casa": casa, "gp": gp, "gc": gc, "pts": pts,
                    "adv": b if casa else a})
    return out

# ------------------------------------------------------- checagens (itens)

class Item:
    def __init__(self, grupo, nome, ok, pontos, dica=""):
        self.grupo, self.nome, self.ok, self.pontos, self.dica = grupo, nome, ok, pontos, dica


def ler_texto(pasta, nome):
    f = pasta / nome
    return f.read_text(encoding="utf-8", errors="replace").lower() if f.is_file() else None


def tem_secoes(texto, secoes):
    return [(s, texto is not None and any(t in texto for t in termos)) for s, termos in secoes]


def inteiro_pos(v):
    return isinstance(v, int) and not isinstance(v, bool) and v > 0


def texto_ok(v):
    return isinstance(v, str) and v.strip() != ""


def tipo_resposta(chave, v):
    if chave in ("melhor_mes", "adversario_mais_gols_marcados"):
        return isinstance(v, str)
    if chave == "media_gols_por_jogo":
        return isinstance(v, (int, float)) and not isinstance(v, bool)
    return isinstance(v, int) and not isinstance(v, bool)


def checar(pasta, disc, jogos):
    """Checagens de formato/estrutura. Devolve (entrega, itens, clube_esperado).

    Os itens carregam os pontos de cada checagem (usados pela correcao privada).
    As respostas aparecem aqui so como "presente e do tipo certo" (0 ponto).
    """
    itens = []
    arq = pasta / "entrega.json"
    try:
        e = json.loads(arq.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None, [Item("estrutura", "entrega.json existe", False, 0, "crie a partir do modelo")], None
    except json.JSONDecodeError as ex:
        return None, [Item("estrutura", "entrega.json e um JSON valido", False, 0, str(ex))], None

    ints = e.get("integrantes")
    ok_int = (isinstance(ints, list) and 1 <= len(ints) <= 3 and
              all(isinstance(i, dict) and texto_ok(i.get("matricula")) and texto_ok(i.get("nome"))
                  for i in ints))
    itens.append(Item("identificacao", "integrantes (1 a 3, com matricula e nome)", ok_int, 0))
    itens.append(Item("identificacao", f'disciplina = "{disc}"', e.get("disciplina") == disc, 0))
    clube = None
    if ok_int:
        clube = clube_de(ints[0]["matricula"], jogos)
        itens.append(Item("identificacao", f"clube = {clube} (matricula do 1o integrante)",
                          e.get("clube") == clube, 0, "rode: trabalho.py clube <matricula>"))

    resp = e.get("respostas") if isinstance(e.get("respostas"), dict) else {}
    for chave in CHAVES[disc]:
        v = resp.get(chave)
        itens.append(Item("respostas", f"{chave} (presente e do tipo certo)",
                          v is not None and tipo_resposta(chave, v), 0))

    readme = ler_texto(pasta, "README.md")
    itens.append(Item("estrutura", "README.md existe", readme is not None, 0))

    if disc == "gdbd":
        ids = e.get("athena_query_ids")
        itens.append(Item("evidencias", "3+ athena_query_ids (UUID)",
                          isinstance(ids, list) and len(ids) >= 3 and all(isinstance(i, str) and UUID.match(i) for i in ids), 0.3))
        bc, bp = e.get("bytes_csv"), e.get("bytes_parquet_particionado")
        itens.append(Item("evidencias", "bytes_parquet_particionado < bytes_csv (ambos > 0)",
                          inteiro_pos(bc) and inteiro_pos(bp) and bp < bc, 0.3,
                          "use o 'Data scanned' do Athena para a MESMA consulta"))
        for s, ok in tem_secoes(readme, [("README: Arquitetura", ["arquitetura"]),
                                         ("README: Decisoes", ["decis"]),
                                         ("README: Comparacao CSV x Parquet", ["csv x parquet", "csv vs parquet", "csv e parquet", "csv versus parquet"]),
                                         ("README: Limpeza", ["limpeza"])]):
            itens.append(Item("estrutura", s, ok, 0.2))
        sql = ler_texto(pasta, "consultas.sql")
        itens.append(Item("estrutura", "consultas.sql existe", sql is not None, 0))
        for nome, termos in [("consultas.sql usa Parquet", ["parquet"]),
                             ("consultas.sql particiona (partitioned_by)", ["partitioned_by"]),
                             ("consultas.sql usa funcao de janela (OVER)", [" over ", " over("])]:
            itens.append(Item("estrutura", nome, sql is not None and any(t in sql for t in termos), 0.2))
    else:  # pdn
        n = e.get("eventos_no_s3")
        njogos = len(partidas(clube, jogos)) if clube else None
        itens.append(Item("streaming", "eventos_no_s3 = numero de jogos do clube",
                          njogos is not None and n == njogos, 0.6))
        itens.append(Item("streaming", "firehose_buffer_segundos informado (> 0)",
                          inteiro_pos(e.get("firehose_buffer_segundos")), 0.4))
        adr = ler_texto(pasta, "adr.md")
        itens.append(Item("estrutura", "adr.md existe", adr is not None, 0))
        for s, ok in tem_secoes(adr, [("adr.md: Contexto", ["contexto"]),
                                      ("adr.md: Alternativas", ["alternativ"]),
                                      ("adr.md: Custo", ["custo"]),
                                      ("adr.md: Decisao", ["decis"])]):
            itens.append(Item("estrutura", s, ok, 0.2))
        job = ler_texto(pasta, "job.py")
        itens.append(Item("estrutura", "job.py (PySpark) usa SparkSession",
                          job is not None and "sparksession" in job, 0.2))
        itens.append(Item("evidencias", "emr_application_id e emr_job_run_id informados",
                          texto_ok(e.get("emr_application_id")) and texto_ok(e.get("emr_job_run_id")), 0.5))
        c = e.get("custo") if isinstance(e.get("custo"), dict) else {}
        itens.append(Item("evidencias", "custo: 2 alternativas com usd_mes > 0 e escolhida",
                          all(isinstance(c.get(k), (int, float)) and c.get(k) > 0 for k in ("alternativa_a_usd_mes", "alternativa_b_usd_mes"))
                          and c.get("escolhida") in ("a", "b"), 0.5))
        b = (e.get("bonus") or {}).get("sagemaker") if isinstance(e.get("bonus"), dict) else None
        itens.append(Item("bonus", "SageMaker (opcional): treino informado e endpoint removido",
                          isinstance(b, dict) and texto_ok(b.get("training_job")) and b.get("endpoint_removido") is True, 1.0))
    return e, itens, clube

# ------------------------------------------------------------------ CLI

def cmd_clube(a):
    print(clube_de(a.matricula, carregar(a.dados)))


def cmd_validar(a):
    _, itens, _ = checar(Path(a.pasta), a.disciplina, carregar(a.dados))
    falhas = 0
    for it in itens:
        if it.grupo == "bonus":
            print(f"  [opcional] {'OK ' if it.ok else '-- '} {it.nome}")
            continue
        print(f"  [{'OK' if it.ok else 'FALTA'}] {it.nome}" + (f"  ({it.dica})" if (not it.ok and it.dica) else ""))
        falhas += 0 if it.ok else 1
    print("\nEstrutura e formato conferidos. Isto NAO diz se as respostas estao certas." if not falhas
          else f"\n{falhas} item(ns) para corrigir antes de entregar.")
    sys.exit(1 if falhas else 0)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--dados", help="JSON local (offline) em vez da URL do repo de dados")
    sub = ap.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("clube"); s.add_argument("matricula"); s.set_defaults(f=cmd_clube)
    s = sub.add_parser("validar"); s.add_argument("pasta")
    s.add_argument("--disciplina", choices=CHAVES, required=True); s.set_defaults(f=cmd_validar)
    a = ap.parse_args()
    try:
        a.f(a)
    except (OSError, ValueError, KeyError) as ex:
        sys.exit(f"erro: {ex}")


if __name__ == "__main__":
    main()
