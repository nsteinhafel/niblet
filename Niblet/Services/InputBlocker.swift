import Carbon.HIToolbox
import Cocoa

@MainActor
final class InputBlocker {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onKeyPress: ((String) -> Void)?
    var blockFunctionKeys: Bool = true

    // Use a static reference to avoid Unmanaged pointer issues
    private static var activeBlocker: InputBlocker?

    /// `NSEvent.EventTypeMask` uses the same bit layout as `CGEventMask`, so it
    /// names event types that `CGEventType` doesn't expose (system-defined, gestures).
    static let eventMask: CGEventMask = {
        let mask: NSEvent.EventTypeMask = [
            // Keyboard
            .keyDown, .keyUp, .flagsChanged,
            // Mouse buttons, drags, and scrolling (mouse movement is allowed)
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .scrollWheel,
            // Special keys: volume, brightness, media
            .systemDefined,
            // Trackpad gestures
            .rotate, .gesture, .magnify, .swipe, .smartMagnify, .pressure,
        ]
        return mask.rawValue
    }()

    private static let tapCallback: CGEventTapCallBack = { _, type, event, _ in
        // macOS disables taps that are slow or interrupted; re-enable it
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = InputBlocker.activeBlocker?.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        guard let blocker = InputBlocker.activeBlocker else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown, let char = InputBlocker.character(from: event) {
            blocker.onKeyPress?(char)
        }

        return passesThrough(type, blockFunctionKeys: blocker.blockFunctionKeys)
            ? Unmanaged.passUnretained(event) : nil
    }

    init() {}

    /// Whether an event the tap intercepted should reach the system.
    static func passesThrough(_ type: CGEventType, blockFunctionKeys: Bool) -> Bool {
        if UInt(type.rawValue) == NSEvent.EventType.systemDefined.rawValue {
            return !blockFunctionKeys
        }
        return false
    }

    /// Returns false if the event tap couldn't be created (e.g. Accessibility
    /// permission was revoked).
    func startBlocking() -> Bool {
        guard eventTap == nil else { return true }

        InputBlocker.activeBlocker = self

        guard
            let tap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: Self.eventMask,
                callback: Self.tapCallback,
                userInfo: nil
            )
        else {
            InputBlocker.activeBlocker = nil
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            InputBlocker.activeBlocker = nil
            return false
        }

        eventTap = tap
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stopBlocking() {
        // Clear static reference first to stop processing events
        InputBlocker.activeBlocker = nil

        guard let tap = eventTap else { return }

        CGEvent.tapEnable(tap: tap, enable: false)

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        CFMachPortInvalidate(tap)

        runLoopSource = nil
        eventTap = nil
    }

    /// The text a key-down event would type, or backspace (`\u{8}`) for delete.
    static func character(from event: CGEvent) -> String? {
        if event.getIntegerValueField(.keyboardEventKeycode) == kVK_Delete {
            return "\u{8}"
        }

        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)

        guard length > 0 else { return nil }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)

        return String(utf16CodeUnits: chars, count: length)
    }
}
