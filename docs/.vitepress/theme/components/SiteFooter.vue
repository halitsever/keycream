<script setup lang="ts">
import { useData, withBase } from 'vitepress'
import type { ThemeConfig } from '../types'
import LogoMark from './LogoMark.vue'

const { theme } = useData<ThemeConfig>()
const repoUrl = `https://github.com/${theme.value.repo}`
</script>

<template>
  <footer class="site-footer">
    <div class="wrap foot-row">
      <a class="foot-brand" :href="withBase('/')">
        <LogoMark />
        KeyCream
      </a>
      <p class="license">
        MIT. Sound packs from <a href="https://github.com/hainguyents13/mechvibes">Mechvibes</a>, under their own licenses.
      </p>
      <nav class="links" aria-label="Footer">
        <a :href="withBase('/guide/installation')">Docs</a>
        <a :href="withBase('/guide/privacy')">Privacy</a>
        <a :href="`${repoUrl}/releases`">Releases</a>
        <a :href="`${repoUrl}/issues`">Issues</a>
        <a :href="repoUrl">GitHub</a>
      </nav>
    </div>
  </footer>
</template>

<style scoped>
.site-footer {
  margin-top: 200px;
  padding: 28px 0 40px;
  border-top: 1px solid var(--line);
}

.foot-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 16px 28px;
  font-size: 0.88rem;
  color: var(--faint);
}

.foot-brand {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 1rem;
  font-weight: 680;
  letter-spacing: -0.02em;
  color: var(--text);
}

.foot-brand :deep(.logo-mark) {
  width: 20px;
  height: 20px;
}

.license {
  margin-right: auto;
}

.license a,
.links a {
  transition: color 0.2s;
}

.license a:hover,
.links a:hover {
  color: var(--text);
}

.license a {
  text-decoration: underline;
  text-underline-offset: 3px;
}

.links {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 20px;
}

@media (max-width: 900px) {
  .site-footer {
    margin-top: 140px;
  }
}
</style>
