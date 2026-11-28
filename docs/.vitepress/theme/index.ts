import type { Theme } from 'vitepress'
import '@fontsource-variable/bricolage-grotesque/opsz.css'
import './styles/base.css'
import './styles/prose.css'
import Layout from './Layout.vue'
import DownloadButton from './components/DownloadButton.vue'
import Faq from './components/Faq.vue'
import PackSample from './components/PackSample.vue'
import SoundBoard from './components/SoundBoard.vue'

export default {
  Layout,
  enhanceApp({ app }) {
    app.component('DownloadButton', DownloadButton)
    app.component('Faq', Faq)
    app.component('PackSample', PackSample)
    app.component('SoundBoard', SoundBoard)
  },
} satisfies Theme
