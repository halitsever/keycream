<script setup lang="ts">
import { withBase } from 'vitepress'
import DownloadButton from './DownloadButton.vue'
import KeyboardDemo from './KeyboardDemo.vue'
import PackList from './PackList.vue'

const features = [
  { title: 'Every key has its own sound', text: 'Letters, Space, Return, Delete and the modifiers each play their own recording, like on the real keyboard.' },
  { title: 'Even volume', text: 'Every key is leveled when a pack loads, so no single key jumps out while you type.' },
  { title: 'Natural typing', text: 'Holding a key plays one click, not a burst, and fast typing overlaps instead of cutting off.' },
  { title: 'Lives in the menu bar', text: 'No Dock icon and nothing to manage. It starts at login and remembers your settings.' },
  { title: 'In your language', text: 'Twelve languages. KeyCream follows your Mac, or you pick one from the menu.' },
  { title: 'Private by design', text: 'It knows which key went down, never what you wrote, and it never connects to the internet.' },
]

const steps = [
  { title: 'Download and unzip', text: 'Get the latest release. It runs on macOS 14 or later, on Apple Silicon and Intel Macs.' },
  { title: 'Move it to Applications and open it', text: 'If macOS asks you to confirm the app, the installation guide shows where to do it.' },
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
    q: 'Does it work on Intel Macs?',
    a: 'Yes. Every release is a universal app for Apple Silicon and Intel, running macOS 14 Sonoma or later.',
  },
  {
    q: 'It went quiet after an update. What happened?',
    a: 'macOS sometimes asks for Input Monitoring again after an app changes. Remove KeyCream from the Input Monitoring list, add it back, and the sounds return.',
  },
]
</script>

<template>
  <div class="home">
    <section class="container hero">
      <h1 class="headline">Mechanical keyboard sounds for your Mac.</h1>
      <div class="hero-side">
        <p class="lede">
          KeyCream lives in your menu bar and plays a real switch recording every time you press a key.
          Free and open source.
        </p>
        <DownloadButton />
      </div>
    </section>

    <section class="container keyboard" aria-label="Try KeyCream">
      <KeyboardDemo />
    </section>

    <section id="packs" class="container section">
      <div class="section-head">
        <h2>Seven switches to choose from</h2>
        <p>Each pack is a recording of a real keyboard. Listen to them here, then switch any time from the menu bar.</p>
      </div>
      <PackList />
    </section>

    <section class="container section">
      <div class="section-head">
        <h2>Made to stay out of your way</h2>
      </div>
      <dl class="features">
        <div v-for="feature in features" :key="feature.title" class="feature">
          <dt>{{ feature.title }}</dt>
          <dd>{{ feature.text }}</dd>
        </div>
      </dl>
    </section>

    <section id="install" class="container section">
      <div class="section-head">
        <h2>Up and running in a minute</h2>
        <p>Need more detail? Read the <a :href="withBase('/guide/installation')">installation guide</a>.</p>
      </div>
      <ol class="steps">
        <li v-for="step in steps" :key="step.title" class="step">
          <h3>{{ step.title }}</h3>
          <p>{{ step.text }}</p>
        </li>
      </ol>
      <DownloadButton />
    </section>

    <section class="container section">
      <div class="section-head">
        <h2>Questions</h2>
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
  display: grid;
  grid-template-columns: minmax(0, 1.8fr) minmax(0, 1fr);
  align-items: end;
  gap: 2.5rem 4rem;
  padding-top: clamp(3rem, 9vw, 7rem);
  padding-bottom: clamp(2.5rem, 6vw, 4.5rem);
}

.headline {
  font-size: clamp(2.9rem, 6.6vw, 5.6rem);
  font-weight: 800;
  line-height: 0.95;
  letter-spacing: -0.035em;
  font-variation-settings: 'opsz' 96;
}

.hero-side {
  display: grid;
  gap: 1.75rem;
  padding-bottom: 0.4rem;
}

.lede {
  margin: 0;
  max-width: 36ch;
  font-size: 1.2rem;
  line-height: 1.5;
  color: var(--text-muted);
}

.keyboard {
  max-width: calc(1000px + 2 * var(--gutter));
}

.section {
  padding-top: clamp(4.5rem, 10vw, 8rem);
}

.section-head {
  display: grid;
  gap: 0.75rem;
  max-width: 44rem;
  margin-bottom: 2.25rem;
}

.section-head h2 {
  font-size: clamp(2rem, 4.2vw, 3rem);
  font-weight: 780;
  letter-spacing: -0.025em;
}

.section-head p {
  margin: 0;
  font-size: 1.1rem;
  color: var(--text-muted);
}

.section-head a {
  color: var(--accent);
  text-underline-offset: 3px;
}

.features {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 2.25rem 4rem;
  margin: 0;
}

.feature dt {
  font-size: 1.2rem;
  font-weight: 680;
  letter-spacing: -0.01em;
}

.feature dd {
  margin: 0.35rem 0 0;
  max-width: 46ch;
  color: var(--text-muted);
}

.steps {
  list-style: none;
  counter-reset: step;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 2rem 3rem;
  margin: 0 0 2.5rem;
  padding: 0;
}

.step {
  counter-increment: step;
}

.step::before {
  content: counter(step);
  display: block;
  margin-bottom: 0.5rem;
  font-size: 3.5rem;
  font-weight: 800;
  line-height: 1;
  color: var(--accent);
  font-variation-settings: 'opsz' 96;
}

.step h3 {
  font-size: 1.2rem;
  font-weight: 680;
}

.step p {
  margin: 0.4rem 0 0;
  color: var(--text-muted);
}

.faq {
  max-width: 48rem;
  border-top: 1px solid var(--rule);
}

.faq details {
  border-bottom: 1px solid var(--rule);
}

.faq summary {
  display: flex;
  justify-content: space-between;
  gap: 1rem;
  padding: 1.15rem 0;
  font-size: 1.15rem;
  font-weight: 650;
  list-style: none;
  cursor: pointer;
}

.faq summary::-webkit-details-marker {
  display: none;
}

.faq summary::after {
  content: '+';
  color: var(--accent);
  font-weight: 500;
  font-size: 1.4rem;
  line-height: 1;
  transition: transform 150ms ease;
}

.faq details[open] summary::after {
  transform: rotate(45deg);
}

.faq details p {
  margin: 0 0 1.25rem;
  max-width: 62ch;
  color: var(--text-muted);
}

@media (max-width: 860px) {
  .hero {
    grid-template-columns: 1fr;
    align-items: start;
  }

  .features,
  .steps {
    grid-template-columns: 1fr;
  }
}
</style>
