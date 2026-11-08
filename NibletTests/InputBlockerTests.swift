import Carbon.HIToolbox
import CoreGraphics
import Testing

@testable import Niblet

@MainActor
@Suite("InputBlocker")
struct InputBlockerTests {
    private func masks(_ type: CGEventType) -> Bool {
        InputBlocker.eventMask & (1 << CGEventMask(type.rawValue)) != 0
    }

    private func keyEvent(keyCode: Int, typing text: String? = nil) throws -> CGEvent {
        let event = try #require(CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true))
        if let text {
            let units = Array(text.utf16)
            event.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
        }
        return event
    }

    // MARK: - Event mask

    @Test(arguments: [
        CGEventType.keyDown, .keyUp, .flagsChanged,
        .leftMouseDown, .leftMouseUp, .leftMouseDragged,
        .rightMouseDown, .rightMouseUp, .rightMouseDragged,
        .otherMouseDown, .otherMouseUp, .otherMouseDragged,
        .scrollWheel,
    ])
    func eventMask_includesKeyboardAndMouseInput(type: CGEventType) {
        #expect(masks(type))
    }

    @Test func eventMask_allowsCursorMovement() {
        #expect(!masks(.mouseMoved))
    }

    @Test(
        arguments: [
            // systemDefined, rotate, gesture, magnify, swipe, smartMagnify, pressure
            14, 18, 29, 30, 31, 32, 34,
        ] as [UInt64])
    func eventMask_includesSpecialKeysAndGestures(bit: UInt64) {
        #expect(InputBlocker.eventMask & (1 << bit) != 0)
    }

    // MARK: - Pass-through decisions

    @Test(arguments: [true, false])
    func systemDefinedEvents_followFunctionKeySetting(blockFunctionKeys: Bool) throws {
        let systemDefined = try #require(CGEventType(rawValue: 14))

        #expect(InputBlocker.passesThrough(systemDefined, blockFunctionKeys: blockFunctionKeys) == !blockFunctionKeys)
    }

    @Test(arguments: [CGEventType.keyDown, .keyUp, .leftMouseDown, .otherMouseDown, .scrollWheel])
    func regularInput_isAlwaysBlocked(type: CGEventType) {
        #expect(!InputBlocker.passesThrough(type, blockFunctionKeys: false))
        #expect(!InputBlocker.passesThrough(type, blockFunctionKeys: true))
    }

    // MARK: - Character extraction

    @Test(arguments: ["q", "Q", " ", "é", "😀"])
    func character_returnsTypedText(text: String) throws {
        let event = try keyEvent(keyCode: kVK_ANSI_Q, typing: text)

        #expect(InputBlocker.character(from: event) == text)
    }

    @Test func character_mapsDeleteToBackspace() throws {
        // Regardless of what the layout reports, delete always means backspace
        let event = try keyEvent(keyCode: kVK_Delete, typing: "\u{7F}")

        #expect(InputBlocker.character(from: event) == "\u{8}")
    }

    @Test func character_isNil_whenKeyProducesNoText() throws {
        let event = try keyEvent(keyCode: kVK_ANSI_Q, typing: "")

        #expect(InputBlocker.character(from: event) == nil)
    }
}
