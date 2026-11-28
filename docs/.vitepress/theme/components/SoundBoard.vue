<script setup lang="ts">
import { onBeforeUnmount, ref } from 'vue'
import { withBase } from 'vitepress'
import { packs } from '../data/packs'
import { scanCodes } from '../data/keymap'

type Clip = { start: number; length: number; gain: number }

const selected = ref(packs.find((p) => p.id === 'CherryMX-brown-pbt')?.id ?? packs[0].id)
const status = ref<'idle' | 'loading' | 'ready' | 'error'>('idle')
const text = ref('')

let context: AudioContext | null = null
let master: GainNode | null = null
const loaded = new Map<string, { buffer: AudioBuffer; clips: Map<string, Clip> }>()
const loading = new Map<string, Promise<void>>()
let lastKeydown = 0

/** Letters only: the sprites hold letters, space, return, delete and shift. */
const letterScan: Record<string, string> = {}
for (const [code, scan] of Object.entries(scanCodes)) if (code.startsWith('Key')) letterScan[code.slice(3).toLowerCase()] = scan
const fallbackKeys = Object.values(letterScan)

/** Same leveling as the app and the home page demo, so no key jumps out. */
function levelGain(samples: Float32Array) {
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

/** Browsers allow audio only after a user gesture, so the context starts on the first key or click. */
function ensureContext() {
  if (!context) {
    context = new AudioContext()
    master = context.createGain()
    master.gain.value = 0.7
    master.connect(context.destination)
  }
  if (context.state === 'suspended') void context.resume()
  return context
}

function load(id: string) {
  if (loaded.has(id)) return Promise.resolve()
  let job = loading.get(id)
  if (!job) {
    job = (async () => {
      const ctx = ensureContext()
      const [map, data] = await Promise.all([
        fetch(withBase(`/sounds/${id}.json`)).then((r) => (r.ok ? r.json() : Promise.reject(new Error(String(r.status))))),
        fetch(withBase(`/sounds/${id}.wav`)).then((r) => (r.ok ? r.arrayBuffer() : Promise.reject(new Error(String(r.status))))),
      ])
      const buffer = await ctx.decodeAudioData(data)
      const channel = buffer.getChannelData(0)
      const clips = new Map<string, Clip>()
      for (const [scan, [startMs, lengthMs]] of Object.entries(map as Record<string, [number, number]>)) {
        const from = Math.floor((startMs / 1000) * buffer.sampleRate)
        const to = from + Math.floor((lengthMs / 1000) * buffer.sampleRate)
        clips.set(scan, { start: startMs / 1000, length: lengthMs / 1000, gain: levelGain(channel.subarray(from, to)) })
      }
      loaded.set(id, { buffer, clips })
    })().finally(() => loading.delete(id))
    loading.set(id, job)
  }
  return job
}

async function select(id: string) {
  selected.value = id
  status.value = 'loading'
  try {
    await load(id)
    if (selected.value === id) status.value = 'ready'
  } catch {
    if (selected.value === id) status.value = 'error'
  }
}

function play(scan: string | undefined) {
  const id = selected.value
  const pack = loaded.get(id)
  if (!pack) {
    void select(id)
    return
  }
  if (!context || !master) return
  const clip = (scan && pack.clips.get(scan)) || pack.clips.get(fallbackKeys[Math.floor(Math.random() * fallbackKeys.length)])
  if (!clip) return
  const source = context.createBufferSource()
  const gain = context.createGain()
  gain.gain.value = clip.gain
  source.buffer = pack.buffer
  source.connect(gain).connect(master)
  source.start(0, clip.start, clip.length)
}

function onKeydown(event: KeyboardEvent) {
  if (event.repeat || event.metaKey || event.ctrlKey) return
  const scan = scanCodes[event.code]
  if (!scan) return
  lastKeydown = performance.now()
  ensureContext()
  play(scan)
}

/** Phone keyboards often send no key codes, so typed characters play instead. */
function onInput(event: Event) {
  if (performance.now() - lastKeydown < 80) return
  const data = (event as InputEvent).data ?? ''
  const char = data.slice(-1).toLowerCase()
  ensureContext()
  play(char === ' ' ? '57' : letterScan[char])
}

onBeforeUnmount(() => {
  void context?.close()
  context = null
})
</script>

<template>
  <div class="board">
    <fieldset class="packs">
      <legend>Switch</legend>
      <button
        v-for="pack in packs"
        :key="pack.id"
        type="button"
        class="chip"
        :class="{ on: selected === pack.id }"
        :aria-pressed="selected === pack.id"
        @click="select(pack.id)"
      >
        <span class="dot" :style="{ background: pack.stem }" aria-hidden="true"></span>
        {{ pack.name }}
        <span class="feel">{{ pack.feel }}</span>
      </button>
    </fieldset>
    <label class="pad">
      <span class="pad-label">Type here to hear {{ packs.find((p) => p.id === selected)?.name }}</span>
      <textarea v-model="text" rows="4" spellcheck="false" autocomplete="off" placeholder="The quick brown fox jumps over the lazy dog" @keydown="onKeydown" @input="onInput"></textarea>
    </label>
    <p class="status" role="status" aria-live="polite">
      <template v-if="status === 'loading'">Loading the recording…</template>
      <template v-else-if="status === 'error'">The recording didn't load. Check your connection and pick the switch again.</template>
      <template v-else-if="status === 'ready'">Ready. Letters, space, return, delete and shift play their own recording; other keys borrow a letter's.</template>
      <template v-else>Pick a switch, then type. Sound starts with your first key.</template>
    </p>
  </div>
</template>

<style scoped>
.board {
  margin: 1.6rem 0 2rem;
  padding: 1.25rem;
  border-radius: 22px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0.015));
  box-shadow: inset 0 0 0 1px var(--line);
}

.packs {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 1rem;
  padding: 0;
  border: 0;
}

.packs legend {
  margin-bottom: 0.6rem;
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--faint);
}

.chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 0.5rem 0.85rem;
  border: 0;
  border-radius: 999px;
  font: inherit;
  font-size: 0.92rem;
  color: var(--dim);
  background: rgba(255, 255, 255, 0.05);
  box-shadow: inset 0 0 0 1px var(--line);
  cursor: pointer;
  transition: color 0.2s, box-shadow 0.2s, background-color 0.2s;
}

.chip:hover,
.chip.on {
  color: var(--text);
  background: rgba(255, 255, 255, 0.09);
}

.chip.on {
  box-shadow: inset 0 0 0 1.5px var(--zinc-50);
}

.dot {
  width: 10px;
  height: 10px;
  border-radius: 3px;
  box-shadow: inset 0 0 0 1px rgba(0, 0, 0, 0.35);
}

.feel {
  font-size: 0.78rem;
  color: var(--faint);
}

.pad {
  display: grid;
  gap: 0.5rem;
}

.pad-label {
  font-size: 0.9rem;
  font-weight: 600;
}

textarea {
  width: 100%;
  min-height: 7rem;
  padding: 0.9rem 1rem;
  border: 0;
  border-radius: 14px;
  font: inherit;
  font-size: 1rem;
  color: var(--text);
  background: rgba(0, 0, 0, 0.35);
  box-shadow: inset 0 0 0 1px var(--line);
  resize: vertical;
}

textarea:focus {
  outline: none;
  box-shadow: inset 0 0 0 1.5px var(--zinc-500);
}

.status {
  margin: 0.75rem 0 0;
  font-size: 0.88rem;
  color: var(--faint);
}
</style>
