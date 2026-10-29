<script setup lang="ts">
// Link fixo para voltar ao sumário (página inicial do Pages).
// O base do deck em produção é algo como "/big-data/gdbd/"; o sumário fica um
// nível acima ("/big-data/"). Em dev local o base é "/", e o link vai para "/".
const base = import.meta.env.BASE_URL || '/'
// remove a barra final, tira o último segmento (o nome do deck) e recoloca a barra
const home = base.replace(/\/$/, '').split('/').slice(0, -1).join('/') + '/'
</script>

<template>
  <a
    class="voltar-inicio"
    :href="home || '/'"
    title="Voltar ao sumário"
    aria-label="Voltar ao sumário"
  >
    ⌂ Início
  </a>
</template>

<style scoped>
.voltar-inicio {
  position: fixed;
  top: 0.5rem;
  right: 0.6rem;
  z-index: 1000;
  font-size: 0.72rem;
  padding: 0.15rem 0.55rem;
  border-radius: 999px;
  color: #64748b;
  text-decoration: none;
  border: 1px solid rgba(100, 116, 139, 0.35);
  background: rgba(15, 23, 42, 0.45);
  opacity: 0.5;
  pointer-events: auto;
  transition: opacity 0.15s ease, color 0.15s ease, border-color 0.15s ease;
}
.voltar-inicio:hover {
  opacity: 1;
  color: #38bdf8;
  border-color: #38bdf8;
}
/* não aparece na impressão/export PDF */
@media print {
  .voltar-inicio { display: none; }
}
</style>
