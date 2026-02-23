//
//  PhotoItem.swift
//  Similarly
//
//  Created by AI Agent
//

import CoreImage
import CoreLocation
import Foundation
import Photos

/// Fotoğraf bilgilerini ve benzerlik analizi için gerekli verileri tutan model
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
    var thumbnail: CIImage?
    var pHash: String?
    var histogram: [CGFloat]?
    var blurScore: Double?
    var brightnessScore: Double?
    var cachedFileSize: Int64?

    var isScreenshot: Bool {
        if #available(iOS 9.0, *) {
            return mediaSubtypes.contains(.photoScreenshot)
        }
        return false
    }

    var isLivePhoto: Bool {
        if #available(iOS 9.1, *) {
            return mediaSubtypes.contains(.photoLive)
        }
        return false
    }

    var fileSize: Int64? {
        // Sadece cache'lenmiş değeri dön (veritabanından gelen değer)
        return cachedFileSize
    }

    var isBlurry: Bool {
        if let blurScore = blurScore {
            let finalThreshold = UserDefaults.standard.doubleValue(
                forKey: "blurThreshold",
                default: AppDefaults.blurThreshold
            )
            return blurScore < finalThreshold
        }
        return false
    }

    var isTooDark: Bool {
        if let brightnessScore = brightnessScore {
            let finalThreshold = UserDefaults.standard.doubleValue(
                forKey: "darknessThreshold",
                default: AppDefaults.darknessThreshold
            )
            return brightnessScore < finalThreshold
        }
        return false
    }

    var isTooBright: Bool {
        if let brightnessScore = brightnessScore {
            let finalThreshold = UserDefaults.standard.doubleValue(
                forKey: "brightnessThreshold",
                default: AppDefaults.brightnessThreshold
            )
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
        cachedFileSize: Int64? = nil, creationDate: Date? = nil, modificationDate: Date? = nil,
        location: CLLocation? = nil, mediaType: PHAssetMediaType? = nil, duration: TimeInterval? = nil,
        pixelWidth: Int? = nil, pixelHeight: Int? = nil, isFavorite: Bool? = nil,
        mediaSubtypes: PHAssetMediaSubtype? = nil
    ) {
        self.id = id
        self.asset = asset
        self.creationDate = creationDate ?? asset.creationDate
        self.modificationDate = modificationDate ?? asset.modificationDate
        self.location = location ?? asset.location
        self.mediaType = mediaType ?? asset.mediaType
        self.duration = duration ?? asset.duration
        self.pixelWidth = pixelWidth ?? asset.pixelWidth
        self.pixelHeight = pixelHeight ?? asset.pixelHeight
        self.isFavorite = isFavorite ?? asset.isFavorite
        self.mediaSubtypes = mediaSubtypes ?? asset.mediaSubtypes
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
