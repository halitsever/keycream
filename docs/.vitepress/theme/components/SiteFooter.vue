<script setup lang="ts">
import { useData, withBase } from 'vitepress'
import type { ThemeConfig } from '../types'

const { theme } = useData<ThemeConfig>()
const repoUrl = `https://github.com/${theme.value.repo}`
</script>

<template>
  <footer class="site-footer">
    <div class="container footer-inner">
      <div class="about">
        <img :src="withBase('/app-icon.png')" alt="" width="44" height="44" />
        <p>
          KeyCream is free and open source under the <a :href="`${repoUrl}/blob/main/LICENSE`">MIT License</a>.
          Sound packs come from <a href="https://github.com/hainguyents13/mechvibes">Mechvibes</a>.
        </p>
      </div>
      <nav class="links" aria-label="Footer">
        <a :href="withBase('/guide/installation')">Docs</a>
        <a :href="withBase('/guide/privacy')">Privacy</a>
        <a :href="`${repoUrl}/releases`">Releases</a>
        <a :href="repoUrl">GitHub</a>
      </nav>
    </div>
  </footer>
</template>

<style scoped>
.site-footer {
  margin-top: clamp(5rem, 10vw, 8rem);
  border-top: 1px solid var(--rule);
}

.footer-inner {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1.5rem 3rem;
  padding-top: 2.25rem;
  padding-bottom: 2.75rem;
}

.about {
  display: flex;
  align-items: center;
  gap: 1rem;
  max-width: 34rem;
}

.about img {
  flex: none;
}

.about p {
  margin: 0;
  color: var(--text-muted);
  font-size: 0.95rem;
}

.about a {
  color: var(--text);
  text-underline-offset: 3px;
}

.links {
  display: flex;
  gap: 1.5rem;
}

.links a {
  font-weight: 560;
  text-decoration: none;
  color: var(--text-muted);
}

.links a:hover {
  color: var(--text);
}
</style>
