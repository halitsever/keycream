<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useData, useRoute, withBase } from 'vitepress'
import type { ThemeConfig } from '../types'
import DownloadButton from './DownloadButton.vue'
import LogoMark from './LogoMark.vue'

const { theme, frontmatter } = useData<ThemeConfig>()
const route = useRoute()
const section = ref('')
let frame = 0

const href = (link: string) => withBase(link)
const anchorOf = (link: string) => link.split('#')[1] ?? ''

function isOn(link: string) {
  const anchor = anchorOf(link)
  if (anchor) return frontmatter.value.layout === 'home' && section.value === anchor
  return route.path.includes('/guide/')
}

/** The section crossing the upper third of the screen counts as the one being read. */
function update() {
  frame = 0
  if (frontmatter.value.layout !== 'home') return
  const line = window.innerHeight * 0.35
  section.value = ''
  for (const item of theme.value.nav) {
    const anchor = anchorOf(item.link)
    const rect = anchor ? document.getElementById(anchor)?.getBoundingClientRect() : undefined
    if (rect && rect.top <= line && rect.bottom > line) section.value = anchor
  }
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

watch(() => route.path, () => requestAnimationFrame(update))
</script>

<template>
  <header class="site-header">
    <nav class="nav" aria-label="Main">
      <a class="brand" :href="withBase('/')" aria-label="KeyCream home">
        <LogoMark />
        <span>KeyCream</span>
      </a>
      <a
        v-for="item in theme.nav"
        :key="item.link"
        class="l"
        :class="{ on: isOn(item.link), docs: !anchorOf(item.link) }"
        :href="href(item.link)"
      >{{ item.text }}</a>
      <a class="gh" :href="`https://github.com/${theme.repo}`" aria-label="KeyCream on GitHub">
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="currentColor"
            d="M12 2.2a10 10 0 0 0-3.16 19.49c.5.09.68-.22.68-.48v-1.7c-2.78.6-3.37-1.34-3.37-1.34-.45-1.16-1.11-1.47-1.11-1.47-.91-.62.07-.6.07-.6 1 .07 1.53 1.03 1.53 1.03.9 1.52 2.34 1.08 2.91.83.09-.65.35-1.09.63-1.34-2.22-.25-4.55-1.11-4.55-4.94 0-1.09.39-1.98 1.03-2.68-.1-.25-.45-1.27.1-2.64 0 0 .84-.27 2.75 1.02a9.5 9.5 0 0 1 5 0c1.91-1.29 2.75-1.02 2.75-1.02.55 1.37.2 2.39.1 2.64.64.7 1.03 1.59 1.03 2.68 0 3.84-2.34 4.68-4.57 4.93.36.31.68.92.68 1.85v2.74c0 .27.18.58.69.48A10 10 0 0 0 12 2.2z"
          />
        </svg>
      </a>
      <DownloadButton compact />
    </nav>
  </header>
</template>

<style scoped>
.site-header {
  position: fixed;
  top: 18px;
  left: 0;
  right: 0;
  z-index: 80;
  display: flex;
  justify-content: center;
  padding: 0 12px;
  pointer-events: none;
}

.nav {
  display: flex;
  align-items: center;
  gap: 2px;
  max-width: 100%;
  padding: 6px 6px 6px 14px;
  border-radius: 999px;
  font-size: 0.9rem;
  background: rgba(31, 23, 18, 0.66);
  backdrop-filter: blur(18px) saturate(1.4);
  -webkit-backdrop-filter: blur(18px) saturate(1.4);
  box-shadow:
    0 0 0 1px var(--line),
    0 10px 40px rgba(0, 0, 0, 0.4);
  pointer-events: auto;
}

.brand {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-right: 10px;
  font-size: 1.05rem;
  font-weight: 680;
  letter-spacing: -0.02em;
  white-space: nowrap;
}

.brand :deep(.logo-mark) {
  width: 22px;
  height: 22px;
}

.l {
  padding: 8px 13px;
  border-radius: 999px;
  white-space: nowrap;
  color: var(--dim);
  transition: color 0.2s, background-color 0.2s;
}

.l:hover,
.l.on {
  color: var(--text);
  background: rgba(244, 235, 217, 0.08);
}

.gh {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  margin-left: 4px;
  border-radius: 999px;
  color: var(--dim);
  transition: color 0.2s, background-color 0.2s;
}

.gh:hover {
  color: var(--text);
  background: rgba(244, 235, 217, 0.08);
}

.gh svg {
  width: 19px;
  height: 19px;
}

@media (max-width: 900px) {
  .l:not(.docs) {
    display: none;
  }
}

@media (max-width: 380px) {
  .brand span {
    display: none;
  }
}
</style>
