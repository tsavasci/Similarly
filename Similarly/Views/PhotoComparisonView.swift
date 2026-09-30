//
//  PhotoComparisonView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI
import UIKit

/// Yan yana karşılaştırma ile fotoğraf seçim görünümü
struct PhotoComparisonView: View {
    let photos: [PhotoItem]
    let initialIndex: Int
    let onSelect: ([PhotoItem]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos = Set<String>()
    @State private var showingFullImage: PhotoItem?

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
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(minimum: 150), spacing: 12),
                                GridItem(.flexible(minimum: 150), spacing: 12),
                            ],
                            spacing: 12
                        ) {
                            ForEach(photos) { photo in
                                ComparisonPhotoCard(
                                    photo: photo,
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
                                .id(photo.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        guard initialIndex > 0, initialIndex < photos.count else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                proxy.scrollTo(photos[initialIndex].id, anchor: .top)
                            }
                        }
                    }
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
                            // Uzun çevirilerde düğme iki satıra bölünüp yanındakinden uzamasın.
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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
                            // Uzun çevirilerde düğme iki satıra bölünüp yanındakinden uzamasın.
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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
    }

    // MARK: - Helper Functions

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
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @StateObject private var loader = AssetImageLoader()
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        VStack(spacing: 8) {
            // Sabit kare taban: fotoğraf overlay olarak yerleşip kırpılır, böylece .fill ile
            // doğal boyutu kartı dışarı itip komşu hücreye taşamaz.
            Color.gray.opacity(0.05)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .overlay {
                    if let image = loader.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(ProgressView())
                    }
                }
                .overlay(alignment: .topLeading) {
                    // Favori badge
                    if photo.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .padding(8)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    // Seçim işareti
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                            .padding(8)
                    }
                }
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
                    // Fixed size: 150x150
                    let baseSize: CGFloat = 150.0
                    let size = CGSize(width: baseSize * displayScale, height: baseSize * displayScale)
                    loader.load(asset: photo.asset, targetSize: size)
                }
            }

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

                    // Bulanıklık uyarısı (ham skor yerine anlaşılır etiket)
                    if photo.isBlurry {
                        HStack(spacing: 2) {
                            Image(systemName: "eye.slash")
                                .font(.system(size: 9))
                            Text(L10n.k("comparison.blurry_label"))
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }

                    // Boyutlar
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 9))
                        Text("\(photo.pixelWidth)×\(photo.pixelHeight)")
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .opacity(photo.isFavorite ? 0.7 : 1.0)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }

    private func formatDate(_ date: Date) -> String {
        L10n.date(date, time: .shortened)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        L10n.bytes(bytes)
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
