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

    private let imageManager = PHCachingImageManager()
    private let context = CIContext()
    private let processingQueue = DispatchQueue(
        label: "com.similarly.photoprocessing", attributes: .concurrent)

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
            errorMessage = "Fotoğraf kütüphanesine erişim reddedildi"
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

                // Get file size on background thread
                var cachedSize: Int64?
                if let resource = PHAssetResource.assetResources(for: asset).first,
                   let fileSize = resource.value(forKey: "fileSize") as? Int64 {
                    cachedSize = fileSize
                }

                // Create photo item with basic info
                if let processedData = processedPhotosData[asset.localIdentifier],
                   asset.modificationDate == processedData.modificationDate {
                    let photo = PhotoItem(
                        id: asset.localIdentifier,
                        asset: asset,
                        thumbnail: nil,
                        pHash: processedData.pHash,
                        histogram: processedData.histogram.map { CGFloat($0) },
                        blurScore: processedData.blurScore,
                        brightnessScore: processedData.brightnessScore,
                        cachedFileSize: processedData.cachedFileSize ?? cachedSize
                    )
                    batchPhotos.append(photo)
                } else {
                    let photo = PhotoItem(
                        id: asset.localIdentifier,
                        asset: asset,
                        cachedFileSize: cachedSize
                    )
                    batchPhotos.append(photo)
                }
            }

            // Load thumbnails for this batch
            var batchWithThumbnails: [PhotoItem] = []
            for photo in batchPhotos {
                let photoWithThumbnail = await loadThumbnail(for: photo)
                batchWithThumbnails.append(photoWithThumbnail)
            }

            // Update the main array and UI
            await MainActor.run {
                allPhotos.append(contentsOf: batchWithThumbnails)
                self.photos = allPhotos
                self.processingProgress = Double(allPhotos.count) / Double(totalCount)

                // Log progress every 5 batches to avoid spamming
                if i % (batchSize * 5) == 0 {
                    print("🔄 Processed \(allPhotos.count) of \(totalCount) photos")
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

            print("✅ Photo library loaded successfully")
            print("📊 Statistics:")
            print("   - 📸 \(imageCount) photos")
            if videoCount > 0 {
                print("   - 🎥 \(videoCount) videos")
            }
            if alreadyProcessed > 0 {
                print("   - 💾 \(alreadyProcessed) photos loaded from database")
            }
            if needsProcessing > 0 {
                print("   - 🔄 \(needsProcessing) new photos to process")
                Task {
                    await self.processPhotos()
                }
            } else {
                print("   - 🎉 All photos are up to date")
            }
        }
    }

    // MARK: - Database Operations

    private func loadProcessedPhotosFromDatabase() -> [String: ProcessedPhotoData] {
        guard let context = modelContext else { return [:] }

        let descriptor = FetchDescriptor<ProcessedPhoto>()
        guard let results = try? context.fetch(descriptor) else {
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
        
        if let existing = try? context.fetch(descriptor).first {
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

        try? context.save()
    }

    // MARK: - Processing Photos

    private func processPhotos() async {
        let totalCount = photos.count
        guard totalCount > 0 else {
            isProcessing = false
            return
        }

        print("🔄 Fotoğraflar işleniyor...")

        // Batch processing için gruplar oluştur
        let batchSize = 50
        let batches = stride(from: 0, to: totalCount, by: batchSize).map {
            Array(photos[$0..<min($0 + batchSize, totalCount)])
        }

        for (batchIndex, batch) in batches.enumerated() {
            await processBatch(batch, startIndex: batchIndex * batchSize)

            let progress =
                Double(min((batchIndex + 1) * batchSize, totalCount)) / Double(totalCount)
            processingProgress = progress
        }

        isProcessing = false
        print("✅ Fotoğraf işleme tamamlandı")
    }

    private func processBatch(_ batch: [PhotoItem], startIndex: Int) async {
        await withTaskGroup(of: (Int, PhotoItem).self) { group in
            for (index, photo) in batch.enumerated() {
                group.addTask {
                    var processedPhoto = photo
                    processedPhoto = await self.loadThumbnail(for: processedPhoto)

                    // Sadece fotoğraflar için analiz yap (video için değil)
                    let mediaType = processedPhoto.asset.mediaType
                    if mediaType == .image {
                        // Sadece işlenmemiş fotoğrafları işle
                        if processedPhoto.pHash == nil {
                            processedPhoto = await self.computePHash(for: processedPhoto)
                            processedPhoto = await self.computeHistogram(for: processedPhoto)
                            processedPhoto = await self.analyzeQuality(for: processedPhoto)

                            // Veritabanına kaydet
                            await self.saveProcessedPhoto(processedPhoto)
                        }
                    }

                    return (startIndex + index, processedPhoto)
                }
            }

            for await (index, processedPhoto) in group {
                if index < photos.count {
                    photos[index] = processedPhoto
                }
            }
        }
    }

    // MARK: - Thumbnail Loading

    private func loadThumbnail(for photo: PhotoItem) async -> PhotoItem {
        var updatedPhoto = photo
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            let targetSize = CGSize(width: 300, height: 300)

            imageManager.requestImage(
                for: photo.asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let image = image,
                    let cgImage = image.cgImage
                {
                    updatedPhoto.thumbnail = CIImage(cgImage: cgImage)
                } else if let image = image {
                    updatedPhoto.thumbnail = CIImage(image: image)
                }
                continuation.resume()
            }
        }
        return updatedPhoto
    }

    // MARK: - pHash Computation (Perceptual Hash)

    private func computePHash(for photo: PhotoItem) async -> PhotoItem {
        var updatedPhoto = photo
        guard let ciImage = photo.thumbnail else { return updatedPhoto }

        // 1. Grayscale'e çevir
        let grayscaleFilter = CIFilter(name: "CIPhotoEffectMono")
        grayscaleFilter?.setValue(ciImage, forKey: kCIInputImageKey)

        guard let grayscaleOutput = grayscaleFilter?.outputImage else { return updatedPhoto }

        // 2. 8x8 boyutuna küçült
        let scaleFilter = CIFilter(name: "CILanczosScaleTransform")
        scaleFilter?.setValue(grayscaleOutput, forKey: kCIInputImageKey)
        scaleFilter?.setValue(8.0 / ciImage.extent.width, forKey: kCIInputScaleKey)
        scaleFilter?.setValue(1.0, forKey: kCIInputAspectRatioKey)

        guard let scaledOutput = scaleFilter?.outputImage else { return updatedPhoto }

        // 3. Pixel değerlerini al
        let extent = CGRect(x: 0, y: 0, width: 8, height: 8)
        guard let cgImage = context.createCGImage(scaledOutput, from: extent) else {
            return updatedPhoto
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
        else { return updatedPhoto }

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
        return updatedPhoto
    }

    // MARK: - Histogram Computation

    private func computeHistogram(for photo: PhotoItem) async -> PhotoItem {
        var updatedPhoto = photo
        guard let ciImage = photo.thumbnail else { return updatedPhoto }

        // Histogram filtresi uygula
        let histogramFilter = CIFilter(name: "CIAreaHistogram")
        histogramFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        histogramFilter?.setValue(
            CIVector(x: 0, y: 0, z: ciImage.extent.width, w: ciImage.extent.height),
            forKey: "inputExtent")
        histogramFilter?.setValue(64, forKey: "inputCount")  // 64 bin histogram
        histogramFilter?.setValue(1.0, forKey: "inputScale")

        guard let outputImage = histogramFilter?.outputImage else { return updatedPhoto }

        // Histogram verilerini çıkar
        let extent = outputImage.extent
        var bitmap = [UInt8](repeating: 0, count: Int(extent.width * extent.height * 4))

        context.render(
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
        return updatedPhoto
    }

    // MARK: - Quality Analysis

    private func analyzeQuality(for photo: PhotoItem) async -> PhotoItem {
        var updatedPhoto = photo
        guard let ciImage = photo.thumbnail else { return updatedPhoto }

        // 1. Bulanıklık analizi (Laplacian Variance)
        let blurScore = calculateBlurScore(ciImage)
        updatedPhoto.blurScore = blurScore

        // 2. Parlaklık analizi
        let brightnessScore = calculateBrightness(ciImage)
        updatedPhoto.brightnessScore = brightnessScore

        return updatedPhoto
    }

    private func calculateBlurScore(_ image: CIImage) -> Double {
        // Laplacian filtresi ile kenar tespiti
        let context = CIContext()

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

        guard let cgImage = context.createCGImage(contrastedImage, from: extent) else {
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

    private func calculateBrightness(_ image: CIImage) -> Double {
        let context = CIContext()
        let extent = CGRect(
            x: 0, y: 0, width: min(image.extent.width, 100), height: min(image.extent.height, 100))

        guard let cgImage = context.createCGImage(image, from: extent) else {
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

        print("🗑️ \(items.count) fotoğraf silindi")
    }
}
