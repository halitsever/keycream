<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { useData, withBase } from 'vitepress'
import type { ThemeConfig } from '../types'
import { languages } from '../data/packs'
import DownloadButton from './DownloadButton.vue'
import KeyboardDemo from './KeyboardDemo.vue'
import KeystrokeStory from './KeystrokeStory.vue'
import MenuBarDemo from './MenuBarDemo.vue'
import PackList from './PackList.vue'

const { theme } = useData<ThemeConfig>()
const repoUrl = `https://github.com/${theme.value.repo}`

const menuPoints = [
  { title: 'Volume.', text: 'Low, Medium or High, on top of your Mac’s own volume.' },
  { title: 'Sound Pack.', text: 'Seven switches. A new pack plays the moment you pick it.' },
  { title: 'Language.', text: 'Twelve languages. It follows your Mac, or you choose one.' },
  { title: 'Sounds On.', text: 'Turns the clicks off without quitting the app.' },
]

const features = [
  { title: 'Every key has its own sound', text: 'Letters, Space, Return, Delete, the modifiers and the function row each play their own recording.' },
  { title: 'Even volume', text: 'Every key is leveled when a pack loads, so no single key jumps out while you type.' },
  { title: 'Natural typing', text: 'Holding a key plays one click, not a burst, and fast typing overlaps instead of cutting off.' },
  { title: 'Built for every Mac', text: 'A universal app for Apple Silicon and Intel on macOS 14 or later. No Dock icon, and it opens at login.' },
]

const neverDoes = ['Store your key presses', 'Turn them into text', 'Connect to the internet', 'Change or block a key']

const steps = [
  { title: 'Download and unzip', text: 'Get the latest release from GitHub. It runs on macOS 14 or later.' },
  { title: 'Move it to Applications', text: 'Open it from there. If macOS won’t open it yet, click Open Anyway under Privacy & Security, or run the Terminal command.' },
  { title: 'Allow keyboard access', text: 'Turn on KeyCream under Privacy & Security, Input Monitoring. Sounds start within a few seconds.' },
]

const questions = [
  {
    q: 'Is KeyCream free?',
    a: 'Yes. KeyCream is free and open source under the MIT License, and so are the bundled sound packs from the Mechvibes project.',
  },
  {
    q: 'Can KeyCream see what I type?',
    a: 'No. macOS tells it which physical key went down, and that is only used to pick a sound. KeyCream never stores keys, never puts them together into text, and has no networking code at all.',
  },
  {
    q: 'Why does it need Input Monitoring?',
    a: 'macOS asks for this permission for any app that reacts to key presses made in other apps. KeyCream only listens. It cannot change, block or send keys.',
  },
  {
    q: 'Do the function keys click too?',
    a: 'Yes. F1 to F12, the brightness, media and volume keys and fn each play the sound of the key in the same spot.',
  },
  {
    q: 'Does it work on Intel Macs?',
    a: 'Yes. Every release is a universal app for Apple Silicon and Intel, running macOS 14 Sonoma or later.',
  },
  {
    q: 'It went quiet after an update. What happened?',
    a: 'macOS sometimes asks for Input Monitoring again after an app changes. Remove KeyCream from the Input Monitoring list, add it back, and the sounds return.',
  },
]

const frame = ref<HTMLElement | null>(null)
const tilt = ref(1)
let reduced = false
let rafId = 0

/** The keyboard lies back on the desk at first and stands up as the hero scrolls away. */
function update() {
  rafId = 0
  if (reduced || !frame.value) {
    tilt.value = 0
    return
  }
  const top = frame.value.getBoundingClientRect().top
  const vh = window.innerHeight
  tilt.value = Math.min(Math.max((top - vh * 0.12) / (vh * 0.6), 0), 1)
}

function onScroll() {
  rafId ||= requestAnimationFrame(update)
}

onMounted(() => {
  reduced = matchMedia('(prefers-reduced-motion: reduce)').matches
  window.addEventListener('scroll', onScroll, { passive: true })
  window.addEventListener('resize', onScroll, { passive: true })
  update()
})

onBeforeUnmount(() => {
  window.removeEventListener('scroll', onScroll)
  window.removeEventListener('resize', onScroll)
  cancelAnimationFrame(rafId)
})
</script>

