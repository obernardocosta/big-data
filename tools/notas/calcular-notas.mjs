#!/usr/bin/env node
/**
 * calcular-notas.mjs — cálculo de notas das disciplinas de Big Data (GDBD/PDN).
 *
 * A avaliação é SEM quiz (decisão registrada no steering). A nota final é a
 * média ponderada de três componentes lançados num CSV versionado:
 *
 *   - presenca:     % de presença (0 a 100)
 *   - participacao: nota de participação nos labs (0 a 10)
 *   - trabalho:     nota do trabalho / entrega final (0 a 10)
 *
 * Todos os componentes são normalizados para a escala 0–10 antes de ponderar
 * (a presença, que vem em %, é dividida por 10). A soma dos pesos deve dar 1.
 *
 * Uso:
 *   node tools/notas/calcular-notas.mjs [caminho-do-csv]
 *   npm run notas -- [caminho-do-csv]
 *
 * Sem argumento, usa a planilha de exemplo da GDBD.
 */

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const RAIZ = resolve(__dirname, "..", "..");

// --- Configuração dos pesos (soma = 1) -------------------------------------
const PESOS = {
  presenca: 0.2, // 20%
  participacao: 0.3, // 30%
  trabalho: 0.5, // 50%
};

const MEDIA_APROVACAO = 6.0;

// --- Utilidades ------------------------------------------------------------

/** Lê um CSV simples (sem aspas/escapes) em array de objetos. */
function lerCsv(caminho) {
  const texto = readFileSync(caminho, "utf8").replace(/^\uFEFF/, "");
  const linhas = texto
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l.length > 0 && !l.startsWith("#"));

  if (linhas.length < 2) {
    throw new Error(
      "CSV sem dados: é preciso ao menos o cabeçalho e uma linha de aluno.",
    );
  }

  const cabecalho = linhas[0].split(",").map((c) => c.trim());
  const obrigatorias = [
    "matricula",
    "nome",
    "presenca",
    "participacao",
    "trabalho",
  ];
  for (const col of obrigatorias) {
    if (!cabecalho.includes(col)) {
      throw new Error(`Coluna obrigatória ausente no CSV: "${col}".`);
    }
  }

  return linhas.slice(1).map((linha, i) => {
    const valores = linha.split(",");
    if (valores.length !== cabecalho.length) {
      throw new Error(
        `Linha ${i + 2} tem ${valores.length} campos, esperado ${cabecalho.length}.`,
      );
    }
    const registro = {};
    cabecalho.forEach((col, idx) => {
      registro[col] = valores[idx].trim();
    });
    return registro;
  });
}

/** Converte string numérica (aceita vírgula decimal) em número validado. */
function numero(valor, { campo, linha, min, max }) {
  const n = Number(String(valor).replace(",", "."));
  if (!Number.isFinite(n)) {
    throw new Error(`Valor inválido em "${campo}" (linha ${linha}): "${valor}".`);
  }
  if (n < min || n > max) {
    throw new Error(
      `Valor fora da faixa em "${campo}" (linha ${linha}): ${n} (esperado ${min}–${max}).`,
    );
  }
  return n;
}

/** Calcula a nota final de um aluno (escala 0–10). */
function calcularNota(registro, linha) {
  const presenca = numero(registro.presenca, {
    campo: "presenca",
    linha,
    min: 0,
    max: 100,
  });
  const participacao = numero(registro.participacao, {
    campo: "participacao",
    linha,
    min: 0,
    max: 10,
  });
  const trabalho = numero(registro.trabalho, {
    campo: "trabalho",
    linha,
    min: 0,
    max: 10,
  });

  const presencaEscala10 = presenca / 10;
  const final =
    presencaEscala10 * PESOS.presenca +
    participacao * PESOS.participacao +
    trabalho * PESOS.trabalho;

  return {
    matricula: registro.matricula,
    nome: registro.nome,
    presenca,
    participacao,
    trabalho,
    final: Math.round(final * 100) / 100,
  };
}

/** Formata a tabela de resultados para o terminal. */
function imprimirTabela(resultados) {
  const larguraNome = Math.max(
    4,
    ...resultados.map((r) => r.nome.length),
  );
  const cab = [
    "Matrícula".padEnd(10),
    "Nome".padEnd(larguraNome),
    "Pres.%".padStart(7),
    "Partic.".padStart(8),
    "Trab.".padStart(7),
    "Final".padStart(7),
    "Situação".padStart(10),
  ].join("  ");
  console.log(cab);
  console.log("-".repeat(cab.length));

  for (const r of resultados) {
    const situacao = r.final >= MEDIA_APROVACAO ? "Aprovado" : "Reprovado";
    console.log(
      [
        String(r.matricula).padEnd(10),
        r.nome.padEnd(larguraNome),
        r.presenca.toFixed(1).padStart(7),
        r.participacao.toFixed(1).padStart(8),
        r.trabalho.toFixed(1).padStart(7),
        r.final.toFixed(2).padStart(7),
        situacao.padStart(10),
      ].join("  "),
    );
  }
}

// --- Programa principal ----------------------------------------------------

function main() {
  const pesoTotal = PESOS.presenca + PESOS.participacao + PESOS.trabalho;
  if (Math.abs(pesoTotal - 1) > 1e-9) {
    console.error(
      `Erro de configuração: os pesos somam ${pesoTotal}, deveriam somar 1.`,
    );
    process.exit(1);
  }

  const argCsv = process.argv[2];
  const caminhoCsv = argCsv
    ? resolve(process.cwd(), argCsv)
    : resolve(RAIZ, "disciplinas/gdbd/avaliacao/notas/turma-exemplo.csv");

  let registros;
  try {
    registros = lerCsv(caminhoCsv);
  } catch (err) {
    console.error(`Erro ao ler o CSV (${caminhoCsv}):\n  ${err.message}`);
    process.exit(1);
  }

  let resultados;
  try {
    resultados = registros.map((r, i) => calcularNota(r, i + 2));
  } catch (err) {
    console.error(`Erro ao calcular notas:\n  ${err.message}`);
    process.exit(1);
  }

  console.log(`Planilha: ${caminhoCsv}`);
  console.log(
    `Pesos: presença ${PESOS.presenca * 100}% | participação ${
      PESOS.participacao * 100
    }% | trabalho ${PESOS.trabalho * 100}%`,
  );
  console.log(`Média para aprovação: ${MEDIA_APROVACAO.toFixed(1)}\n`);

  imprimirTabela(resultados);

  const aprovados = resultados.filter((r) => r.final >= MEDIA_APROVACAO).length;
  const mediaTurma =
    resultados.reduce((s, r) => s + r.final, 0) / resultados.length;

  console.log(
    `\nTotal: ${resultados.length} aluno(s) | Aprovados: ${aprovados} | ` +
      `Reprovados: ${resultados.length - aprovados} | ` +
      `Média da turma: ${mediaTurma.toFixed(2)}`,
  );
}

main();
