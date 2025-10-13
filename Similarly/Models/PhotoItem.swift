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

    // Metadata bilgileri
    var creationDate: Date? {
        asset.creationDate
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

    init(
        id: String, asset: PHAsset, thumbnail: CIImage? = nil, pHash: String? = nil,
        histogram: [CGFloat]? = nil
    ) {
        self.id = id
        self.asset = asset
        self.thumbnail = thumbnail
        self.pHash = pHash
        self.histogram = histogram
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
    let id = UUID()
    var photos: [PhotoItem]
    var similarityScore: Double

    var count: Int {
        photos.count
    }

    var representativePhoto: PhotoItem? {
        photos.first
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SimilarPhotoGroup, rhs: SimilarPhotoGroup) -> Bool {
        lhs.id == rhs.id
    }
}
