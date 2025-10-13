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
import UIKit

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

    init() {
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

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        // Sadece fotoğrafları al (video hariç)
        fetchOptions.predicate = NSPredicate(
            format: "mediaType = %d", PHAssetMediaType.image.rawValue)

        let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
        var tempPhotos: [PhotoItem] = []

        fetchResult.enumerateObjects { asset, _, _ in
            let photo = PhotoItem(id: asset.localIdentifier, asset: asset)
            tempPhotos.append(photo)
        }

        photos = tempPhotos
        print("📸 \(photos.count) fotoğraf bulundu")

        await processPhotos()
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
                    processedPhoto = await self.computePHash(for: processedPhoto)
                    processedPhoto = await self.computeHistogram(for: processedPhoto)
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
