//
//  SimilarityManager.swift
//  Similarly
//
//  Created by AI Agent
//

import Combine
import Foundation
import Photos
import os

private let logger = Logger(subsystem: "com.similarly.app", category: "similarity")

@MainActor
final class SimilarityManager: ObservableObject {
    @Published var similarGroups: [SimilarPhotoGroup] = []
    @Published var duplicateGroups: [SimilarPhotoGroup] = []
    @Published var screenshotGroups: [SimilarPhotoGroup] = []
    @Published var blurryPhotos: [PhotoItem] = []
    @Published var darkPhotos: [PhotoItem] = []
    @Published var brightPhotos: [PhotoItem] = []
    @Published var videos: [PhotoItem] = []
    @Published var livePhotos: [PhotoItem] = []
    @Published private(set) var isAnalyzing = false
    @Published private(set) var analysisProgress: Double = 0.0
    /// Her gruptan en iyi fotoğraf tutulup diğerleri silinirse kazanılacak tahmini alan (bayt)
    @Published private(set) var potentialSavings: Int64 = 0
    /// Son analizdeki görsel sayısı ve bunlardan başarıyla analiz edilebilenlerin sayısı
    @Published private(set) var imageCount = 0
    @Published private(set) var analyzedImageCount = 0

    /// Görsel var ama hiçbiri analiz edilemediyse true; bu durumda "kütüphane temiz" demek yanıltıcı olur.
    var isAnalysisUnavailable: Bool {
        imageCount > 0 && analyzedImageCount == 0
    }

    // Benzerlik eşikleri - UserDefaults'tan alınıyor
    private var currentSettings: SimilaritySettings {
        let defaults = UserDefaults.standard
        return SimilaritySettings(
            similarityThreshold: defaults.doubleValue(
                forKey: "similarityThreshold",
                default: AppDefaults.similarityThreshold
            ),
            dateThresholdSeconds: defaults.doubleValue(
                forKey: "dateThreshold",
                default: AppDefaults.dateThresholdSeconds
            ),
            locationThresholdMeters: defaults.doubleValue(
                forKey: "locationThreshold",
                default: AppDefaults.locationThresholdMeters
            )
        )
    }

    private var blurThreshold: Double {
        UserDefaults.standard.doubleValue(forKey: "blurThreshold", default: AppDefaults.blurThreshold)
    }

    private var darknessThreshold: Double {
        UserDefaults.standard.doubleValue(forKey: "darknessThreshold", default: AppDefaults.darknessThreshold)
    }

    private var brightnessThreshold: Double {
        UserDefaults.standard.doubleValue(forKey: "brightnessThreshold", default: AppDefaults.brightnessThreshold)
    }

    // MARK: - Main Analysis Function

    /// Benzer fotoğrafları ve kalite sorunlarını bulur. Ağır hesaplama ana thread dışında yapılır;
    /// çağıran görev iptal edilirse sonuçlar boş bırakılır.
    func findSimilarPhotos(from photos: [PhotoItem], featurePrints: [String: [Float]]) async {
        isAnalyzing = true
        analysisProgress = 0.0
        resetResults()

        videos = photos.filter { $0.mediaType == .video }
        livePhotos = photos.filter { $0.isLivePhoto }

        let images = photos.filter { $0.mediaType == .image }
        imageCount = images.count
        analyzedImageCount = images.filter { featurePrints[$0.id] != nil }.count
        detectQualityIssues(images)

        let snapshots = images.map { photo in
            PhotoSnapshot(
                id: photo.id,
                creationDate: photo.creationDate,
                latitude: photo.location?.coordinate.latitude,
                longitude: photo.location?.coordinate.longitude,
                pixelWidth: photo.pixelWidth,
                pixelHeight: photo.pixelHeight
            )
        }

        logger.info("Similarity analysis started for \(images.count) images")

        do {
            let clusters = try await SimilarityEngine.run(
                photos: snapshots,
                vectors: featurePrints,
                settings: currentSettings
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self, self.isAnalyzing else { return }
                    self.analysisProgress = progress
                }
            }

            let photosByID = Dictionary(images.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let groups = clusters.map { cluster in
                SimilarPhotoGroup(
                    photos: cluster.memberIDs.compactMap { photosByID[$0] },
                    similarityScore: cluster.score,
                    isDuplicate: cluster.isDuplicate
                )
            }
            categorizeGroups(groups)
            analysisProgress = 1.0
            logger.info(
                "Found \(self.duplicateGroups.count) duplicate, \(self.screenshotGroups.count) screenshot, \(self.similarGroups.count) similar groups"
            )
        } catch {
            // İptal edildi: yarım sonuç gösterme.
            resetResults()
            logger.info("Similarity analysis cancelled")
        }

        isAnalyzing = false
    }

