//
//  SimilarPhotoDetailView.swift
//  Similarly
//
//  Created by AI Agent (Arch Swift)
//

import Photos
import SwiftUI

/// Benzer fotoğraf grubu detay ekranı (fotoğraf seçimi, silme, karşılaştırma)
struct SimilarPhotoDetailView: View {
    let group: SimilarPhotoGroup
    @ObservedObject var photoManager: PhotoLibraryManager

    @State private var selectedPhotos = Set<String>()
    @State private var showingDeleteConfirmation = false
    @State private var showingFullImage: PhotoItem?
    @State private var showingComparison = false
    @State private var comparisonStartIndex = 0
    @State private var showingCelebration = false
    @State private var lastDeletedCount = 0
    @State private var lastSavedBytes: Int64 = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            // Üst bilgi
            VStack(spacing: 8) {
                Text(
                    group.isDuplicate
                        ? L10n.f("similar.row.duplicate_count", group.count)
                        : L10n.f("similar.detail.count", group.count)
                )
                    .font(.title2)
                    .fontWeight(.bold)

                Text(L10n.k("similar.detail.select_to_delete"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Favori uyarısı
                if group.hasFavorite {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(L10n.k("similar.detail.favorite_protected"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()

            // Fotoğraf grid'i
            GeometryReader { geometry in
                let spacing: CGFloat = 12
                let horizontalPadding: CGFloat = 16
                let totalHorizontalPadding = horizontalPadding * 2
                let availableWidth = max(100, geometry.size.width - totalHorizontalPadding - spacing)
                let cellWidth = max(75, floor(availableWidth / 2))
                let columns = [
                    GridItem(.fixed(cellWidth), spacing: spacing),
                    GridItem(.fixed(cellWidth), spacing: spacing),
                ]

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(Array(group.photos.enumerated()), id: \.element.id) { index, photo in
                            PhotoGridItem(
                                photo: photo,
                                cellSize: cellWidth,
                                isSelected: selectedPhotos.contains(photo.id),
                                onTap: {
                                    // Favori fotoğrafları seçilmeye izin verme
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
                                    comparisonStartIndex = index
                                    showingComparison = true
                                }
                            )
                            .frame(width: cellWidth)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 4)
                }
            }

            // Karşılaştırma butonu
            Button(action: {
                comparisonStartIndex = 0
                showingComparison = true
            }) {
                HStack {
                    Image(systemName: "arrow.left.and.right.square")
                    Text(L10n.k("comparison.title"))
                        .fontWeight(.semibold)
                }
                // Uzun çevirilerde düğme iki satıra bölünüp yanındakinden uzamasın.
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // Alt butonlar
            HStack(spacing: 15) {
                // Tümünü seç/kaldır (favoriler hariç)
                Button(action: {
                    let nonFavorites = group.photos.filter { !$0.isFavorite }
                    if selectedPhotos.count == nonFavorites.count {
                        selectedPhotos.removeAll()
                    } else {
                        selectedPhotos = Set(nonFavorites.map { $0.id })
                    }
                }) {
                    HStack {
                        let nonFavorites = group.photos.filter { !$0.isFavorite }
                        Image(
                            systemName: selectedPhotos.count == nonFavorites.count
                                ? "checkmark.circle" : "circle")
                        Text(
                            selectedPhotos.count == nonFavorites.count
                                ? L10n.k("common.clear_all") : L10n.k("common.select_all"))
                    }
                    // Uzun çevirilerde düğme iki satıra bölünüp yanındakinden uzamasın.
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }

                // En eskilerini seç (favoriler hariç)
                Button(action: {
                    selectOldestPhotos()
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text(L10n.k("common.oldest"))
                    }
                    // Uzun çevirilerde düğme iki satıra bölünüp yanındakinden uzamasın.
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            // Sil butonu
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text(L10n.f("common.delete_selected_count", selectedPhotos.count))
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
            .padding()
        }
        .navigationTitle(L10n.k("similar.detail.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        // Onay bu ekranda gösterilir; geri dönüş yalnızca silme başarılı olduktan sonra yapılır.
        .alert(L10n.t("photos.alert.delete_title"), isPresented: $showingDeleteConfirmation) {
            Button(L10n.t("common.cancel"), role: .cancel) {}
            Button(L10n.t("common.delete"), role: .destructive) {
                deleteSelectedPhotos()
            }
        } message: {
            Text(L10n.f("photos.alert.delete_message", selectedPhotos.count))
        }
        .fullScreenCover(item: $showingFullImage) { photo in
            FullImageView(photo: photo)
        }
        .fullScreenCover(isPresented: $showingComparison) {
            PhotoComparisonView(
                photos: group.photos,
                initialIndex: comparisonStartIndex,
                onSelect: { selectedItems in
                    selectedPhotos = Set(selectedItems.map(\.id))
                }
            )
        }
        .sheet(isPresented: $showingCelebration, onDismiss: {
            dismiss()
        }) {
            CleanCelebrationView(
                deletedCount: lastDeletedCount,
                savedBytes: lastSavedBytes,
                onDismiss: {
                    showingCelebration = false
                }
            )
        }
    }

    private func deleteSelectedPhotos() {
        let photosToDelete = group.photos.filter { selectedPhotos.contains($0.id) }
        let count = photosToDelete.count
        let bytes = photosToDelete.reduce(Int64(0)) { $0 + $1.estimatedFileSize }

        Task {
            do {
                // Silinenler, PhotoLibraryManager.onPhotosRemoved ile gruplardan da çıkarılır.
                if try await photoManager.deletePhotos(photosToDelete) {
                    lastDeletedCount = count
                    lastSavedBytes = bytes
                    selectedPhotos.removeAll()
                    showingCelebration = true
                }
            } catch {
                photoManager.setError(
                    L10n.f("errors.delete_photos_failed", error.localizedDescription)
                )
            }
        }
    }

    private func selectOldestPhotos() {
        // Favori olmayanları seç ve en eskileri bul
        let nonFavorites = group.photos.filter { !$0.isFavorite }
        let sorted = nonFavorites.sorted { photo1, photo2 in
            guard let date1 = photo1.creationDate, let date2 = photo2.creationDate else {
                return false
            }
            return date1 < date2
        }

        // En yeni olanı hariç hepsini seç
        selectedPhotos.removeAll()
        for photo in sorted.dropLast() {
            selectedPhotos.insert(photo.id)
        }
    }
}

#Preview {
    NavigationStack {
        SimilarPhotoDetailView(
            group: SimilarPhotoGroup(photos: [], similarityScore: 0.95),
            photoManager: PhotoLibraryManager()
        )
    }
}
