<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useData, useRoute, withBase } from 'vitepress'
import type { ThemeConfig } from '../types'

const { theme, page } = useData<ThemeConfig>()
const route = useRoute()
const menuOpen = ref(false)

const normalize = (path: string) => path.replace(/(\.html)?\/?$/, '')
const isActive = (link: string) => normalize(withBase(link)) === normalize(route.path)

const links = computed(() => theme.value.sidebar.flatMap((group) => group.items))
const index = computed(() => links.value.findIndex((item) => isActive(item.link)))
const previous = computed(() => (index.value > 0 ? links.value[index.value - 1] : null))
const next = computed(() => (index.value >= 0 && index.value < links.value.length - 1 ? links.value[index.value + 1] : null))
const current = computed(() => links.value[index.value]?.text ?? 'Contents')
const editUrl = computed(() => `https://github.com/${theme.value.repo}/edit/main/docs/${page.value.relativePath}`)

watch(() => route.path, () => (menuOpen.value = false))
</script>

<template>
  <div class="wrap doc">
    <aside class="sidebar">
      <button class="menu-toggle" type="button" :aria-expanded="menuOpen" aria-controls="doc-menu" @click="menuOpen = !menuOpen">
        <span>{{ current }}</span>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" aria-hidden="true">
          <path d="M6 9l6 6 6-6" />
        </svg>
      </button>
      <nav id="doc-menu" class="menu" :class="{ open: menuOpen }" aria-label="Documentation">
        <div v-for="group in theme.sidebar" :key="group.text" class="group">
          <p class="group-title">{{ group.text }}</p>
          <ul>
            <li v-for="item in group.items" :key="item.link">
              <a :href="withBase(item.link)" :class="{ active: isActive(item.link) }" :aria-current="isActive(item.link) ? 'page' : undefined">{{ item.text }}</a>
            </li>
          </ul>
        </div>
      </nav>
    </aside>

    <article class="article">
      <Content class="prose" />

      <footer class="article-footer">
        <a class="edit" :href="editUrl" target="_blank" rel="noopener">Edit this page on GitHub</a>
        <nav class="pager" aria-label="Pages">
          <a v-if="previous" class="pager-link" :href="withBase(previous.link)">
            <span class="pager-label">Previous</span>
            {{ previous.text }}
          </a>
          <a v-if="next" class="pager-link next" :href="withBase(next.link)">
            <span class="pager-label">Next</span>
            {{ next.text }}
          </a>
        </nav>
      </footer>
    </article>
  </div>
</template>

<style scoped>
.doc {
  position: relative;
  display: grid;
  grid-template-columns: 230px minmax(0, 1fr);
  gap: 72px;
  padding-top: 140px;
  padding-bottom: 2rem;
}

.doc::before {
  content: '';
  position: absolute;
  left: 50%;
  top: -320px;
  width: 1200px;
  height: 700px;
  transform: translateX(-50%);
  z-index: -1;
  pointer-events: none;
  background: radial-gradient(closest-side, rgba(255, 255, 255, 0.06), transparent);
}

.sidebar {
  position: sticky;
  top: 110px;
  align-self: start;
}

.menu-toggle {
  display: none;
}

.group + .group {
  margin-top: 1.9rem;
}

.group-title {
  margin: 0 0 0.6rem;
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--faint);
}

.group ul {
  display: grid;
  gap: 2px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.group a {
  display: block;
  margin-left: -0.8rem;
  padding: 0.4rem 0.8rem;
  border-radius: 10px;
  font-size: 0.97rem;
  color: var(--dim);
  transition: color 0.2s, background-color 0.2s;
}

.group a:hover {
  color: var(--text);
  background: rgba(255, 255, 255, 0.05);
}

.group a.active {
  color: var(--text);
  font-weight: 560;
  background: rgba(255, 255, 255, 0.08);
  box-shadow: inset 2px 0 0 var(--zinc-50);
}

.article {
  min-width: 0;
}

.article-footer {
  max-width: var(--measure);
  margin-top: 4.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--line);
}

.edit {
  font-size: 0.92rem;
  color: var(--faint);
  text-decoration: underline;
  text-underline-offset: 3px;
}

.edit:hover {
  color: var(--text);
}

.pager {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 1.6rem;
}

.pager-link {
  display: grid;
  gap: 0.25rem;
  padding: 1.1rem 1.25rem;
  border-radius: 18px;
  font-weight: 600;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0.015));
  box-shadow: inset 0 0 0 1px var(--line);
  transition: box-shadow 0.2s, transform 0.2s;
}

.pager-link:hover {
  transform: translateY(-2px);
  box-shadow: inset 0 0 0 1.5px var(--zinc-500);
}

.pager-link.next {
  grid-column: 2;
  text-align: right;
}

.pager-label {
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--faint);
}

@media (max-width: 900px) {
  .doc {
    grid-template-columns: minmax(0, 1fr);
    gap: 1.5rem;
    padding-top: 104px;
  }

  .sidebar {
    position: static;
  }

  .menu-toggle {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    padding: 0.85rem 1.1rem;
    border: 0;
    border-radius: 14px;
    background: rgba(255, 255, 255, 0.05);
    box-shadow: inset 0 0 0 1px var(--line);
    font-weight: 600;
    cursor: pointer;
  }

  .menu-toggle svg {
    width: 1.1rem;
    height: 1.1rem;
    transition: transform 150ms ease;
  }

  .menu-toggle[aria-expanded='true'] svg {
    transform: rotate(180deg);
  }

  .menu {
    display: none;
    padding: 1.25rem 0.9rem 0.5rem;
  }

  .menu.open {
    display: block;
  }
}
</style>
