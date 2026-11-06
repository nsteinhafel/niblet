import Foundation

final class PhraseDetector {
    /// Phrases longer than the key buffer can never match.
    static let maxPhraseLength = 50

    private var buffer: String = ""
    private let maxBufferSize = PhraseDetector.maxPhraseLength

    var phrase: String
    var onPhraseDetected: (() -> Void)?

    init(phrase: String) {
        self.phrase = phrase
    }

    /// Removes characters `processKey` can never receive and caps the length
    /// so the phrase fits in the key buffer.
    static func sanitize(phrase: String) -> String {
        String(phrase.filter { $0.unicodeScalars.allSatisfy(isTypeable) }.prefix(maxPhraseLength))
    }

    /// Space is typeable; other whitespace, control characters (escape, return),
    /// and private-use scalars (arrow/function keys from
    /// `keyboardGetUnicodeString`) are not.
    private static func isTypeable(_ scalar: Unicode.Scalar) -> Bool {
        if scalar == " " { return true }
        if scalar.properties.isPatternWhitespace { return false }
        switch scalar.properties.generalCategory {
        case .control, .format, .privateUse:
            return false
        default:
            return true
        }
    }

    func processKey(_ key: String) {
        // Handle backspace
        if key == "\u{8}" {
            if !buffer.isEmpty {
                buffer.removeLast()
            }
            return
        }

        // Ignore non-printable keys so they can't pollute the buffer
        guard key.unicodeScalars.allSatisfy(Self.isTypeable) else {
            return
        }

        // Add to buffer
        buffer.append(key)

        // Trim buffer if too long
        if buffer.count > maxBufferSize {
            buffer.removeFirst(buffer.count - maxBufferSize)
        }

        // Check for phrase match (case-insensitive so caps lock can't prevent unlocking)
        if !phrase.isEmpty, buffer.lowercased().hasSuffix(phrase.lowercased()) {
            buffer = ""
            onPhraseDetected?()
        }
    }

    func reset() {
        buffer = ""
    }
}
