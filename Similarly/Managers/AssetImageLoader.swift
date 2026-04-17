import Foundation
import Photos
import UIKit
import CoreImage

final class AssetImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private let imageManager = PHCachingImageManager()
    private var currentRequestID: PHImageRequestID?
    
    deinit {
        cancel()
    }
    
    func load(asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode) {
        cancel()
        
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        
        currentRequestID = imageManager.requestImage(for: asset,
                                                     targetSize: targetSize,
                                                     contentMode: contentMode,
                                                     options: options) { [weak self] image, info in
            guard let self = self else { return }
            
            let canceled = (info?[PHImageCancelledKey] as? Bool) == true
            if !canceled {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
    
    func cancel() {
        if let requestID = currentRequestID {
            imageManager.cancelImageRequest(requestID)
            currentRequestID = nil
        }
    }
}

extension CIImage {
    func toUIImage(context: CIContext = CIContext()) -> UIImage? {
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}
