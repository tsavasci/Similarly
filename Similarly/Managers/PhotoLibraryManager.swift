//
//  PhotoLibraryManager.swift
//  Similarly
//
//  Created by AI Agent
//

import Combine
import CoreImage
import Foundation
import Photos
import SwiftData
import UIKit

// MARK: - Helper Types

/// Sendable data structure for processed photo information
struct ProcessedPhotoData: Sendable {
    let id: String
    let pHash: String?
    let histogram: [Double]
    let blurScore: Double
    let brightnessScore: Double
    let cachedFileSize: Int64?
    let modificationDate: Date

    init(from photo: ProcessedPhoto) {
        self.id = photo.id
        self.pHash = photo.pHash
        self.histogram = photo.histogram ?? []
        self.blurScore = photo.blurScore ?? 0.0
        self.brightnessScore = photo.brightnessScore ?? 0.0
        self.cachedFileSize = photo.cachedFileSize
        self.modificationDate = photo.modificationDate ?? Date.distantPast
    }
}

/// Fotoğraf kütüphanesine erişim ve işlemleri yöneten sınıf
@MainActor
class PhotoLibraryManager: ObservableObject {
    @Published var photos: [PhotoItem] = []
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var isProcessing = false
    @Published var processingProgress: Double = 0.0
    @Published var errorMessage: String?

    nonisolated(unsafe) private static var analysisCIContext = CIContext(options: nil)
    private static let thumbnailCache: NSCache<NSString, CIImage> = {
        let cache = NSCache<NSString, CIImage>()
        cache.totalCostLimit = 500 * 1024 * 1024 // 500 MB limit
        return cache
    }()
    private let imageManager = PHCachingImageManager()

    var modelContext: ModelContext?

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccessAndFetch() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status

