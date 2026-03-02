//
//  UIImage+Extensions.swift
//  Similarly
//
//  Created by AI Agent
//

import CoreImage
import UIKit

private let conversionCIContext = CIContext(options: nil)

extension UIImage {
    /// CIImage'den UIImage oluşturur
    convenience init?(ciImage: CIImage) {
        guard !ciImage.extent.isEmpty,
              let cgImage = conversionCIContext.createCGImage(ciImage, from: ciImage.extent) else {
            print("SIMilarly-LOG: Failed in UIImage(ciImage:). Extent was empty or invalid: \(ciImage.extent)")
            return nil
        }
        self.init(cgImage: cgImage)
    }

    /// UIImage'den CIImage oluşturur
    func toCIImage() -> CIImage? {
        if let cgImg = self.cgImage {
            return CIImage(cgImage: cgImg)
        }
        return nil
    }
}

extension CIImage {
    /// CIImage'den UIImage oluşturur
    func toUIImage() -> UIImage? {
        guard !extent.isEmpty,
              let cgImage = conversionCIContext.createCGImage(self, from: extent)
        else {
            print("SIMilarly-LOG: Failed to convert CIImage to UIImage. Extent was empty or invalid: \(extent)")
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

extension CGImage {
    /// CGImage'den UIImage oluşturur
    func toUIImage() -> UIImage {
        return UIImage(cgImage: self)
    }
}
