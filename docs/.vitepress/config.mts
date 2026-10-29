import { defineConfigWithTheme } from 'vitepress'
import type { ThemeConfig } from './theme/types'

const site = 'https://halitsever.github.io/keycream/'
const description = 'Mechanical keyboard sounds for your Mac. A free, open-source menu bar app that plays a real switch recording for every keystroke.'

export default defineConfigWithTheme<ThemeConfig>({
  base: '/keycream/',
  lang: 'en',
  title: 'KeyCream',
  titleTemplate: ':title – KeyCream',
  description,
  cleanUrls: true,
  appearance: { initialValue: 'dark', storageKey: 'keycream-theme' },
  sitemap: { hostname: site },
  srcExclude: ['scripts/**', 'README.md'],

  head: [
    ['link', { rel: 'icon', href: '/keycream/favicon.ico', sizes: '32x32' }],
    ['link', { rel: 'icon', href: '/keycream/favicon.svg', type: 'image/svg+xml' }],
    ['link', { rel: 'apple-touch-icon', href: '/keycream/apple-touch-icon.png' }],
    ['meta', { name: 'theme-color', content: '#2A1F1A' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: 'KeyCream' }],
    ['meta', { property: 'og:image', content: `${site}app-icon.png` }],
    ['meta', { name: 'twitter:card', content: 'summary' }],
  ],

  transformPageData(pageData) {
    const title = pageData.frontmatter.title ?? pageData.title
    pageData.frontmatter.head ??= []
    pageData.frontmatter.head.push(
      ['meta', { property: 'og:title', content: pageData.frontmatter.layout === 'home' ? 'KeyCream' : `${title} – KeyCream` }],
      ['meta', { property: 'og:description', content: pageData.frontmatter.description ?? description }],
    )
  },

  // The page should read as KeyCream's own site, not as a generator's output.
  transformHtml(html) {
    return html
      .replace(/<meta name="generator"[^>]*>\s*/g, '')
      // The inline theme script has its storage key hard-coded, so it must match the storageKey above.
      .replaceAll('vitepress-theme-appearance', 'keycream-theme')
  },

  markdown: {
    theme: { light: 'vitesse-light', dark: 'vitesse-dark' },
    container: {
      tipLabel: 'Tip',
      infoLabel: 'Good to know',
      warningLabel: 'Heads up',
      dangerLabel: 'Careful',
      detailsLabel: 'Details',
    },
  },

  themeConfig: {
    repo: 'halitsever/keycream',
    nav: [
      { text: 'Docs', link: '/guide/installation' },
      { text: 'Sound packs', link: '/#packs' },
      { text: 'GitHub', link: 'https://github.com/halitsever/keycream' },
    ],
    sidebar: [
      {
        text: 'Getting started',
        items: [
          { text: 'Installation', link: '/guide/installation' },
          { text: 'Using KeyCream', link: '/guide/usage' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Sound packs', link: '/guide/sound-packs' },
          { text: 'Privacy', link: '/guide/privacy' },
          { text: 'Troubleshooting', link: '/guide/troubleshooting' },
        ],
      },
      {
        text: 'Development',
        items: [{ text: 'Building from source', link: '/guide/building' }],
      },
    ],
  },
})
