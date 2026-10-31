<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'
import type { ThemeConfig } from '../types'
import { formatSize, useLatestRelease } from '../composables/useLatestRelease'

const props = withDefaults(defineProps<{ compact?: boolean }>(), { compact: false })

const { theme } = useData<ThemeConfig>()
const { release, state, releasesPage } = useLatestRelease(theme.value.repo)

const href = computed(() => release.value?.downloadUrl ?? releasesPage)
const details = computed(() => {
  if (state.value === 'ready' && release.value) {
    return `Version ${release.value.version}, ${formatSize(release.value.sizeBytes)}. macOS 14 or later, Apple Silicon and Intel.`
  }
  if (state.value === 'unavailable') return 'Opens the latest release on GitHub. macOS 14 or later.'
  return 'macOS 14 or later, Apple Silicon and Intel.'
})
</script>

<template>
  <a v-if="props.compact" class="dl-compact" :href="href">Download</a>
  <div v-else class="download">
    <a class="btn btn-primary" :href="href">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M12 4v11m0 0l-4.5-4.5M12 15l4.5-4.5M5 20h14" />
      </svg>
      Download for Mac
    </a>
    <slot />
    <p class="details" aria-live="polite">{{ details }}</p>
  </div>
</template>

<style scoped>
.download {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
}

.details {
  flex-basis: 100%;
  margin-top: 12px;
  font-size: 0.88rem;
  color: var(--faint);
}

.dl-compact {
  display: inline-flex;
  align-items: center;
  height: 36px;
  margin-left: 4px;
  padding: 0 16px;
  border-radius: 999px;
  font-weight: 620;
  white-space: nowrap;
  color: var(--espresso);
  background: var(--cream);
  transition: background-color 0.2s;
}

.dl-compact:hover {
  background: #fff6e6;
}
</style>
