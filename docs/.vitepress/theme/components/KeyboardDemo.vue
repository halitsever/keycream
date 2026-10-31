<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { withBase } from 'vitepress'
import { fileForScanCode, scanCodes } from '../data/keymap'

type Kind = 'alpha' | 'mod' | 'fn' | 'accent'

interface Key {
  code: string
  label: string
  /** Width in keyboard units, where a letter key is 1. */
  width: number
  kind: Kind
  /** Shown instead of the label when the keyboard is too narrow for words. */
  symbol?: string
}

const props = withDefaults(defineProps<{ tilt?: number }>(), { tilt: 0 })

const symbols: Record<string, string> = {
  delete: '⌫', tab: '⇥', 'caps lock': '⇪', return: '↩', shift: '⇧', control: '⌃', option: '⌥', command: '⌘', esc: '⎋',
}
const k = (code: string, label: string, width = 1, kind?: Kind): Key => ({
  code, label, width, symbol: symbols[label], kind: kind ?? (label.length > 1 ? 'mod' : 'alpha'),
})
const letters = (codes: string) => [...codes].map((c) => k(`Key${c}`, c))
const functionKeys = Array.from({ length: 12 }, (_, i) => k(`F${i + 1}`, `F${i + 1}`, 1.125, 'fn'))

const rows: Key[][] = [
  [k('Escape', 'esc', 1.5, 'accent'), ...functionKeys],
  [k('Backquote', '`'), ...[...'1234567890'].map((d) => k(`Digit${d}`, d)), k('Minus', '-'), k('Equal', '='), k('Backspace', 'delete', 2)],
  [k('Tab', 'tab', 1.5), ...letters('QWERTYUIOP'), k('BracketLeft', '['), k('BracketRight', ']'), k('Backslash', '\\', 1.5)],
  [k('CapsLock', 'caps lock', 1.75), ...letters('ASDFGHJKL'), k('Semicolon', ';'), k('Quote', "'"), k('Enter', 'return', 2.25, 'accent')],
  [k('ShiftLeft', 'shift', 2.25), ...letters('ZXCVBNM'), k('Comma', ','), k('Period', '.'), k('Slash', '/'), k('ShiftRight', 'shift', 2.75)],
  [
    k('ControlLeft', 'control', 1.25), k('AltLeft', 'option', 1.25), k('MetaLeft', 'command', 1.25), k('Space', '', 6.25, 'alpha'),
    k('MetaRight', 'command', 1.25), k('AltRight', 'option', 1.25), k('Fn', 'fn', 1.25, 'mod'), k('ControlRight', 'control', 1.25),
  ],
]

const pressed = reactive(new Set<string>())
/** A counter per key, so each press mounts a fresh ripple and restarts its animation. */
const pulses = reactive(new Map<string, number>())
const typed = ref('')
const muted = ref(false)
const focused = ref(false)
const typedTail = computed(() => typed.value.slice(-34))

const tiltStyle = computed(() => ({
  transform: `rotateX(${(props.tilt * 34).toFixed(2)}deg) scale(${(1 - props.tilt * 0.08).toFixed(4)})`,
}))

let context: AudioContext | null = null
let master: GainNode | null = null
const rawFiles = new Map<string, ArrayBuffer>()
const sounds = new Map<string, { buffer: AudioBuffer; gain: number }>()
let fetching: Promise<void> | null = null
let decoding: Promise<void> | null = null

function fetchSounds() {
  fetching ??= (async () => {
    const files = [...new Set(Object.values(fileForScanCode as Record<string, string>))]
    await Promise.all(
      files.map(async (file) => rawFiles.set(file, await (await fetch(withBase(`/keys/${file}`))).arrayBuffer())),
    )
  })()
  return fetching
}

