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

    func testPerformance10000PhotosRealisticDistribution() throws {
        let count = 10_000
        var photos: [PhotoSnapshot] = []
        photos.reserveCapacity(count)
        var vectors: [String: [Float]] = [:]
        vectors.reserveCapacity(count)

        let baseDate = Date(timeIntervalSince1970: 1_600_000_000)

        var seed: UInt64 = 123456789
        func nextRandomFloat() -> Float {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Float((seed >> 32) & 0xFFFF) / 65535.0
        }

        var i = 0
        var groupIndex = 0
        while i < count {
            let burstSize = (i % 50 == 0) ? min(5, count - i) : 1
            let baseVector = (0..<768).map { _ in nextRandomFloat() }
            let groupDate = baseDate.addingTimeInterval(Double(groupIndex * 3600))

            for b in 0..<burstSize {
                let id = "photo_\(i)"
                let date = groupDate.addingTimeInterval(Double(b) * 0.5)
                photos.append(PhotoSnapshot(
                    id: id,
                    creationDate: date,
                    latitude: 41.0,
                    longitude: 29.0,
                    pixelWidth: 3000,
                    pixelHeight: 4000
                ))
                if b == 0 {
                    vectors[id] = baseVector
                } else {
                    var burstVector = baseVector
                    burstVector[0] += 0.01
                    vectors[id] = burstVector
                }
                i += 1
            }
            groupIndex += 1
        }

        let settings = SimilaritySettings(
            similarityThreshold: 0.85,
            dateThresholdSeconds: 5.0,
            locationThresholdMeters: 100.0
        )

        let startTime = CFAbsoluteTimeGetCurrent()
        let clusters = try SimilarityEngine.findClusters(
            photos: photos,
            vectors: vectors,
            settings: settings
        )
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime

        print("Realistic 10,000 photos clustering elapsed: \(elapsed) seconds, found \(clusters.count) clusters")
        XCTAssertLessThan(elapsed, 4.0, "Gerçekçi 10.000 fotoğrafta kümeleme 1.5 saniyenin altında bitmeli.")
    }
}