        if status == .authorized || status == .limited {
            await fetchAssets()
        } else {
            setError(L10n.t("errors.photo_access_denied"))
        }
    }

    // MARK: - Fetching Assets

    func fetchAssets() async {
        isProcessing = true
        processingProgress = 0.0

        // Load processed photos from database first (main thread for SwiftData safety)
        let processedPhotosData = await MainActor.run {
            return self.loadProcessedPhotosFromDatabase()
        }

        // Configure fetch options
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        fetchOptions.predicate = NSPredicate(
            format: "mediaType = %d OR mediaType = %d",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaType.video.rawValue
        )

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var allPhotos: [PhotoItem] = []

        // Process in batches to avoid memory pressure
        let batchSize = 20
        let totalCount = fetchResult.count

        for i in stride(from: 0, to: totalCount, by: batchSize) {
            let endIndex = min(i + batchSize, totalCount)
            var batchPhotos: [PhotoItem] = []

            // Process each asset in the current batch
            for j in i..<endIndex {
                let asset = fetchResult.object(at: j)
                let creationDate = asset.creationDate
                let modificationDate = asset.modificationDate
                let location = asset.location
                let mediaType = asset.mediaType
                let duration = asset.duration
                let pixelWidth = asset.pixelWidth
                let pixelHeight = asset.pixelHeight
                let isFavorite = asset.isFavorite
                let mediaSubtypes = asset.mediaSubtypes

                // Create photo item with basic info
                if let processedData = processedPhotosData[asset.localIdentifier],
                    modificationDate == processedData.modificationDate
                {
                    let photo = PhotoItem(
                        id: asset.localIdentifier,
                        asset: asset,
                        thumbnail: nil,
                        pHash: processedData.pHash,
                        histogram: processedData.histogram.map { CGFloat($0) },
                        blurScore: processedData.blurScore,
                        brightnessScore: processedData.brightnessScore,
                        cachedFileSize: processedData.cachedFileSize,
                        creationDate: creationDate,
                        modificationDate: modificationDate,
                        location: location,
                        mediaType: mediaType,
                        duration: duration,
                        pixelWidth: pixelWidth,
                        pixelHeight: pixelHeight,
                        isFavorite: isFavorite,
                        mediaSubtypes: mediaSubtypes
                    )
                    batchPhotos.append(photo)
                } else {
                    let photo = PhotoItem(
                        id: asset.localIdentifier,
                        asset: asset,
                        cachedFileSize: nil,
                        creationDate: creationDate,
                        modificationDate: modificationDate,
                        location: location,
                        mediaType: mediaType,
                        duration: duration,
                        pixelWidth: pixelWidth,
                        pixelHeight: pixelHeight,
                        isFavorite: isFavorite,
                        mediaSubtypes: mediaSubtypes
                    )
                    batchPhotos.append(photo)
                }
            }

            // Append batch without loading thumbnails (on-demand loading in views)
            await MainActor.run {
                allPhotos.append(contentsOf: batchPhotos)
                self.photos = allPhotos
                self.processingProgress = Double(allPhotos.count) / Double(totalCount)
                // Log progress every 10 batches to avoid spamming
                if i % (batchSize * 10) == 0 {
                    print(L10n.f("log.photo.processed_progress", allPhotos.count, totalCount))
                }
            }
        }

        // Final update on main thread
        await MainActor.run {
            self.isProcessing = false
            self.processingProgress = 1.0

            // Log final statistics
            let imageCount = allPhotos.filter { $0.mediaType == .image }.count
            let videoCount = allPhotos.filter { $0.mediaType == .video }.count
            let alreadyProcessed = allPhotos.filter { $0.pHash != nil }.count
            let needsProcessing = imageCount - alreadyProcessed

            print(L10n.t("log.photo.loaded_ok"))
            print(L10n.t("log.photo.stats_header"))
            print(L10n.f("log.photo.stats_images", imageCount))
            if videoCount > 0 {
                print(L10n.f("log.photo.stats_videos", videoCount))
            }
            if alreadyProcessed > 0 {
                print(L10n.f("log.photo.stats_loaded_db", alreadyProcessed))
            }
            if needsProcessing > 0 {
                print(L10n.f("log.photo.stats_to_process", needsProcessing))
                Task {
                    await self.processPhotos()
                }
            } else {
                print(L10n.t("log.photo.stats_up_to_date"))
            }
        }
    }

    // MARK: - Database Operations

    private func loadProcessedPhotosFromDatabase() -> [String: ProcessedPhotoData] {
        guard let context = modelContext else { return [:] }

        let descriptor = FetchDescriptor<ProcessedPhoto>()
        let results: [ProcessedPhoto]
        do {
            results = try context.fetch(descriptor)
        } catch {
            setError(
                L10n.f(
                    "errors.load_previous_analysis_failed",
                    error.localizedDescription
                )
            )
            return [:]
        }

        var dict: [String: ProcessedPhotoData] = [:]
        for photo in results {
            dict[photo.id] = ProcessedPhotoData(from: photo)
        }
        return dict
    }

    private func saveProcessedPhoto(_ photo: PhotoItem) async {
        guard let context = modelContext else { return }

        // Varsa güncelle, yoksa ekle
        let photoId = photo.id
        let descriptor = FetchDescriptor<ProcessedPhoto>(
            predicate: #Predicate { processedPhoto in
                processedPhoto.id == photoId
            }
        )
        
        do {
            if let existing = try context.fetch(descriptor).first {
                // Güncelle
                existing.pHash = photo.pHash
                existing.histogram = photo.histogram?.map { Double($0) }
                existing.blurScore = photo.blurScore
                existing.brightnessScore = photo.brightnessScore
                existing.cachedFileSize = photo.cachedFileSize
                existing.lastProcessedDate = Date()
                existing.modificationDate = photo.modificationDate
            } else {
                // Yeni ekle
                let processed = ProcessedPhoto(from: photo)
                context.insert(processed)
            }

            try context.save()
        } catch {
            setError(
                L10n.f(
                    "errors.save_analysis_failed",
                    error.localizedDescription
                )
            )
        }
    }

    // MARK: - Processing Photos

    private func processPhotos() async {
        let totalCount = photos.count
        guard totalCount > 0 else {
            isProcessing = false
            return
        }

        print(L10n.t("log.photo.processing_start"))

        // Batch processing için gruplar oluştur
        let batchSize = 50
        let batches = stride(from: 0, to: totalCount, by: batchSize).map {
            Array(photos[$0..<min($0 + batchSize, totalCount)])
        }

        // Paralel batch processing - 3 batch'i aynı anda işle
        let concurrentBatchLimit = 3
        for startIdx in stride(from: 0, to: batches.count, by: concurrentBatchLimit) {
            let endIdx = min(startIdx + concurrentBatchLimit, batches.count)
            let concurrentBatches = Array(batches[startIdx..<endIdx])
            
            await withTaskGroup(of: Void.self) { group in
                for (relativeBatchIndex, batch) in concurrentBatches.enumerated() {
                    let absoluteBatchIndex = startIdx + relativeBatchIndex
                    group.addTask {
                        await self.processBatch(batch, startIndex: absoluteBatchIndex * batchSize)
                    }
                }
            }
            
            // Update progress after processing concurrent batches
            let progress = Double(min(endIdx * batchSize, totalCount)) / Double(totalCount)
            processingProgress = progress
        }

        isProcessing = false
        print(L10n.t("log.photo.processing_done"))
    }

    private func processBatch(_ batch: [PhotoItem], startIndex: Int) async {
        var photosToPersist: [PhotoItem] = []

        await withTaskGroup(of: (Int, PhotoItem, Bool).self) { group in
            for (index, photo) in batch.enumerated() {
                group.addTask {
                    var processedPhoto = photo
                    processedPhoto = await self.loadThumbnail(for: processedPhoto)
                    var shouldPersist = false

                    // Sadece fotoğraflar için analiz yap (video için değil)
                    let mediaType = processedPhoto.mediaType
                    if mediaType == .image {
                        // Sadece işlenmemiş fotoğrafları işle
                        if processedPhoto.pHash == nil {
                            processedPhoto = self.computePHash(for: processedPhoto)
                            processedPhoto = self.computeHistogram(for: processedPhoto)
                            processedPhoto = self.analyzeQuality(for: processedPhoto)
                            shouldPersist = true
                        }
                    }

                    return (startIndex + index, processedPhoto, shouldPersist)
                }
            }

            for await (index, processedPhoto, shouldPersist) in group {
                if index < photos.count {
                    photos[index] = processedPhoto
                }
                if shouldPersist {
                    photosToPersist.append(processedPhoto)
                }
            }
        }

        for photo in photosToPersist {
            await saveProcessedPhoto(photo)
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail(for photo: PhotoItem) async -> PhotoItem {
        var updatedPhoto = photo
        guard photo.asset.pixelWidth > 0, photo.asset.pixelHeight > 0 else {
            return updatedPhoto
        }

        let cacheKey = photo.id as NSString
        
        // Check cache first
        if let cachedThumbnail = Self.thumbnailCache.object(forKey: cacheKey) {
            updatedPhoto.thumbnail = cachedThumbnail
            return updatedPhoto
        }
        
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            let targetSize = photo.asset.safeAspectFitTargetSize(
                in: CGSize(width: 300, height: 300),
                minimumEdge: 8
            )
            var resumed = false

            let requestID = imageManager.requestImage(
                for: photo.asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                if cancelled { return }

                if let image = image, let cgImage = image.cgImage {
                    updatedPhoto.thumbnail = CIImage(cgImage: cgImage)
                } else if let image = image {
                    updatedPhoto.thumbnail = CIImage(image: image)
                }
                
                // Cache the thumbnail if successfully loaded
                if let thumbnail = updatedPhoto.thumbnail {
                    let estimatedCost = max(1, Int(300 * 300 / 100)) // Approximate cost
                    Self.thumbnailCache.setObject(thumbnail, forKey: cacheKey, cost: estimatedCost)
                }

                if !resumed {
                    resumed = true
                    continuation.resume()
                }
            }

            // Safety timeout: ensure we always resume even if PhotoKit never calls back with a final result
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !resumed {
                    resumed = true
                    self.imageManager.cancelImageRequest(requestID)
                    continuation.resume()
                }
            }
        }
        return updatedPhoto
    }

    // MARK: - pHash Computation (Perceptual Hash)

    nonisolated private func computePHash(for photo: PhotoItem) -> PhotoItem {
        var updatedPhoto = photo
        guard let ciImage = photo.thumbnail else { return updatedPhoto }

        autoreleasepool {
            // 1. Grayscale'e çevir
            let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")
            grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)

            guard let grayscaleOutput = grayscaleFilter?.outputImage else { return }

            // 2. 8x8 boyutuna küçült
            let scaleFilter = CIFilter(name: "CILanczosScaleTransform")
            scaleFilter?.setValue(grayscaleOutput, forKey: kCIInputImageKey)
            scaleFilter?.setValue(8.0 / ciImage.extent.width, forKey: kCIInputScaleKey)
            scaleFilter?.setValue(1.0, forKey: kCIInputAspectRatioKey)

            guard let scaledOutput = scaleFilter?.outputImage else { return }

            // 3. Pixel değerlerini al
            let extent = CGRect(x: 0, y: 0, width: 8, height: 8)
            guard let cgImage = Self.analysisCIContext.createCGImage(scaledOutput, from: extent) else {
                return
            }

            // 4. Bitmap oluştur
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8

            var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

            guard
                let context = CGContext(
                    data: &pixelData,
                    width: width,
                    height: height,
                    bitsPerComponent: bitsPerComponent,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                )
            else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

            // 5. Ortalama hesapla
            var sum: Double = 0
            var values: [Double] = []

            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * bytesPerPixel
                    let r = Double(pixelData[offset])
                    let g = Double(pixelData[offset + 1])
                    let b = Double(pixelData[offset + 2])
                    let gray = (r + g + b) / 3.0
                    values.append(gray)
                    sum += gray
                }
            }

            let average = sum / Double(width * height)

            // 6. Hash oluştur
            var hash: UInt64 = 0
            for (index, value) in values.enumerated() {
                if value > average {
                    hash |= (1 << index)
                }
            }

            updatedPhoto.pHash = String(format: "%016llx", hash)
        }
        
        return updatedPhoto
    }

    // MARK: - Histogram Computation

    nonisolated private func computeHistogram(for photo: PhotoItem) -> PhotoItem {
        var updatedPhoto = photo
        guard let ciImage = photo.thumbnail else { return updatedPhoto }

        autoreleasepool {
            // Histogram filtresi uygula
            let histogramFilter = CIFilter(name: "CIAreaHistogram")
            histogramFilter?.setValue(ciImage, forKey: kCIInputImageKey)
            histogramFilter?.setValue(
                CIVector(x: 0, y: 0, z: ciImage.extent.width, w: ciImage.extent.height),
                forKey: "inputExtent")
            histogramFilter?.setValue(64, forKey: "inputCount")  // 64 bin histogram
            histogramFilter?.setValue(1.0, forKey: "inputScale")

            guard let outputImage = histogramFilter?.outputImage else { return }

            // Histogram verilerini çıkar
            let extent = outputImage.extent
            var bitmap = [UInt8](repeating: 0, count: Int(extent.width * extent.height * 4))

            Self.analysisCIContext.render(
                outputImage, toBitmap: &bitmap, rowBytes: Int(extent.width) * 4, bounds: extent,
                format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())

            // Her renk kanalı için histogram değerleri
            var histogramValues: [CGFloat] = []
            for i in stride(from: 0, to: bitmap.count, by: 4) {
                let r = CGFloat(bitmap[i])
                let g = CGFloat(bitmap[i + 1])
                let b = CGFloat(bitmap[i + 2])
                histogramValues.append(contentsOf: [r, g, b])
            }

            updatedPhoto.histogram = histogramValues
        }
        
        return updatedPhoto
    }

    // MARK: - Quality Analysis

    nonisolated private func analyzeQuality(for photo: PhotoItem) -> PhotoItem {
        var updatedPhoto = photo
        guard let ciImage = photo.thumbnail else { return updatedPhoto }

        autoreleasepool {
            // 1. Bulanıklık analizi (Laplacian Variance)
            let blurScore = calculateBlurScore(ciImage)
            updatedPhoto.blurScore = blurScore

            // 2. Parlaklık analizi
            let brightnessScore = calculateBrightness(ciImage)
            updatedPhoto.brightnessScore = brightnessScore
        }

        return updatedPhoto
    }

    nonisolated private func calculateBlurScore(_ image: CIImage) -> Double {
        // Grayscale'e çevir
        guard let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono"),
            let colorControlsFilter = CIFilter(name: "CIColorControls")
        else {
            return 200.0  // Default: not blurry
        }

        grayscaleFilter.setValue(image, forKey: kCIInputImageKey)
        guard let grayscaleOutput = grayscaleFilter.outputImage else {
            return 200.0
        }

        // Kontrast artır (kenarları belirginleştir)
        colorControlsFilter.setValue(grayscaleOutput, forKey: kCIInputImageKey)
        colorControlsFilter.setValue(2.0, forKey: kCIInputContrastKey)

        guard let contrastedImage = colorControlsFilter.outputImage else {
            return 200.0
        }

        // Küçük bir bölge üzerinde çalış (performans için)
        let extent = CGRect(
            x: 0, y: 0, width: min(contrastedImage.extent.width, 100),
            height: min(contrastedImage.extent.height, 100))

        guard let cgImage = Self.analysisCIContext.createCGImage(contrastedImage, from: extent) else {
            return 200.0
        }

        // Piksel verilerini al
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context2 = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return 200.0
        }

        context2.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Laplacian variance hesapla (basitleştirilmiş)
        var variance = 0.0
        var mean = 0.0
        var count = 0

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = (y * width + x) * bytesPerPixel
                let center = Double(pixelData[idx])

                // 4-komşu Laplacian
                let top = Double(pixelData[((y - 1) * width + x) * bytesPerPixel])
                let bottom = Double(pixelData[((y + 1) * width + x) * bytesPerPixel])
                let left = Double(pixelData[(y * width + (x - 1)) * bytesPerPixel])
                let right = Double(pixelData[(y * width + (x + 1)) * bytesPerPixel])

                let laplacian = abs(4 * center - top - bottom - left - right)
                mean += laplacian
                count += 1
            }
        }

        mean /= Double(count)

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = (y * width + x) * bytesPerPixel
                let center = Double(pixelData[idx])

                let top = Double(pixelData[((y - 1) * width + x) * bytesPerPixel])
                let bottom = Double(pixelData[((y + 1) * width + x) * bytesPerPixel])
                let left = Double(pixelData[(y * width + (x - 1)) * bytesPerPixel])
                let right = Double(pixelData[(y * width + (x + 1)) * bytesPerPixel])

                let laplacian = abs(4 * center - top - bottom - left - right)
                variance += pow(laplacian - mean, 2)
            }
        }

        variance /= Double(count)

        return variance
    }

    nonisolated private func calculateBrightness(_ image: CIImage) -> Double {
        let extent = CGRect(
            x: 0, y: 0, width: min(image.extent.width, 100), height: min(image.extent.height, 100))

        guard let cgImage = Self.analysisCIContext.createCGImage(image, from: extent) else {
            return 0.5  // Default: medium brightness
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context2 = CGContext(
                data: &pixelData,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return 0.5
        }

        context2.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Ortalama parlaklık hesapla (RGB -> Luminance)
        var totalBrightness = 0.0
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])

            // Perceived luminance formula
            let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            totalBrightness += luminance
        }

        return totalBrightness / Double(width * height)
    }

    // MARK: - Delete Photos

    func deletePhotos(_ items: [PhotoItem]) async throws {
        let assets = items.map { $0.asset }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        }

        // Silinen fotoğrafları listeden kaldır
        let deletedIds = Set(items.map { $0.id })
        photos.removeAll { deletedIds.contains($0.id) }

        print(L10n.f("log.photo.deleted_count", items.count))
    }

    func setError(_ message: String) {
        errorMessage = message
    }
}
