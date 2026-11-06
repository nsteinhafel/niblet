import XCTest

@testable import Niblet

final class PhraseDetectorTests: XCTestCase {

    func testDetectsPhrase_whenExactMatch() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "quit" {
            detector.processKey(String(char))
        }

        XCTAssertTrue(detected)
    }

    func testDetectsPhrase_whenPhraseFollowsOtherText() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "hello quit" {
            detector.processKey(String(char))
        }

        XCTAssertTrue(detected)
    }

    func testDoesNotDetect_whenPhraseIncomplete() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "qui" {
            detector.processKey(String(char))
        }

        XCTAssertFalse(detected)
    }

    func testDoesNotDetect_whenWrongPhrase() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "exit" {
            detector.processKey(String(char))
        }

        XCTAssertFalse(detected)
    }

    func testMatchesCaseInsensitively() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "QUIT" {
            detector.processKey(String(char))
        }

        XCTAssertTrue(detected)
    }

    func testIgnoresNonPrintableKeys() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        detector.processKey("q")
        detector.processKey("u")
        detector.processKey("\u{1B}")  // escape
        detector.processKey("\u{F700}")  // up arrow (function-key private use area)
        detector.processKey("\r")  // return
        detector.processKey("i")
        detector.processKey("t")

        XCTAssertTrue(detected)
    }

    func testHandlesBackspace() {
        let detector = PhraseDetector(phrase: "quit")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "quix" {
            detector.processKey(String(char))
        }
        detector.processKey("\u{8}")  // backspace
        detector.processKey("t")

        XCTAssertTrue(detected)
    }

    func testReset_clearsBuffer() {
        let detector = PhraseDetector(phrase: "quit")
        var detectedCount = 0
        detector.onPhraseDetected = { detectedCount += 1 }

        for char in "qui" {
            detector.processKey(String(char))
        }
        detector.reset()
        detector.processKey("t")

        XCTAssertEqual(detectedCount, 0)
    }

    func testEmptyPhrase_neverDetects() {
        let detector = PhraseDetector(phrase: "")
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "any keys at all" {
            detector.processKey(String(char))
        }

        XCTAssertFalse(detected)
    }

    func testSanitize_removesUntypeableWhitespace() {
        XCTAssertEqual(PhraseDetector.sanitize(phrase: "qu\tit\n"), "quit")
    }

    func testSanitize_removesControlAndFunctionKeyCharacters() {
        XCTAssertEqual(PhraseDetector.sanitize(phrase: "qu\u{1B}it\u{F700}"), "quit")
    }

    func testSanitize_keepsSpaces() {
        XCTAssertEqual(PhraseDetector.sanitize(phrase: "open sesame"), "open sesame")
    }

    func testSanitize_capsLengthToBufferSize() {
        let long = String(repeating: "a", count: PhraseDetector.maxPhraseLength + 10)
        let sanitized = PhraseDetector.sanitize(phrase: long)

        XCTAssertEqual(sanitized.count, PhraseDetector.maxPhraseLength)
    }

    func testDetectsPhrase_atMaxLength() {
        let phrase = String(repeating: "a", count: PhraseDetector.maxPhraseLength)
        let detector = PhraseDetector(phrase: phrase)
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "xyz" + phrase {
            detector.processKey(String(char))
        }

        XCTAssertTrue(detected)
    }

    func testDetectsMultipleTimes() {
        let detector = PhraseDetector(phrase: "quit")
        var detectedCount = 0
        detector.onPhraseDetected = { detectedCount += 1 }

        for char in "quit quit" {
            detector.processKey(String(char))
        }

        XCTAssertEqual(detectedCount, 2)
    }
}
