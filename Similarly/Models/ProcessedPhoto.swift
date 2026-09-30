//
//  ProcessedPhoto.swift
//  Similarly
//
//  Created by AI Agent
//

import Foundation
import SwiftData

/// Analiz algoritması değiştiğinde artırılır; daha eski sürümle kaydedilmiş fotoğraflar yeniden işlenir.
nonisolated enum AnalysisVersion {
    static let current = 3
}

/// Veritabanında saklanan işlenmiş fotoğraf modeli
@Model
final class ProcessedPhoto {
    @Attribute(.unique) var id: String
    /// Vision feature print vektörü (ham `Float` baytları)
    var featurePrint: Data?
    var blurScore: Double?
    var brightnessScore: Double?
    var cachedFileSize: Int64?
    var creationDate: Date?
    var lastProcessedDate: Date
    var modificationDate: Date?
    var analysisVersion: Int = 0
    /// Kullanıcı "kalite sorunu yok" olarak işaretlediyse true
    var qualityDismissed: Bool = false

    init(
        id: String,
        featurePrint: Data? = nil,
        blurScore: Double? = nil,
        brightnessScore: Double? = nil,
        cachedFileSize: Int64? = nil,
        creationDate: Date? = nil,
        lastProcessedDate: Date = Date(),
        modificationDate: Date? = nil,
        analysisVersion: Int = AnalysisVersion.current,
        qualityDismissed: Bool = false
    ) {
        self.id = id
        self.featurePrint = featurePrint
        self.blurScore = blurScore
        self.brightnessScore = brightnessScore
        self.cachedFileSize = cachedFileSize
        self.creationDate = creationDate
        self.lastProcessedDate = lastProcessedDate
        self.modificationDate = modificationDate
        self.analysisVersion = analysisVersion
        self.qualityDismissed = qualityDismissed
    }
}

// MARK: - Feature Print Encoding

nonisolated enum FeaturePrintCoding {
    static func encode(_ vector: [Float]) -> Data {
        vector.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    static func decode(_ data: Data) -> [Float] {
        var vector = [Float](repeating: 0, count: data.count / MemoryLayout<Float>.stride)
        _ = vector.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return vector
    }
}
