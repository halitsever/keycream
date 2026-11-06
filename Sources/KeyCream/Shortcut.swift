import AppKit

/** A key combination recorded from the settings window that turns key sounds on or off from any app. */
struct Shortcut: Codable, Equatable {
    let keyCode: Int64
    /** Raw `NSEvent.ModifierFlags`, which use the same bits as `CGEventFlags`. */
    let modifiers: UInt
    /** What the key types with no modifiers, used for the menu's key equivalent. */
    let characters: String

    private static let relevantModifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command]
    private static let functionKeyCodes: Set<Int64> = [
        122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79, 80, 90,
    ]
    private static let keyNames: [Int64: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6", 98: "F7", 100: "F8", 101: "F9",
        109: "F10", 103: "F11", 111: "F12", 105: "F13", 107: "F14", 113: "F15", 106: "F16", 64: "F17",
        79: "F18", 80: "F19", 90: "F20",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋", 117: "⌦", 115: "↖", 119: "↘", 116: "⇞",
        121: "⇟", 123: "←", 124: "→", 125: "↓", 126: "↑", 76: "⌤",
    ]

    var modifierFlags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }

    /** Modifiers in the order macOS menus show them. */
    var displayString: String {
        let flags = modifierFlags
        var text = ""
        if flags.contains(.control) { text += "⌃" }
        if flags.contains(.option) { text += "⌥" }
        if flags.contains(.shift) { text += "⇧" }
        if flags.contains(.command) { text += "⌘" }
        return text + (Self.keyNames[keyCode] ?? characters.uppercased())
    }

    /** nil when the combination would get in the way of normal typing, such as a bare letter or Shift with one. */
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(Self.relevantModifiers)
        let keyCode = Int64(event.keyCode)
        let isFunctionKey = Self.functionKeyCodes.contains(keyCode)
        guard isFunctionKey || !flags.intersection([.control, .option, .command]).isEmpty else { return nil }
        self.keyCode = keyCode
        modifiers = flags.rawValue
        characters = event.characters(byApplyingModifiers: []) ?? ""
    }

    func matches(keyCode: Int64, flags: CGEventFlags) -> Bool {
        let pressed = NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue)).intersection(Self.relevantModifiers)
        return keyCode == self.keyCode && pressed == modifierFlags
    }
}
