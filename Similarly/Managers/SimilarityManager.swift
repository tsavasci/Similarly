//
//  SimilarityManager.swift
//  Similarly
//
//  Created by AI Agent
//

import Combine
import CoreImage
import CoreLocation
import Foundation
import Photos

/// Fotoğrafları karşılaştıran ve benzer gruplar oluşturan sınıf
@MainActor
class SimilarityManager: ObservableObject {
    @Published var similarGroups: [SimilarPhotoGroup] = []
    @Published var duplicateGroups: [SimilarPhotoGroup] = []
    @Published var screenshotGroups: [SimilarPhotoGroup] = []
    @Published var blurryPhotos: [PhotoItem] = []
    @Published var darkPhotos: [PhotoItem] = []
    @Published var brightPhotos: [PhotoItem] = []
    @Published var videos: [PhotoItem] = []
    @Published var livePhotos: [PhotoItem] = []
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0

    // Benzerlik eşikleri - UserDefaults'tan alınıyor
    private var dateThresholdSeconds: TimeInterval {
        UserDefaults.standard.doubleValue(
            forKey: "dateThreshold",
            default: AppDefaults.dateThresholdSeconds
        )
    }

    private var locationThresholdMeters: Double {
        UserDefaults.standard.doubleValue(
            forKey: "locationThreshold",
            default: AppDefaults.locationThresholdMeters
        )
    }

    private var similarityThreshold: Double {
        UserDefaults.standard.doubleValue(
            forKey: "similarityThreshold",
            default: AppDefaults.similarityThreshold
        )
    }

    private var pHashThreshold: Int {
        // Benzerlik threshold'una göre dinamik hesapla
        // 0.85 = 10 hamming distance
        // 0.70 = 15 hamming distance
        // 0.95 = 5 hamming distance
        let similarity = similarityThreshold
        if similarity >= 0.95 {
            return 5
        } else if similarity >= 0.85 {
            return 10
        } else if similarity >= 0.75 {
            return 12
        } else {
            return 15
        }
    }

    private var blurThreshold: Double {
        UserDefaults.standard.doubleValue(
            forKey: "blurThreshold",
            default: AppDefaults.blurThreshold
        )
    }

    private var darknessThreshold: Double {
        UserDefaults.standard.doubleValue(
            forKey: "darknessThreshold",
            default: AppDefaults.darknessThreshold
        )
    }

    private var brightnessThreshold: Double {
        UserDefaults.standard.doubleValue(
            forKey: "brightnessThreshold",
            default: AppDefaults.brightnessThreshold
        )
    }

    // MARK: - Main Analysis Function

    func findSimilarPhotos(from photos: [PhotoItem]) async {
        isAnalyzing = true
        analysisProgress = 0.0
        similarGroups = []

        // Videoları ve Live Photos'ları ayır
        videos = photos.filter { $0.mediaType == .video }
        livePhotos = photos.filter { $0.isLivePhoto }

        // Sadece image'ları analiz et
        let imagesToAnalyze = photos.filter { $0.mediaType == .image }

        print(L10n.f("log.similarity.start", imagesToAnalyze.count))
        if !videos.isEmpty {
            print(L10n.f("log.similarity.videos_found", videos.count))
        }
        if !livePhotos.isEmpty {
            print(L10n.f("log.similarity.live_found", livePhotos.count))
        }

        // 1. Metadata ile ön filtreleme yap
        let candidateGroups = await filterByMetadata(imagesToAnalyze)
        analysisProgress = 0.3

        print(L10n.f("log.similarity.candidates_found", candidateGroups.count))

        // 2. Görüntü bazlı benzerlik analizi
        var finalGroups: [SimilarPhotoGroup] = []

        for (index, group) in candidateGroups.enumerated() {
            if group.count > 1 {
                let similarGroup = await analyzeImageSimilarity(group)
                // Kullanıcı eşiğine göre yeterince benzer grupları ekle
                if similarGroup.count > 1 && similarGroup.similarityScore >= similarityThreshold {
                    finalGroups.append(similarGroup)
                }
            }

            let progress = 0.3 + (0.7 * Double(index + 1) / Double(candidateGroups.count))
            analysisProgress = progress
        }

        // Grupları kategorilere ayır
        categorizeGroups(finalGroups)

        isAnalyzing = false
        analysisProgress = 1.0

        // Kalite sorunlu fotoğrafları filtrele
        detectQualityIssues(imagesToAnalyze)

        print(L10n.f("log.similarity.groups_similar", similarGroups.count))
        print(L10n.f("log.similarity.groups_duplicate", duplicateGroups.count))
        print(L10n.f("log.similarity.groups_screenshot", screenshotGroups.count))
        print(L10n.f("log.similarity.blurry_found", blurryPhotos.count))
        print(L10n.f("log.similarity.dark_found", darkPhotos.count))
        print(L10n.f("log.similarity.bright_found", brightPhotos.count))
    }

