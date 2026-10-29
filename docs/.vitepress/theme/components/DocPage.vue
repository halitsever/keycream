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
  <div class="container doc">
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
  display: grid;
  grid-template-columns: 220px minmax(0, 1fr);
  gap: 4rem;
  padding-top: 3.5rem;
  padding-bottom: 2rem;
}

.sidebar {
  position: sticky;
  top: calc(var(--header-height) + 2rem);
  align-self: start;
}

.menu-toggle {
  display: none;
}

.group + .group {
  margin-top: 1.75rem;
}

.group-title {
  margin: 0 0 0.5rem;
  font-size: 0.9rem;
  font-weight: 650;
  color: var(--text-muted);
}

.group ul {
  list-style: none;
  margin: 0;
  padding: 0;
}

.group a {
  display: block;
  margin-left: -0.75rem;
  padding: 0.35rem 0.75rem;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 540;
}

.group a:hover {
  background: var(--surface);
}

.group a.active {
  background: var(--surface);
  color: var(--accent);
  font-weight: 650;
}

.article {
  min-width: 0;
}

.article-footer {
  max-width: var(--measure);
  margin-top: 4rem;
  padding-top: 1.5rem;
  border-top: 1px solid var(--rule);
}

.edit {
  color: var(--text-muted);
  font-size: 0.95rem;
  text-underline-offset: 3px;
}

.pager {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-top: 1.5rem;
}

.pager-link {
  display: grid;
  gap: 0.2rem;
  padding: 1rem 1.15rem;
  border-radius: 12px;
  box-shadow: inset 0 0 0 1.5px var(--rule);
  text-decoration: none;
  font-weight: 650;
}

.pager-link:hover {
  box-shadow: inset 0 0 0 1.5px var(--accent);
}

.pager-link.next {
  grid-column: 2;
  text-align: right;
}

.pager-label {
  font-size: 0.85rem;
  font-weight: 500;
  color: var(--text-muted);
}

@media (max-width: 860px) {
  .doc {
    grid-template-columns: minmax(0, 1fr);
    gap: 1.5rem;
    padding-top: 1.5rem;
  }

  .sidebar {
    position: static;
  }

  .menu-toggle {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    padding: 0.75rem 1rem;
    border: 0;
    border-radius: 12px;
    background: var(--surface);
    font-weight: 620;
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
    padding: 1.25rem 0.75rem 0.5rem;
  }

  .menu.open {
    display: block;
  }
}
</style>
