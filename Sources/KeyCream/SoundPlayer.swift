import AVFoundation

/** Plays the sound assigned to each key from a Mechvibes pack loaded into memory. */
final class SoundPlayer {
    private struct PreparedSound {
        let buffer: AVAudioPCMBuffer
        let gain: Float
    }

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    /** Several nodes so fast typing overlaps instead of cutting the previous click. */
    private var players: [AVAudioPlayerNode] = []
    private var nextPlayer = 0
    private var sounds: [String: PreparedSound] = [:]
    private var configObserver: NSObjectProtocol?

    /** Player volume goes above 1 when a quiet file needs boosting, so the user level is applied per play. */
    var volume: Float = 1.0

    init(playerCount: Int = 10) throws {
        format = engine.mainMixerNode.outputFormat(forBus: 0)
        for _ in 0..<playerCount {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        try engine.start()

        configObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            self?.restartEngine()
        }
    }

    deinit {
        if let configObserver { NotificationCenter.default.removeObserver(configObserver) }
        engine.stop()
    }

    /** Replaces the current sounds only when the whole pack loads, so a broken pack keeps the old one playing. */
    func load(_ pack: SoundPack) throws {
        let config = pack.config
        let packVolume = Float(config.recommendedVolume ?? 1.0)
        var loaded: [String: PreparedSound] = [:]

        switch config.keyDefineType {
        case .multi:
            var fileSounds: [String: PreparedSound] = [:]
            for (code, definition) in config.defines {
                guard case let .file(name)? = definition else { continue }
                if fileSounds[name] == nil {
                    let raw = try Self.loadBuffer(pack.directory.appendingPathComponent(name))
                    fileSounds[name] = try Self.prepare(raw, format: format, packVolume: packVolume)
                }
                loaded[code] = fileSounds[name]
            }
        case .single:
            let source = try Self.loadBuffer(pack.directory.appendingPathComponent(config.sound))
            let sampleRate = source.format.sampleRate
            for (code, definition) in config.defines {
                guard case let .range(startMs, durationMs)? = definition, durationMs > 0 else { continue }
                let start = Int(sampleRate * (startMs / 1000))
                let length = Int(sampleRate * (durationMs / 1000))
                guard length > 0, start + length <= Int(source.frameLength),
                      let slice = Self.copy(source, from: start, length: length) else { continue }
                loaded[code] = try Self.prepare(slice, format: format, packVolume: packVolume)
            }
        }

        guard !loaded.isEmpty else { throw Self.error("\(config.name) has no playable sounds") }
        sounds = loaded
        print("Loaded \(config.name): \(loaded.count) keys")
    }

    func play(code: String) {
        guard let sound = sounds[code] else { return }
        if !engine.isRunning { restartEngine() }

        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        player.stop()
        player.volume = sound.gain * volume
        player.scheduleBuffer(sound.buffer, at: nil)
        player.play()
    }

    /** The engine stops itself when the output device changes, e.g. headphones plugged in. */
    private func restartEngine() {
        do {
            try engine.start()
        } catch {
            print("Audio engine restart failed: \(error)")
        }
    }

    // MARK: - Loading

    private static func prepare(_ raw: AVAudioPCMBuffer, format: AVAudioFormat, packVolume: Float) throws -> PreparedSound {
        let converted = try convert(raw, to: format)
        applyProcessing(to: converted)
        let buffer = trimLeadingSilence(converted) ?? converted
        let (rms, peak) = loudness(of: buffer)
        guard rms > 1e-4, peak > 1e-4 else {
            return PreparedSound(buffer: buffer, gain: packVolume)
        }
        // Bring every key to the same RMS without pushing peaks past 0.92.
        let gain = min(max(min(0.04 / rms, 0.92 / peak), 0.05), 8.0)
        return PreparedSound(buffer: buffer, gain: gain * packVolume)
    }

    private static func loadBuffer(_ url: URL) throws -> AVAudioPCMBuffer {
        let file = try AVAudioFile(forReading: url)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
            throw error("Cannot allocate buffer for \(url.lastPathComponent)")
        }
        try file.read(into: buffer)
        return buffer
    }

    private static func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        if buffer.format == format { return buffer }
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            throw error("Cannot convert \(buffer.format) to \(format)")
        }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1024
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            throw error("Cannot allocate conversion buffer")
        }
        var consumed = false
        var conversionError: NSError?
        converter.convert(to: output, error: &conversionError) { _, status in
            if consumed {
                status.pointee = .endOfStream
                return nil
            }
            consumed = true
            status.pointee = .haveData
            return buffer
        }
        if let conversionError { throw conversionError }
        return output
    }

    /** DC-blocking high-pass, soft knee above 0.5, then a slight boost that sharpens the attack. */
    private static func applyProcessing(to buffer: AVAudioPCMBuffer) {
        guard let channels = buffer.floatChannelData else { return }
        for channel in 0..<Int(buffer.format.channelCount) {
            let samples = channels[channel]
            var previousInput: Float = 0
            var filtered: Float = 0
            var previousOutput: Float = 0
            for i in 0..<Int(buffer.frameLength) {
                let input = samples[i]
                filtered = (filtered + input - previousInput) * 0.98
                previousInput = input

                var shaped = filtered
                let magnitude = abs(filtered)
                if magnitude > 0.5 {
                    let knee = (magnitude - 0.5) / 3 + 0.5
                    shaped = filtered >= 0 ? knee : -knee
                }
                shaped *= 1.1
                previousOutput = shaped + (shaped + previousOutput * -0.3) * 0.15
                samples[i] = previousOutput
            }
        }
    }

    /** Starts 32 frames before the first sample above 0.003 so the click plays without delay. */
    private static func trimLeadingSilence(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let channels = buffer.floatChannelData else { return nil }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        for frame in 0..<frameCount {
            var level: Float = 0
            for channel in 0..<channelCount {
                level = max(level, abs(channels[channel][frame]))
            }
            guard level >= 0.003 else { continue }
            if frame <= 32 { return buffer }
            return copy(buffer, from: frame - 32, length: frameCount - frame + 32)
        }
        return nil
    }

    private static func copy(_ buffer: AVAudioPCMBuffer, from start: Int, length: Int) -> AVAudioPCMBuffer? {
        guard length > 0, start + length <= Int(buffer.frameLength),
              let source = buffer.floatChannelData,
              let output = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(length)),
              let destination = output.floatChannelData else { return nil }
        output.frameLength = AVAudioFrameCount(length)
        for channel in 0..<Int(buffer.format.channelCount) {
            destination[channel].update(from: source[channel] + start, count: length)
        }
        return output
    }

    /** RMS weighted toward fast changes, so the sharp click counts more than its quiet tail. */
    private static func loudness(of buffer: AVAudioPCMBuffer) -> (rms: Float, peak: Float) {
        guard let channels = buffer.floatChannelData else { return (0, 0) }
        var weightedSum: Float = 0
        var weightTotal: Float = 0
        var peak: Float = 0
        for channel in 0..<Int(buffer.format.channelCount) {
            var previous: Float = 0
            for i in 0..<Int(buffer.frameLength) {
                let sample = channels[channel][i]
                let weight = abs(sample - previous) * 0.5 + 1
                weightedSum += sample * sample * weight
                weightTotal += weight
                peak = max(peak, abs(sample))
                previous = sample
            }
        }
        guard weightTotal > 0 else { return (0, peak) }
        return (sqrt(weightedSum / weightTotal), peak)
    }

    private static func error(_ message: String) -> NSError {
        NSError(domain: "KeyCream", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
