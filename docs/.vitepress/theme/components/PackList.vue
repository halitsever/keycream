<script setup lang="ts">
import { onBeforeUnmount } from 'vue'
import { withBase } from 'vitepress'
import { type SwitchFeel, packs } from '../data/packs'
import { useSamples } from '../composables/useSamples'

const { playing, toggle, stop } = useSamples()

/** Force curves, drawn the way switch makers chart them: travel to the right, force upward. */
const curves: Record<SwitchFeel, string> = {
  Linear: 'M3 19 L41 5',
  Tactile: 'M3 19 L10 9 Q13 5.5 16 9.5 L19 13 L41 5',
  Clicky: 'M3 19 L10 6.5 L12.5 14.5 L41 5',
}

onBeforeUnmount(stop)
</script>

<template>
  <ul class="packs">
    <li v-for="pack in packs" :key="pack.id">
      <button
        class="sw"
        :class="{ on: playing === pack.id }"
        type="button"
        :aria-pressed="playing === pack.id"
        :aria-label="`${playing === pack.id ? 'Stop' : 'Listen to'} ${pack.name}`"
        @click="toggle(pack.id)"
      >
        <span class="art">
          <svg class="switch" viewBox="0 0 120 120" aria-hidden="true">
            <rect x="15" y="19" width="90" height="90" rx="14" fill="rgba(0,0,0,.45)" />
            <rect x="11" y="42" width="8" height="20" rx="2.5" :fill="pack.housing" />
            <rect x="101" y="42" width="8" height="20" rx="2.5" :fill="pack.housing" />
            <rect x="15" y="14" width="90" height="90" rx="14" :fill="pack.housing" :fill-opacity="pack.clear ? 0.7 : 1" />
            <path d="M29 14h62a14 14 0 0 1 14 14v8H15v-8a14 14 0 0 1 14-14z" fill="#fff" fill-opacity=".08" />
            <rect x="48" y="21" width="24" height="9" rx="2.5" fill="rgba(0,0,0,.35)" />
            <circle cx="60" cy="61" r="27" fill="rgba(0,0,0,.3)" />
            <rect x="43" y="47" width="34" height="30" rx="6" :fill="pack.stem" />
            <rect x="43" y="47" width="34" height="30" rx="6" fill="#000" fill-opacity=".16" />
            <rect x="48" y="57.5" width="24" height="7" rx="1.5" :fill="pack.stem" />
            <rect x="56.5" y="49" width="7" height="24" rx="1.5" :fill="pack.stem" />
            <rect x="48" y="57.5" width="24" height="2" rx="1" fill="#fff" fill-opacity=".25" />
          </svg>
          <span class="badge" aria-hidden="true">
            <svg v-if="playing === pack.id" viewBox="0 0 24 24"><rect x="7" y="7" width="10" height="10" rx="2" /></svg>
            <svg v-else viewBox="0 0 24 24"><path d="M9 6.6v10.8a.9.9 0 0 0 1.37.77l8.7-5.4a.9.9 0 0 0 0-1.54l-8.7-5.4A.9.9 0 0 0 9 6.6z" /></svg>
          </span>
          <span v-if="playing === pack.id" class="eq" aria-hidden="true"><i></i><i></i><i></i><i></i></span>
        </span>
        <span class="name">{{ pack.name }}</span>
        <span class="feel">
          <svg viewBox="0 0 44 22" aria-hidden="true"><path :d="curves[pack.feel]" /></svg>
          {{ pack.feel }}
        </span>
        <span class="summary">{{ pack.summary }}</span>
      </button>
    </li>
    <li>
      <a class="sw add" :href="withBase('/guide/sound-packs#adding-your-own-pack')">
        <span class="art plus" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M12 5v14M5 12h14" /></svg>
        </span>
        <span class="name">Your own pack</span>
        <span class="summary">KeyCream reads the Mechvibes format. The guide shows how to add one.</span>
      </a>
    </li>
  </ul>
