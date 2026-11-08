import Testing

@testable import Niblet

@Suite("PhraseDetector")
struct PhraseDetectorTests {
    /// Feeds `keys` to a detector one at a time and returns how often the phrase matched.
    private func detections(of phrase: String, typing keys: [String]) -> Int {
        let detector = PhraseDetector(phrase: phrase)
        var count = 0
        detector.onPhraseDetected = { count += 1 }
        for key in keys {
            detector.processKey(key)
        }
        return count
    }

    private func detections(of phrase: String, typing text: String) -> Int {
        detections(of: phrase, typing: text.map(String.init))
    }

    // MARK: - Matching

    @Test(arguments: ["quit", "hello quit", "QUIT", "QuIt", "xyz quit"])
    func detects(typed: String) {
        #expect(detections(of: "quit", typing: typed) == 1)
    }

    @Test(arguments: ["", "qui", "exit", "qiut", "q u i t"])
    func doesNotDetect(typed: String) {
        #expect(detections(of: "quit", typing: typed) == 0)
    }

    @Test func detectsPhraseContainingSpaces() {
        #expect(detections(of: "open sesame", typing: "open sesame") == 1)
    }

    @Test func detectsMultipleTimes() {
        #expect(detections(of: "quit", typing: "quit quit") == 2)
    }

    @Test func clearsBuffer_afterMatch() {
        // Without the reset, the last eight keys would match a second time
        #expect(detections(of: "quitquit", typing: "quitquitquit") == 1)
    }

    @Test func emptyPhrase_neverDetects() {
        #expect(detections(of: "", typing: "any keys at all") == 0)
    }

    @Test func ignoresNonPrintableKeys() {
        let keys = ["q", "u", "\u{1B}", "\u{F700}", "\r", "\t", "i", "t"]  // escape, up arrow, return, tab

        #expect(detections(of: "quit", typing: keys) == 1)
    }

    // MARK: - Backspace

    @Test func backspace_removesLastKey() {
        #expect(detections(of: "quit", typing: ["q", "u", "i", "x", "\u{8}", "t"]) == 1)
    }

    @Test func backspace_onEmptyBuffer_isIgnored() {
        #expect(detections(of: "quit", typing: ["\u{8}", "\u{8}", "q", "u", "i", "t"]) == 1)
    }

    // MARK: - Buffer

    @Test func reset_clearsBuffer() {
        let detector = PhraseDetector(phrase: "quit")
        var count = 0
        detector.onPhraseDetected = { count += 1 }

        for char in "qui" {
            detector.processKey(String(char))
        }
        detector.reset()
        detector.processKey("t")

        #expect(count == 0)
    }

    @Test func detectsPhrase_atMaxLength_afterOverflow() {
        let phrase = String(repeating: "a", count: PhraseDetector.maxPhraseLength)

        #expect(detections(of: phrase, typing: String(repeating: "x", count: 200) + phrase) == 1)
    }

    @Test func changingPhrase_takesEffectImmediately() {
        let detector = PhraseDetector(phrase: "quit")
        var count = 0
        detector.onPhraseDetected = { count += 1 }

        detector.phrase = "bye"
        for char in "quit bye" {
            detector.processKey(String(char))
        }

        #expect(count == 1)
    }

    // MARK: - Sanitizing

    @Test(arguments: [
        ("qu\tit\n", "quit"),  // whitespace other than space
        ("qu\u{1B}it\u{F700}", "quit"),  // escape and function-key private use
        ("qu\u{200B}it", "quit"),  // zero-width space (format)
        ("open sesame", "open sesame"),
        ("Grüße", "Grüße"),
        ("", ""),
    ])
    func sanitize(input: String, expected: String) {
        #expect(PhraseDetector.sanitize(phrase: input) == expected)
    }

    @Test func sanitize_capsLengthToBufferSize() {
        let long = String(repeating: "a", count: PhraseDetector.maxPhraseLength + 10)

        #expect(PhraseDetector.sanitize(phrase: long).count == PhraseDetector.maxPhraseLength)
    }
}
