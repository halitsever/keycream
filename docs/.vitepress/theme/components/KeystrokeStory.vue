<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { type KeyTrace, traceKey } from '../data/keymap'

const chapters = [
  {
    label: 'Key down',
    title: 'macOS reports a key',
    text: 'A listen-only event tap tells KeyCream that a physical key went down, as a key code. Releasing a key is silent, and the repeats macOS sends while you hold one are skipped.',
  },
  {
    label: 'Scan code',
    title: 'The key code becomes a scan code',
    text: 'KeyCream translates the Mac key code to the PC scan code that Mechvibes packs are written for. A is 30, Space is 57, Return is 28.',
  },
  {
    label: 'Sound',
    title: 'The pack picks the recording',
    text: 'The selected pack maps every scan code to a sound: a file of its own, or a slice of one long recording.',
  },
  {
    label: 'Play',
    title: 'It plays at once, and overlaps',
    text: 'Each sound was decoded, trimmed and leveled when the pack loaded. Ten players take turns, so fast typing overlaps instead of cutting itself off.',
  },
]

const names: Record<string, string> = {
  Space: 'space', Enter: 'return', Backspace: 'delete', Tab: 'tab', CapsLock: 'caps', Escape: 'esc',
  ShiftLeft: 'shift', ShiftRight: 'shift', MetaLeft: 'cmd', MetaRight: 'cmd', AltLeft: 'opt', AltRight: 'opt',
  ControlLeft: 'ctrl', ControlRight: 'ctrl', ArrowUp: '↑', ArrowDown: '↓', ArrowLeft: '←', ArrowRight: '→',
  Backquote: '`', Minus: '-', Equal: '=', BracketLeft: '[', BracketRight: ']', Backslash: '\\',
  Semicolon: ';', Quote: "'", Comma: ',', Period: '.', Slash: '/',
}

function labelFor(code: string) {
  if (names[code]) return names[code]
  const match = /^(?:Key|Digit)(.)$/.exec(code)
  return match ? match[1] : code
}

const root = ref<HTMLElement | null>(null)
const active = ref(0)
const trace = ref<KeyTrace>(traceKey('KeyK', 'K')!)
const isDown = ref(false)
const nextVoice = ref(0)
/** Press counters, used as keys so each new press restarts the matching animation. */
const strokes = ref(0)
const voiceHits = reactive(Array.from({ length: 10 }, () => 0))

const bars = computed(() => {
  let seed = [...(trace.value.file ?? trace.value.scanCode)].reduce((sum, char) => sum * 31 + char.charCodeAt(0), 7) >>> 0
  const random = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 2 ** 32)
  return Array.from({ length: 44 }, (_, i) => {
    const body = Math.exp(-i / 10) * (0.55 + random() * 0.45)
    const release = i > 15 && i < 22 ? Math.exp(-(i - 16) / 2) * 0.35 * random() : 0
    return Math.max(0.04, Math.min(1, body + release))
  })
})

let inView = false
let lastRealKey = 0
let frame = 0
let autoTimer = 0
let autoIndex = 0
let releaseTimer = 0

function strike(code: string) {
  const next = traceKey(code, labelFor(code))
  if (!next) return
  trace.value = next
  isDown.value = true
  window.clearTimeout(releaseTimer)
  releaseTimer = window.setTimeout(() => (isDown.value = false), 120)
  voiceHits[nextVoice.value]++
  nextVoice.value = (nextVoice.value + 1) % voiceHits.length
  strokes.value++
}

function update() {
  frame = 0
  const el = root.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  const travel = rect.height - window.innerHeight
  const progress = travel > 0 ? Math.min(Math.max(-rect.top / travel, 0), 0.9999) : 0
  active.value = Math.floor(progress * chapters.length)
  inView = rect.top < window.innerHeight && rect.bottom > 0
}

function onScroll() {
  frame ||= requestAnimationFrame(update)
}

function onKeyDown(event: KeyboardEvent) {
  if (!inView || event.repeat) return
  lastRealKey = performance.now()
  strike(event.code)
}

/** Keeps the rig moving while nobody types, spelling the name one key at a time. */
function autoplay() {
  if (!inView || performance.now() - lastRealKey < 3500) return
  strike(`Key${'KEYCREAM'[autoIndex % 8]}`)
  autoIndex++
}

