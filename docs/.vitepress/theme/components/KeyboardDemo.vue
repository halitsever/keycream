<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { withBase } from 'vitepress'

interface Key {
  code: string
  label: string
  /** Width in keyboard units, where a letter key is 1. */
  width?: number
  /** Shown instead of the label when the keyboard is too narrow for words. */
  symbol?: string
}

const symbols: Record<string, string> = {
  delete: '⌫', tab: '⇥', 'caps lock': '⇪', return: '↩', shift: '⇧', control: '⌃', option: '⌥', command: '⌘',
}
const k = (code: string, label: string, width = 1): Key => ({ code, label, width, symbol: symbols[label] })
const letters = (codes: string) => [...codes].map((c) => k(`Key${c}`, c))

const rows: Key[][] = [
  [k('Backquote', '`'), ...[...'1234567890'].map((d) => k(`Digit${d}`, d)), k('Minus', '-'), k('Equal', '='), k('Backspace', 'delete', 2)],
  [k('Tab', 'tab', 1.5), ...letters('QWERTYUIOP'), k('BracketLeft', '['), k('BracketRight', ']'), k('Backslash', '\\', 1.5)],
  [k('CapsLock', 'caps lock', 1.75), ...letters('ASDFGHJKL'), k('Semicolon', ';'), k('Quote', "'"), k('Enter', 'return', 2.25)],
  [k('ShiftLeft', 'shift', 2.25), ...letters('ZXCVBNM'), k('Comma', ','), k('Period', '.'), k('Slash', '/'), k('ShiftRight', 'shift', 2.75)],
  [k('ControlLeft', 'control', 1.25), k('AltLeft', 'option', 1.25), k('MetaLeft', 'command', 1.5), k('Space', '', 7), k('MetaRight', 'command', 1.5), k('AltRight', 'option', 1.25), k('ControlRight', 'control', 1.25)],
]

/** Browser key codes to the PC scan codes that Mechvibes packs are keyed by. */
const scanCodes: Record<string, string> = {
  Escape: '1', Backquote: '41', Minus: '12', Equal: '13', Backspace: '14', Tab: '15',
  BracketLeft: '26', BracketRight: '27', Backslash: '43', CapsLock: '58', Semicolon: '39', Quote: '40', Enter: '28',
  ShiftLeft: '42', Comma: '51', Period: '52', Slash: '53', ShiftRight: '54',
  ControlLeft: '29', AltLeft: '56', MetaLeft: '3675', Space: '57', MetaRight: '3676', AltRight: '3640', ControlRight: '3613',
  ArrowUp: '57416', ArrowLeft: '57419', ArrowRight: '57421', ArrowDown: '57424',
}
;[...'1234567890'].forEach((d, i) => (scanCodes[`Digit${d}`] = String(i + 2)))
const letterRows: [string, number][] = [['QWERTYUIOP', 16], ['ASDFGHJKL', 30], ['ZXCVBNM', 44]]
for (const [row, first] of letterRows) [...row].forEach((c, i) => (scanCodes[`Key${c}`] = String(first + i)))

const pressed = reactive(new Set<string>())
const typed = ref('')
const muted = ref(false)
const focused = ref(false)
const typedTail = computed(() => typed.value.slice(-42))

let context: AudioContext | null = null
let master: GainNode | null = null
let fileForScanCode: Record<string, string> | null = null
const rawFiles = new Map<string, ArrayBuffer>()
const sounds = new Map<string, { buffer: AudioBuffer; gain: number }>()
let fetching: Promise<void> | null = null
let decoding: Promise<void> | null = null