<template>
  <div class="home">
    <section class="hero" aria-labelledby="hero-title">
      <div class="wrap hero-copy">
        <p class="eyebrow">Mechanical keyboard sounds for macOS</p>
        <h1 id="hero-title">Every key<br /><span class="hl">goes thock.</span></h1>
        <p class="hero-lede">
          KeyCream plays a real switch recording each time you press a key. It lives in your menu bar, it&rsquo;s free,
          and it never sees what you type.
        </p>
        <DownloadButton class="hero-cta">
          <a class="btn btn-ghost" href="#packs">Hear the switches</a>
        </DownloadButton>
      </div>
      <div ref="frame" class="wrap hero-frame">
        <KeyboardDemo :tilt="tilt" />
      </div>
    </section>

    <section id="using" class="wrap sec using" aria-labelledby="using-title">
      <div>
        <p class="kicker">Using KeyCream</p>
        <h2 id="using-title" class="display">Lives in your menu bar.</h2>
        <p class="lead">
          There&rsquo;s no window and no Dock icon. Click the keycap at the top of your screen and everything is right
          there. Every choice is saved the moment you make it.
        </p>
        <ul class="points">
          <li v-for="point in menuPoints" :key="point.title"><strong>{{ point.title }}</strong> {{ point.text }}</li>
        </ul>
      </div>
      <MenuBarDemo />
    </section>

    <KeystrokeStory />

    <section id="packs" class="wrap sec" aria-labelledby="packs-title">
      <div class="sec-head">
        <div>
          <p class="kicker">Sound packs</p>
          <h2 id="packs-title" class="display">Seven switches to choose from.</h2>
        </div>
        <p class="lead">
          Each pack is a recording of a real mechanical keyboard. Listen to them here, then switch any time from the menu bar.
        </p>
      </div>
      <PackList />
    </section>

    <section class="wrap sec" aria-labelledby="features-title">
      <div class="sec-head">
        <div>
          <p class="kicker">Details</p>
          <h2 id="features-title" class="display">Made to stay out of your way.</h2>
        </div>
      </div>
      <div class="bento">
        <article class="card privacy">
          <h3>Private by design</h3>
          <p>
            macOS tells KeyCream which key went down, as a number. That number picks a sound, and then it&rsquo;s gone.
          </p>
          <p class="never-title">It never does any of this:</p>
          <ul class="never">
            <li v-for="item in neverDoes" :key="item">
              <svg viewBox="0 0 16 16" aria-hidden="true"><path d="M4.5 4.5l7 7M11.5 4.5l-7 7" /></svg>
              <span>{{ item }}</span>
            </li>
          </ul>
          <a class="more" :href="withBase('/guide/privacy')">Read the privacy notes</a>
        </article>
        <article v-for="feature in features" :key="feature.title" class="card">
          <h3>{{ feature.title }}</h3>
          <p>{{ feature.text }}</p>
        </article>
        <article class="card languages">
          <div>
            <h3>In your language</h3>
            <p>KeyCream follows your Mac&rsquo;s language, or you pick one from its menu.</p>
          </div>
          <ul>
            <li v-for="name in languages" :key="name">{{ name }}</li>
          </ul>
        </article>
      </div>
    </section>

    <section id="install" class="wrap sec" aria-labelledby="install-title">
      <div class="install">
        <div>
          <p class="kicker">Install</p>
          <h2 id="install-title" class="display">Up and running in a&nbsp;minute.</h2>
          <ol class="steps">
            <li v-for="(step, index) in steps" :key="step.title">
              <span class="cap" aria-hidden="true">{{ index + 1 }}</span>
              <div>
                <h3>{{ step.title }}</h3>
                <p>{{ step.text }}</p>
              </div>
            </li>
          </ol>
          <DownloadButton />
        </div>

        <div class="term" role="region" aria-label="Terminal commands">
          <div class="term-bar"><i></i><i></i><i></i><span>Terminal</span></div>
          <pre><span class="c"># If macOS blocks the first launch</span>
<span class="p">%</span> xattr -dr com.apple.quarantine /Applications/KeyCream.app

<span class="c"># Or build it yourself, with Xcode 15.3 or later</span>
<span class="p">%</span> git clone {{ repoUrl }}.git
<span class="p">%</span> cd keycream &amp;&amp; ./build.sh
<span class="p">%</span> open build/KeyCream.app<span class="caret" aria-hidden="true"></span></pre>
          <p class="term-note">
            More help in the <a :href="withBase('/guide/installation')">installation guide</a> and
            <a :href="withBase('/guide/building')">building from source</a>.
          </p>
        </div>
      </div>
    </section>

    <section class="wrap sec faq-sec" aria-labelledby="faq-title">
      <div>
        <h2 id="faq-title" class="display">Questions</h2>
        <p class="lead">
          Something else? <a :href="`${repoUrl}/issues`">Open an issue on GitHub</a> or read the
          <a :href="withBase('/guide/troubleshooting')">troubleshooting guide</a>.
        </p>
      </div>
      <div class="faq">
        <details v-for="item in questions" :key="item.q">
          <summary>{{ item.q }}</summary>
          <p>{{ item.a }}</p>
        </details>
      </div>
    </section>
  </div>