/** Matches the app's leveling, so no key jumps out. */
function levelGain(buffer: AudioBuffer) {
  const samples = buffer.getChannelData(0)
  let sum = 0
  let peak = 0
  for (const value of samples) {
    sum += value * value
    peak = Math.max(peak, Math.abs(value))
  }
  const rms = Math.sqrt(sum / samples.length)
  if (rms < 1e-4 || peak < 1e-4) return 1
  return Math.min(Math.max(Math.min(0.04 / rms, 0.92 / peak), 0.05), 8)
}

/** Browsers only allow audio after a user gesture, so the context is created on the first key press or tap. */
function startAudio() {
  if (!context) {
    context = new AudioContext()
    master = context.createGain()
    master.gain.value = 0.7
    master.connect(context.destination)
  }
  if (context.state === 'suspended') void context.resume()
  decoding ??= (async () => {
    await fetchSounds()
    await Promise.all(
      [...rawFiles].map(async ([file, data]) => {
        const buffer = await context!.decodeAudioData(data.slice(0))
        sounds.set(file, { buffer, gain: levelGain(buffer) })
      }),
    )
  })().catch((error) => {
    // A failed download shouldn't silence the demo for good, so the next key press tries again.
    decoding = null
    fetching = null
    throw error
  })
  return decoding
}

function play(code: string) {
  if (muted.value) return
  const scanCode = scanCodes[code]
  if (!scanCode) return
  const requestedAt = performance.now()
  void startAudio().then(() => {
    // The very first press waits for decoding; play it only if the wait was short enough to still feel like that press.
    if (performance.now() - requestedAt > 300) return
    const file = (fileForScanCode as Record<string, string>)[scanCode]
    const sound = file ? sounds.get(file) : undefined
    if (!sound || !context || !master) return
    const source = context.createBufferSource()
    const gain = context.createGain()
    gain.gain.value = sound.gain
    source.buffer = sound.buffer
    source.connect(gain).connect(master)
    source.start()
  }, () => {})
}

function down(code: string) {
  pressed.add(code)
  pulses.set(code, (pulses.get(code) ?? 0) + 1)
}

function type(event: KeyboardEvent) {
  if (event.key === 'Backspace') typed.value = typed.value.slice(0, -1)
  else if (event.key === 'Enter') typed.value = ''
  else if (event.key.length === 1 && !event.metaKey && !event.ctrlKey) typed.value += event.key
}

const introTimers: number[] = []
let showingIntro = false

/** Types the product name once on load, silently, to show that the keyboard reacts. */
function playIntro() {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return
  showingIntro = true
  ;[...'KEYCREAM'].forEach((letter, index) => {
    const at = 900 + index * 130
    introTimers.push(
      window.setTimeout(() => {
        if (!showingIntro) return
        down(`Key${letter}`)
        typed.value += letter.toLowerCase()
      }, at),
      window.setTimeout(() => pressed.delete(`Key${letter}`), at + 95),
    )
  })
}

function endIntro() {
  if (!showingIntro) return
  showingIntro = false
  introTimers.forEach((timer) => window.clearTimeout(timer))
  typed.value = ''
}

function onKeyDown(event: KeyboardEvent) {
  endIntro()
  if (event.repeat) {
    pressed.add(event.code)
    return
  }
  down(event.code)
  play(event.code)
  type(event)
  // While the keyboard has focus, keys that would scroll or move focus belong to the demo.
  if (focused.value && ['Space', 'Tab', 'ArrowUp', 'ArrowDown', 'Quote', 'Slash'].includes(event.code)) {
    event.preventDefault()
  }
}

function onKeyUp(event: KeyboardEvent) {
  pressed.delete(event.code)
}

function release() {
  pressed.clear()
}

function pressByPointer(key: Key) {
  endIntro()
  down(key.code)
  play(key.code)
  if (key.code === 'Backspace') typed.value = typed.value.slice(0, -1)
  else if (key.code === 'Enter') typed.value = ''
  else if (key.code === 'Space') typed.value += ' '
  else if (key.label.length === 1) typed.value += key.label.toLowerCase()
}

function releaseByPointer(key: Key) {
  pressed.delete(key.code)
}

