//
//  SimilarityEngineTests.swift
//  SimilarlyTests
//

import XCTest
@testable import Similarly

final class SimilarityEngineTests: XCTestCase {

    func testIdenticalVectorsProduceDuplicateCluster() throws {
        // İki adet birebir aynı vektör
        let vector: [Float] = [Float](repeating: 0.1, count: 768)
        let now = Date()

        let photo1 = PhotoSnapshot(id: "photo1", creationDate: now, latitude: 41.0, longitude: 29.0, pixelWidth: 1000, pixelHeight: 1000)
        let photo2 = PhotoSnapshot(id: "photo2", creationDate: now.addingTimeInterval(1.0), latitude: 41.0, longitude: 29.0, pixelWidth: 1000, pixelHeight: 1000)

        let settings = SimilaritySettings(
            similarityThreshold: 0.85,
            dateThresholdSeconds: 5.0,
            locationThresholdMeters: 100.0
        )

        let clusters = try SimilarityEngine.findClusters(
            photos: [photo1, photo2],
            vectors: ["photo1": vector, "photo2": vector],
            settings: settings
        )

        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.memberIDs.count, 2)
        XCTAssertTrue(clusters.first?.isDuplicate ?? false)
        XCTAssertGreaterThanOrEqual(clusters.first?.score ?? 0, 0.99)
    }

    func testDifferentVectorsDoNotCluster() throws {
        // Birbirinden tamamen zıt/farklı iki vektör
        var vector1 = [Float](repeating: 0.0, count: 768)
        var vector2 = [Float](repeating: 0.0, count: 768)
        vector1[0] = 1.0
        vector2[1] = 1.0

        let now = Date()
        let photo1 = PhotoSnapshot(id: "p1", creationDate: now, latitude: nil, longitude: nil, pixelWidth: 800, pixelHeight: 600)
        let photo2 = PhotoSnapshot(id: "p2", creationDate: now.addingTimeInterval(1.0), latitude: nil, longitude: nil, pixelWidth: 800, pixelHeight: 600)

        let settings = SimilaritySettings(
            similarityThreshold: 0.85,
            dateThresholdSeconds: 5.0,
            locationThresholdMeters: 100.0
        )

        let clusters = try SimilarityEngine.findClusters(
            photos: [photo1, photo2],
            vectors: ["p1": vector1, "p2": vector2],
            settings: settings
        )

        XCTAssertTrue(clusters.isEmpty, "Farklı fotoğraflar gruplanmamalıdır.")
    }
}
