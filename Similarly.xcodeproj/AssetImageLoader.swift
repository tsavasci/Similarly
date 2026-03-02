//
//  AssetImageLoader.swift
//  Similarly
//
//  A lightweight on-demand image loader backed by PHCachingImageManager and NSCache
//

import Photos
import UIKit
import SwiftUI

final class AssetImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let manager = PHCachingImageManager()
    private static let cache: NSCache<NSString, UIImage> = {
        let c = NSCache<NSString, UIImage>()
        // Set a reasonable cost limit (~100 MB). Each image cost ~width*height.
        c.totalCostLimit = 100 * 1024 * 1024
        return c
    }()

    func load(asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode = .aspectFill) {
        let key = cacheKey(for: asset, targetSize: targetSize, contentMode: contentMode)
        if let cached = Self.cache.object(forKey: key) {
            if self.image !== cached { self.image = cached }
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        manager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: contentMode,
            options: options
        ) { [weak self] img, _ in
            guard let self = self, let img = img else { return }
            let cost = Int(img.size.width * img.size.height)
            Self.cache.setObject(img, forKey: key, cost: cost)
            DispatchQueue.main.async { self.image = img }
        }
    }

    private func cacheKey(for asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode) -> NSString {
        let sizeKey = "\(Int(targetSize.width))x\(Int(targetSize.height))"
        return NSString(string: asset.localIdentifier + "_" + sizeKey + "_\(contentMode.rawValue)")
    }
}
