//
//  PhotoAnalyzerTests.swift
//  SimilarlyTests
//
//  Created by AI Agent (Test Guard)
//

import XCTest
import Photos
@testable import Similarly

final class PhotoAnalyzerTests: XCTestCase {

    func testPhotoAnalysisResultInitialization() {
        let dummyVector: [Float] = [0.1, 0.2, 0.3, 0.4]
        let result = PhotoAnalysisResult(
            id: "test-id-123",
            featurePrint: dummyVector,
            blurScore: 125.5,
            brightnessScore: 0.65
        )

        XCTAssertEqual(result.id, "test-id-123")
        XCTAssertEqual(result.featurePrint, dummyVector)
        XCTAssertEqual(result.blurScore, 125.5)
        XCTAssertEqual(result.brightnessScore, 0.65)
    }

    func testAnalyzerWithEmptyIdentifiersReturnsEmpty() async {
        let analyzer = PhotoAnalyzer()
        let results = await analyzer.analyze(localIdentifiers: [])
        XCTAssertTrue(results.isEmpty)
    }

    func testPhotoItemAnalysisAssignment() {
        let asset = PHAsset()
        var item = PhotoItem(asset: asset)

        XCTAssertFalse(item.hasAnalysis)
        XCTAssertNil(item.blurScore)
        XCTAssertNil(item.brightnessScore)

        item.blurScore = 80.0
        item.brightnessScore = 0.5
        item.hasAnalysis = true

        XCTAssertTrue(item.hasAnalysis)
        XCTAssertEqual(item.blurScore, 80.0)
        XCTAssertEqual(item.brightnessScore, 0.5)
        XCTAssertTrue(item.isBlurry)
        XCTAssertFalse(item.isTooDark)
        XCTAssertFalse(item.isTooBright)
    }
}
