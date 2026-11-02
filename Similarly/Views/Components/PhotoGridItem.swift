//
//  PhotoGridItem.swift
//  Similarly
//
//  Created by AI Agent (Arch Swift)
//

import Photos
import SwiftUI

/// Benzer grup detayında fotoğraf karesini gösteren ızgara bileşeni
struct PhotoGridItem: View {
    let photo: PhotoItem
    let cellSize: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @StateObject private var loader = AssetImageLoader()
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Background to maintain bounds
                Color.gray.opacity(0.05)
                
                if let image = loader.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // Loading placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .frame(minHeight: 44)
                        )
                }

                // Favori badge (sol üst)
                if photo.isFavorite {
                    VStack {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.yellow)
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }

                // Seçim işareti (sağ üst)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .padding(8)
                }
            }
            .frame(width: max(75, cellSize), height: max(75, cellSize))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        photo.isFavorite ? Color.yellow : (isSelected ? Color.blue : Color.clear),
                        lineWidth: photo.isFavorite ? 3 : (isSelected ? 3 : 0)
                    )
            )
            .onAppear {
                // DispatchQueue kullanarak daha reliable delay sağla
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    let side = max(1, cellSize * displayScale)
                    let size = CGSize(width: side, height: side)
                    loader.load(asset: photo.asset, targetSize: size)
                }
            }

            // Tarih bilgisi
            HStack {
                if let date = photo.creationDate {
                    Text(L10n.date(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if photo.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                }
            }

            // Boyut bilgisi
            Text("\(photo.pixelWidth) × \(photo.pixelHeight)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .opacity(photo.isFavorite ? 1.0 : (isSelected ? 1.0 : 0.95))
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}
