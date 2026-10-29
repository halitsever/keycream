import { onMounted, ref } from 'vue'

export interface Release {
  version: string
  downloadUrl: string
  sizeBytes: number
}

type State = 'loading' | 'ready' | 'unavailable'

// Module scope, so every download button on a page shares one GitHub API request.
const release = ref<Release | null>(null)
const state = ref<State>('loading')
let request: Promise<void> | null = null

async function load(repo: string) {
  try {
    const response = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      headers: { Accept: 'application/vnd.github+json' },
    })
    if (!response.ok) throw new Error(`GitHub answered ${response.status}`)
    const data = await response.json()
    const asset = data.assets?.find((item: { name: string }) => item.name.endsWith('.zip'))
    if (!asset) throw new Error('The latest release has no .zip asset')
    release.value = {
      version: String(data.tag_name).replace(/^v/, ''),
      downloadUrl: asset.browser_download_url,
      sizeBytes: asset.size,
    }
    state.value = 'ready'
  } catch {
    state.value = 'unavailable'
  }
}

export function useLatestRelease(repo: string) {
  onMounted(() => {
    request ??= load(repo)
  })
  return { release, state, releasesPage: `https://github.com/${repo}/releases/latest` }
}

export function formatSize(bytes: number) {
  return `${Math.max(1, Math.round(bytes / 1_000_000))} MB`
}
