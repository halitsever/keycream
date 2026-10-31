<script setup lang="ts">
import { withBase } from 'vitepress'
</script>

<template>
  <section class="wrap not-found">
    <p class="caps" aria-hidden="true">
      <span>4</span><span>0</span><span>4</span>
    </p>
    <h1>This page doesn&rsquo;t exist.</h1>
    <p class="text">The link may be old, or the page has moved.</p>
    <div class="actions">
      <a class="btn btn-primary" :href="withBase('/')">Go to the home page</a>
      <a class="btn btn-ghost" :href="withBase('/guide/installation')">Open the docs</a>
    </div>
  </section>
</template>

<style scoped>
.not-found {
  position: relative;
  padding-top: 190px;
}

.not-found::before {
  content: '';
  position: absolute;
  left: 50%;
  top: -200px;
  width: 1100px;
  height: 760px;
  transform: translateX(-50%);
  pointer-events: none;
  z-index: -1;
  background: radial-gradient(closest-side, rgba(200, 135, 74, 0.24), transparent);
}

.caps {
  display: flex;
  gap: clamp(10px, 2vw, 18px);
  margin-bottom: 48px;
}

.caps span {
  display: grid;
  place-items: center;
  width: clamp(76px, 14vw, 128px);
  aspect-ratio: 1;
  border-radius: 20%;
  background: linear-gradient(180deg, #fdf8ec, #efe2c7);
  color: var(--espresso);
  font-size: clamp(2.4rem, 6vw, 4.2rem);
  font-weight: 760;
  letter-spacing: -0.04em;
  box-shadow:
    inset 0 calc(-1 * clamp(6px, 1.2vw, 10px)) 0 var(--cream-shade),
    0 clamp(6px, 1.2vw, 10px) 0 #7d6345,
    0 20px 40px rgba(0, 0, 0, 0.5);
}

.caps span:nth-child(2) {
  transform: translateY(clamp(5px, 1vw, 8px));
  box-shadow:
    inset 0 -4px 0 var(--cream-shade),
    0 3px 0 #7d6345,
    0 10px 20px rgba(0, 0, 0, 0.5);
}

h1 {
  font-size: clamp(2.2rem, 5vw, 3.8rem);
  font-weight: 760;
  font-variation-settings: 'opsz' 96;
  letter-spacing: -0.045em;
  line-height: 1;
}

.text {
  margin: 16px 0 36px;
  font-size: 1.2rem;
  color: var(--dim);
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
</style>
