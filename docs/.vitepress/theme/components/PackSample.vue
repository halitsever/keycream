<script setup lang="ts">
import { computed, onBeforeUnmount } from 'vue'
import { packs } from '../data/packs'
import { useSamples } from '../composables/useSamples'

/** A play button for one pack's typing sample, the same file as the home page's Listen buttons. */
const props = defineProps<{ id: string }>()
const pack = computed(() => packs.find((p) => p.id === props.id))
const { playing, toggle, stop } = useSamples()
onBeforeUnmount(() => playing.value === props.id && stop())
</script>

<template>
  <button v-if="pack" class="pack-sample" :class="{ on: playing === pack.id }" type="button" :aria-pressed="playing === pack.id" @click="toggle(pack.id)">
    <svg v-if="playing === pack.id" viewBox="0 0 24 24" aria-hidden="true"><rect x="7" y="7" width="10" height="10" rx="2" /></svg>
    <svg v-else viewBox="0 0 24 24" aria-hidden="true"><path d="M9 6.6v10.8a.9.9 0 0 0 1.37.77l8.7-5.4a.9.9 0 0 0 0-1.54l-8.7-5.4A.9.9 0 0 0 9 6.6z" /></svg>
    <span>{{ playing === pack.id ? 'Stop' : 'Listen to' }} {{ pack.name }}</span>
    <span class="feel">{{ pack.feel }}, KeyCream's recording</span>
  </button>
</template>

<style scoped>
.pack-sample {
  display: inline-flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.6rem;
  margin: 0.4rem 0.5rem 0.4rem 0;
  padding: 0.6rem 1rem 0.6rem 0.75rem;
  border: 0;
  border-radius: 999px;
  font: inherit;
  font-weight: 600;
  color: var(--text);
  background: rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 0 0 1px var(--line);
  cursor: pointer;
}

.pack-sample:hover,
.pack-sample.on {
  box-shadow: inset 0 0 0 1.5px var(--zinc-500);
}

.pack-sample svg {
  width: 1.4rem;
  height: 1.4rem;
  fill: currentColor;
}

.feel {
  font-size: 0.82rem;
  font-weight: 500;
  color: var(--faint);
}
</style>
