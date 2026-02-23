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
        guard let cgImage = conversionCIContext.createCGImage(ciImage, from: ciImage.extent) else {
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
        guard let cgImage = conversionCIContext.createCGImage(self, from: self.extent) else {
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