    // MARK: - Group Categorization

    private func categorizeGroups(_ groups: [SimilarPhotoGroup]) {
        var duplicates: [SimilarPhotoGroup] = []
        var screenshots: [SimilarPhotoGroup] = []
        var similar: [SimilarPhotoGroup] = []

        for group in groups {
            // Her grupta favorileri korumak için sırala
            let sortedGroup = sortGroupWithFavoritesFirst(group)

            if sortedGroup.isDuplicate {
                duplicates.append(sortedGroup)
            } else if sortedGroup.allScreenshots {
                screenshots.append(sortedGroup)
            } else {
                similar.append(sortedGroup)
            }
        }

        // Benzerlik skoruna göre sırala (en yüksek benzerlik önce)
        duplicateGroups = duplicates.sorted { $0.similarityScore > $1.similarityScore }
        screenshotGroups = screenshots.sorted { $0.similarityScore > $1.similarityScore }
        similarGroups = similar.sorted { $0.similarityScore > $1.similarityScore }
    }

    private func sortGroupWithFavoritesFirst(_ group: SimilarPhotoGroup) -> SimilarPhotoGroup {
        let sortedPhotos = group.photos.sorted { photo1, photo2 in
            // 1. Favoriler önce
            if photo1.isFavorite != photo2.isFavorite {
                return photo1.isFavorite
            }

            // 2. Yüksek çözünürlük önce
            let resolution1 = photo1.pixelWidth * photo1.pixelHeight
            let resolution2 = photo2.pixelWidth * photo2.pixelHeight
            if resolution1 != resolution2 {
                return resolution1 > resolution2
            }

            // 3. Yeni tarih önce
            if let date1 = photo1.creationDate, let date2 = photo2.creationDate {
                return date1 > date2
            }

            return false
        }

        return SimilarPhotoGroup(
            photos: sortedPhotos,
            similarityScore: group.similarityScore
        )
    }

    // MARK: - Quality Issue Detection

    private func detectQualityIssues(_ photos: [PhotoItem]) {
        var blurry: [PhotoItem] = []
        var dark: [PhotoItem] = []
        var bright: [PhotoItem] = []

        for photo in photos {
            // Kullanıcı eşikleri ile karşılaştır
            if let blurScore = photo.blurScore, blurScore <= blurThreshold {
                blurry.append(photo)
            }
            if let brightnessScore = photo.brightnessScore, brightnessScore <= darknessThreshold {
                dark.append(photo)
            }
            if let brightnessScore = photo.brightnessScore, brightnessScore >= brightnessThreshold {
                bright.append(photo)
            }
        }

        // Kalite skoruna göre sırala (en kötü önce)
        blurryPhotos = blurry.sorted { ($0.blurScore ?? 0) < ($1.blurScore ?? 0) }
        darkPhotos = dark.sorted { ($0.brightnessScore ?? 1) < ($1.brightnessScore ?? 1) }
        brightPhotos = bright.sorted { ($0.brightnessScore ?? 0) > ($1.brightnessScore ?? 0) }
    }

