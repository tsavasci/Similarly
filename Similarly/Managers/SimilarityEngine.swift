//
//  SimilarityEngine.swift
//  Similarly
//
//  Vision feature print vektörleri üzerinden benzer ve kopya fotoğraf gruplarını bulan saf motor.
//  Ana thread dışında çalışır ve iptal edilebilir.
//

import Accelerate
import CoreLocation
import Foundation

/// Motorun ihtiyaç duyduğu, thread'ler arasında güvenle taşınabilen fotoğraf özeti
nonisolated struct PhotoSnapshot: Sendable {
    let id: String
    let creationDate: Date?
    let latitude: Double?
    let longitude: Double?
    let pixelWidth: Int
    let pixelHeight: Int
}

nonisolated struct SimilaritySettings: Sendable {
    /// 0-1 arası benzerlik eşiği (kullanıcı ayarı)
    let similarityThreshold: Double
    /// Bu süre içinde çekilen her fotoğraf çifti aday olur (seri çekim)
    let dateThresholdSeconds: TimeInterval
    /// Bu mesafe içinde (ve `locationTimeWindow` içinde) çekilen çiftler aday olur
    let locationThresholdMeters: Double
}

/// Bulunan bir grup: üye kimlikleri, ortalama benzerlik ve kopya bilgisi
nonisolated struct SimilarityCluster: Sendable {
    let memberIDs: [String]
    let score: Double
    let isDuplicate: Bool
}