</template>

<style scoped>
.hero {
  position: relative;
  padding-top: 168px;
  overflow-x: clip;
}

/* The lamp: one soft pool of light behind the headline. */
.hero::before {
  content: '';
  position: absolute;
  left: 50%;
  top: -260px;
  width: 1300px;
  height: 900px;
  transform: translateX(-50%);
  pointer-events: none;
  filter: blur(10px);
  background: radial-gradient(closest-side, rgba(255, 255, 255, 0.07), rgba(255, 255, 255, 0.02) 55%, transparent);
}

.hero-copy {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 440px);
  column-gap: 48px;
  align-items: end;
}

.eyebrow,
h1 {
  grid-column: 1 / -1;
}

.eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 26px;
  font-size: 0.95rem;
  font-weight: 520;
  color: var(--dim);
}

.eyebrow::before {
  content: '';
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--zinc-50);
  box-shadow: 0 0 0 4px rgba(255, 255, 255, 0.2);
  animation: pulse 1.8s infinite;
}

@keyframes pulse {
  50% {
    box-shadow: 0 0 0 8px rgba(255, 255, 255, 0);
  }
}

h1 {
  margin-bottom: 44px;
  font-size: clamp(3.6rem, 11vw, 10rem);
  font-weight: 780;
  font-variation-settings: 'opsz' 96;
  letter-spacing: -0.055em;
  line-height: 0.88;
  white-space: nowrap;
  text-wrap: nowrap;
}

.hl {
  padding-right: 0.04em;
  color: transparent;
  -webkit-background-clip: text;
  background-clip: text;
  background-image: linear-gradient(100deg, var(--zinc-50) 0%, var(--zinc-300) 45%, var(--zinc-500) 100%);
}

.hero-lede {
  max-width: 34rem;
  font-size: 1.25rem;
  line-height: 1.55;
  color: var(--dim);
}

.hero-cta {
  justify-content: flex-end;
}

.hero-cta :deep(.details) {
  text-align: right;
}

.hero-frame {
  max-width: calc(1180px + 2 * var(--gutter));
  margin-top: 96px;
}

.sec {
  padding-top: 180px;
}

.using {
  display: grid;
  grid-template-columns: 1fr 1.15fr;
  gap: 72px;
  align-items: center;
}

.points {
  display: grid;
  gap: 14px;
  margin: 34px 0 0;
  padding: 0;
  list-style: none;
}

.points li {
  position: relative;
  padding-left: 26px;
  font-size: 1rem;
  line-height: 1.55;
  color: var(--dim);
}

.points li::before {
  content: '';
  position: absolute;
  left: 2px;
  top: 8px;
  width: 9px;
  height: 9px;
  border-radius: 3px;
  background: var(--zinc-400);
  box-shadow: inset 0 -2px 0 rgba(0, 0, 0, 0.25);
}

.points strong {
  font-weight: 600;
  color: var(--text);
}

.sec-head {
  display: grid;
  grid-template-columns: 1.2fr 1fr;
  gap: 24px 64px;
  align-items: end;
  margin-bottom: 52px;
}

.sec-head .display {
  margin-bottom: 0;
}

.bento {
  display: grid;
  grid-template-columns: 1.25fr 1fr 1fr;
  gap: 14px;
}

.privacy {
  grid-row: span 2;
  display: flex;
  flex-direction: column;
  background:
    radial-gradient(90% 60% at 0% 0%, rgba(255, 255, 255, 0.06), transparent 70%),
    linear-gradient(180deg, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0.015));
}

.privacy h3 {
  font-size: 1.6rem;
}

.never-title {
  margin-top: 22px;
  font-size: 0.9rem;
  font-weight: 560;
  color: var(--text);
}

.never {
  display: grid;
  gap: 0;
  margin: 8px 0 24px;
  padding: 0;
  list-style: none;
}

.never li {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid var(--line);
  font-size: 1rem;
}

.never svg {
  flex: none;
  width: 22px;
  height: 22px;
  padding: 4px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.08);
  fill: none;
  stroke: var(--text);
  stroke-width: 2;
  stroke-linecap: round;
}

.more {
  margin-top: auto;
  font-weight: 600;
  color: var(--accent);
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 4px;
}

.languages {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: minmax(220px, 0.8fr) 2fr;
  gap: 18px 40px;
  align-items: center;
}

