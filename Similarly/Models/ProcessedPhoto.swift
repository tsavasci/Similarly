//
//  ProcessedPhoto.swift
//  Similarly
//
//  Created by AI Agent
//

import Foundation
import SwiftData

/// Veritabanında saklanan işlenmiş fotoğraf modeli
@Model
final class ProcessedPhoto {
    @Attribute(.unique) var id: String
    var pHash: String?
    var histogram: [Double]?
    var blurScore: Double?
    var brightnessScore: Double?
    var cachedFileSize: Int64?
    var creationDate: Date?
    var lastProcessedDate: Date
    var modificationDate: Date?

    init(
        id: String,
        pHash: String? = nil,
        histogram: [Double]? = nil,
        blurScore: Double? = nil,
        brightnessScore: Double? = nil,
        cachedFileSize: Int64? = nil,
        creationDate: Date? = nil,
        lastProcessedDate: Date = Date(),
        modificationDate: Date? = nil
    ) {
        self.id = id
        self.pHash = pHash
        self.histogram = histogram
        self.blurScore = blurScore
        self.brightnessScore = brightnessScore
        self.cachedFileSize = cachedFileSize
        self.creationDate = creationDate
        self.lastProcessedDate = lastProcessedDate
        self.modificationDate = modificationDate
    }

    /// PhotoItem'dan ProcessedPhoto oluştur
    convenience init(from photoItem: PhotoItem) {
        self.init(
            id: photoItem.id,
            pHash: photoItem.pHash,
            histogram: photoItem.histogram?.map { Double($0) },
            blurScore: photoItem.blurScore,
            brightnessScore: photoItem.brightnessScore,
            cachedFileSize: photoItem.cachedFileSize,
            creationDate: photoItem.creationDate,
            lastProcessedDate: Date(),
            modificationDate: photoItem.modificationDate
        )
    }
}
