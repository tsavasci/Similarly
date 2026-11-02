//
//  FullImageView.swift
//  Similarly
//
//  Created by AI Agent (Arch Swift)
//

import Photos
import SwiftUI
import ImageIO

/// Seçilen fotoğrafı tam ekran gösteren görünüm
struct FullImageView: View {
    let photo: PhotoItem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var fullImage: UIImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                if let image = fullImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Kapat butonu
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .task {
                let maxPixelSize = max(geometry.size.width, geometry.size.height) * displayScale
                fullImage = await Self.loadImage(for: photo.asset, maxPixelSize: maxPixelSize)
            }
        }
    }

    /// Görüntü verisini PhotoKit'ten alır ve ekran boyutuna küçültür (ana thread dışında).
    private static func loadImage(for asset: PHAsset, maxPixelSize: CGFloat) async -> UIImage? {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else { return nil }

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.version = .current

        let data: Data? = await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { @Sendable data, _, _, _ in
                continuation.resume(returning: data)
            }
        }
        guard let data else { return nil }
        return await downsampleImage(from: data, maxPixelSize: max(1, maxPixelSize))
    }

    @concurrent
    private static func downsampleImage(from data: Data, maxPixelSize: CGFloat) async -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard
            let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary)
        else {
            return UIImage(data: data)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxPixelSize.rounded(.up))
        ]

        guard
            let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                thumbnailOptions as CFDictionary
            )
        else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
    }
}