.languages ul {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.languages li {
  padding: 7px 13px;
  border-radius: 999px;
  font-size: 0.92rem;
  background: rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 0 0 1px var(--line);
}

.install {
  display: grid;
  grid-template-columns: 1fr 1.05fr;
  gap: 64px;
  align-items: start;
}

.steps {
  display: grid;
  gap: 22px;
  margin: 36px 0 40px;
  padding: 0;
  list-style: none;
}

.steps li {
  display: flex;
  gap: 18px;
}

/* The step numbers are keycaps, like the rest of the brand. */
.cap {
  flex: none;
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border-radius: 11px;
  background: linear-gradient(180deg, #fafafa, #e4e4e7);
  color: var(--zinc-900);
  font-weight: 700;
  box-shadow:
    inset 0 -4px 0 #d4d4d8,
    0 4px 0 #71717a,
    0 8px 14px rgba(0, 0, 0, 0.4);
}

.steps h3 {
  font-size: 1.15rem;
  font-weight: 620;
  letter-spacing: -0.015em;
}

.steps p {
  margin-top: 4px;
  color: var(--dim);
}

.term {
  overflow: hidden;
  border-radius: 22px;
  background: var(--zinc-900);
  box-shadow:
    0 0 0 1px var(--line),
    0 30px 80px rgba(0, 0, 0, 0.5);
}

.term-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  height: 42px;
  padding: 0 16px;
  border-bottom: 1px solid var(--line);
}

.term-bar i {
  width: 11px;
  height: 11px;
  border-radius: 50%;
  background: var(--zinc-700);
}

.term-bar span {
  margin: 0 auto;
  transform: translateX(-24px);
  font-family: var(--mono);
  font-size: 0.75rem;
  color: var(--faint);
}

.term pre {
  margin: 0;
  padding: 26px 26px 28px;
  overflow-x: auto;
  font-size: 0.86rem;
  line-height: 2;
  color: var(--zinc-200);
  white-space: pre;
}

.term .p {
  color: var(--zinc-400);
  user-select: none;
}

.term .c {
  color: var(--faint);
}

.caret {
  display: inline-block;
  width: 8px;
  height: 16px;
  margin-left: 4px;
  vertical-align: -3px;
  background: var(--zinc-50);
  animation: blink 1s steps(1) infinite;
}

@keyframes blink {
  50% {
    opacity: 0;
  }
}

.term-note {
  padding: 16px 26px 22px;
  border-top: 1px solid var(--line);
  font-size: 0.9rem;
  color: var(--dim);
}

.term-note a,
.lead a {
  color: var(--accent);
  text-decoration: underline;
  text-decoration-thickness: 1px;
  text-underline-offset: 3px;
}

.faq-sec {
  display: grid;
  grid-template-columns: 0.9fr 1.3fr;
  gap: 64px;
  align-items: start;
}

.faq-sec .display {
  margin-top: 0;
}

.faq {
  border-top: 1px solid var(--line);
}

.faq details {
  border-bottom: 1px solid var(--line);
}

.faq summary {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem 0;
  font-size: 1.15rem;
  font-weight: 580;
  letter-spacing: -0.01em;
  list-style: none;
  cursor: pointer;
}

.faq summary::-webkit-details-marker {
  display: none;
}

.faq summary::after {
  content: '';
  flex: none;
  width: 26px;
  height: 26px;
  border-radius: 8px;
  background:
    linear-gradient(var(--zinc-50), var(--zinc-50)) center / 10px 2px no-repeat,
    linear-gradient(var(--zinc-50), var(--zinc-50)) center / 2px 10px no-repeat,
    rgba(255, 255, 255, 0.06);
  transition: transform 0.2s ease;
}

.faq details[open] summary::after {
  transform: rotate(45deg);
}

.faq details p {
  max-width: 62ch;
  padding-bottom: 1.4rem;
  color: var(--dim);
}

@media (max-width: 1000px) {
  .bento {
    grid-template-columns: 1fr 1fr;
  }

  .privacy {
    grid-row: auto;
    grid-column: 1 / -1;
  }
}

@media (max-width: 900px) {
  .hero {
    padding-top: 128px;
  }

  .hero-copy {
    grid-template-columns: 1fr;
    row-gap: 28px;
  }

  h1 {
    margin-bottom: 4px;
    font-size: 15.5vw;
  }

  .hero-cta {
    justify-content: flex-start;
  }

  .hero-cta :deep(.details) {
    text-align: left;
  }

  .hero-frame {
    margin-top: 64px;
  }

  .sec {
    padding-top: 120px;
  }

  .using,
  .sec-head,
  .install,
  .faq-sec,
  .languages {
    grid-template-columns: 1fr;
    gap: 36px;
  }

  .sec-head {
    gap: 18px;
    margin-bottom: 36px;
  }

  .languages {
    gap: 18px;
  }
}

@media (max-width: 560px) {
  .bento {
    grid-template-columns: 1fr;
  }

  .hero-lede {
    font-size: 1.1rem;
  }
}
</style>
