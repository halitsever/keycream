<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { withBase } from 'vitepress'
import { packs } from '../data/packs'

const playing = ref<string | null>(null)
let audio: HTMLAudioElement | null = null

function stop() {
  audio?.pause()
  audio = null
  playing.value = null
}

function toggle(id: string) {
  const wasPlaying = playing.value === id
  stop()
  if (wasPlaying) return
  audio = new Audio(withBase(`/samples/${id}.wav`))
  audio.addEventListener('ended', stop)
  playing.value = id
  audio.play().catch(stop)
}

onBeforeUnmount(stop)
</script>

<template>
  <ul class="packs">
    <li v-for="pack in packs" :key="pack.id" class="pack" :class="{ playing: playing === pack.id }">
      <button
        class="listen"
        type="button"
        :aria-pressed="playing === pack.id"
        :aria-label="`${playing === pack.id ? 'Stop' : 'Listen to'} ${pack.name}`"
        @click="toggle(pack.id)"
      >
        <svg v-if="playing === pack.id" viewBox="0 0 24 24" aria-hidden="true"><rect x="6.5" y="6.5" width="11" height="11" rx="2" /></svg>
        <svg v-else viewBox="0 0 24 24" aria-hidden="true"><path d="M8 5.8v12.4a1 1 0 0 0 1.5.86l10-6.2a1 1 0 0 0 0-1.72l-10-6.2A1 1 0 0 0 8 5.8z" /></svg>
      </button>
      <div class="text">
        <h3 class="name">{{ pack.name }}</h3>
        <p class="summary">{{ pack.summary }}</p>
      </div>
      <span class="feel" :data-feel="pack.feel">{{ pack.feel }}</span>
    </li>
  </ul>
</template>

<style scoped>
.packs {
  list-style: none;
  margin: 0;
  padding: 0;
  border-top: 1px solid var(--rule);
}

.pack {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 1.25rem;
  padding: 1.1rem 0;
  border-bottom: 1px solid var(--rule);
}

.listen {
  display: grid;
  place-items: center;
  width: 3rem;
  height: 3rem;
  border: 0;
  border-radius: 12px;
  background: var(--cream);
  color: var(--espresso);
  box-shadow: inset 0 -3px 0 var(--cream-shade);
  cursor: pointer;
  transition: transform 60ms ease, box-shadow 60ms ease;
}

.listen:active,
.playing .listen {
  transform: translateY(2px);
  box-shadow: inset 0 -1px 0 var(--cream-shade);
}

.playing .listen {
  background: var(--caramel);
}

.listen svg {
  width: 1.25rem;
  height: 1.25rem;
  fill: currentColor;
}

.name {
  font-size: 1.2rem;
  font-weight: 680;
  letter-spacing: -0.01em;
}

.summary {
  margin: 0.15rem 0 0;
  color: var(--text-muted);
}

.feel {
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--accent);
}

@media (max-width: 560px) {
  .pack {
    grid-template-columns: auto 1fr;
    gap: 0.25rem 1rem;
  }

  .feel {
    grid-column: 2;
    grid-row: 2;
  }

  .listen {
    grid-row: span 2;
  }
}
</style>
