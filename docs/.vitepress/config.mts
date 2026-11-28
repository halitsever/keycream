import { defineConfigWithTheme } from 'vitepress'
import type { ThemeConfig } from './theme/types'

const site = 'https://projects.halit.org/keycream/'
const description = 'Mechanical keyboard sounds for Mac. KeyCream is a free, open-source menu bar app that plays a real switch recording for every keystroke, with seven sound packs.'

const repo = 'https://github.com/halitsever/keycream'
const blog: [string, string][] = [
  ['mechvibes-dx', 'Mechvibes DX'],
  ['creamy-keyboard-sound', 'Creamy keyboard sound'],
  ['linear-keyboard-switches', 'Linear switches'],
  ['cherry-mx-brown', 'Cherry MX Brown'],
  ['keyboard-switch-types', 'Keyboard switch types'],
  ['cherry-mx-red-vs-brown-vs-blue', 'Red vs Brown vs Blue'],
  ['mechvibes-custom-sound-packs', 'Mechvibes custom sounds'],
  ['is-mechvibes-safe', 'Is Mechvibes safe?'],
  ['cherry-mx-blue', 'Cherry MX Blue'],
  ['cherry-mx-black', 'Cherry MX Black'],
  ['clicky-switches', 'Clicky switches'],
  ['tactile-vs-linear-switches', 'Tactile vs linear'],
  ['thocky-keyboard', 'What is thock?'],
  ['asmr-keyboard', 'ASMR keyboard sounds'],
]
const halit = { '@type': 'Person', name: 'Halit Sever', url: 'https://halit.org' }
const license = 'https://opensource.org/licenses/MIT'
const author = { '@type': 'Person', name: 'Halit Sever', url: 'https://github.com/halitsever' }

const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'SoftwareSourceCode',
      '@id': `${site}#source`,
      name: 'KeyCream',
      description,
      url: site,
      image: `${site}og.png`,
      codeRepository: repo,
      programmingLanguage: 'Swift',
      license,
      author,
    },
  ],
}

export default defineConfigWithTheme<ThemeConfig>({
  /** keeps the page hash map out of every page's HTML, which Semrush reads as a low text-to-HTML ratio */
  metaChunk: true,
  base: '/keycream/',
  lang: 'en',
  title: 'KeyCream',
  titleTemplate: ':title – KeyCream',
  description,
  cleanUrls: true,
  // Clears the floating nav. Matches scroll-padding-top in base.css and the story anchor.
  scrollOffset: 96,
  appearance: 'force-dark',
  sitemap: { hostname: site },
  srcExclude: ['scripts/**', 'README.md'],

  head: [
    /** Cloudflare Web Analytics, one token for every page on projects.halit.org. */
    ['script', { defer: '', src: 'https://static.cloudflareinsights.com/beacon.min.js', 'data-cf-beacon': '{"token": "dd7e54d3f48841c187d72d9dbb92a6b6"}' }],
    ['link', { rel: 'icon', href: '/keycream/favicon.ico', sizes: '32x32' }],
    ['link', { rel: 'icon', href: '/keycream/favicon.svg', type: 'image/svg+xml' }],
    ['link', { rel: 'apple-touch-icon', href: '/keycream/apple-touch-icon.png' }],
    ['meta', { name: 'theme-color', content: '#09090B' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:site_name', content: 'KeyCream' }],
    ['meta', { property: 'og:image', content: `${site}og.png` }],
    ['meta', { property: 'og:image:width', content: '1280' }],
    ['meta', { property: 'og:image:height', content: '640' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['script', { type: 'application/ld+json' }, JSON.stringify(jsonLd)],
  ],

  transformPageData(pageData) {
    const title = pageData.frontmatter.title ?? pageData.title
    const path = pageData.relativePath.replace(/(^|\/)index\.md$/, '$1').replace(/\.md$/, '')
    const url = site + path
    const desc = pageData.frontmatter.description ?? description
    pageData.frontmatter.head ??= []
    const graph: Record<string, unknown>[] = []
    if (path.startsWith('blog/') && path !== 'blog/') {
      graph.push(
        {
          '@type': 'BlogPosting',
          headline: title,
          description: desc,
          url,
          mainEntityOfPage: url,
          image: `${site}og.png`,
          inLanguage: 'en',
          datePublished: pageData.frontmatter.date,
          dateModified: pageData.frontmatter.date,
          author: halit,
          publisher: halit,
        },
        {
          '@type': 'BreadcrumbList',
          itemListElement: [
            { '@type': 'ListItem', position: 1, name: 'KeyCream', item: site },
            { '@type': 'ListItem', position: 2, name: 'Blog', item: `${site}blog/` },
            { '@type': 'ListItem', position: 3, name: title, item: url },
          ],
        },
      )
    } else if (path === 'blog/') {
      graph.push({ '@type': 'Blog', name: 'KeyCream blog', description: desc, url, inLanguage: 'en', author: halit })
    }
    const faq = pageData.frontmatter.faq as { q: string; a: string }[] | undefined
    if (faq?.length) {
      graph.push({ '@type': 'FAQPage', mainEntity: faq.map((f) => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a } })) })
    }
    if (graph.length) pageData.frontmatter.head.push(['script', { type: 'application/ld+json' }, JSON.stringify({ '@context': 'https://schema.org', '@graph': graph })])
    pageData.frontmatter.head.push(
      ['link', { rel: 'canonical', href: url }],
      ['meta', { property: 'og:url', content: url }],
      ['meta', { property: 'og:title', content: pageData.frontmatter.layout === 'home' ? 'Mechanical keyboard sounds for Mac – KeyCream' : pageData.frontmatter.titleTemplate === false ? title : `${title} – KeyCream` }],
      ['meta', { property: 'og:description', content: desc }],
    )
  },

  // The page should read as KeyCream's own site, not as a generator's output.
  transformHtml(html) {
    return html
      .replace(/<meta name="generator"[^>]*>\s*/g, '')
      // The site is dark only and uses no icon font, so these are dead weight.
      .replace(/<link[^>]*vp-icons\.css[^>]*>\s*/g, '')
      .replace(/<script id="check-(?:dark-mode|mac-os)">[\s\S]*?<\/script>\s*/g, '')
  },

  markdown: {
    theme: { light: 'github-light-default', dark: 'github-dark-default' },
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
      { text: 'How it works', link: '/#how' },
      { text: 'Sound packs', link: '/#packs' },
      { text: 'Install', link: '/#install' },
      { text: 'Docs', link: '/guide/installation' },
      { text: 'Blog', link: '/blog/' },
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
      {
        text: 'Compare',
        items: [
          { text: 'KeyCream vs Klack vs Mechvibes', link: '/guide/keycream-vs-klack-vs-mechvibes' },
          { text: 'Keyboard switch sounds', link: '/sounds' },
        ],
      },
    ],
    blogSidebar: [
      { text: 'Blog', items: [{ text: 'All posts', link: '/blog/' }, ...blog.map(([slug, text]) => ({ text, link: `/blog/${slug}` }))] },
      {
        text: 'KeyCream',
        items: [
          { text: 'Keyboard switch sounds', link: '/sounds' },
          { text: 'Sound packs', link: '/guide/sound-packs' },
          { text: 'Installation', link: '/guide/installation' },
        ],
      },
    ],
  },
})
