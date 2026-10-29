//
//  ReviewManagerTests.swift
//  SimilarlyTests
//

import XCTest
@testable import Similarly

final class ReviewManagerTests: XCTestCase {
    var userDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "TestUserDefaults_\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        userDefaults = nil
        super.tearDown()
    }

    @MainActor
    func testShouldNotPromptOnZeroDeletes() {
        let manager = ReviewManager(userDefaults: userDefaults)
        let shouldPrompt = manager.shouldRequestReview(recentDeletedCount: 0, recentSavedBytes: 0)
        XCTAssertFalse(shouldPrompt)
    }

    @MainActor
    func testShouldPromptOnHighImpactClean() {
        let manager = ReviewManager(userDefaults: userDefaults)
        // 5 fotoğraf ve 25 MB silinmiş olsun
        let shouldPrompt = manager.shouldRequestReview(recentDeletedCount: 5, recentSavedBytes: 25 * 1024 * 1024)
        XCTAssertTrue(shouldPrompt)
    }

    @MainActor
    func testShouldPromptOnMultipleExperiencedCleans() {
        let manager = ReviewManager(userDefaults: userDefaults)
        manager.recordSuccessfulClean(deletedPhotosCount: 2, savedBytes: 2 * 1024 * 1024)
        manager.recordSuccessfulClean(deletedPhotosCount: 3, savedBytes: 3 * 1024 * 1024)

        XCTAssertEqual(manager.lifetimePhotosDeleted, 5)
        XCTAssertEqual(manager.lifetimeBytesSaved, 5 * 1024 * 1024)
    }

    @MainActor
    func testShouldRespectCooldownPeriod() {
        let manager = ReviewManager(userDefaults: userDefaults)
        let now = Date()
        userDefaults.set(now.timeIntervalSince1970, forKey: "review_last_prompt_date")

        // 10 gün sonra tekrar çağrılsın (cooldown 30 gün)
        let tenDaysLater = now.addingTimeInterval(10 * 24 * 60 * 60)
        let shouldPrompt = manager.shouldRequestReview(recentDeletedCount: 10, recentSavedBytes: 50 * 1024 * 1024, currentDate: tenDaysLater)
        XCTAssertFalse(shouldPrompt, "Cooldown süresi dolmadan inceleme istenmemelidir.")

        // 35 gün sonra cooldown bitmiş olmalı
        let thirtyFiveDaysLater = now.addingTimeInterval(35 * 24 * 60 * 60)
        let shouldPromptAfterCooldown = manager.shouldRequestReview(recentDeletedCount: 10, recentSavedBytes: 50 * 1024 * 1024, currentDate: thirtyFiveDaysLater)
        XCTAssertTrue(shouldPromptAfterCooldown, "Cooldown tamamlandıktan sonra inceleme istenebilmelidir.")
    }
}
