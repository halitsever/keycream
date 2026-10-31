import { ref } from 'vue'
import { withBase } from 'vitepress'

// Module scope, so the menu bar demo and the pack grid never play over each other.
const playing = ref<string | null>(null)
let audio: HTMLAudioElement | null = null

function stop() {
  audio?.pause()
  audio = null
  playing.value = null
}

function play(id: string, volume = 1) {
  stop()
  audio = new Audio(withBase(`/samples/${id}.wav`))
  audio.volume = volume
  audio.addEventListener('ended', stop)
  playing.value = id
  audio.play().catch(stop)
}

function toggle(id: string, volume = 1) {
  if (playing.value === id) stop()
  else play(id, volume)
}

export function useSamples() {
  return { playing, play, toggle, stop }
}
