//
//  GroupRowThumbnail.swift
//  Similarly
//
//  Created by AI Agent (Arch Swift)
//

import Photos
import SwiftUI

/// Benzer grup satırında küçük önizleme gösteren görünüm
struct GroupRowThumbnail: View {
    let photo: PhotoItem
    @StateObject private var loader = AssetImageLoader()
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                photo.isFavorite ? Color.yellow : Color.white,
                                lineWidth: photo.isFavorite ? 4 : 3
                            )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if photo.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .padding(4)
                    .background(Circle().fill(Color.black.opacity(0.5)))
                    .offset(x: 4, y: 4)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let size = CGSize(width: 80 * displayScale, height: 80 * displayScale)
                loader.load(asset: photo.asset, targetSize: size)
            }
        }
    }
}