nonisolated enum SimilarityEngine {
    /// Benzerlik skoruna çevrilirken kullanılan azami feature print mesafesi: score = 1 - d / maxDistance.
    /// Vektörler birim normda olduğundan mesafe 0-2 aralığındadır.
    static let maxDistance: Float = 2.0
    /// Bu mesafenin altındaki çiftler "kopya" sayılır. Cihazda ölçüldü: birebir aynı dosyalar ≈ 0,
    /// yeniden sıkıştırılmış/renk dönüştürülmüş kopyalar ≈ 0.05-0.10, farklı seri çekim kareleri ≥ 0.15.
    static let duplicateDistance: Float = 0.10
    /// Aynı boyuttaki fotoğraflar için ek zaman penceresi
    static let sameSizeTimeWindow: TimeInterval = 60
    /// Konum eşleşmesinin geçerli olduğu azami zaman farkı
    static let locationTimeWindow: TimeInterval = 3600
    /// Gruplar birleşirken temsilcilerin eşikten en fazla bu kadar altında kalmasına izin verilir (zincirlenmeyi önler)
    static let chainingTolerance: Double = 0.05
    /// Tarihi olmayan fotoğraflar için tek bir boyut kovasında karşılaştırılacak azami fotoğraf sayısı
    static let maxUndatedBucketSize = 500

    // Tarihten bağımsız kopya araması (SimHash / rastgele hiper-düzlem LSH).
    // d = 0.10 bir kopya için bit başına çakışma olasılığı ≈ %96.8 → 20 bitlik 10 banttan en az birinde
    // eşleşme olasılığı ≈ %99.9; alakasız bir çift (d ≈ 0.9) ise ≈ %0.8 olasılıkla aday olur.
    static let lshBands = 10
    static let lshBitsPerBand = 20
    /// Bundan kalabalık LSH kovaları atlanır (çok sayıda neredeyse aynı görüntüde karesel patlamayı önler)
    static let maxLSHBucketSize = 2000

    /// Motoru arka planda çalıştırır. `progress` 0-1 arası değerlerle çağrılır.
    @concurrent
    static func run(
        photos: [PhotoSnapshot],
        vectors: [String: [Float]],
        settings: SimilaritySettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> [SimilarityCluster] {
        try findClusters(photos: photos, vectors: vectors, settings: settings, progress: progress)
    }

    static func findClusters(
        photos: [PhotoSnapshot],
        vectors: [String: [Float]],
        settings: SimilaritySettings,
        progress: (Double) -> Void = { _ in }
    ) throws -> [SimilarityCluster] {
        // Yalnızca vektörü olan fotoğraflarla çalış.
        let items = photos.compactMap { photo -> (PhotoSnapshot, [Float])? in
            guard let vector = vectors[photo.id], !vector.isEmpty else { return nil }
            return (photo, vector)
        }
        guard items.count > 1 else { return [] }

        var unionFind = UnionFind(count: items.count)
        let threshold = settings.similarityThreshold

        func similarity(_ i: Int, _ j: Int) -> (score: Double, distance: Float)? {
            let a = items[i].1
            let b = items[j].1
            guard a.count == b.count else { return nil }
            let distance = vDSP.distanceSquared(a, b).squareRoot()
            let score = max(0, 1 - Double(distance / maxDistance))
            return (score, distance)
        }

        /// `duplicatesOnly`: yalnızca kopya eşiğinin altındaki çiftleri birleştir (tarihten bağımsız arama için).
        func consider(_ i: Int, _ j: Int, duplicatesOnly: Bool = false) {
            guard let edge = similarity(i, j), edge.score >= threshold else { return }
            if duplicatesOnly && edge.distance > duplicateDistance { return }
            let isDuplicateEdge = edge.distance <= duplicateDistance

            let rootI = unionFind.find(i)
            let rootJ = unionFind.find(j)
            if rootI == rootJ {
                unionFind.addEdge(to: rootI, score: edge.score, isDuplicate: isDuplicateEdge)
                return
            }

            // Zincirlenmeyi önle: iki grubun temsilcileri de birbirine yeterince benzemeli.
            let representativeI = unionFind.representative(of: rootI)
            let representativeJ = unionFind.representative(of: rootJ)
            if representativeI != i || representativeJ != j {
                guard let repEdge = similarity(representativeI, representativeJ),
                    repEdge.score >= threshold - chainingTolerance
                else { return }
            }
            unionFind.union(rootI, rootJ, score: edge.score, isDuplicate: isDuplicateEdge)
        }

        // 1. Tarihli fotoğraflar: tarihe göre sırala, kayan zaman penceresiyle aday çiftleri üret.
        let dated = items.indices
            .filter { items[$0].0.creationDate != nil }
            .sorted { items[$0].0.creationDate! < items[$1].0.creationDate! }
        let maxWindow = max(settings.dateThresholdSeconds, sameSizeTimeWindow, locationTimeWindow)

        let totalWork = Double(max(1, items.count))
        var lastReportedProgress = 0.0

        for (position, i) in dated.enumerated() {
            if position % 256 == 0 {
                try Task.checkCancellation()
                let current = 0.6 * Double(position) / totalWork
                if current - lastReportedProgress >= 0.01 {
                    progress(current)
                    lastReportedProgress = current
                }
            }

            let photoI = items[i].0
            guard let dateI = photoI.creationDate else { continue }

            var next = position + 1
            while next < dated.count {
                let j = dated[next]
                let photoJ = items[j].0
                guard let dateJ = photoJ.creationDate else { break }
                let timeDiff = dateJ.timeIntervalSince(dateI)
                if timeDiff > maxWindow { break }

                if isCandidate(photoI, photoJ, timeDiff: timeDiff, settings: settings) {
                    consider(i, j)
                }
                next += 1
            }
        }

        // 2. Tarihsiz fotoğraflar: yalnızca aynı piksel boyutundakiler kendi aralarında karşılaştırılır.
        let undated = items.indices.filter { items[$0].0.creationDate == nil }
        let undatedBuckets = Dictionary(grouping: undated) { index in
            SizeKey(width: items[index].0.pixelWidth, height: items[index].0.pixelHeight)
        }
        for bucket in undatedBuckets.values where bucket.count > 1 && bucket.count <= maxUndatedBucketSize {
            try Task.checkCancellation()
            for a in 0..<bucket.count {
                for b in (a + 1)..<bucket.count {
                    consider(bucket[a], bucket[b])
                }
            }
        }
        progress(0.6)

        // 3. Tarihten bağımsız kopyalar: aylar sonra yeniden kaydedilmiş kopyalar zaman penceresine girmez.
        let undatedBucketSizes = undatedBuckets.mapValues(\.count)
        func alreadyCompared(_ i: Int, _ j: Int) -> Bool {
            let a = items[i].0
            let b = items[j].0
            if let dateA = a.creationDate, let dateB = b.creationDate {
                let (earlier, later) = dateA <= dateB ? (a, b) : (b, a)
                let timeDiff = abs(dateB.timeIntervalSince(dateA))
                return timeDiff <= maxWindow && isCandidate(earlier, later, timeDiff: timeDiff, settings: settings)
            }
            if a.creationDate == nil, b.creationDate == nil,
                a.pixelWidth == b.pixelWidth, a.pixelHeight == b.pixelHeight
            {
                let size = undatedBucketSizes[SizeKey(width: a.pixelWidth, height: a.pixelHeight)] ?? 0
                return size <= maxUndatedBucketSize
            }
            return false
        }

        var comparedDuplicatePairs = Set<UInt64>()
        try forEachDuplicateCandidate(vectors: items.map(\.1)) { i, j in
            guard !alreadyCompared(i, j) else { return }
            // Aynı çift birden çok bantta eşleşebilir; grup istatistiklerini şişirmemek için bir kez işle.
            let key = UInt64(min(i, j)) << 32 | UInt64(max(i, j))
            guard comparedDuplicatePairs.insert(key).inserted else { return }
            consider(i, j, duplicatesOnly: true)
        } progress: { fraction in
            progress(0.6 + 0.4 * fraction)
        }
        progress(1.0)

        // 4. Bağlı bileşenleri grupla.
        var members: [Int: [Int]] = [:]
        for index in items.indices {
            members[unionFind.find(index), default: []].append(index)
        }

        return members.compactMap { root, indices in
            guard indices.count > 1 else { return nil }
            let stats = unionFind.stats(of: root)
            return SimilarityCluster(
                memberIDs: indices.map { items[$0].0.id },
                score: stats.edgeCount > 0 ? stats.scoreSum / Double(stats.edgeCount) : threshold,
                isDuplicate: stats.allDuplicate
            )
        }
    }

    /// SimHash imzalarından aynı bantta aynı imzaya sahip vektör çiftlerini `body`'ye verir.
    /// İmzalar tek bir matris çarpımıyla (vDSP) hesaplanır.
    private static func forEachDuplicateCandidate(
        vectors: [[Float]],
        body: (Int, Int) -> Void,
        progress: (Double) -> Void
    ) throws {
        guard vectors.count > 1, let dimension = vectors.first?.count, dimension > 0 else { return }

        let planeCount = lshBands * lshBitsPerBand
        let hyperplanes = gaussianMatrix(rows: dimension, columns: planeCount)
        var buckets: [UInt64: [Int32]] = [:]

        // İmzaları parça parça hesapla (bellek: parça × boyut).
        let chunkSize = 512
        var chunk = [Float](repeating: 0, count: chunkSize * dimension)
        var projections = [Float](repeating: 0, count: chunkSize * planeCount)
        for start in stride(from: 0, to: vectors.count, by: chunkSize) {
            try Task.checkCancellation()
            let end = min(start + chunkSize, vectors.count)
            let rows = end - start
            for row in 0..<rows {
                let vector = vectors[start + row]
                guard vector.count == dimension else { continue }
                chunk.replaceSubrange(row * dimension..<(row + 1) * dimension, with: vector)
            }
            vDSP_mmul(chunk, 1, hyperplanes, 1, &projections, 1, vDSP_Length(rows), vDSP_Length(planeCount), vDSP_Length(dimension))

            for row in 0..<rows where vectors[start + row].count == dimension {
                let base = row * planeCount
                for band in 0..<lshBands {
                    var signature: UInt64 = 0
                    for bit in 0..<lshBitsPerBand where projections[base + band * lshBitsPerBand + bit] >= 0 {
                        signature |= 1 << UInt64(bit)
                    }
                    buckets[UInt64(band) << 32 | signature, default: []].append(Int32(start + row))
                }
            }
        }
        progress(0.3)

        let totalBuckets = Double(max(1, buckets.count))
        var processed = 0
        for members in buckets.values {
            processed += 1
            guard members.count > 1, members.count <= maxLSHBucketSize else { continue }
            if processed % 1024 == 0 {
                try Task.checkCancellation()
                progress(0.3 + 0.7 * Double(processed) / totalBuckets)
            }
            for a in 0..<members.count {
                for b in (a + 1)..<members.count {
                    body(Int(members[a]), Int(members[b]))
                }
            }
        }
    }

    /// Sabit tohumlu (her çalıştırmada aynı) standart normal dağılımlı matris; satır-öncelikli rows × columns.
    private static func gaussianMatrix(rows: Int, columns: Int) -> [Float] {
        var generator = SplitMix64(seed: 0x5EED_51A1_1A2B_C3D4)
        var matrix = [Float](repeating: 0, count: rows * columns)
        var index = 0
        while index < matrix.count {
            // Box-Muller: iki düzgün dağılımlı sayıdan iki normal dağılımlı sayı
            let u1 = max(Double(generator.next() >> 11) / Double(1 << 53), .leastNonzeroMagnitude)
            let u2 = Double(generator.next() >> 11) / Double(1 << 53)
            let radius = (-2 * log(u1)).squareRoot()
            matrix[index] = Float(radius * cos(2 * .pi * u2))
            if index + 1 < matrix.count {
                matrix[index + 1] = Float(radius * sin(2 * .pi * u2))
            }
            index += 2
        }
        return matrix
    }

    /// Metadata'ya göre iki fotoğrafın karşılaştırılmaya değer olup olmadığı.
    /// Tarih yalnızca aday seçiminde kullanılır; benzerlik skoruna etki etmez.
    private static func isCandidate(
        _ a: PhotoSnapshot,
        _ b: PhotoSnapshot,
        timeDiff: TimeInterval,
        settings: SimilaritySettings
    ) -> Bool {
        if timeDiff <= settings.dateThresholdSeconds {
            return true
        }

        if timeDiff <= sameSizeTimeWindow {
            let sizeA = Double(a.pixelWidth * a.pixelHeight)
            let sizeB = Double(b.pixelWidth * b.pixelHeight)
            if max(sizeA, sizeB) > 0, abs(sizeA - sizeB) / max(sizeA, sizeB) < 0.1 {
                return true
            }
        }

        if timeDiff <= locationTimeWindow,
            let latA = a.latitude, let lonA = a.longitude,
            let latB = b.latitude, let lonB = b.longitude
        {
            let distance = CLLocation(latitude: latA, longitude: lonA)
                .distance(from: CLLocation(latitude: latB, longitude: lonB))
            if distance <= settings.locationThresholdMeters {
                return true
            }
        }

        return false
    }

    private struct SizeKey: Hashable {
        let width: Int
        let height: Int
    }
}

// MARK: - Seeded Random

/// Tekrarlanabilir hiper-düzlemler için basit, hızlı tohumlu üreteç
nonisolated private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Union-Find

/// Grup istatistiklerini (kenar skor toplamı, kopya bilgisi, temsilci) tutan Union-Find
nonisolated private struct UnionFind {
    struct Stats {
        var scoreSum: Double = 0
        var edgeCount = 0
        var allDuplicate = true
        var representative: Int
    }

    private var parent: [Int]
    private var rank: [Int]
    private var statsByRoot: [Int: Stats] = [:]

    init(count: Int) {
        parent = Array(0..<count)
        rank = Array(repeating: 0, count: count)
    }

    mutating func find(_ x: Int) -> Int {
        var root = x
        while parent[root] != root { root = parent[root] }
        // Yol sıkıştırma
        var node = x
        while parent[node] != root {
            let next = parent[node]
            parent[node] = root
            node = next
        }
        return root
    }

    func representative(of root: Int) -> Int {
        statsByRoot[root]?.representative ?? root
    }

    func stats(of root: Int) -> Stats {
        statsByRoot[root] ?? Stats(representative: root)
    }

    mutating func addEdge(to root: Int, score: Double, isDuplicate: Bool) {
        var stats = stats(of: root)
        stats.scoreSum += score
        stats.edgeCount += 1
        stats.allDuplicate = stats.allDuplicate && isDuplicate
        statsByRoot[root] = stats
    }

    mutating func union(_ rootA: Int, _ rootB: Int, score: Double, isDuplicate: Bool) {
        let statsA = stats(of: rootA)
        let statsB = stats(of: rootB)

        let newRoot: Int
        let oldRoot: Int
        if rank[rootA] < rank[rootB] {
            newRoot = rootB
            oldRoot = rootA
        } else {
            newRoot = rootA
            oldRoot = rootB
            if rank[rootA] == rank[rootB] { rank[rootA] += 1 }
        }
        parent[oldRoot] = newRoot

        statsByRoot[oldRoot] = nil
        statsByRoot[newRoot] = Stats(
            scoreSum: statsA.scoreSum + statsB.scoreSum + score,
            edgeCount: statsA.edgeCount + statsB.edgeCount + 1,
            allDuplicate: statsA.allDuplicate && statsB.allDuplicate && isDuplicate,
            // Daha büyük geçmişe sahip grubun temsilcisini koru
            representative: statsA.edgeCount >= statsB.edgeCount ? statsA.representative : statsB.representative
        )
    }
}