    // MARK: - Metadata Filtering

    private func filterByMetadata(_ photos: [PhotoItem]) async -> [[PhotoItem]] {
        guard !photos.isEmpty else { return [] }

        let indexes = buildMetadataIndexes(for: photos)
        var groups: [[PhotoItem]] = []
        var processed = Set<String>()

        for (index, photo) in photos.enumerated() {
            if processed.contains(photo.id) {
                continue
            }

            var group = [photo]
            processed.insert(photo.id)
            var candidateIndexes = Set<Int>()

            if let date = photo.creationDate {
                let bucket = Int(floor(date.timeIntervalSince1970 / indexes.dateBucketSize))
                for neighborBucket in (bucket - 1)...(bucket + 1) {
                    if let indices = indexes.dateBuckets[neighborBucket] {
                        candidateIndexes.formUnion(indices)
                    }
                }
            }

            if let location = photo.location {
                let cell = locationCell(for: location, cellSizeMeters: indexes.locationCellSize)
                for xOffset in -1...1 {
                    for yOffset in -1...1 {
                        let neighborCell = LocationCell(x: cell.x + xOffset, y: cell.y + yOffset)
                        if let indices = indexes.locationBuckets[neighborCell] {
                            candidateIndexes.formUnion(indices)
                        }
                    }
                }
            }

            // Sadece indekslenmiş adayları karşılaştır
            for candidateIndex in candidateIndexes.sorted() {
                if candidateIndex == index {
                    continue
                }

                let otherPhoto = photos[candidateIndex]
                if processed.contains(otherPhoto.id) {
                    continue
                }

                if isMetadataSimilar(photo, otherPhoto) {
                    group.append(otherPhoto)
                    processed.insert(otherPhoto.id)
                }
            }

            groups.append(group)
        }

        return groups
    }

    private func buildMetadataIndexes(for photos: [PhotoItem]) -> MetadataIndexes {
        // Metadata kuralında en geniş tarih penceresi 60 saniye.
        let dateBucketSize = max(1.0, max(dateThresholdSeconds, 60.0))
        let locationCellSize = max(1.0, locationThresholdMeters)
        var dateBuckets: [Int: [Int]] = [:]
        var locationBuckets: [LocationCell: [Int]] = [:]

        for (index, photo) in photos.enumerated() {
            if let date = photo.creationDate {
                let bucket = Int(floor(date.timeIntervalSince1970 / dateBucketSize))
                dateBuckets[bucket, default: []].append(index)
            }

            if let location = photo.location {
                let cell = locationCell(for: location, cellSizeMeters: locationCellSize)
                locationBuckets[cell, default: []].append(index)
            }
        }

        return MetadataIndexes(
            dateBuckets: dateBuckets,
            locationBuckets: locationBuckets,
            dateBucketSize: dateBucketSize,
            locationCellSize: locationCellSize
        )
    }

    private func locationCell(for location: CLLocation, cellSizeMeters: Double) -> LocationCell {
        // Web Mercator projection ile enleme göre değişen ölçek sorununu azalt.
        let earthRadius = 6_378_137.0
        let latitudeRadians = location.coordinate.latitude * .pi / 180.0
        let longitudeRadians = location.coordinate.longitude * .pi / 180.0
        let clampedLatitude = min(max(latitudeRadians, -1.4844222297453324), 1.4844222297453324)
        let xMeters = earthRadius * longitudeRadians
        let yMeters = earthRadius * log(tan(.pi / 4.0 + clampedLatitude / 2.0))

        return LocationCell(
            x: Int(floor(xMeters / cellSizeMeters)),
            y: Int(floor(yMeters / cellSizeMeters))
        )
    }