    private func resetResults() {
        similarGroups = []
        duplicateGroups = []
        screenshotGroups = []
        blurryPhotos = []
        darkPhotos = []
        brightPhotos = []
        potentialSavings = 0
    }

    // MARK: - Group Categorization

    private func categorizeGroups(_ groups: [SimilarPhotoGroup]) {
        var duplicates: [SimilarPhotoGroup] = []
        var screenshots: [SimilarPhotoGroup] = []
        var similar: [SimilarPhotoGroup] = []

        for group in groups where group.count > 1 {
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
        recalculateSavings()
    }

    private func sortGroupWithFavoritesFirst(_ group: SimilarPhotoGroup) -> SimilarPhotoGroup {
        var sorted = group
        sorted.photos = group.photos.sorted { photo1, photo2 in
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
            return (photo1.creationDate ?? .distantPast) > (photo2.creationDate ?? .distantPast)
        }
        return sorted
    }

    // MARK: - Quality Issue Detection

    private func detectQualityIssues(_ photos: [PhotoItem]) {
        let blurLimit = blurThreshold
        let darkLimit = darknessThreshold
        let brightLimit = brightnessThreshold

        var blurry: [PhotoItem] = []
        var dark: [PhotoItem] = []
        var bright: [PhotoItem] = []

        for photo in photos where photo.hasAnalysis && !photo.qualityDismissed {
            if let blurScore = photo.blurScore, blurScore <= blurLimit {
                blurry.append(photo)
            }
            if let brightnessScore = photo.brightnessScore {
                if brightnessScore <= darkLimit {
                    dark.append(photo)
                } else if brightnessScore >= brightLimit {
                    bright.append(photo)
                }
            }
        }

        // Kalite skoruna göre sırala (en kötü önce)
        blurryPhotos = blurry.sorted { ($0.blurScore ?? 0) < ($1.blurScore ?? 0) }
        darkPhotos = dark.sorted { ($0.brightnessScore ?? 1) < ($1.brightnessScore ?? 1) }
        brightPhotos = bright.sorted { ($0.brightnessScore ?? 0) > ($1.brightnessScore ?? 0) }
    }

    // MARK: - Removing Photos

    /// Silinen (veya kütüphaneden kaybolan) fotoğrafları tüm sonuç listelerinden çıkarır.
    /// Tek fotoğrafı kalan gruplar düşürülür; yeniden analiz gerekmez.
    func removePhotos(ids: Set<String>) {
        guard !ids.isEmpty else { return }

        func prune(_ groups: [SimilarPhotoGroup]) -> [SimilarPhotoGroup] {
            groups.compactMap { group in
                var updated = group
                updated.photos.removeAll { ids.contains($0.id) }
                return updated.count > 1 ? updated : nil
            }
        }

        similarGroups = prune(similarGroups)
        duplicateGroups = prune(duplicateGroups)
        screenshotGroups = prune(screenshotGroups)
        blurryPhotos.removeAll { ids.contains($0.id) }
        darkPhotos.removeAll { ids.contains($0.id) }
        brightPhotos.removeAll { ids.contains($0.id) }
        videos.removeAll { ids.contains($0.id) }
        livePhotos.removeAll { ids.contains($0.id) }
        recalculateSavings()
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

    // MARK: - Helper Functions

    func getTotalSimilarPhotosCount() -> Int {
        similarGroups.reduce(0) { $0 + $1.count }
    }

    func getTotalDuplicatesCount() -> Int {
        duplicateGroups.reduce(0) { $0 + $1.count }
    }

    func getTotalScreenshotsCount() -> Int {
        screenshotGroups.reduce(0) { $0 + $1.count }
    }

    func getAllGroups() -> [SimilarPhotoGroup] {
        duplicateGroups + screenshotGroups + similarGroups
    }

    /// Kalite sorunu olan farklı fotoğraf sayısı (hem bulanık hem karanlık olan bir fotoğraf bir kez sayılır)
    func getTotalQualityIssuesCount() -> Int {
        Set((blurryPhotos + darkPhotos + brightPhotos).map(\.id)).count
    }

    /// Her gruptan en iyi fotoğraf tutulduğunda silinebilecek fotoğraf sayısı
    func getCleanablePhotosCount() -> Int {
        getAllGroups().reduce(0) { $0 + max(0, $1.count - 1) }
    }

    func getTotalVideosCount() -> Int {
        videos.count
    }

    func getTotalLivePhotosCount() -> Int {
        livePhotos.count
    }

    private func recalculateSavings() {
        // Her gruptan en iyi fotoğrafı (ilk sıradaki) tutup diğerlerini silmeyi varsay.
        potentialSavings = getAllGroups().reduce(Int64(0)) { total, group in
            total + group.photos.dropFirst().reduce(Int64(0)) { $0 + $1.estimatedFileSize }
        }
    }
}
