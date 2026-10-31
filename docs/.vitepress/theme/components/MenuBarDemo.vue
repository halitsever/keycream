<script setup lang="ts">
import { ref } from 'vue'
import { languages, packs } from '../data/packs'
import { useSamples } from '../composables/useSamples'

type Submenu = 'volume' | 'pack' | 'language'

/** Same levels as the app's Volume menu. */
const levels = [
  { label: 'Low', value: 0.3 },
  { label: 'Medium', value: 0.6 },
  { label: 'High', value: 1 },
]

const { play, stop } = useSamples()
const menuOpen = ref(true)
const open = ref<Submenu | null>('pack')
const soundsOn = ref(true)
const openAtLogin = ref(true)
const volume = ref(2)
const packId = ref(packs[0].id)
const language = ref<string | null>(null)

function audition(id: string) {
  if (soundsOn.value) play(id, levels[volume.value].value)
}

function choosePack(id: string) {
  packId.value = id
  audition(id)
}

function chooseVolume(index: number) {
  volume.value = index
  audition(packId.value)
}

function toggleSounds() {
  soundsOn.value = !soundsOn.value
  if (!soundsOn.value) stop()
}

function quit() {
  stop()
  menuOpen.value = false
  open.value = null
}

function toggleMenu() {
  menuOpen.value = !menuOpen.value
  open.value = menuOpen.value ? 'pack' : null
}
</script>

<template>
  <div class="desk">
    <div class="mb-strip">
      <b>Finder</b>
      <span class="hide-sm">File</span>
      <span class="hide-sm">Edit</span>
      <span class="hide-sm">View</span>
      <span class="hide-xs">Window</span>
      <span class="r">
        <button class="mb-icon" :class="{ on: menuOpen }" type="button" :aria-expanded="menuOpen" aria-label="KeyCream menu" @click="toggleMenu">
          <svg viewBox="10 12 100 98" aria-hidden="true">
            <rect x="10" y="12" width="100" height="98" rx="24" fill="#fff" />
            <path
              d="M39 18H81Q98 18 98 35V70Q98 80 88 80H86Q83 80 83 83V86A3 3 0 0 1 77 86V83Q77 80 74 80H71Q68 80 68 83V91A5 5 0 0 1 58 91V83Q58 80 55 80H50Q47 80 47 83V99.5A6.5 6.5 0 0 1 34 99.5V83Q34 80 31 80Q22 80 22 70V35Q22 18 39 18Z"
              fill="#18181b"
            />
          </svg>
        </button>
        <svg class="hide-xs" viewBox="0 0 20 14" width="17" aria-hidden="true">
          <path d="M10 13.2 7.2 10a4 4 0 0 1 5.6 0zM4.6 7.4a7.6 7.6 0 0 1 10.8 0l-1.5 1.6a5.5 5.5 0 0 0-7.8 0zM1.8 4.6a11.6 11.6 0 0 1 16.4 0l-1.5 1.5a9.5 9.5 0 0 0-13.4 0z" fill="currentColor" />
        </svg>
        <span>Sun 1 Nov 10:41</span>
      </span>
    </div>

    <div v-if="menuOpen" class="menu" role="menu" aria-label="KeyCream">
      <button class="mi" type="button" role="menuitemcheckbox" :aria-checked="soundsOn" @mouseenter="open = null" @click="toggleSounds">
        <span v-if="soundsOn" class="ck" aria-hidden="true">✓</span>Sounds On
      </button>

      <div class="has-sub" @mouseenter="open = 'volume'">
        <button class="mi" :class="{ hi: open === 'volume' }" type="button" aria-haspopup="menu" :aria-expanded="open === 'volume'" @click="open = 'volume'">
          Volume<span class="ar" aria-hidden="true">›</span>
        </button>
        <div v-if="open === 'volume'" class="submenu" role="menu" aria-label="Volume">
          <button
            v-for="(level, index) in levels"
            :key="level.label"
            class="mi"
            type="button"
            role="menuitemradio"
            :aria-checked="index === volume"
            @click="chooseVolume(index)"
          >
            <span v-if="index === volume" class="ck" aria-hidden="true">✓</span>{{ level.label }}
          </button>
        </div>
      </div>

      <div class="has-sub" @mouseenter="open = 'pack'">
        <button class="mi" :class="{ hi: open === 'pack' }" type="button" aria-haspopup="menu" :aria-expanded="open === 'pack'" @click="open = 'pack'">
          Sound Pack<span class="ar" aria-hidden="true">›</span>
        </button>
        <div v-if="open === 'pack'" class="submenu wide" role="menu" aria-label="Sound Pack">
          <button
            v-for="pack in packs"
            :key="pack.id"
            class="mi"
            type="button"
            role="menuitemradio"
            :aria-checked="pack.id === packId"
            @click="choosePack(pack.id)"
          >
            <span v-if="pack.id === packId" class="ck" aria-hidden="true">✓</span>
            <i class="stem" :style="{ background: pack.stem }" aria-hidden="true"></i>{{ pack.name }}
          </button>
        </div>
      </div>

      <button class="mi" type="button" role="menuitemcheckbox" :aria-checked="openAtLogin" @mouseenter="open = null" @click="openAtLogin = !openAtLogin">
        <span v-if="openAtLogin" class="ck" aria-hidden="true">✓</span>Open at Login
      </button>

      <div class="has-sub" @mouseenter="open = 'language'">
        <button class="mi" :class="{ hi: open === 'language' }" type="button" aria-haspopup="menu" :aria-expanded="open === 'language'" @click="open = 'language'">
          Language<span class="ar" aria-hidden="true">›</span>
        </button>
        <div v-if="open === 'language'" class="submenu lang" role="menu" aria-label="Language">
          <button class="mi" type="button" role="menuitemradio" :aria-checked="language === null" @click="language = null">
            <span v-if="language === null" class="ck" aria-hidden="true">✓</span>System Language
          </button>
          <hr />
          <button
            v-for="name in languages"
            :key="name"
            class="mi"
            type="button"
            role="menuitemradio"
            :aria-checked="language === name"
            @click="language = name"
          >
            <span v-if="language === name" class="ck" aria-hidden="true">✓</span>{{ name }}
          </button>
        </div>
      </div>

      <hr />
      <button class="mi" type="button" @mouseenter="open = null" @click="quit">Quit<kbd>⌘Q</kbd></button>
    </div>

    <p class="desk-hint">
      <template v-if="menuOpen">Try the menu. <b>Pick a pack</b> to hear it.</template>
      <template v-else>Click the keycap in the menu bar to open it again.</template>
    </p>
  </div>
