//
//  PhotoComparisonView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI

/// Yan yana karşılaştırma ile fotoğraf seçim görünümü
struct PhotoComparisonView: View {
    let photos: [PhotoItem]
    let initialIndex: Int
    let onSelect: ([PhotoItem]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos = Set<String>()
    @State private var showingFullImage: PhotoItem?
    @State private var fullImages: [String: UIImage] = [:]

    init(photos: [PhotoItem], initialIndex: Int = 0, onSelect: @escaping ([PhotoItem]) -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Üst bilgi
                VStack(spacing: 12) {
                    Text(L10n.k("comparison.title"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L10n.k("comparison.subtitle"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // İpucu
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.caption)
                        Text(L10n.k("comparison.hint.long_press"))
                            .font(.caption)

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(L10n.k("comparison.hint.tap_select"))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 2)

                // Fotoğraf grid'i
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                        ],
                        spacing: 12
                    ) {
                        ForEach(photos) { photo in
                            ComparisonPhotoCard(
                                photo: photo,
                                fullImage: fullImages[photo.id],
                                isSelected: selectedPhotos.contains(photo.id),
                                onTap: {
                                    if photo.isFavorite {
                                        return
                                    }
                                    if selectedPhotos.contains(photo.id) {
                                        selectedPhotos.remove(photo.id)
                                    } else {
                                        selectedPhotos.insert(photo.id)
                                    }
                                },
                                onLongPress: {
                                    // Haptic feedback
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    showingFullImage = photo
                                }
                            )
                        }
                    }
                    .padding()
                }

                // Alt kontrol butonu
                VStack(spacing: 12) {
                    // Seçim özeti
                    if !selectedPhotos.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(L10n.f("comparison.selected_count", selectedPhotos.count))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    HStack(spacing: 12) {
                        // Tümünü seç/kaldır
                        Button(action: {
                            let nonFavorites = photos.filter { !$0.isFavorite }
                            if selectedPhotos.count == nonFavorites.count {
                                selectedPhotos.removeAll()
                            } else {
                                selectedPhotos = Set(nonFavorites.map { $0.id })
                            }
                        }) {
                            HStack {
                                let nonFavorites = photos.filter { !$0.isFavorite }
                                Image(
                                    systemName: selectedPhotos.count == nonFavorites.count
                                        ? "checkmark.circle" : "circle"
                                )
                                Text(
                                    selectedPhotos.count == nonFavorites.count
                                        ? L10n.k("common.clear_all") : L10n.k("common.select_all")
                                )
                                .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }

                        // Seçilenleri sil
                        Button(action: {
                            finalizeSelections()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(L10n.k("common.delete_selected"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPhotos.isEmpty ? Color.gray : Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedPhotos.isEmpty)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.t("common.close")) {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.t("common.done")) {
                        finalizeSelections()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .fullScreenCover(item: $showingFullImage) { photo in
            FullImageView(photo: photo)
        }
        .onAppear {
            loadImages()
        }
    }

    // MARK: - Helper Functions
    private func loadImages() {
        for photo in photos {
            loadFullImage(for: photo)
        }
    }

    private func loadFullImage(for photo: PhotoItem) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: CGSize(width: 500, height: 500),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                fullImages[photo.id] = image
            }
        }
    }

    private func finalizeSelections() {
        // Seçilen fotoğrafları işle
        let selectedPhotoItems = photos.filter { selectedPhotos.contains($0.id) }

        // Seçimleri tek seferde parent'a aktar
        onSelect(selectedPhotoItems)

        // Haptic feedback
        if !selectedPhotos.isEmpty {
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        }

        dismiss()
    }
}

// MARK: - Comparison Photo Card
struct ComparisonPhotoCard: View {
    let photo: PhotoItem
    let fullImage: UIImage?
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Fotoğraf
                    if let image = fullImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .cornerRadius(12)
                    } else if let thumbnail = photo.thumbnail,
                        let uiImage = thumbnail.toUIImage()
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                            )
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .cornerRadius(12)
                            .overlay(
                                ProgressView()
                            )
                    }

                    // Favori badge
                    if photo.isFavorite {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                                .padding(6)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                            Spacer()
                        }
                        .padding(8)
                    }

                    // Seçim işareti
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(Color.white))
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // Metadata bilgileri
            VStack(spacing: 4) {
                // Tarih
                if let date = photo.creationDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(formatDate(date))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }

                // Boyut ve kalite skoru
                HStack(spacing: 8) {
                    // Dosya boyutu
                    if let size = photo.fileSize {
                        HStack(spacing: 2) {
                            Image(systemName: "doc")
                                .font(.system(size: 9))
                            Text(formatFileSize(size))
                                .font(.caption2)
                        }
                    }

                    Spacer()

                    // Blur score
                    if let blurScore = photo.blurScore {
                        HStack(spacing: 2) {
                            Image(systemName: "eye")
                                .font(.system(size: 9))
                            Text(String(format: "%.0f", blurScore))
                                .font(.caption2)
                        }
                        .foregroundColor(blurScore < 100 ? .orange : .green)
                    }

                    // Boyutlar
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9))
                        Text("\(photo.pixelWidth)×\(photo.pixelHeight)")
                            .font(.caption2)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    photo.isFavorite ? Color.yellow : (isSelected ? Color.blue : Color.clear),
                    lineWidth: photo.isFavorite ? 3 : (isSelected ? 3 : 0)
                )
        )
        .opacity(photo.isFavorite ? 0.7 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Preview
#Preview {
    PhotoComparisonView(
        photos: [],
        initialIndex: 0,
        onSelect: { _ in }
    )
}
