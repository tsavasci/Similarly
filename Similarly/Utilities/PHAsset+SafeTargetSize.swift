//
//  PHAsset+SafeTargetSize.swift
//  Similarly
//
//  Defensive helpers for PhotoKit target size calculations.
//

import CoreGraphics
import Photos

nonisolated extension PHAsset {
    /// Calculates an aspect-fit target size with a guaranteed minimum edge.
    /// This avoids PhotoKit requests that can collapse to `Nx0` for ultra-wide/tall assets.
    func safeAspectFitTargetSize(in boundingSize: CGSize, minimumEdge: CGFloat = 1) -> CGSize {
        let fallback = CGSize(width: 300, height: 300)
        let minEdge = max(1, minimumEdge.rounded(.up))

        let boundedWidth = boundingSize.width.isFinite ? boundingSize.width : fallback.width
        let boundedHeight = boundingSize.height.isFinite ? boundingSize.height : fallback.height
        let safeBounds = CGSize(
            width: max(minEdge, boundedWidth.rounded(.up)),
            height: max(minEdge, boundedHeight.rounded(.up))
        )

        let assetWidth = CGFloat(pixelWidth)
        let assetHeight = CGFloat(pixelHeight)
        guard assetWidth > 0, assetHeight > 0 else {
            return safeBounds
        }

        let widthScale = safeBounds.width / assetWidth
        let heightScale = safeBounds.height / assetHeight
        let scale = min(widthScale, heightScale)
        guard scale.isFinite, scale > 0 else {
            return safeBounds
        }

        let fittedWidth = max(minEdge, (assetWidth * scale).rounded(.down))
        let fittedHeight = max(minEdge, (assetHeight * scale).rounded(.down))

        return CGSize(width: fittedWidth, height: fittedHeight)
    }
}
