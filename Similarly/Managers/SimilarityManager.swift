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
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0

    // Benzerlik eşikleri
    private let dateThresholdSeconds: TimeInterval = 5.0  // 5 saniye içinde
    private let locationThresholdMeters: Double = 100.0  // 100 metre içinde
    private let pHashThreshold: Int = 10  // Hamming distance
    private let histogramThreshold: Double = 0.15  // %85 benzerlik

    // MARK: - Main Analysis Function

    func findSimilarPhotos(from photos: [PhotoItem]) async {
        isAnalyzing = true
        analysisProgress = 0.0
        similarGroups = []

        print("🔍 \(photos.count) fotoğraf arasında benzerlik analizi başlatılıyor...")

        // 1. Metadata ile ön filtreleme yap
        let candidateGroups = await filterByMetadata(photos)
        analysisProgress = 0.3

        print("📊 \(candidateGroups.count) aday grup bulundu (metadata bazlı)")

        // 2. Görüntü bazlı benzerlik analizi
        var finalGroups: [SimilarPhotoGroup] = []

        for (index, group) in candidateGroups.enumerated() {
            if group.count > 1 {
                let similarGroup = await analyzeImageSimilarity(group)
                if similarGroup.count > 1 {
                    finalGroups.append(similarGroup)
                }
            }

            let progress = 0.3 + (0.7 * Double(index + 1) / Double(candidateGroups.count))
            analysisProgress = progress
        }

        // Benzerlik skoruna göre sırala (en yüksek benzerlik önce)
        finalGroups.sort { $0.similarityScore > $1.similarityScore }

        similarGroups = finalGroups
        isAnalyzing = false
        analysisProgress = 1.0

        print("✅ \(similarGroups.count) benzer fotoğraf grubu bulundu")
    }

    // MARK: - Metadata Filtering

    private func filterByMetadata(_ photos: [PhotoItem]) async -> [[PhotoItem]] {
        var groups: [[PhotoItem]] = []
        var processed = Set<String>()

        for photo in photos {
            if processed.contains(photo.id) {
                continue
            }

            var group = [photo]
            processed.insert(photo.id)

            // Bu fotoğrafa yakın metadata'ya sahip diğer fotoğrafları bul
            for otherPhoto in photos {
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
        var totalScore: Double = 0.0
        var comparisonCount = 0

        // Tüm fotoğrafları birbiriyle karşılaştır
        for i in 0..<photos.count {
            for j in (i + 1)..<photos.count {
                let score = comparePhotos(photos[i], photos[j])

                if score > 0.7 {  // %70'den fazla benzerlik
                    totalScore += score
                    comparisonCount += 1

                    // İlk fotoğrafı henüz eklememişsek ekle
                    if !similarPhotos.contains(where: { $0.id == photos[i].id }) {
                        similarPhotos.append(photos[i])
                    }

                    // İkinci fotoğrafı da ekle
                    if !similarPhotos.contains(where: { $0.id == photos[j].id }) {
                        similarPhotos.append(photos[j])
                    }
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

    // MARK: - Helper Functions

    func getSimilarityDescription(_ score: Double) -> String {
        switch score {
        case 0.95...:
            return "Neredeyse aynı"
        case 0.85..<0.95:
            return "Çok benzer"
        case 0.75..<0.85:
            return "Benzer"
        case 0.65..<0.75:
            return "Biraz benzer"
        default:
            return "Az benzer"
        }
    }

    func getTotalSimilarPhotosCount() -> Int {
        return similarGroups.reduce(0) { $0 + $1.count }
    }

    func getPotentialSpaceSavings() -> Int64 {
        var totalSize: Int64 = 0

        for group in similarGroups {
            // Her gruptan en iyi kaliteyi tutup diğerlerini sil
            let photosToDelete = group.photos.dropFirst()
            for photo in photosToDelete {
                // Gerçek dosya boyutunu PHAssetResource ile al
                if let resource = PHAssetResource.assetResources(for: photo.asset).first,
                    let fileSize = resource.value(forKey: "fileSize") as? Int64
                {
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
}
