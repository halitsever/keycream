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
    return `Version ${release.value.version}, ${formatSize(release.value.sizeBytes)}. Needs macOS 14 or later.`
  }
  if (state.value === 'unavailable') return 'Opens the latest release on GitHub. Needs macOS 14 or later.'
  return 'Needs macOS 14 or later.'
})
</script>

<template>
  <div class="download" :class="{ compact: props.compact }">
    <a class="button" :href="href">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M12 4v11m0 0l-4.5-4.5M12 15l4.5-4.5M5 20h14" />
      </svg>
      {{ props.compact ? 'Download' : 'Download for Mac' }}
    </a>
    <p v-if="!props.compact" class="details" aria-live="polite">{{ details }}</p>
  </div>
</template>

<style scoped>
.download {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.75rem;
}

.details {
  margin: 0;
  color: var(--text-muted);
  font-size: 0.95rem;
}

.compact .button {
  padding: 0.6em 1em 0.65em;
  font-size: 0.95rem;
}
</style>