function toggleMute() {
  muted.value = !muted.value
  try {
    localStorage.setItem('keycream-demo-muted', muted.value ? '1' : '0')
  } catch {}
}

let idleHandle = 0

onMounted(() => {
  try {
    muted.value = localStorage.getItem('keycream-demo-muted') === '1'
  } catch {}
  window.addEventListener('keydown', onKeyDown)
  window.addEventListener('keyup', onKeyUp)
  window.addEventListener('blur', release)
  playIntro()
  // Desktop visitors are likely to type, so the sounds download once the page is idle.
  if (matchMedia('(hover: hover) and (pointer: fine)').matches) {
    const prefetch = () => void fetchSounds().catch(() => {})
    idleHandle = 'requestIdleCallback' in window ? window.requestIdleCallback(prefetch, { timeout: 4000 }) : window.setTimeout(prefetch, 2000)
  }
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKeyDown)
  window.removeEventListener('keyup', onKeyUp)
  window.removeEventListener('blur', release)
  introTimers.forEach((timer) => window.clearTimeout(timer))
  if ('cancelIdleCallback' in window) window.cancelIdleCallback(idleHandle)
  else window.clearTimeout(idleHandle)
  void context?.close()
})
</script>

<template>
  <figure class="demo">
    <div class="stage">
      <div class="tilt" :style="tiltStyle">
        <div class="screen" aria-hidden="true">
          <span v-if="typedTail" class="typed">{{ typedTail }}</span>
          <span v-else class="placeholder">Start typing</span>
          <span class="caret"></span>
        </div>

        <div class="board">
          <div class="glow" aria-hidden="true"></div>
          <div
            class="case"
            tabindex="0"
            role="group"
            aria-label="Playable keyboard. Type to hear the NovelKeys Cream sound pack."
            @focus="focused = true"
            @blur="focused = false"
          >
            <div class="plate">
              <div v-for="(row, index) in rows" :key="index" class="row" :class="{ 'f-row': index === 0 }">
                <button
                  v-for="key in row"
                  :key="key.code"
                  type="button"
                  tabindex="-1"
                  class="key"
                  :class="[key.kind, { down: pressed.has(key.code), space: key.code === 'Space' }]"
                  :style="{ gridColumn: `span ${key.width * 8}` }"
                  :aria-label="key.label || 'space'"
                  @pointerdown.prevent="pressByPointer(key)"
                  @pointerup="releaseByPointer(key)"
                  @pointerleave="releaseByPointer(key)"
                >
                  <span class="top">
                    <span :class="{ word: key.symbol }">{{ key.label }}</span>
                    <span v-if="key.symbol" class="symbol" aria-hidden="true">{{ key.symbol }}</span>
                  </span>
                  <span v-if="pulses.get(key.code)" :key="pulses.get(key.code)" class="wave" aria-hidden="true"></span>
                  <svg v-if="key.code === 'Space'" class="drips" viewBox="0 0 70 14" preserveAspectRatio="none" aria-hidden="true">
                    <path d="M12 0h5v9.5a2.5 2.5 0 0 1-5 0zM27 0h4v5.5a2 2 0 0 1-4 0zM40 0h5v12a2.5 2.5 0 0 1-5 0zM53 0h3v3.5a1.5 1.5 0 0 1-3 0z" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <figcaption class="caption">
      <span class="hint-desktop">This keyboard is live. Type on yours to hear NovelKeys Cream, the pack KeyCream starts with.</span>
      <span class="hint-touch">This keyboard is live. Tap a key to hear NovelKeys Cream, the pack KeyCream starts with.</span>
      <button class="mute" type="button" :aria-pressed="muted" @click="toggleMute">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M4 9.5h3.5L12 5.5v13l-4.5-4H4z" />
          <path v-if="!muted" d="M15.5 9a4.5 4.5 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11" />
          <path v-else d="M16 9.5l5 5M21 9.5l-5 5" />
        </svg>
        {{ muted ? 'Sound off' : 'Sound on' }}
      </button>
    </figcaption>
  </figure>
</template>

