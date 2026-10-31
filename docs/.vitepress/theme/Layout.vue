<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useData } from 'vitepress'
import DocPage from './components/DocPage.vue'
import HomePage from './components/HomePage.vue'
import NotFound from './components/NotFound.vue'
import SiteFooter from './components/SiteFooter.vue'
import SiteHeader from './components/SiteHeader.vue'

const { page, frontmatter } = useData()
const progress = ref<HTMLElement | null>(null)
let frame = 0

function update() {
  frame = 0
  const max = document.documentElement.scrollHeight - window.innerHeight
  if (progress.value) progress.value.style.transform = `scaleX(${max > 0 ? window.scrollY / max : 0})`
}

function onScroll() {
  frame ||= requestAnimationFrame(update)
}

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  update()
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
  cancelAnimationFrame(frame)
})
</script>

<template>
  <div class="grain" aria-hidden="true"></div>
  <div ref="progress" class="progress" aria-hidden="true"></div>
  <a class="skip-link" href="#main">Skip to content</a>
  <SiteHeader />
  <main id="main">
    <NotFound v-if="page.isNotFound" />
    <HomePage v-else-if="frontmatter.layout === 'home'" />
    <DocPage v-else />
  </main>
  <SiteFooter />
</template>

<style>
.progress {
  position: fixed;
  top: 0;
  left: 0;
  z-index: 95;
  width: 100%;
  height: 2px;
  transform: scaleX(0);
  transform-origin: 0 50%;
  background: linear-gradient(90deg, var(--zinc-500), var(--zinc-50));
}

.skip-link {
  position: absolute;
  top: -100px;
  left: 1rem;
  z-index: 100;
  padding: 0.6rem 1rem;
  border-radius: 10px;
  background: var(--zinc-50);
  color: var(--zinc-900);
  font-weight: 650;
}

.skip-link:focus {
  top: 0.75rem;
}
</style>
