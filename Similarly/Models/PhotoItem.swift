//
//  PhotoItem.swift
//  Similarly
//
//  Created by AI Agent
//

import CoreImage
import Foundation
import Photos

/// Fotoğraf bilgilerini ve benzerlik analizi için gerekli verileri tutan model
struct PhotoItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    var thumbnail: CIImage?
    var pHash: String?
    var histogram: [CGFloat]?
    var blurScore: Double?
    var brightnessScore: Double?
    var cachedFileSize: Int64?

    // Metadata bilgileri
    var creationDate: Date? {
        asset.creationDate
    }

    var modificationDate: Date? {
        asset.modificationDate
    }

    var location: CLLocation? {
        asset.location
    }

    var mediaType: PHAssetMediaType {
        asset.mediaType
    }

    var duration: TimeInterval {
        asset.duration
    }

    var pixelWidth: Int {
        asset.pixelWidth
    }

    var pixelHeight: Int {
        asset.pixelHeight
    }

    var isFavorite: Bool {
        asset.isFavorite
    }

    var isScreenshot: Bool {
        if #available(iOS 9.0, *) {
            return (asset.mediaSubtypes.contains(.photoScreenshot))
        }
        return false
    }

    var isLivePhoto: Bool {
        if #available(iOS 9.1, *) {
            return (asset.mediaSubtypes.contains(.photoLive))
        }
        return false
    }

    var fileSize: Int64? {
        // Sadece cache'lenmiş değeri dön
        // Bu değer PhotoLibraryManager.fetchAssets() içinde prefetch edilir
        return cachedFileSize
    }

    var isBlurry: Bool {
        if let blurScore = blurScore {
            let threshold = UserDefaults.standard.double(forKey: "blurThreshold")
            let finalThreshold = threshold > 0 ? threshold : 100.0
            return blurScore < finalThreshold
        }
        return false
    }

    var isTooDark: Bool {
        if let brightnessScore = brightnessScore {
            let threshold = UserDefaults.standard.double(forKey: "darknessThreshold")
            let finalThreshold = threshold > 0 ? threshold : 0.2
            return brightnessScore < finalThreshold
        }
        return false
    }

    var isTooBright: Bool {
        if let brightnessScore = brightnessScore {
            let threshold = UserDefaults.standard.double(forKey: "brightnessThreshold")
            let finalThreshold = threshold > 0 ? threshold : 0.9
            return brightnessScore > finalThreshold
        }
        return false
    }

    var hasQualityIssues: Bool {
        return isBlurry || isTooDark || isTooBright
    }

    init(
        id: String, asset: PHAsset, thumbnail: CIImage? = nil, pHash: String? = nil,
        histogram: [CGFloat]? = nil, blurScore: Double? = nil, brightnessScore: Double? = nil,
        cachedFileSize: Int64? = nil
    ) {
        self.id = id
        self.asset = asset
        self.thumbnail = thumbnail
        self.pHash = pHash
        self.histogram = histogram
        self.blurScore = blurScore
        self.brightnessScore = brightnessScore
        self.cachedFileSize = cachedFileSize
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

    init(id: UUID = UUID(), photos: [PhotoItem], similarityScore: Double) {
        self.id = id
        self.photos = photos
        self.similarityScore = similarityScore
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

    var isDuplicate: Bool {
        similarityScore >= 0.99
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
