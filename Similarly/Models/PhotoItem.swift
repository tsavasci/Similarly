//
//  PhotoItem.swift
//  Similarly
//
//  Created by AI Agent
//

import CoreLocation
import Foundation
import Photos

/// Fotoğraf bilgilerini ve analiz sonuçlarını tutan model.
/// Feature print vektörleri bellek tasarrufu için burada değil, `PhotoLibraryManager.featurePrints` içinde tutulur.
struct PhotoItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    let creationDate: Date?
    let modificationDate: Date?
    let location: CLLocation?
    let mediaType: PHAssetMediaType
    let duration: TimeInterval
    let pixelWidth: Int
    let pixelHeight: Int
    let isFavorite: Bool
    let mediaSubtypes: PHAssetMediaSubtype
    var blurScore: Double?
    var brightnessScore: Double?
    var cachedFileSize: Int64?
    /// Güncel analiz sürümüyle başarıyla analiz edildiyse true
    var hasAnalysis: Bool
    /// Kullanıcı "kalite sorunu yok" olarak işaretlediyse true
    var qualityDismissed: Bool

    var isScreenshot: Bool {
        mediaSubtypes.contains(.photoScreenshot)
    }

    var isLivePhoto: Bool {
        mediaSubtypes.contains(.photoLive)
    }

    var fileSize: Int64? {
        cachedFileSize
    }

    /// Dosya boyutu bilinmiyorsa piksel sayısından tahmin eder (HEIC/JPEG ≈ piksel başına 0.2 bayt).
    var estimatedFileSize: Int64 {
        fileSize ?? Int64(pixelWidth * pixelHeight) / 5
    }

    var isBlurry: Bool {
        guard let blurScore else { return false }
        return blurScore <= UserDefaults.standard.doubleValue(
            forKey: "blurThreshold",
            default: AppDefaults.blurThreshold
        )
    }

    var isTooDark: Bool {
        guard let brightnessScore else { return false }
        return brightnessScore <= UserDefaults.standard.doubleValue(
            forKey: "darknessThreshold",
            default: AppDefaults.darknessThreshold
        )
    }

    var isTooBright: Bool {
        guard let brightnessScore else { return false }
        return brightnessScore >= UserDefaults.standard.doubleValue(
            forKey: "brightnessThreshold",
            default: AppDefaults.brightnessThreshold
        )
    }

    var hasQualityIssues: Bool {
        isBlurry || isTooDark || isTooBright
    }

    init(
        asset: PHAsset,
        blurScore: Double? = nil,
        brightnessScore: Double? = nil,
        cachedFileSize: Int64? = nil,
        hasAnalysis: Bool = false,
        qualityDismissed: Bool = false
    ) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.creationDate = asset.creationDate
        self.modificationDate = asset.modificationDate
        self.location = asset.location
        self.mediaType = asset.mediaType
        self.duration = asset.duration
        self.pixelWidth = asset.pixelWidth
        self.pixelHeight = asset.pixelHeight
        self.isFavorite = asset.isFavorite
        self.mediaSubtypes = asset.mediaSubtypes
        self.blurScore = blurScore
        self.brightnessScore = brightnessScore
        self.cachedFileSize = cachedFileSize
        self.hasAnalysis = hasAnalysis
        self.qualityDismissed = qualityDismissed
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Benzer fotoğraf grubunu temsil eden model
struct SimilarPhotoGroup: Identifiable, Hashable {
    let id: UUID
    var photos: [PhotoItem]
    var similarityScore: Double
    /// Gruptaki fotoğraflar birbirinin neredeyse birebir kopyasıysa true
    var isDuplicate: Bool

    init(id: UUID = UUID(), photos: [PhotoItem], similarityScore: Double, isDuplicate: Bool = false) {
        self.id = id
        self.photos = photos
        self.similarityScore = similarityScore
        self.isDuplicate = isDuplicate
    }

    var count: Int {
        photos.count
    }

    var representativePhoto: PhotoItem? {
        photos.first
    }

    var hasFavorite: Bool {
        photos.contains { $0.isFavorite }
    }

    var favoritePhoto: PhotoItem? {
        photos.first { $0.isFavorite }
    }

    var allScreenshots: Bool {
        !photos.isEmpty && photos.allSatisfy { $0.isScreenshot }
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SimilarPhotoGroup, rhs: SimilarPhotoGroup) -> Bool {
        lhs.id == rhs.id
    }
}
