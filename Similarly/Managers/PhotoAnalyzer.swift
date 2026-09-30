//
//  PhotoAnalyzer.swift
//  Similarly
//
//  Görüntü yükleme, Vision feature print ve kalite (bulanıklık/parlaklık) analizi.
//  Tamamen ana thread dışında çalışır.
//

import CoreImage
import ImageIO
import Photos
import UIKit
import Vision
import os

/// Tek bir fotoğrafın analiz sonucu
nonisolated struct PhotoAnalysisResult: Sendable {
    let id: String
    let featurePrint: [Float]
    let blurScore: Double?
    let brightnessScore: Double?
}

nonisolated struct PhotoAnalyzer: Sendable {
    /// Vision ve kalite analizi için istenen görüntünün en uzun kenarı (piksel)
    private static let requestEdge: CGFloat = 512
    /// Bulanıklık ölçümünden önce görüntünün küçültüleceği en uzun kenar (piksel)
    private static let qualityEdge: CGFloat = 256
    /// iCloud'dan indirilmesi gereken görüntüler için bekleme süresi
    private static let imageTimeout: TimeInterval = 15
    /// Aynı anda analiz edilen fotoğraf sayısı
    private static let maxConcurrency = 4

    private static let logger = Logger(subsystem: "com.similarly.app", category: "analysis")
    private static let ciContext = CIContext(options: [.cacheIntermediates: false])
    private static let srgb = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()

    /// Verilen asset kimliklerini sınırlı eşzamanlılıkla analiz eder.
    /// Görüntüsü yüklenemeyen veya Vision'ın işleyemediği fotoğraflar sonuçta yer almaz.
    @concurrent
    func analyze(localIdentifiers: [String]) async -> [PhotoAnalysisResult] {
        guard !localIdentifiers.isEmpty else { return [] }

        // Her alt görev kendi asset'lerini getirir; böylece PHAsset görevler arasında paylaşılmaz.
        let chunkSize = max(1, (localIdentifiers.count + Self.maxConcurrency - 1) / Self.maxConcurrency)
        let chunks = stride(from: 0, to: localIdentifiers.count, by: chunkSize).map {
            Array(localIdentifiers[$0..<min($0 + chunkSize, localIdentifiers.count)])
        }

        return await withTaskGroup(of: [PhotoAnalysisResult].self) { group in
            for chunk in chunks {
                group.addTask {
                    await Self.analyzeSequentially(chunk)
                }
            }

            var results: [PhotoAnalysisResult] = []
            results.reserveCapacity(localIdentifiers.count)
            for await chunkResults in group {
                results.append(contentsOf: chunkResults)
            }
            return results
        }
    }

    private static func analyzeSequentially(_ ids: [String]) async -> [PhotoAnalysisResult] {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var assets: [PHAsset] = []
        assets.reserveCapacity(fetchResult.count)
        fetchResult.enumerateObjects { asset, _, _ in assets.append(asset) }

        var results: [PhotoAnalysisResult] = []
        for asset in assets {
            if Task.isCancelled { break }
            if let result = await analyze(asset: asset) {
                results.append(result)
            }
        }
        return results
    }

    private static func analyze(asset: PHAsset) async -> PhotoAnalysisResult? {
        guard asset.mediaType == .image, asset.pixelWidth > 0, asset.pixelHeight > 0 else { return nil }
        guard let (cgImage, orientation) = await loadImage(for: asset) else { return nil }

        let featurePrint: [Float]
        #if targetEnvironment(simulator)
        // Simülatörde Vision'ın sinir ağı çalışmıyor ("Failed to create espresso context").
        // Geliştirme ve ekran görüntüsü için basit bir yedek vektör kullan; cihaz derlemesine girmez.
        guard let fallback = simulatorFeatureVector(of: cgImage) else { return nil }
        featurePrint = fallback
        #else
        do {
            let observation = try await GenerateImageFeaturePrintRequest().perform(on: cgImage, orientation: orientation)
            featurePrint = vector(from: observation)
        } catch {
            logger.error("Feature print failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        #endif
        guard !featurePrint.isEmpty else { return nil }

        let quality = measureQuality(of: cgImage)
        return PhotoAnalysisResult(
            id: asset.localIdentifier,
            featurePrint: featurePrint,
            blurScore: quality?.blur,
            brightnessScore: quality?.brightness
        )
    }

    // MARK: - Image Loading

    private static func loadImage(for asset: PHAsset) async -> (CGImage, CGImagePropertyOrientation)? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        // .exact: her fotoğraf tam olarak aynı hedef boyutta istenir. Feature print en çok girdi
        // çözünürlüğüne duyarlıdır (cihazda ölçüldü: aynı fotoğraf 512 px'e karşı 1600 px ≈ 0.6 mesafe),
        // bu yüzden kopyaların aynı boyutta analiz edilmesi şarttır.
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        let targetSize = asset.safeAspectFitTargetSize(
            in: CGSize(width: requestEdge, height: requestEdge),
            minimumEdge: 8
        )
        let manager = PHImageManager.default()

        return await withCheckedContinuation { continuation in
            let resumed = OSAllocatedUnfairLock(initialState: false)
            let resumeOnce: @Sendable ((CGImage, CGImagePropertyOrientation)?) -> Void = { value in
                let shouldResume = resumed.withLock { alreadyResumed in
                    defer { alreadyResumed = true }
                    return !alreadyResumed
                }
                if shouldResume { continuation.resume(returning: value) }
            }

            let requestID = manager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                // highQualityFormat tek sonuç verir; yine de ara (degraded) sonuçları yok say.
                if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }

                if let image, let cgImage = image.cgImage {
                    resumeOnce((cgImage, CGImagePropertyOrientation(image.imageOrientation)))
                } else {
                    resumeOnce(nil)
                }
            }

            // Güvenlik zaman aşımı: PhotoKit hiç geri çağırmazsa bile devam et.
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + imageTimeout) {
                manager.cancelImageRequest(requestID)
                resumeOnce(nil)
            }
        }
    }

    // MARK: - Feature Print

    private static func vector(from observation: FeaturePrintObservation) -> [Float] {
        let data = observation.data
        switch observation.elementType {
        case .float:
            return FeaturePrintCoding.decode(data)
        case .double:
            var doubles = [Double](repeating: 0, count: data.count / MemoryLayout<Double>.stride)
            _ = doubles.withUnsafeMutableBytes { data.copyBytes(to: $0) }
            return doubles.map { Float($0) }
        @unknown default:
            return []
        }
    }

    #if targetEnvironment(simulator)
    /// Yalnızca simülatör: görüntüyü 16×16'ya küçültüp RGB değerlerinden 768 boyutlu (Vision ile aynı),
    /// ortalaması çıkarılmış, birim normlu bir vektör üretir.
    private static func simulatorFeatureVector(of cgImage: CGImage) -> [Float]? {
        let side = 16
        let input = CIImage(cgImage: cgImage)
        guard input.extent.width > 0, input.extent.height > 0 else { return nil }

        let scaleY = CGFloat(side) / input.extent.height
        let aspectRatio = (CGFloat(side) / input.extent.width) / scaleY
        let scaled = input.applyingFilter(
            "CILanczosScaleTransform",
            parameters: [kCIInputScaleKey: scaleY, kCIInputAspectRatioKey: aspectRatio]
        )

        let rowBytes = side * 4
        var pixels = [UInt8](repeating: 0, count: rowBytes * side)
        ciContext.render(
            scaled.clampedToExtent(),
            toBitmap: &pixels,
            rowBytes: rowBytes,
            bounds: CGRect(x: 0, y: 0, width: side, height: side),
            format: .RGBA8,
            colorSpace: srgb
        )

        var vector: [Float] = []
        vector.reserveCapacity(side * side * 3)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            vector.append(Float(pixels[index]))
            vector.append(Float(pixels[index + 1]))
            vector.append(Float(pixels[index + 2]))
        }
        let mean = vector.reduce(0, +) / Float(vector.count)
        vector = vector.map { $0 - mean }
        let norm = vector.reduce(0) { $0 + $1 * $1 }.squareRoot()
        guard norm > 0 else { return nil }
        return vector.map { $0 / norm }
    }
    #endif

    // MARK: - Quality

    /// Görüntünün tamamını küçültüp gri tonlamaya çevirir; Laplacian varyansı (bulanıklık)
    /// ve ortalama lüminansı (parlaklık, 0-1) tek geçişte hesaplar.
    static func measureQuality(of cgImage: CGImage) -> (blur: Double, brightness: Double)? {
        let input = CIImage(cgImage: cgImage)
        let longestEdge = max(input.extent.width, input.extent.height)
        guard longestEdge > 0 else { return nil }

        var image = input
        let scale = min(1, qualityEdge / longestEdge)
        if scale < 1 {
            image = image.applyingFilter(
                "CILanczosScaleTransform",
                parameters: [kCIInputScaleKey: scale, kCIInputAspectRatioKey: 1.0]
            )
        }
        image = image.applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0.0])

        let extent = image.extent.integral
        let width = Int(extent.width)
        let height = Int(extent.height)
        guard width >= 3, height >= 3 else { return nil }

        let rowBytes = width * 4
        var pixels = [UInt8](repeating: 0, count: rowBytes * height)
        ciContext.render(
            image,
            toBitmap: &pixels,
            rowBytes: rowBytes,
            bounds: extent,
            format: .RGBA8,
            colorSpace: srgb
        )

        return laplacianVarianceAndBrightness(gray: pixels, width: width, height: height, bytesPerPixel: 4)
    }

    /// Gri tonlamalı piksel tamponundan (her pikselin ilk kanalı kullanılır) 4-komşu Laplacian
    /// varyansını ve ortalama parlaklığı hesaplar. Boyut 3x3'ten küçükse nil döner.
    static func laplacianVarianceAndBrightness(
        gray pixels: [UInt8],
        width: Int,
        height: Int,
        bytesPerPixel: Int
    ) -> (blur: Double, brightness: Double)? {
        guard width >= 3, height >= 3, pixels.count >= width * height * bytesPerPixel else { return nil }

        func value(_ x: Int, _ y: Int) -> Double {
            Double(pixels[(y * width + x) * bytesPerPixel])
        }

        var sum = 0.0
        var sumOfSquares = 0.0
        var count = 0.0
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let laplacian = 4 * value(x, y) - value(x, y - 1) - value(x, y + 1) - value(x - 1, y) - value(x + 1, y)
                sum += laplacian
                sumOfSquares += laplacian * laplacian
                count += 1
            }
        }

        var brightnessSum = 0.0
        for index in stride(from: 0, to: width * height * bytesPerPixel, by: bytesPerPixel) {
            brightnessSum += Double(pixels[index])
        }

        let mean = sum / count
        let variance = max(0, sumOfSquares / count - mean * mean)
        let brightness = brightnessSum / Double(width * height) / 255.0
        return (variance, brightness)
    }
}

// MARK: - Orientation

nonisolated extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