<style scoped>
.demo {
  --pad: max(10px, 2cqi);
  --gap: max(3px, 0.5cqi);
  --unit: calc((100cqi - 2 * var(--pad)) / 15);
  margin: 0;
  container-type: inline-size;
}

.stage {
  perspective: 1700px;
}

.tilt {
  transform-origin: 50% 0;
  will-change: transform;
}

.screen {
  display: flex;
  align-items: center;
  justify-content: center;
  height: calc(var(--unit) * 1.15);
  margin-bottom: calc(var(--unit) * 0.5);
  overflow: hidden;
  font-size: max(22px, calc(var(--unit) * 0.68));
  font-weight: 640;
  font-variation-settings: 'opsz' 48;
  letter-spacing: -0.03em;
  white-space: pre;
}

.placeholder {
  color: var(--faint);
}

.caret {
  flex: none;
  width: 0.07em;
  height: 0.95em;
  margin-left: 0.06em;
  border-radius: 2px;
  background: var(--caramel-light);
  animation: blink 1.1s steps(1) infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.board {
  position: relative;
}

/* A warm light under the case, as if the desk lamp hit the plate. */
.glow {
  position: absolute;
  inset: -14% -8% -24%;
  z-index: -1;
  pointer-events: none;
  background: radial-gradient(closest-side, rgba(224, 164, 107, 0.34), rgba(200, 135, 74, 0.1) 60%, transparent);
  filter: blur(24px);
}

.case {
  position: relative;
  padding: var(--pad);
  border-radius: calc(var(--unit) * 0.42);
  background: linear-gradient(180deg, #3d2f27 0%, #2a1f1a 55%, #221914 100%);
  box-shadow:
    inset 0 1px 0 rgba(255, 236, 210, 0.16),
    inset 0 -3px 6px rgba(0, 0, 0, 0.45),
    0 0 0 1px rgba(0, 0, 0, 0.55),
    0 calc(var(--unit) * 0.5) calc(var(--unit) * 1.1) rgba(0, 0, 0, 0.55),
    0 calc(var(--unit) * 1.3) calc(var(--unit) * 2.6) rgba(0, 0, 0, 0.45);
  touch-action: manipulation;
  user-select: none;
  -webkit-user-select: none;
}

.case:focus-visible {
  outline-offset: 6px;
  border-radius: calc(var(--unit) * 0.42);
}

.plate {
  padding: calc(var(--gap) * 1.2) 0;
  border-radius: calc(var(--unit) * 0.22);
  background: #110b08;
  box-shadow: inset 0 2px 10px rgba(0, 0, 0, 0.8);
}

.row {
  display: grid;
  grid-template-columns: repeat(120, 1fr);
}

.row + .row {
  margin-top: var(--gap);
}

.f-row {
  margin-bottom: calc(var(--gap) * 2.2);
}

.key {
  --skirt: linear-gradient(180deg, #e8dabd, #cbb48c);
  --face: linear-gradient(180deg, #fdf8ec, #f1e5cc);
  --edge: #7d6345;
  --ink: #2a1f1a;
  position: relative;
  height: calc(var(--unit) - var(--gap));
  margin: 0 calc(var(--gap) / 2);
  padding: 0;
  border: 0;
  border-radius: calc(var(--unit) * 0.15);
  background: var(--skirt);
  color: var(--ink);
  box-shadow:
    0 calc(var(--unit) * 0.055) 0 var(--edge),
    0 calc(var(--unit) * 0.1) calc(var(--unit) * 0.14) rgba(0, 0, 0, 0.55);
  cursor: pointer;
  transition: transform 45ms ease-out, box-shadow 45ms ease-out;
}

.mod {
  --skirt: linear-gradient(180deg, #d3bb93, #b2966a);
  --face: linear-gradient(180deg, #ead9bb, #dcc6a2);
  --edge: #6b5136;
  --ink: #4a382d;
}

.accent {
  --skirt: linear-gradient(180deg, #c98b53, #a46833);
  --face: linear-gradient(180deg, #ebb179, #d4945a);
  --edge: #6f431d;
  --ink: #2a1f1a;
}

.fn {
  height: calc(var(--unit) * 0.7);
}

.f-row .accent {
  height: calc(var(--unit) * 0.7);
}

.key.down {
  transform: translateY(calc(var(--unit) * 0.05));
  box-shadow:
    0 calc(var(--unit) * 0.012) 0 var(--edge),
    0 calc(var(--unit) * 0.03) calc(var(--unit) * 0.05) rgba(0, 0, 0, 0.5);
}

.top {
  position: absolute;
  inset: calc(var(--unit) * 0.045) calc(var(--unit) * 0.085) calc(var(--unit) * 0.15);
  display: grid;
  place-items: center;
  border-radius: calc(var(--unit) * 0.11);
  background: var(--face);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.75),
    0 1px 2px rgba(80, 50, 20, 0.22);
  font-size: max(9px, calc(var(--unit) * 0.29));
  font-weight: 620;
  line-height: 1;
}

.down .top {
  filter: brightness(0.96);
}

.mod .top {
  place-items: end start;
  padding: 0 0 calc(var(--unit) * 0.12) calc(var(--unit) * 0.1);
  font-size: max(7px, calc(var(--unit) * 0.16));
  font-weight: 560;
}

.fn .top,
.f-row .accent .top {
  inset: calc(var(--unit) * 0.035) calc(var(--unit) * 0.075) calc(var(--unit) * 0.11);
  font-size: max(7px, calc(var(--unit) * 0.17));
  font-weight: 580;
}

.accent .top {
  place-items: end start;
  padding: 0 0 calc(var(--unit) * 0.12) calc(var(--unit) * 0.12);
  font-size: max(7px, calc(var(--unit) * 0.18));
}

.f-row .accent .top {
  place-items: center;
  padding: 0;
}

/* A ring that leaves the key, standing in for the sound. */
.wave {
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  animation: wave 0.6s cubic-bezier(0.2, 0.7, 0.3, 1) forwards;
}

@keyframes wave {
  from {
    box-shadow: 0 0 0 0 rgba(255, 220, 174, 0.75);
  }

  to {
    box-shadow: 0 0 0 calc(var(--unit) * 0.42) rgba(255, 220, 174, 0);
  }
}

.drips {
  position: absolute;
  top: calc(100% - var(--unit) * 0.16 - 2px);
  left: calc(var(--unit) * 0.085);
  width: calc(100% - var(--unit) * 0.17);
  height: calc(var(--unit) * 0.6);
  fill: #f6ecd8;
  overflow: visible;
  pointer-events: none;
  filter: drop-shadow(0 1px 1px rgba(0, 0, 0, 0.35));
}

.caption {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 0.75rem 1.25rem;
  margin-top: 2.6rem;
  font-size: 0.95rem;
  color: var(--dim);
  text-align: center;
}

.hint-touch {
  display: none;
}

@media (hover: none) {
  .hint-desktop {
    display: none;
  }

  .hint-touch {
    display: inline;
  }
}

.mute {
  display: inline-flex;
  align-items: center;
  gap: 0.45em;
  height: 34px;
  padding: 0 14px;
  border: 0;
  border-radius: 999px;
  background: rgba(244, 235, 217, 0.06);
  box-shadow: inset 0 0 0 1px var(--line);
  font-size: 0.88rem;
  font-weight: 560;
  cursor: pointer;
}

.mute:hover {
  background: rgba(244, 235, 217, 0.1);
}

.mute svg {
  width: 1.1em;
  height: 1.1em;
}

.symbol {
  display: none;
}

@container (max-width: 640px) {
  .word {
    display: none;
  }

  .symbol {
    display: inline;
  }

  .mod .top,
  .accent .top {
    place-items: center;
    padding: 0;
    font-size: max(10px, calc(var(--unit) * 0.34));
  }

  .fn .top {
    font-size: max(6px, calc(var(--unit) * 0.2));
  }
}
</style>
