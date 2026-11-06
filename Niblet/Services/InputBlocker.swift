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

    // System-defined event type for special keys (volume, brightness, media)
    // swiftlint:disable:next force_unwrapping
    private static let systemDefinedEventType = CGEventType(rawValue: 14)!

    private static var eventMask: CGEventMask {
        var mask: CGEventMask = 0
        // Keyboard events
        mask |= (1 << CGEventType.keyDown.rawValue)
        mask |= (1 << CGEventType.keyUp.rawValue)
        mask |= (1 << CGEventType.flagsChanged.rawValue)
        // Mouse events
        mask |= (1 << CGEventType.leftMouseDown.rawValue)
        mask |= (1 << CGEventType.leftMouseUp.rawValue)
        mask |= (1 << CGEventType.rightMouseDown.rawValue)
        mask |= (1 << CGEventType.rightMouseUp.rawValue)
        mask |= (1 << CGEventType.leftMouseDragged.rawValue)
        mask |= (1 << CGEventType.rightMouseDragged.rawValue)
        mask |= (1 << CGEventType.scrollWheel.rawValue)
        // System-defined events (volume, brightness, media, etc.)
        mask |= (1 << 14)
        // Gesture events (pinch, rotate, swipe, etc.)
        mask |= (1 << 18)  // rotate
        mask |= (1 << 29)  // gesture
        mask |= (1 << 30)  // magnify
        mask |= (1 << 31)  // swipe
        mask |= (1 << 32)  // smartMagnify
        mask |= (1 << 34)  // pressure
        return mask
    }

    private static let tapCallback: CGEventTapCallBack = { _, type, event, _ in
        // Handle tap disabled events
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let blocker = InputBlocker.activeBlocker, let tap = blocker.eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        // If no active blocker, let events through
        guard let blocker = InputBlocker.activeBlocker else {
            return Unmanaged.passUnretained(event)
        }

        // Handle system-defined events (special keys like volume, brightness)
        if type == InputBlocker.systemDefinedEventType {
            return blocker.blockFunctionKeys ? nil : Unmanaged.passUnretained(event)
        }

        // Process keyDown events for phrase detection
        if type == .keyDown, let char = blocker.characterFromEvent(event) {
            blocker.onKeyPress?(char)
        }

        // Block the event
        return nil
    }

    init() {}

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
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stopBlocking() {
        // Clear static reference first to stop processing events
        InputBlocker.activeBlocker = nil

        guard let tap = eventTap else { return }

        CGEvent.tapEnable(tap: tap, enable: false)

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        runLoopSource = nil
        eventTap = nil
    }

    private func characterFromEvent(_ event: CGEvent) -> String? {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Handle backspace
        if keyCode == kVK_Delete {
            return "\u{8}"
        }

        // Use CGEvent's built-in unicode string extraction
        var length = 0
        event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)

        guard length > 0 else { return nil }

        var chars = [UniChar](repeating: 0, count: length)
        event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &chars)

        return String(utf16CodeUnits: chars, count: length)
    }

}