</template>

<style scoped>
.desk {
  position: relative;
  height: 450px;
  overflow: hidden;
  border-radius: 26px;
  background:
    radial-gradient(70% 90% at 88% 0%, rgba(255, 255, 255, 0.12), transparent 70%),
    radial-gradient(90% 120% at 0% 100%, #3f3f46 0%, transparent 60%),
    linear-gradient(160deg, #27272a 0%, #18181b 55%, #09090b 100%);
  box-shadow:
    0 0 0 1px var(--line),
    0 40px 100px rgba(0, 0, 0, 0.55);
  font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', system-ui, sans-serif;
}

.mb-strip {
  position: absolute;
  inset: 0 0 auto;
  height: 30px;
  display: flex;
  align-items: center;
  gap: 20px;
  padding: 0 16px;
  font-size: 13px;
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

.mb-strip b {
  font-weight: 700;
}

.r {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-left: auto;
}

.mb-icon {
  display: grid;
  place-items: center;
  width: 30px;
  height: 22px;
  padding: 0;
  border: 0;
  border-radius: 5px;
  background: transparent;
  cursor: default;
}

.mb-icon.on {
  background: rgba(255, 255, 255, 0.24);
}

.mb-icon svg {
  width: 16px;
  height: 16px;
}

.menu,
.submenu {
  position: absolute;
  padding: 5px;
  border-radius: 11px;
  font-size: 13px;
  color: #f4f4f5;
  background: rgba(39, 39, 42, 0.8);
  backdrop-filter: blur(30px) saturate(1.6);
  -webkit-backdrop-filter: blur(30px) saturate(1.6);
  box-shadow:
    0 0 0 0.5px rgba(255, 255, 255, 0.2),
    0 20px 50px rgba(0, 0, 0, 0.5);
}

.menu {
  top: 36px;
  right: 128px;
  width: 220px;
}

.has-sub {
  position: relative;
}

.submenu {
  top: -5px;
  right: calc(100% + 1px);
  width: 170px;
}

.submenu.wide {
  width: 222px;
}

/* Like macOS, a submenu that would run off the bottom moves up. */
.submenu.lang {
  top: -100px;
}

.mi {
  position: relative;
  display: flex;
  align-items: center;
  gap: 9px;
  width: 100%;
  height: 24px;
  padding: 0 10px 0 22px;
  border: 0;
  border-radius: 5px;
  text-align: left;
  white-space: nowrap;
  background: none;
  cursor: default;
}

.mi:hover,
.mi.hi,
.mi:focus-visible {
  outline: none;
  color: #fff;
  background: var(--zinc-600);
}

.ck {
  position: absolute;
  left: 7px;
  font-size: 11px;
}

.ar {
  margin-left: auto;
  font-size: 16px;
  line-height: 1;
  color: rgba(255, 255, 255, 0.55);
}

.mi:hover .ar,
.mi.hi .ar {
  color: #fff;
}

.mi kbd {
  margin-left: auto;
  font-family: inherit;
  color: rgba(255, 255, 255, 0.45);
}

.stem {
  flex: none;
  width: 10px;
  height: 10px;
  border-radius: 3px;
  box-shadow: inset 0 0 0 0.5px rgba(255, 255, 255, 0.35);
}

hr {
  height: 1px;
  margin: 5px 10px;
  border: 0;
  background: rgba(255, 255, 255, 0.13);
}

.desk-hint {
  position: absolute;
  left: 26px;
  bottom: 24px;
  max-width: 60%;
  font-family: var(--font);
  font-size: 0.92rem;
  color: rgba(255, 255, 255, 0.72);
}

.desk-hint b {
  font-weight: 600;
  color: var(--zinc-50);
}

@media (max-width: 700px) {
  .desk {
    height: 540px;
  }

  .hide-sm {
    display: none;
  }

  .menu {
    right: 14px;
  }

  .submenu,
  .submenu.lang {
    top: 20px;
    right: 14px;
  }

  .desk-hint {
    left: 18px;
    right: 18px;
    max-width: none;
  }
}

@media (max-width: 420px) {
  .hide-xs {
    display: none;
  }
}
</style>
