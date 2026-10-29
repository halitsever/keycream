// Renders a short typing sample for every sound pack, for the website's "Listen" buttons.
// Usage: swift docs/scripts/make-samples.swift Resources/SoundPacks docs/public/samples
import AVFoundation

let phrase = "keycream sounds good"
/** PC scan codes that Mechvibes configs use as keys. */
let scanCodes: [Character: String] = [
    "q": "16", "w": "17", "e": "18", "r": "19", "t": "20", "y": "21", "u": "22", "i": "23", "o": "24", "p": "25",
    "a": "30", "s": "31", "d": "32", "f": "33", "g": "34", "h": "35", "j": "36", "k": "37", "l": "38",
    "z": "44", "x": "45", "c": "46", "v": "47", "b": "48", "n": "49", "m": "50", " ": "57",
]
let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func read(_ url: URL) -> AVAudioPCMBuffer {
    guard let file = try? AVAudioFile(forReading: url),
          let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
          (try? file.read(into: buffer)) != nil else { fail("Cannot read \(url.path)") }
    return buffer
}

func convert(_ buffer: AVAudioPCMBuffer) -> [Float] {
    guard let converter = AVAudioConverter(from: buffer.format, to: format),
          let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate) + 1024) else {
        fail("Cannot convert \(buffer.format)")
    }
    var consumed = false
    converter.convert(to: output, error: nil) { _, status in
        if consumed { status.pointee = .endOfStream; return nil }
        consumed = true
        status.pointee = .haveData
        return buffer
    }
    return Array(UnsafeBufferPointer(start: output.floatChannelData![0], count: Int(output.frameLength)))
}

func slice(_ buffer: AVAudioPCMBuffer, startMs: Double, durationMs: Double) -> AVAudioPCMBuffer {
    let rate = buffer.format.sampleRate
    let start = Int(rate * startMs / 1000), length = Int(rate * durationMs / 1000)
    let out = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(length))!
    out.frameLength = AVAudioFrameCount(length)
    for channel in 0..<Int(buffer.format.channelCount) {
        out.floatChannelData![channel].update(from: buffer.floatChannelData![channel] + start, count: length)
    }
    return out
}

/** Same targets the app uses, so every key in every pack lands at a similar loudness. */
func normalized(_ samples: [Float]) -> [Float] {
    let peak = samples.map(abs).max() ?? 0
    let rms = (samples.reduce(0) { $0 + $1 * $1 } / Float(max(samples.count, 1))).squareRoot()
    guard rms > 1e-4, peak > 1e-4 else { return samples }
    let gain = min(max(min(0.04 / rms, 0.92 / peak), 0.05), 8)
    return samples.map { $0 * gain }
}

let args = CommandLine.arguments
guard args.count == 3 else { fail("Usage: make-samples.swift <SoundPacks dir> <output dir>") }
let packsDir = URL(fileURLWithPath: args[1]), outDir = URL(fileURLWithPath: args[2])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

for folder in try FileManager.default.contentsOfDirectory(at: packsDir, includingPropertiesForKeys: nil) {
    guard let data = try? Data(contentsOf: folder.appendingPathComponent("config.json")),
          let config = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let defines = config["defines"] as? [String: Any] else { continue }

    let single = (config["key_define_type"] as? String) == "single"
    let source = single ? read(folder.appendingPathComponent(config["sound"] as! String)) : nil
    var keySounds: [String: [Float]] = [:]
    func sound(for code: String) -> [Float] {
        if let cached = keySounds[code] { return cached }
        let buffer: AVAudioPCMBuffer
        if let source, let range = defines[code] as? [Double] {
            buffer = slice(source, startMs: range[0], durationMs: range[1])
        } else if let name = defines[code] as? String {
            buffer = read(folder.appendingPathComponent(name))
        } else {
            fail("\(folder.lastPathComponent) has no sound for key \(code)")
        }
        keySounds[code] = normalized(convert(buffer))
        return keySounds[code]!
    }

    // A fixed, slightly uneven rhythm reads as a person typing rather than a metronome.
    let gaps: [Double] = [0.13, 0.11, 0.15, 0.12, 0.10, 0.14, 0.12, 0.16]
    var events: [(time: Double, samples: [Float])] = []
    var time = 0.15
    for (index, char) in phrase.enumerated() {
        events.append((time, sound(for: scanCodes[char]!)))
        time += gaps[index % gaps.count] + (char == " " ? 0.08 : 0)
    }
    let total = Int((time + 0.4) * format.sampleRate)
    var mix = [Float](repeating: 0, count: total)
    for event in events {
        let start = Int(event.time * format.sampleRate)
        for (i, value) in event.samples.enumerated() where start + i < total { mix[start + i] += value }
    }
    let peak = mix.map(abs).max() ?? 1
    if peak > 0.95 { mix = mix.map { $0 * 0.95 / peak } }

    let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(total))!
    out.frameLength = AVAudioFrameCount(total)
    mix.withUnsafeBufferPointer { out.floatChannelData![0].update(from: $0.baseAddress!, count: total) }
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false,
    ]
    let target = outDir.appendingPathComponent("\(folder.lastPathComponent).wav")
    try? FileManager.default.removeItem(at: target)
    let file = try AVAudioFile(forWriting: target, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    try file.write(from: out)
    print("Wrote \(target.lastPathComponent)")
}
