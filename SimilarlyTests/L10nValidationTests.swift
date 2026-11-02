//
//  L10nValidationTests.swift
//  SimilarlyTests
//
//  Created by AI Agent (Test Guard)
//

import XCTest
@testable import Similarly

final class L10nValidationTests: XCTestCase {

    func testResolvedLanguageCode() {
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "en"), "en")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "tr"), "tr")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "de"), "de")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "ar"), "ar")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "zh-Hans"), "zh-Hans")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "es"), "es")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "fr"), "fr")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "ja"), "ja")
        XCTAssertEqual(L10n.resolvedLanguageCode(for: "unknown-code"), "en")
    }

    func testFormattingHelpers() {
        let countText = L10n.f("common.photos_count", 42)
        XCTAssertFalse(countText.isEmpty)

        let bytesText = L10n.bytes(1024 * 1024)
        XCTAssertFalse(bytesText.isEmpty)

        let numberText = L10n.number(1234)
        XCTAssertFalse(numberText.isEmpty)

        let percentText = L10n.percent(0.85)
        XCTAssertTrue(percentText.contains("85"))

        let dateText = L10n.date(Date())
        XCTAssertFalse(dateText.isEmpty)
    }

    func testCriticalKeysExistInMainBundle() {
        let keys = [
            "app.name",
            "main.subtitle",
            "main.actions.find_similar",
            "main.actions.load_photos",
            "main.limited_access.banner",
            "main.limited_access.action",
            "common.favorite",
            "common.similar",
            "common.clear_all",
            "common.select_all",
            "common.oldest"
        ]

        for key in keys {
            let translated = L10n.t(key)
            XCTAssertFalse(translated.isEmpty, "Key \(key) should not have empty string")
        }
    }
}
