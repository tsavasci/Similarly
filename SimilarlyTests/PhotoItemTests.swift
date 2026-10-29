//
//  PhotoItemTests.swift
//  SimilarlyTests
//

import XCTest
import Photos
@testable import Similarly

final class PhotoItemTests: XCTestCase {

    func testQualityCalculations() {
        let asset = PHAsset()
        var item = PhotoItem(asset: asset)

        // Henüz analiz yokken
        XCTAssertFalse(item.hasAnalysis)
        XCTAssertFalse(item.hasQualityIssues)

        // Bulanık olarak işaretlendiğinde
        item.blurScore = 30.0 // Varsayılan eşik 100.0
        XCTAssertTrue(item.isBlurry)
        XCTAssertTrue(item.hasQualityIssues)

        // Karanlık olarak işaretlendiğinde
        item.blurScore = 150.0 // Bulanık değil
        item.brightnessScore = 0.05 // Varsayılan karanlık eşiği 0.2
        XCTAssertTrue(item.isTooDark)
        XCTAssertTrue(item.hasQualityIssues)

        // Normal kalitede olduğunda
        item.brightnessScore = 0.5
        XCTAssertFalse(item.isBlurry)
        XCTAssertFalse(item.isTooDark)
        XCTAssertFalse(item.isTooBright)
        XCTAssertFalse(item.hasQualityIssues)
    }

    func testEstimatedFileSize() {
        let asset = PHAsset()
        let item = PhotoItem(asset: asset)
        // asset boyutu varsayılan olarak 0x0
        XCTAssertEqual(item.estimatedFileSize, 0)
    }
}