/** Moves the page so the chosen chapter sits in the middle of its scroll range. */
function goTo(index: number) {
  const el = root.value
  if (!el) return
  const travel = el.offsetHeight - window.innerHeight
  const top = el.getBoundingClientRect().top + window.scrollY + travel * ((index + 0.5) / chapters.length)
  window.scrollTo({ top, behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' })
}

onMounted(() => {
  window.addEventListener('scroll', onScroll, { passive: true })
  window.addEventListener('resize', onScroll, { passive: true })
  window.addEventListener('keydown', onKeyDown)
  update()
  if (!matchMedia('(prefers-reduced-motion: reduce)').matches) autoTimer = window.setInterval(autoplay, 1150)
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
  window.removeEventListener('resize', onScroll)
  window.removeEventListener('keydown', onKeyDown)
  cancelAnimationFrame(frame)
  window.clearInterval(autoTimer)
  window.clearTimeout(releaseTimer)
})
</script>

<template>
  <section ref="root" class="story" aria-labelledby="how-title">
    <span id="how" class="anchor" aria-hidden="true"></span>
    <div class="pin">
      <div class="copy">
        <p class="kicker">How it works</p>
        <h2 id="how-title" class="display">From key press to&nbsp;click</h2>
        <div class="chap-wrap">
          <article v-for="(chapter, index) in chapters" :key="chapter.label" class="chap" :class="{ on: index === active }" :aria-hidden="index !== active">
            <p class="num">{{ String(index + 1).padStart(2, '0') }}</p>
            <h3>{{ chapter.title }}</h3>
            <p>{{ chapter.text }}</p>
          </article>
        </div>
        <ol class="chap-nav">
          <li v-for="(chapter, index) in chapters" :key="chapter.label">
            <button type="button" :class="{ on: index <= active }" :aria-current="index === active ? 'step' : undefined" @click="goTo(index)">
              {{ chapter.label }}
            </button>
          </li>
        </ol>
        <p class="hint"><i aria-hidden="true"></i>Scroll to step through, or press any key.</p>
      </div>

      <div class="rig" aria-hidden="true">
        <div class="rig-key">
          <div class="bigkey" :class="{ down: isDown }">
            <span class="face">{{ trace.label }}</span>
          </div>
          <span :key="strokes" class="ring"></span>
        </div>

        <ol class="flow">
          <li :class="{ lit: active >= 0, cur: active === 0 }">
            <span class="name">Key code</span>
            <span class="val">{{ trace.macKeyCode ?? 'n/a' }}</span>
            <span :key="strokes" class="flash"></span>
          </li>
          <li :class="{ lit: active >= 1, cur: active === 1 }">
            <span class="name">Scan code</span>
            <span class="val">{{ trace.scanCode }}</span>
            <span :key="strokes" class="flash"></span>
          </li>
          <li :class="{ lit: active >= 2, cur: active === 2 }">
            <span class="name">Sound</span>
            <span class="val">{{ trace.file ?? 'none' }}</span>
            <span :key="strokes" class="flash"></span>
          </li>
          <li :class="{ lit: active >= 3, cur: active === 3 }">
            <span class="name">Player</span>
            <span class="voices">
              <i v-for="(hits, index) in voiceHits" :key="`${index}-${hits}`" :class="{ hit: hits > 0, last: (index + 1) % voiceHits.length === nextVoice && hits > 0 }"></i>
            </span>
            <span :key="strokes" class="flash"></span>
          </li>
        </ol>

        <div class="wave" :class="{ lit: active >= 3 }">
          <i v-for="(height, index) in bars" :key="index" :style="{ height: `${height * 100}%` }"></i>
          <span :key="strokes" class="sweep"></span>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.story {
  position: relative;
  height: 420vh;
  margin-top: 140px;
}

/* Anchor jumps stop 96px above their target, so this lands the story exactly where the pin starts. */
.anchor {
  position: absolute;
  top: 96px;
  bottom: 0;
  left: 0;
  width: 1px;
  pointer-events: none;
}

.pin {
  position: sticky;
  top: 0;
  display: grid;
  grid-template-columns: minmax(300px, 420px) 1fr;
  gap: 64px;
  align-items: center;
  height: 100vh;
  max-width: calc(var(--page) + 2 * var(--gutter));
  margin: 0 auto;
  padding: 84px var(--gutter) 32px;
}

.copy .display {
  font-size: clamp(2.2rem, 3.8vw, 3.4rem);
}

.chap-wrap {
  position: relative;
  height: 230px;
}

.chap {
  position: absolute;
  inset: 0;
  opacity: 0;
  transform: translateY(16px);
  transition: opacity 0.45s, transform 0.45s;
  pointer-events: none;
}

.chap.on {
  opacity: 1;
  transform: none;
}

.num {
  font-family: var(--mono);
  font-size: 0.82rem;
  color: var(--accent);
}

.chap h3 {
  margin: 8px 0 12px;
  font-size: 1.75rem;
  font-weight: 640;
  letter-spacing: -0.03em;
  line-height: 1.15;
}

.chap p:not(.num) {
  font-size: 1.05rem;
  line-height: 1.62;
  color: var(--dim);
}

.chap-nav {
  display: flex;
  gap: 6px;
  margin: 10px 0 0;
  padding: 0;
  list-style: none;
}

.chap-nav li {
  flex: 1;
}

.chap-nav button {
  width: 100%;
  padding: 10px 0 0;
  border: 0;
  border-top: 2px solid var(--line);
  background: none;
  font-size: 0.8rem;
  font-weight: 560;
  text-align: left;
  color: var(--faint);
  cursor: pointer;
  transition: color 0.3s, border-color 0.3s;
}

.chap-nav button.on {
  color: var(--text);
  border-color: var(--zinc-50);
}

.hint {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 28px;
  font-size: 0.85rem;
  color: var(--faint);
}

.hint i {
  position: relative;
  flex: none;
  width: 14px;
  height: 22px;
  border-radius: 8px;
  border: 1.5px solid var(--faint);
}

.hint i::after {
  content: '';
  position: absolute;
  left: 50%;
  top: 4px;
  width: 2px;
  height: 5px;
  margin-left: -1px;
  border-radius: 2px;
  background: var(--faint);
  animation: wheel 1.6s infinite;
}

@keyframes wheel {
  60% {
    transform: translateY(6px);
    opacity: 0;
  }
}

/* The rig */
.rig {
  position: relative;
  display: grid;
  grid-template-columns: 0.9fr 1.1fr;
  grid-template-rows: 1fr auto;
  gap: 28px 36px;
  align-items: center;
  width: 100%;
  max-width: 760px;
  justify-self: center;
  padding: 40px;
  border-radius: 28px;
  background:
    radial-gradient(70% 80% at 25% 30%, rgba(255, 255, 255, 0.06), transparent 70%),
    linear-gradient(180deg, #18181b, #0f0f11);
  box-shadow:
    0 0 0 1px var(--line),
    0 40px 120px rgba(0, 0, 0, 0.55),
    0 0 140px rgba(255, 255, 255, 0.03);
}

.rig-key {
  position: relative;
  display: grid;
  place-items: center;
  aspect-ratio: 1;
}

.bigkey {
  position: relative;
  width: 78%;
  aspect-ratio: 1;
  border-radius: 18%;
  background: linear-gradient(180deg, #d4d4d8, #a1a1aa);
  box-shadow:
    0 14px 0 #71717a,
    0 26px 40px rgba(0, 0, 0, 0.6);
  transition: transform 70ms ease-out, box-shadow 70ms ease-out;
}

.bigkey.down {
  transform: translateY(11px);
  box-shadow:
    0 3px 0 #71717a,
    0 8px 14px rgba(0, 0, 0, 0.55);
}

.face {
  position: absolute;
  inset: 5% 9% 16%;
  display: grid;
  place-items: center;
  border-radius: 14%;
  background: linear-gradient(180deg, #fafafa, #e4e4e7);
  box-shadow: inset 0 2px 0 rgba(255, 255, 255, 0.8);
  color: var(--zinc-900);
  font-size: clamp(2rem, 4.4vw, 3.6rem);
  font-weight: 700;
  letter-spacing: -0.03em;
}

.ring {
  position: absolute;
  inset: 11%;
  border-radius: 18%;
  pointer-events: none;
  animation: ring 0.9s cubic-bezier(0.2, 0.7, 0.3, 1) forwards;
}

@keyframes ring {
  from {
    box-shadow: 0 0 0 0 rgba(255, 255, 255, 0.5);
  }

  to {
    box-shadow: 0 0 0 46px rgba(255, 255, 255, 0);
  }
}

.flow {
  position: relative;
  display: grid;
  gap: 12px;
  margin: 0;
  padding: 0 0 0 22px;
  list-style: none;
}

/* The wire the signal travels down. */
.flow::before {
  content: '';
  position: absolute;
  left: 4px;
  top: 22px;
  bottom: 22px;
  width: 2px;
  border-radius: 2px;
  background: linear-gradient(180deg, var(--zinc-400), rgba(161, 161, 170, 0.15));
}

.flow li {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  min-height: 56px;
  padding: 0 18px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.035);
  box-shadow: inset 0 0 0 1px var(--line);
  opacity: 0.38;
  transition: opacity 0.35s, box-shadow 0.35s, background-color 0.35s;
}

.flow li::before {
  content: '';
  position: absolute;
  left: -22px;
  top: 50%;
  width: 10px;
  height: 10px;
  margin-top: -5px;
  border-radius: 50%;
  background: var(--panel);
  box-shadow: inset 0 0 0 2px var(--zinc-400);
}

.flow li.lit {
  opacity: 1;
}

.flow li.cur {
  background: rgba(255, 255, 255, 0.06);
  box-shadow:
    inset 0 0 0 1.5px rgba(255, 255, 255, 0.5),
    0 10px 30px rgba(255, 255, 255, 0.05);
}

.name {
  font-size: 0.9rem;
  color: var(--dim);
}

.val {
  font-family: var(--mono);
  font-size: 1.15rem;
  font-weight: 500;
  color: var(--text);
}

.flash {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  opacity: 0;
}

.lit .flash {
  animation: flash 0.5s ease-out;
}

@keyframes flash {
  from {
    opacity: 1;
    background: rgba(255, 255, 255, 0.1);
  }

  to {
    opacity: 0;
  }
}

.voices {
  display: grid;
  grid-template-columns: repeat(10, 10px);
  gap: 5px;
}

.voices i {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.12);
}

.voices i.hit {
  background: rgba(255, 255, 255, 0.45);
}

.voices i.last {
  background: var(--zinc-50);
  box-shadow: 0 0 10px rgba(255, 255, 255, 0.7);
  animation: voice 0.6s ease-out;
}

@keyframes voice {
  from {
    transform: scale(1.6);
  }
}

.wave {
  position: relative;
  grid-column: 1 / -1;
  display: flex;
  align-items: center;
  gap: 3px;
  height: 64px;
  padding: 0 14px;
  overflow: hidden;
  border-radius: 14px;
  background: rgba(0, 0, 0, 0.22);
  box-shadow: inset 0 0 0 1px var(--line);
  opacity: 0.4;
  transition: opacity 0.35s;
}

.wave.lit {
  opacity: 1;
}

.wave i {
  flex: 1;
  min-height: 2px;
  border-radius: 2px;
  background: linear-gradient(180deg, var(--zinc-50), var(--zinc-500));
  transition: height 0.25s ease;
}

.sweep {
  position: absolute;
  top: 0;
  bottom: 0;
  left: 0;
  width: 2px;
  background: var(--text);
  box-shadow: 0 0 12px rgba(255, 255, 255, 0.7);
  opacity: 0;
  animation: sweep 0.55s linear;
}

@keyframes sweep {
  from {
    left: 14px;
    opacity: 1;
  }

  to {
    left: calc(100% - 14px);
    opacity: 0.6;
  }
}

@media (max-width: 900px) {
  .story {
    height: 380vh;
    margin-top: 100px;
  }

  .pin {
    grid-template-columns: 1fr;
    gap: 18px;
    align-content: start;
    padding-top: 76px;
    padding-bottom: 16px;
  }

  .rig {
    order: -1;
    grid-template-columns: 0.7fr 1.3fr;
    gap: 14px 16px;
    padding: 18px;
    border-radius: 22px;
  }

  .copy .display {
    margin: 0.2rem 0 0.8rem;
    font-size: 1.9rem;
  }

  .kicker {
    display: none;
  }

  .chap-wrap {
    height: 190px;
  }

  .chap h3 {
    font-size: 1.3rem;
  }

  .chap p:not(.num) {
    font-size: 0.95rem;
  }

  .flow {
    gap: 6px;
    padding-left: 16px;
  }

  .flow::before {
    left: 2px;
  }

  .flow li {
    min-height: 38px;
    padding: 0 10px;
    border-radius: 10px;
  }

  .flow li::before {
    left: -17px;
    width: 8px;
    height: 8px;
    margin-top: -4px;
  }

  .name {
    font-size: 0.75rem;
  }

  .val {
    font-size: 0.88rem;
  }

  .voices {
    grid-template-columns: repeat(5, 7px);
    gap: 3px;
  }

  .voices i {
    width: 7px;
    height: 7px;
  }

  .bigkey {
    box-shadow:
      0 8px 0 #71717a,
      0 14px 22px rgba(0, 0, 0, 0.6);
  }

  .bigkey.down {
    transform: translateY(6px);
  }

  .wave {
    height: 40px;
  }

  .hint {
    display: none;
  }
}
</style>