    private func isMetadataSimilar(_ photo1: PhotoItem, _ photo2: PhotoItem) -> Bool {
        // Tarih yakınlığı kontrolü (seri çekim)
        if let date1 = photo1.creationDate, let date2 = photo2.creationDate {
            let timeDiff = abs(date1.timeIntervalSince(date2))
            if timeDiff <= dateThresholdSeconds {
                return true
            }
        }

        // Lokasyon yakınlığı kontrolü
        if let loc1 = photo1.location, let loc2 = photo2.location {
            let distance = loc1.distance(from: loc2)
            if distance <= locationThresholdMeters {
                return true
            }
        }

        // Boyut benzerliği (aynı kamera/ayarlar)
        let size1 = photo1.pixelWidth * photo1.pixelHeight
        let size2 = photo2.pixelWidth * photo2.pixelHeight
        let sizeDiff = abs(Double(size1 - size2)) / Double(max(size1, size2))
        if sizeDiff < 0.1 {  // %10 fark
            // Aynı boyutsa ve yakın tarihliyse grup adayı
            if let date1 = photo1.creationDate, let date2 = photo2.creationDate {
                let timeDiff = abs(date1.timeIntervalSince(date2))
                if timeDiff <= 60.0 {  // 1 dakika içinde
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Image Similarity Analysis

    private func analyzeImageSimilarity(_ photos: [PhotoItem]) async -> SimilarPhotoGroup {
        var similarPhotos: [PhotoItem] = []
        var similarPhotoIds = Set<String>()
        var totalScore: Double = 0.0
        var comparisonCount = 0
        let candidatePairs = buildCandidatePairs(for: photos)

        for pair in candidatePairs {
            let score = comparePhotos(photos[pair.first], photos[pair.second])

            if score >= similarityThreshold {
                totalScore += score
                comparisonCount += 1

                // O(1) üyelik kontrolü ile gereksiz taramayı azalt.
                if similarPhotoIds.insert(photos[pair.first].id).inserted {
                    similarPhotos.append(photos[pair.first])
                }

                if similarPhotoIds.insert(photos[pair.second].id).inserted {
                    similarPhotos.append(photos[pair.second])
                }
            }
        }

        let averageScore = comparisonCount > 0 ? totalScore / Double(comparisonCount) : 0.0

        return SimilarPhotoGroup(
            photos: similarPhotos.isEmpty ? photos : similarPhotos,
            similarityScore: averageScore
        )
    }

    // MARK: - Photo Comparison

    func comparePhotos(_ photo1: PhotoItem, _ photo2: PhotoItem) -> Double {
        var totalScore: Double = 0.0
        var scoreCount = 0

        // 1. pHash karşılaştırması (en önemli)
        if let hash1 = photo1.pHash, let hash2 = photo2.pHash {
            let hammingDistance = calculateHammingDistance(hash1, hash2)
            if hammingDistance > pHashThreshold {
                return 0.0
            }
            let pHashScore = 1.0 - (Double(hammingDistance) / 64.0)  // 64 bit hash
            totalScore += pHashScore * 2.0  // pHash'e daha fazla ağırlık ver
            scoreCount += 2
        }

        // 2. Histogram karşılaştırması
        if let hist1 = photo1.histogram, let hist2 = photo2.histogram {
            let histScore = compareHistograms(hist1, hist2)
            totalScore += histScore
            scoreCount += 1
        }

        // 3. Metadata bonusu
        if let date1 = photo1.creationDate, let date2 = photo2.creationDate {
            let timeDiff = abs(date1.timeIntervalSince(date2))
            if timeDiff <= dateThresholdSeconds {
                totalScore += 0.3  // Seri çekim bonusu
                scoreCount += 1
            }
        }

        return scoreCount > 0 ? totalScore / Double(scoreCount) : 0.0
    }

    // MARK: - Hamming Distance (pHash için)

    private func calculateHammingDistance(_ hash1: String, _ hash2: String) -> Int {
        guard hash1.count == hash2.count else { return 64 }  // Maksimum fark

        var distance = 0

        let chars1 = Array(hash1)
        let chars2 = Array(hash2)

        for i in 0..<chars1.count {
            if chars1[i] != chars2[i] {
                // Hex karakterlerdeki bit farklarını say
                if let val1 = Int(String(chars1[i]), radix: 16),
                    let val2 = Int(String(chars2[i]), radix: 16)
                {
                    let xor = val1 ^ val2
                    distance += xor.nonzeroBitCount
                }
            }
        }

        return distance
    }

    // MARK: - Histogram Comparison

    private func compareHistograms(_ hist1: [CGFloat], _ hist2: [CGFloat]) -> Double {
        guard hist1.count == hist2.count, !hist1.isEmpty else { return 0.0 }

        // Bhattacharyya distance kullanarak benzerlik hesapla
        let sum1 = hist1.reduce(0, +)
        let sum2 = hist2.reduce(0, +)

        guard sum1 > 0, sum2 > 0 else { return 0.0 }

        // Normalize et
        let norm1 = hist1.map { $0 / sum1 }
        let norm2 = hist2.map { $0 / sum2 }

        // Bhattacharyya coefficient
        var bc: CGFloat = 0.0
        for i in 0..<norm1.count {
            bc += sqrt(norm1[i] * norm2[i])
        }

        // Similarity score (0-1 arası)
        let similarity = Double(bc)

        return similarity
    }

    private func buildCandidatePairs(for photos: [PhotoItem]) -> [PhotoPair] {
        guard photos.count > 1 else { return [] }

        let threshold = min(max(pHashThreshold, 0), 63)
        let segmentCount = min(64, max(1, threshold + 1))
        let segments = buildHashSegments(count: segmentCount)

        var hashByIndex: [Int: UInt64] = [:]
        var buckets: [PHashBucketKey: [Int]] = [:]
        var nonHashedIndices: [Int] = []

        for (index, photo) in photos.enumerated() {
            guard let hashString = photo.pHash, let hashValue = UInt64(hashString, radix: 16) else {
                nonHashedIndices.append(index)
                continue
            }

            hashByIndex[index] = hashValue
            for segment in segments {
                let key = PHashBucketKey(
                    segmentIndex: segment.index,
                    value: extractSegmentValue(from: hashValue, segment: segment)
                )
                buckets[key, default: []].append(index)
            }
        }

        var candidatePairs = Set<PhotoPair>()
        let nonHashedSet = Set(nonHashedIndices)

        for i in photos.indices {
            if let hashValue = hashByIndex[i] {
                var neighbors = Set<Int>()
                for segment in segments {
                    let key = PHashBucketKey(
                        segmentIndex: segment.index,
                        value: extractSegmentValue(from: hashValue, segment: segment)
                    )
                    if let indices = buckets[key] {
                        for j in indices where j > i {
                            neighbors.insert(j)
                        }
                    }
                }

                // Hash olmayan fotoğraflarla karşılaştırmayı koru.
                for j in nonHashedSet where j > i {
                    neighbors.insert(j)
                }

                for j in neighbors {
                    candidatePairs.insert(PhotoPair(first: i, second: j))
                }
            } else {
                // Hash olmayanlar için fallback: önceki davranışı korumak adına tam tarama.
                for j in (i + 1)..<photos.count {
                    candidatePairs.insert(PhotoPair(first: i, second: j))
                }
            }
        }

        return candidatePairs.sorted { lhs, rhs in
            if lhs.first == rhs.first {
                return lhs.second < rhs.second
            }
            return lhs.first < rhs.first
        }
    }

    private func buildHashSegments(count: Int) -> [HashSegment] {
        let base = 64 / count
        let remainder = 64 % count
        var segments: [HashSegment] = []
        segments.reserveCapacity(count)

        var currentStart = 0
        for index in 0..<count {
            let extraBit = index < remainder ? 1 : 0
            let bitCount = base + extraBit
            segments.append(HashSegment(index: index, startBit: currentStart, bitCount: bitCount))
            currentStart += bitCount
        }

        return segments
    }

    private func extractSegmentValue(from hashValue: UInt64, segment: HashSegment) -> UInt64 {
        if segment.bitCount == 64 {
            return hashValue
        }

        let mask = (UInt64(1) << UInt64(segment.bitCount)) - 1
        return (hashValue >> UInt64(segment.startBit)) & mask
    }

    // MARK: - Helper Functions

    func getSimilarityDescription(_ score: Double) -> String {
        switch score {
        case 0.95...:
            return L10n.t("similarity.almost_identical")
        case 0.85..<0.95:
            return L10n.t("similarity.very_similar")
        case 0.75..<0.85:
            return L10n.t("similarity.similar")
        case 0.65..<0.75:
            return L10n.t("similarity.slightly_similar")
        default:
            return L10n.t("similarity.less_similar")
        }
    }

    func getTotalSimilarPhotosCount() -> Int {
        return similarGroups.reduce(0) { $0 + $1.count }
    }

    func getTotalDuplicatesCount() -> Int {
        return duplicateGroups.reduce(0) { $0 + $1.count }
    }

    func getTotalScreenshotsCount() -> Int {
        return screenshotGroups.reduce(0) { $0 + $1.count }
    }

    func getAllGroups() -> [SimilarPhotoGroup] {
        return duplicateGroups + screenshotGroups + similarGroups
    }

    func getTotalQualityIssuesCount() -> Int {
        return blurryPhotos.count + darkPhotos.count + brightPhotos.count
    }

    func getTotalVideosCount() -> Int {
        return videos.count
    }

    func getTotalLivePhotosCount() -> Int {
        return livePhotos.count
    }

    // Fotoğrafları kalite sorunları listelerinden kaldır
    func removeFromBlurryPhotos(_ photos: [PhotoItem]) {
        let photoIds = Set(photos.map { $0.id })
        blurryPhotos.removeAll { photoIds.contains($0.id) }
    }

    func removeFromDarkPhotos(_ photos: [PhotoItem]) {
        let photoIds = Set(photos.map { $0.id })
        darkPhotos.removeAll { photoIds.contains($0.id) }
    }

    func removeFromBrightPhotos(_ photos: [PhotoItem]) {
        let photoIds = Set(photos.map { $0.id })
        brightPhotos.removeAll { photoIds.contains($0.id) }
    }

    func getPotentialSpaceSavings() -> Int64 {
        var totalSize: Int64 = 0

        for group in similarGroups {
            // Her gruptan en iyi kaliteyi tutup diğerlerini sil
            let photosToDelete = group.photos.dropFirst()
            for photo in photosToDelete {
                if let fileSize = photo.fileSize {
                    totalSize += fileSize
                } else {
                    // Fallback: JPEG sıkıştırma oranı ~1/10 olarak tahmin et
                    let estimatedSize = Int64(photo.pixelWidth * photo.pixelHeight) / 5
                    totalSize += estimatedSize
                }
            }
        }

        return totalSize
    }

    private struct LocationCell: Hashable {
        let x: Int
        let y: Int
    }

    private struct MetadataIndexes {
        let dateBuckets: [Int: [Int]]
        let locationBuckets: [LocationCell: [Int]]
        let dateBucketSize: TimeInterval
        let locationCellSize: Double
    }

    private struct HashSegment {
        let index: Int
        let startBit: Int
        let bitCount: Int
    }

    private struct PHashBucketKey: Hashable {
        let segmentIndex: Int
        let value: UInt64
    }

    private struct PhotoPair: Hashable {
        let first: Int
        let second: Int

        init(first: Int, second: Int) {
            if first < second {
                self.first = first
                self.second = second
            } else {
                self.first = second
                self.second = first
            }
        }
    }
}
