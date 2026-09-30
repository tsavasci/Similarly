//
//  AssetImageLoader.swift
//  Similarly
//
//  Tüm görünümlerin paylaştığı, NSCache destekli hafif PhotoKit görüntü yükleyicisi.
//

import Combine
import Photos
import UIKit

@MainActor
final class AssetImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?

    /// Her satırın ayrı bir PHCachingImageManager oluşturması pahalı olduğundan tek bir örnek paylaşılır.
    /// PhotoKit ve NSCache thread-safe'tir; PhotoKit geri çağrısından erişildikleri için izole değiller.
    private nonisolated static let manager = PHCachingImageManager()
    private nonisolated(unsafe) static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 100 * 1024 * 1024  // ~100 MB (maliyet = piksel sayısı × 4 bayt)
        return cache
    }()

    // deinit'ten erişilebilmesi için izole değil; yalnızca ana thread'den değiştirilir.
    private nonisolated(unsafe) var requestID: PHImageRequestID?

    deinit {
        if let requestID {
            Self.manager.cancelImageRequest(requestID)
        }
    }

    func load(asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill) {
        guard asset.pixelWidth > 0, asset.pixelHeight > 0 else { return }

        // Geçersiz (0 veya sonsuz) boyutlarla istek yapma.
        let validSize: CGSize
        if targetSize.width.isFinite, targetSize.height.isFinite, targetSize.width > 0, targetSize.height > 0 {
            validSize = CGSize(width: targetSize.width.rounded(.up), height: targetSize.height.rounded(.up))
        } else {
            validSize = CGSize(width: 300, height: 300)
        }

        let key = Self.cacheKey(for: asset, targetSize: validSize, contentMode: contentMode)
        if let cached = Self.cache.object(forKey: key as NSString) {
            if image !== cached { image = cached }
            return
        }

        cancel()

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        requestID = Self.manager.requestImage(
            for: asset,
            targetSize: validSize,
            contentMode: contentMode,
            options: options
        ) { @Sendable [weak self] result, info in
            let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
            guard !cancelled, let result else { return }

            if !degraded {
                let cost = Int(result.size.width * result.scale * result.size.height * result.scale) * 4
                Self.cache.setObject(result, forKey: key as NSString, cost: cost)
            }
            Task { @MainActor [weak self] in
                self?.image = result
            }
        }
    }

    func cancel() {
        if let requestID {
            Self.manager.cancelImageRequest(requestID)
            self.requestID = nil
        }
    }

    private static func cacheKey(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode) -> String {
        "\(asset.localIdentifier)_\(Int(targetSize.width))x\(Int(targetSize.height))_\(contentMode.rawValue)"
    }
}
