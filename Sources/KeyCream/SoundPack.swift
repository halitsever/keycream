import Foundation

/** A Mechvibes `config.json`. */
struct SoundPackConfig: Decodable {
    enum KeyDefineType: String, Decodable {
        /** One file per key. */
        case multi
        /** One long recording, each key a millisecond range of it. */
        case single
    }

    enum KeyDefinition: Decodable {
        case file(String)
        case range(startMs: Double, durationMs: Double)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let name = try? container.decode(String.self) {
                self = .file(name)
                return
            }
            let values = try container.decode([Double].self)
            guard values.count == 2 else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected [start, duration]")
            }
            self = .range(startMs: values[0], durationMs: values[1])
        }
    }

    let name: String
    let keyDefineType: KeyDefineType
    let sound: String
    let defines: [String: KeyDefinition?]
    let recommendedVolume: Double?

    enum CodingKeys: String, CodingKey {
        case name, sound, defines
        case keyDefineType = "key_define_type"
        case recommendedVolume = "recommended_volume"
    }
}

struct SoundPack {
    /** The folder name, stable across launches and used to remember the selection. */
    let id: String
    let directory: URL
    let config: SoundPackConfig

    /** Recording credits stay in THIRD_PARTY_NOTICES.md, so the menu only names the switch. */
    var name: String { Self.displayNames[id] ?? config.name }

    static let defaultID = "NovelKeys-cream"

    private static let displayNames: [String: String] = [
        "NovelKeys-cream": "NovelKeys Cream",
        "CherryMX-black-pbt": "Cherry MX Black (PBT)",
        "CherryMX-blue-pbt": "Cherry MX Blue (PBT)",
        "CherryMX-brown-pbt": "Cherry MX Brown (PBT)",
        "CherryMX-red-pbt": "Cherry MX Red (PBT)",
        "Everglide-crystal-purple": "Everglide Crystal Purple",
        "Everglide-oreo": "Everglide Oreo",
    ]

    /** Every pack under the app's `SoundPacks` resource folder, sorted by display name. */
    static func bundled() -> [SoundPack] {
        guard let root = Bundle.main.resourceURL?.appendingPathComponent("SoundPacks"),
              let folders = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        return folders.compactMap { folder in
            do {
                let data = try Data(contentsOf: folder.appendingPathComponent("config.json"))
                let config = try JSONDecoder().decode(SoundPackConfig.self, from: data)
                return SoundPack(id: folder.lastPathComponent, directory: folder, config: config)
            } catch {
                print("Skipping sound pack \(folder.lastPathComponent): \(error)")
                return nil
            }
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}
