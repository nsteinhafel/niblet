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

    func testCaseInsensitive_whenDisabled() {
        let detector = PhraseDetector(phrase: "quit", caseSensitive: false)
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "QUIT" {
            detector.processKey(String(char))
        }

        XCTAssertTrue(detected)
    }

    func testCaseSensitive_whenEnabled() {
        let detector = PhraseDetector(phrase: "quit", caseSensitive: true)
        var detected = false
        detector.onPhraseDetected = { detected = true }

        for char in "QUIT" {
            detector.processKey(String(char))
        }

        XCTAssertFalse(detected)
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
