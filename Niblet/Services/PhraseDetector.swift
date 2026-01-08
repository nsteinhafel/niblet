import Foundation

final class PhraseDetector {
    private var buffer: String = ""
    private let maxBufferSize = 50

    var phrase: String
    var caseSensitive: Bool
    var onPhraseDetected: (() -> Void)?

    init(phrase: String, caseSensitive: Bool = false) {
        self.phrase = phrase
        self.caseSensitive = caseSensitive
    }

    func processKey(_ key: String) {
        // Handle backspace
        if key == "\u{8}" {
            if !buffer.isEmpty {
                buffer.removeLast()
            }
            return
        }

        // Ignore non-printable characters except what we handle above
        guard key.unicodeScalars.allSatisfy({ !$0.properties.isPatternWhitespace || key == " " }) else {
            return
        }

        // Add to buffer
        buffer.append(key)

        // Trim buffer if too long
        if buffer.count > maxBufferSize {
            buffer.removeFirst(buffer.count - maxBufferSize)
        }

        // Check for phrase match
        let checkBuffer = caseSensitive ? buffer : buffer.lowercased()
        let checkPhrase = caseSensitive ? phrase : phrase.lowercased()

        if checkBuffer.hasSuffix(checkPhrase) {
            buffer = ""
            onPhraseDetected?()
        }
    }

    func reset() {
        buffer = ""
    }
}