</template>

<style scoped>
.packs {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.packs li {
  display: flex;
}

.sw {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 100%;
  padding: 8px 8px 20px;
  border: 0;
  border-radius: 20px;
  text-align: left;
  background: rgba(255, 255, 255, 0.03);
  box-shadow: inset 0 0 0 1px var(--line);
  cursor: pointer;
  transition: transform 0.25s ease, box-shadow 0.25s ease, background-color 0.25s ease;
}

.sw:hover {
  transform: translateY(-3px);
  background: rgba(255, 255, 255, 0.05);
}

.sw.on {
  background: rgba(255, 255, 255, 0.06);
  box-shadow:
    inset 0 0 0 2px var(--zinc-50),
    0 14px 40px rgba(255, 255, 255, 0.06);
}

.art {
  position: relative;
  display: grid;
  place-items: center;
  width: 100%;
  aspect-ratio: 5 / 4;
  margin-bottom: 16px;
  border-radius: 14px;
  background:
    radial-gradient(60% 60% at 50% 45%, rgba(255, 255, 255, 0.07), transparent 70%),
    var(--zinc-950);
  box-shadow: inset 0 2px 12px rgba(0, 0, 0, 0.6);
}

.switch {
  width: 60%;
  filter: drop-shadow(0 10px 14px rgba(0, 0, 0, 0.45));
  transition: transform 0.3s cubic-bezier(0.3, 1.4, 0.5, 1);
}

.sw:hover .switch {
  transform: translateY(-2px) rotate(-3deg);
}

.sw.on .switch {
  transform: scale(0.95);
}

.badge {
  position: absolute;
  right: 10px;
  bottom: 10px;
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.1);
  color: var(--text);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
  transition: background-color 0.2s, color 0.2s;
}

.sw:hover .badge,
.sw.on .badge {
  background: var(--zinc-50);
  color: var(--zinc-900);
}

.badge svg {
  width: 16px;
  height: 16px;
  fill: currentColor;
}

.eq {
  position: absolute;
  left: 14px;
  bottom: 14px;
  display: flex;
  align-items: flex-end;
  gap: 3px;
  height: 18px;
}

.eq i {
  width: 3px;
  height: 100%;
  border-radius: 2px;
  background: var(--zinc-50);
  transform-origin: bottom;
  animation: eq 0.8s ease-in-out infinite;
}

.eq i:nth-child(2) {
  animation-delay: -0.3s;
}

.eq i:nth-child(3) {
  animation-delay: -0.55s;
}

.eq i:nth-child(4) {
  animation-delay: -0.15s;
}

@keyframes eq {
  50% {
    transform: scaleY(0.3);
  }
}

.name {
  padding: 0 8px;
  font-size: 1.05rem;
  font-weight: 620;
  letter-spacing: -0.015em;
  line-height: 1.25;
}

.feel {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  margin: 6px 8px 0;
  font-size: 0.82rem;
  font-weight: 560;
  color: var(--accent);
}

.feel svg {
  width: 26px;
  height: 13px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.summary {
  margin-top: 8px;
  padding: 0 8px;
  font-size: 0.9rem;
  line-height: 1.5;
  color: var(--dim);
}

.add {
  background: transparent;
  box-shadow: inset 0 0 0 1px var(--line);
  outline-offset: 3px;
}

.add .art {
  background: transparent;
  box-shadow: inset 0 0 0 1.5px rgba(255, 255, 255, 0.14);
  background-image: repeating-linear-gradient(135deg, rgba(255, 255, 255, 0.04) 0 8px, transparent 8px 16px);
  color: var(--faint);
}

.add .art svg {
  width: 40px;
  height: 40px;
}

.add:hover .art {
  color: var(--text);
}

@media (max-width: 1000px) {
  .packs {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 420px) {
  .name {
    font-size: 0.95rem;
  }

  .summary {
    font-size: 0.84rem;
  }
}
</style>