function fetchSounds() {
  fetching ??= (async () => {
    const response = await fetch(withBase('/keys/map.json'))
    fileForScanCode = await response.json()
    const files = [...new Set(Object.values(fileForScanCode!))]
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
    const file = fileForScanCode?.[scanCode]
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
    const at = 700 + index * 120
    introTimers.push(
      window.setTimeout(() => {
        if (!showingIntro) return
        pressed.add(`Key${letter}`)
        typed.value += letter.toLowerCase()
      }, at),
      window.setTimeout(() => pressed.delete(`Key${letter}`), at + 90),
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
  pressed.add(event.code)
  if (event.repeat) return
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
  pressed.add(key.code)
  play(key.code)
  if (key.code === 'Backspace') typed.value = typed.value.slice(0, -1)
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
    <div
      class="case"
      tabindex="0"
      role="group"
      aria-label="Playable keyboard. Type to hear the NovelKeys Cream sound pack."
      @focus="focused = true"
      @blur="focused = false"
    >
      <div class="typed" aria-hidden="true">
        <span v-if="typedTail" class="typed-text">{{ typedTail }}</span>
        <span v-else class="typed-placeholder">Start typing…</span>
        <span class="caret"></span>
      </div>

      <div v-for="(row, index) in rows" :key="index" class="row">
        <button
          v-for="key in row"
          :key="key.code"
          type="button"
          tabindex="-1"
          class="key"
          :class="{ down: pressed.has(key.code), mod: key.label.length > 1, space: key.code === 'Space' }"
          :style="{ gridColumn: `span ${(key.width ?? 1) * 4}` }"
          :aria-label="key.label || 'space'"
          @pointerdown.prevent="pressByPointer(key)"
          @pointerup="releaseByPointer(key)"
          @pointerleave="releaseByPointer(key)"
        >
          <span class="cap">
            <span :class="{ word: key.symbol }">{{ key.label }}</span>
            <span v-if="key.symbol" class="symbol" aria-hidden="true">{{ key.symbol }}</span>
          </span>
          <svg v-if="key.code === 'Space'" class="drips" viewBox="0 0 70 14" preserveAspectRatio="none" aria-hidden="true">
            <path d="M12 0h5v9.5a2.5 2.5 0 0 1-5 0zM27 0h4v5.5a2 2 0 0 1-4 0zM40 0h5v12a2.5 2.5 0 0 1-5 0zM53 0h3v3.5a1.5 1.5 0 0 1-3 0z" />
          </svg>
        </button>
      </div>
    </div>

    <figcaption class="caption">
      <span class="hint-desktop">This keyboard is live. Type on yours to hear NovelKeys Cream, the pack KeyCream starts with.</span>
      <span class="hint-touch">This keyboard is live. Tap the keys to hear NovelKeys Cream, the pack KeyCream starts with.</span>
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
  margin: 0;
  container-type: inline-size;
}

.case {
  --unit: calc((100cqi - 2 * var(--pad)) / 15);
  --pad: max(10px, 2.2cqi);
  --gap: max(3px, 0.55cqi);
  position: relative;
  padding: var(--pad);
  border-radius: max(14px, 2.4cqi);
  background: var(--roast);
  box-shadow:
    inset 0 2px 0 rgba(255, 255, 255, 0.06),
    inset 0 -6px 14px rgba(0, 0, 0, 0.35),
    0 24px 50px -24px rgba(0, 0, 0, 0.55);
  touch-action: manipulation;
  user-select: none;
  -webkit-user-select: none;
}

.case:focus-visible {
  outline-offset: 6px;
}

.typed {
  display: flex;
  align-items: center;
  height: calc(var(--unit) * 0.9);
  margin-bottom: calc(var(--gap) * 3);
  padding: 0 calc(var(--unit) * 0.3);
  border-radius: calc(var(--unit) * 0.16);
  background: rgba(0, 0, 0, 0.25);
  color: var(--cream);
  font-size: max(13px, calc(var(--unit) * 0.34));
  font-weight: 500;
  white-space: pre;
  overflow: hidden;
}

.typed-placeholder {
  color: rgba(244, 235, 217, 0.45);
}

.caret {
  width: 2px;
  height: 1.1em;
  margin-left: 2px;
  background: var(--caramel-light);
  animation: blink 1.1s steps(1) infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.row {
  display: grid;
  grid-template-columns: repeat(60, 1fr);
  column-gap: var(--gap);
}

.row + .row {
  margin-top: var(--gap);
}

.key {
  position: relative;
  height: calc(var(--unit) - var(--gap));
  padding: 0;
  border: 0;
  border-radius: calc(var(--unit) * 0.14);
  background: var(--cream);
  color: var(--espresso);
  box-shadow:
    inset 0 calc(var(--unit) * -0.09) 0 var(--cream-shade),
    0 1px 0 rgba(0, 0, 0, 0.35);
  cursor: pointer;
  transition: transform 45ms ease-out, box-shadow 45ms ease-out, background-color 45ms;
}

.key.down {
  transform: translateY(calc(var(--unit) * 0.05));
  background: #ece0c7;
  box-shadow:
    inset 0 calc(var(--unit) * -0.035) 0 var(--cream-shade),
    0 0 0 rgba(0, 0, 0, 0.35);
}

.cap {
  position: absolute;
  inset: 0;
  display: grid;
  place-items: center;
  padding-bottom: calc(var(--unit) * 0.08);
  font-size: max(9px, calc(var(--unit) * 0.3));
  font-weight: 620;
  line-height: 1;
}

.mod .cap {
  place-items: end start;
  padding: 0 0 calc(var(--unit) * 0.16) calc(var(--unit) * 0.16);
  font-size: max(7px, calc(var(--unit) * 0.19));
  font-weight: 560;
}

.drips {
  position: absolute;
  top: calc(100% - 2px);
  left: 0;
  width: 100%;
  height: calc(var(--unit) * 0.75);
  fill: var(--cream);
  overflow: visible;
  pointer-events: none;
}

.caption {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 0.75rem 1.5rem;
  margin-top: 2.2rem;
  color: var(--text-muted);
  font-size: 0.95rem;
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
  padding: 0.45em 0.8em;
  border: 0;
  border-radius: 10px;
  background: var(--surface);
  color: var(--text);
  font-size: 0.9rem;
  font-weight: 560;
  cursor: pointer;
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

  .mod .cap {
    place-items: center;
    padding: 0 0 calc(var(--unit) * 0.08);
    font-size: max(10px, calc(var(--unit) * 0.36));
  }
}
</style>
