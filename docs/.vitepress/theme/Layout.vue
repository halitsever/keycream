<script setup lang="ts">
import { useData } from 'vitepress'
import DocPage from './components/DocPage.vue'
import HomePage from './components/HomePage.vue'
import NotFound from './components/NotFound.vue'
import SiteFooter from './components/SiteFooter.vue'
import SiteHeader from './components/SiteHeader.vue'

const { page, frontmatter } = useData()
</script>

<template>
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
.skip-link {
  position: absolute;
  top: -100px;
  left: 1rem;
  z-index: 50;
  padding: 0.6rem 1rem;
  border-radius: 10px;
  background: var(--button-bg);
  color: var(--button-text);
  font-weight: 650;
  text-decoration: none;
}

.skip-link:focus {
  top: 0.75rem;
}
</style>
