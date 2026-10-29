import CoreGraphics
import Foundation

/** Listen-only event tap that reports physical key presses. Needs Input Monitoring permission. */
final class KeyboardMonitor {
    var onKeyDown: ((Int64) -> Void)?

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /** Device-specific modifier bits, so left and right Shift/Cmd/etc. are told apart. */
    private static let modifierMasks: [Int64: UInt64] = [
        59: 0x0000_0001, 62: 0x0000_2000, // control
        56: 0x0000_0002, 60: 0x0000_0004, // shift
        55: 0x0000_0008, 54: 0x0000_0010, // command
        58: 0x0000_0020, 61: 0x0000_0040, // option
    ]
    private static let capsLockKeyCode: Int64 = 57

    static var hasPermission: Bool { CGPreflightListenEventAccess() }

    @discardableResult
    static func requestPermission() -> Bool { CGRequestListenEventAccess() }

    var isRunning: Bool { tap != nil }

    func start() -> Bool {
        guard tap == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                if let userInfo {
                    Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue().handle(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        runLoopSource = source
        return true
    }

    func stop() {
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CFMachPortInvalidate(tap)
        self.tap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
        case .keyDown:
            if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 { return }
            onKeyDown?(event.getIntegerValueField(.keyboardEventKeycode))
        case .flagsChanged:
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            if keyCode == Self.capsLockKeyCode {
                // Caps Lock sends one event per press, toggling on and off.
                onKeyDown?(keyCode)
            } else if let mask = Self.modifierMasks[keyCode], event.flags.rawValue & mask != 0 {
                onKeyDown?(keyCode)
            }
        default:
            break
        }
    }
}
