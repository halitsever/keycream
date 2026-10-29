<script setup lang="ts">
import { withBase } from 'vitepress'
</script>

<template>
  <section class="container not-found">
    <p class="code" aria-hidden="true">404</p>
    <h1>This page doesn't exist.</h1>
    <p class="text">The link may be old, or the page has moved.</p>
    <div class="actions">
      <a class="button" :href="withBase('/')">Go to the home page</a>
      <a class="button button-quiet" :href="withBase('/guide/installation')">Open the docs</a>
    </div>
  </section>
</template>

<style scoped>
.not-found {
  padding-top: clamp(4rem, 12vw, 9rem);
}

.code {
  margin: 0 0 0.5rem;
  font-size: clamp(5rem, 16vw, 10rem);
  font-weight: 800;
  line-height: 0.9;
  letter-spacing: -0.04em;
  color: var(--accent);
  font-variation-settings: 'opsz' 96;
}

h1 {
  font-size: clamp(1.8rem, 4vw, 2.6rem);
  font-weight: 760;
}

.text {
  margin: 0.75rem 0 2rem;
  color: var(--text-muted);
  font-size: 1.1rem;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
}
</style>
