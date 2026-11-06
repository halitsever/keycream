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

    enum Feel: Int, CaseIterable {
        case linear, tactile, clicky

        var titleKey: String { ["feel_linear", "feel_tactile", "feel_clicky"][rawValue] }
    }

    /** How a known switch is named and drawn. Colors match the website's switch drawings. */
    struct Look {
        let brand: String
        let switchName: String
        let feel: Feel
        let housing: UInt32
        let stem: UInt32
        /** Crystal housings let the plate show through. */
        var isClear = false
    }

    /** Recording credits stay in THIRD_PARTY_NOTICES.md, so the menu only names the switch. */
    var name: String { brand.map { "\($0) \(switchName)" } ?? switchName }
    /** Menus list packs under their brand, so items there show only this part. */
    var switchName: String { look?.switchName ?? config.name }
    var brand: String? { look?.brand }
    /** nil for a pack KeyCream doesn't ship. */
    var look: Look? { Self.looks[id] }

    static let defaultID = "NovelKeys-cream"

    private static let looks: [String: Look] = [
        "NovelKeys-cream": Look(brand: "NovelKeys", switchName: "Cream", feel: .linear, housing: 0xE6D8BA, stem: 0xF6ECD6),
        "CherryMX-black-pbt": Look(brand: "Cherry MX", switchName: "Black (PBT)", feel: .linear, housing: 0x2B2A2C, stem: 0x141315),
        "CherryMX-red-pbt": Look(brand: "Cherry MX", switchName: "Red (PBT)", feel: .linear, housing: 0x2B2A2C, stem: 0xD8352D),
        "CherryMX-brown-pbt": Look(brand: "Cherry MX", switchName: "Brown (PBT)", feel: .tactile, housing: 0x2B2A2C, stem: 0x8B5632),
        "CherryMX-blue-pbt": Look(brand: "Cherry MX", switchName: "Blue (PBT)", feel: .clicky, housing: 0x2B2A2C, stem: 0x2F6FE0),
        "Everglide-crystal-purple": Look(brand: "Everglide", switchName: "Crystal Purple", feel: .tactile, housing: 0xB7A2EA, stem: 0x7A4BD8, isClear: true),
        "Everglide-oreo": Look(brand: "Everglide", switchName: "Oreo", feel: .tactile, housing: 0x1B1A1C, stem: 0xF1EFEA),
    ]

    /** Packs by brand, brands sorted by name. A pack with no known brand gets a group of its own. */
    static func groupedByBrand(_ packs: [SoundPack]) -> [(title: String, packs: [SoundPack])] {
        Dictionary(grouping: packs) { $0.brand ?? $0.config.name }
            .map { (title: $0.key, packs: $0.value) }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

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
