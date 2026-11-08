import Foundation
import Testing
import os

@testable import Niblet

@MainActor
@Suite("LockManager")
final class LockManagerTests {
    private let suiteName = "NibletTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let blocker = FakeInputBlocker()
    private let overlay = FakeOverlay()
    private let permissions = FakePermissions()

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func makeManager() -> LockManager {
        LockManager(defaults: defaults, inputBlocker: blocker, overlay: overlay, permissions: permissions)
    }

    /// Unlocking from a typed phrase hops through a `Task`, so give it a chance to run.
    private func waitForUnlock(_ manager: LockManager) async {
        var attempts = 0
        while manager.isLocked, attempts < 100 {
            await Task.yield()
            attempts += 1
        }
    }

    // MARK: - Settings

    @Test func usesDefaultSettings_whenNothingPersisted() {
        let manager = makeManager()

        #expect(manager.unlockPhrase == LockManager.defaultUnlockPhrase)
        #expect(manager.blockFunctionKeys)
        #expect(manager.showOverlay)
        #expect(!manager.isLocked)
    }

    @Test func loadsPersistedSettings() {
        defaults.set("open sesame", forKey: LockManager.Keys.unlockPhrase)
        defaults.set(false, forKey: LockManager.Keys.blockFunctionKeys)
        defaults.set(false, forKey: LockManager.Keys.showOverlay)

        let manager = makeManager()

        #expect(manager.unlockPhrase == "open sesame")
        #expect(!manager.blockFunctionKeys)
        #expect(!manager.showOverlay)
    }

    @Test func sanitizesPersistedPhrase_onLoad() {
        defaults.set("qu\tit\n", forKey: LockManager.Keys.unlockPhrase)

        #expect(makeManager().unlockPhrase == "quit")
    }

    @Test func persistsSettingChanges() {
        let manager = makeManager()

        manager.unlockPhrase = "bye"
        manager.blockFunctionKeys = false
        manager.showOverlay = false

        #expect(defaults.string(forKey: LockManager.Keys.unlockPhrase) == "bye")
        #expect(defaults.object(forKey: LockManager.Keys.blockFunctionKeys) as? Bool == false)
        #expect(defaults.object(forKey: LockManager.Keys.showOverlay) as? Bool == false)
    }

    @Test func sanitizesPhrase_whenSet() {
        let manager = makeManager()

        manager.unlockPhrase = "by\u{1B}e\n"

        #expect(manager.unlockPhrase == "bye")
        #expect(defaults.string(forKey: LockManager.Keys.unlockPhrase) == "bye")
    }

    // MARK: - Locking

    @Test func lock_blocksInputAndShowsOverlay() {
        let manager = makeManager()

        manager.lock()

        #expect(manager.isLocked)
        #expect(blocker.isBlocking)
        #expect(overlay.shownPhrases == ["quit"])
        #expect(permissions.guideCount == 0)
    }

    @Test(arguments: [true, false])
    func lock_passesFunctionKeySettingToBlocker(block: Bool) {
        let manager = makeManager()
        manager.blockFunctionKeys = block
        blocker.blockFunctionKeys = !block

        manager.lock()

        #expect(blocker.blockFunctionKeys == block)
    }

    @Test func lock_skipsOverlay_whenDisabled() {
        let manager = makeManager()
        manager.showOverlay = false

        manager.lock()

        #expect(manager.isLocked)
        #expect(blocker.isBlocking)
        #expect(overlay.shownPhrases.isEmpty)
    }

    @Test func lock_withoutPermission_promptsAndStaysUnlocked() {
        permissions.hasAccessibilityPermission = false
        let manager = makeManager()

        manager.lock()

        #expect(!manager.isLocked)
        #expect(blocker.startCount == 0)
        #expect(overlay.shownPhrases.isEmpty)
        #expect(permissions.requestCount == 1)
        #expect(permissions.guideCount == 1)
    }

    @Test func lock_whenBlockingFails_neverShowsOverlay() {
        blocker.startSucceeds = false
        let manager = makeManager()

        manager.lock()

        #expect(!manager.isLocked)
        #expect(overlay.shownPhrases.isEmpty)
        #expect(permissions.guideCount == 1)
    }

    @Test func lock_restoresDefaultPhrase_whenEmpty() {
        let manager = makeManager()
        manager.unlockPhrase = ""

        manager.lock()

        #expect(manager.unlockPhrase == LockManager.defaultUnlockPhrase)
        #expect(overlay.shownPhrases == [LockManager.defaultUnlockPhrase])
    }

    @Test func lock_isIdempotent() {
        let manager = makeManager()

        manager.lock()
        manager.lock()

        #expect(blocker.startCount == 1)
        #expect(overlay.shownPhrases.count == 1)
    }

    // MARK: - Unlocking

    @Test func unlock_stopsBlockingAndHidesOverlay() {
        let manager = makeManager()
        manager.lock()

        manager.unlock()

        #expect(!manager.isLocked)
        #expect(!blocker.isBlocking)
        #expect(!overlay.isShowing)
    }

    @Test func unlock_whenNotLocked_doesNothing() {
        let manager = makeManager()

        manager.unlock()

        #expect(blocker.stopCount == 0)
        #expect(overlay.hideCount == 0)
    }

    @Test func typingPhrase_unlocks() async {
        let manager = makeManager()
        manager.lock()

        blocker.type("asdf quit")
        await waitForUnlock(manager)

        #expect(!manager.isLocked)
        #expect(!blocker.isBlocking)
        #expect(!overlay.isShowing)
    }

    @Test func typingOtherKeys_staysLocked() async {
        let manager = makeManager()
        manager.lock()

        blocker.type("qui exit")
        await waitForUnlock(manager)

        #expect(manager.isLocked)
    }

    @Test func typingPhrase_usesPhraseChangedBeforeLocking() async {
        let manager = makeManager()
        manager.unlockPhrase = "bye"
        manager.lock()

        blocker.type("quit")
        await waitForUnlock(manager)
        #expect(manager.isLocked)

        blocker.type("bye")
        await waitForUnlock(manager)
        #expect(!manager.isLocked)
    }

    @Test func partialPhrase_doesNotCarryOverToNextLock() async {
        let manager = makeManager()
        manager.lock()
        blocker.type("qu")
        manager.unlock()

        manager.lock()
        blocker.type("it")
        await waitForUnlock(manager)

        #expect(manager.isLocked)
    }

    @Test(arguments: [true, false])
    func keyPress_postsFlashNotification_onlyWithOverlay(showOverlay: Bool) {
        let manager = makeManager()
        manager.showOverlay = showOverlay
        manager.lock()

        let posts = OSAllocatedUnfairLock(initialState: 0)
        let observer = NotificationCenter.default.addObserver(forName: .keyPressed, object: nil, queue: nil) { _ in
            posts.withLock { $0 += 1 }
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        blocker.type("ab")

        #expect(posts.withLock { $0 } == (showOverlay ? 2 : 0))
    }
}
