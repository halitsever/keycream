// Cuts the keys the /sounds page plays out of every pack into one small mono WAV per pack, plus a JSON map.
// Usage: node docs/scripts/make-web-sounds.mjs Resources/SoundPacks docs/public/sounds
import { mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'

const [packsDir, outDir] = process.argv.slice(2)
if (!packsDir || !outDir) throw new Error('usage: make-web-sounds.mjs <SoundPacks> <out>')

/** Letters, space, return, delete and shift as PC scan codes. Other keys borrow a letter's sound in the browser. */
const keys = [
  ...[16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 38, 44, 45, 46, 47, 48, 49, 50],
  57, 28, 14, 42,
].map(String)
const gapMs = 20

function readWav(file) {
  const buf = readFileSync(file)
  let offset = 12
  let fmt
  while (offset < buf.length) {
    const id = buf.toString('ascii', offset, offset + 4)
    const size = buf.readUInt32LE(offset + 4)
    const body = offset + 8
    if (id === 'fmt ') {
      fmt = { channels: buf.readUInt16LE(body + 2), rate: buf.readUInt32LE(body + 4), bits: buf.readUInt16LE(body + 14) }
    } else if (id === 'data') {
      if (!fmt || fmt.bits !== 16) throw new Error(`${file}: only 16-bit PCM is supported`)
      const frames = Math.floor(size / (2 * fmt.channels))
      const mono = new Float32Array(frames)
      for (let i = 0; i < frames; i++) {
        let sum = 0
        for (let c = 0; c < fmt.channels; c++) sum += buf.readInt16LE(body + 2 * (i * fmt.channels + c))
        mono[i] = sum / fmt.channels
      }
      return { rate: fmt.rate, samples: mono }
    }
    offset = body + size + (size % 2)
  }
  throw new Error(`${file}: no data chunk`)
}

function writeWav(file, rate, samples) {
  const out = Buffer.alloc(44 + samples.length * 2)
  out.write('RIFF', 0, 'ascii')
  out.writeUInt32LE(36 + samples.length * 2, 4)
  out.write('WAVEfmt ', 8, 'ascii')
  out.writeUInt32LE(16, 16)
  out.writeUInt16LE(1, 20)
  out.writeUInt16LE(1, 22)
  out.writeUInt32LE(rate, 24)
  out.writeUInt32LE(rate * 2, 28)
  out.writeUInt16LE(2, 32)
  out.writeUInt16LE(16, 34)
  out.write('data', 36, 'ascii')
  out.writeUInt32LE(samples.length * 2, 40)
  samples.forEach((s, i) => out.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(s))), 44 + i * 2))
  writeFileSync(file, out)
}

mkdirSync(outDir, { recursive: true })
for (const id of readdirSync(packsDir).sort()) {
  const config = JSON.parse(readFileSync(join(packsDir, id, 'config.json'), 'utf8'))
  const clips = []
  let rate
  const single = config.key_define_type === 'single' ? readWav(join(packsDir, id, config.sound)) : null
  for (const key of keys) {
    const def = config.defines[key]
    if (!def) continue
    let clip
    if (single) {
      const [startMs, lengthMs] = def
      const start = Math.round((startMs / 1000) * single.rate)
      clip = single.samples.subarray(start, start + Math.round((lengthMs / 1000) * single.rate))
      rate = single.rate
    } else {
      const wav = readWav(join(packsDir, id, def))
      clip = wav.samples
      rate = wav.rate
    }
    clips.push([key, clip])
  }
  const gap = Math.round((gapMs / 1000) * rate)
  const total = clips.reduce((n, [, clip]) => n + clip.length + gap, 0)
  const sprite = new Float32Array(total)
  const map = {}
  let at = 0
  for (const [key, clip] of clips) {
    sprite.set(clip, at)
    map[key] = [Math.round((at / rate) * 1000), Math.round((clip.length / rate) * 1000)]
    at += clip.length + gap
  }
  writeWav(join(outDir, `${id}.wav`), rate, sprite)
  writeFileSync(join(outDir, `${id}.json`), JSON.stringify(map) + '\n')
  console.log(`${id}: ${clips.length} keys, ${(sprite.length / rate).toFixed(1)} s`)
}
