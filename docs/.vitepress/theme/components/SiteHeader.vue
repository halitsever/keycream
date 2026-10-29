<script setup lang="ts">
import { useData, withBase } from 'vitepress'
import type { ThemeConfig } from '../types'
import DownloadButton from './DownloadButton.vue'

const { theme, isDark } = useData<ThemeConfig>()

const href = (link: string) => (link.startsWith('/') ? withBase(link) : link)
const isExternal = (link: string) => /^https?:/.test(link)
</script>

<template>
  <header class="site-header">
    <div class="container bar">
      <a class="brand" :href="withBase('/')" aria-label="KeyCream home">
        <img class="logo logo-light" :src="withBase('/keycream-logo.svg')" alt="" width="132" height="32" />
        <img class="logo logo-dark" :src="withBase('/keycream-logo-dark.svg')" alt="" width="132" height="32" />
      </a>

      <nav class="nav" aria-label="Main">
        <a
          v-for="item in theme.nav"
          :key="item.link"
          class="nav-link"
          :class="{ secondary: item.link.includes('#') }"
          :href="href(item.link)"
          :target="isExternal(item.link) ? '_blank' : undefined"
          :rel="isExternal(item.link) ? 'noopener' : undefined"
        >{{ item.text }}</a>
      </nav>

      <div class="actions">
        <button
          class="theme-toggle"
          type="button"
          :aria-label="isDark ? 'Switch to light theme' : 'Switch to dark theme'"
          :aria-pressed="isDark"
          @click="isDark = !isDark"
        >
          <svg v-if="isDark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
            <circle cx="12" cy="12" r="4.2" />
            <path d="M12 2.5v2.2M12 19.3v2.2M4.6 4.6l1.6 1.6M17.8 17.8l1.6 1.6M2.5 12h2.2M19.3 12h2.2M4.6 19.4l1.6-1.6M17.8 6.2l1.6-1.6" />
          </svg>
          <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round" aria-hidden="true">
            <path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z" />
          </svg>
        </button>
        <DownloadButton compact />
      </div>
    </div>
  </header>
</template>

<style scoped>
.site-header {
  position: sticky;
  top: 0;
  z-index: 20;
  background: color-mix(in srgb, var(--bg) 88%, transparent);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border-bottom: 1px solid var(--rule);
}

.bar {
  display: flex;
  align-items: center;
  gap: 2rem;
  height: var(--header-height);
}

.brand {
  flex: none;
}

.logo {
  height: 30px;
  width: auto;
}

.logo-dark,
.dark .logo-light {
  display: none;
}

.dark .logo-dark {
  display: block;
}

.nav {
  display: flex;
  gap: 1.5rem;
  margin-right: auto;
}

.nav-link {
  font-weight: 560;
  text-decoration: none;
  color: var(--text-muted);
}

.nav-link:hover {
  color: var(--text);
}

.actions {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}

.theme-toggle {
  display: grid;
  place-items: center;
  width: 2.4rem;
  height: 2.4rem;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
}

.theme-toggle:hover {
  color: var(--text);
  background: var(--surface);
}

.theme-toggle svg {
  width: 1.2rem;
  height: 1.2rem;
}

@media (max-width: 720px) {
  .bar {
    gap: 1rem;
  }

  .nav {
    gap: 1rem;
  }

  .nav-link.secondary {
    display: none;
  }
}

@media (max-width: 480px) {
  .logo {
    height: 24px;
  }

  .nav-link:not(:first-child) {
    display: none;
  }
}
</style>
