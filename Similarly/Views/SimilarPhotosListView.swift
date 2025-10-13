//
//  SimilarPhotosListView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI

/// Benzer fotoğraf gruplarını liste halinde gösteren görünüm
struct SimilarPhotosListView: View {
    @ObservedObject var similarityManager: SimilarityManager
    @ObservedObject var photoManager: PhotoLibraryManager
    @State private var selectedGroup: SimilarPhotoGroup?
    @State private var showingDeleteConfirmation = false
    @State private var photosToDelete: [PhotoItem] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if similarityManager.similarGroups.isEmpty {
                // Benzer fotoğraf bulunamadı
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("Tebrikler!")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Benzer fotoğraf bulunamadı.\nFotoğraf kütüphaneniz temiz görünüyor.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                // Benzer fotoğraf grupları listesi
                List {
                    // Özet bilgi
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundColor(.blue)
                                Text("\(similarityManager.similarGroups.count) benzer grup bulundu")
                                    .font(.headline)
                            }

                            HStack {
                                Image(systemName: "photo.stack")
                                    .foregroundColor(.purple)
                                Text(
                                    "\(similarityManager.getTotalSimilarPhotosCount()) benzer fotoğraf"
                                )
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            }

                            if similarityManager.getPotentialSpaceSavings() > 0 {
                                HStack {
                                    Image(systemName: "internaldrive")
                                        .foregroundColor(.orange)
                                    Text(
                                        "~\(formatBytes(similarityManager.getPotentialSpaceSavings())) tasarruf edilebilir"
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Gruplar
                    Section(header: Text("Benzer Fotoğraf Grupları")) {
                        ForEach(similarityManager.similarGroups) { group in
                            NavigationLink {
                                SimilarPhotoDetailView(
                                    group: group,
                                    photoManager: photoManager,
                                    onDelete: { photos in
                                        photosToDelete = photos
                                        showingDeleteConfirmation = true
                                    }
                                )
                            } label: {
                                SimilarGroupRow(group: group)
                                    .padding(.leading, -20)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
        }
        .navigationTitle("Benzer Fotoğraflar")
        .navigationBarTitleDisplayMode(.large)
        .alert("Fotoğrafları Sil", isPresented: $showingDeleteConfirmation) {
            Button("İptal", role: .cancel) {
                photosToDelete = []
            }
            Button("Sil", role: .destructive) {
                Task {
                    try? await photoManager.deletePhotos(photosToDelete)
                    photosToDelete = []

                    // Fotoğraf kütüphanesini yeniden yükle
                    await photoManager.fetchAssets()

                    // Grupları güncelle
                    await similarityManager.findSimilarPhotos(from: photoManager.photos)
                }
            }
        } message: {
            Text("\(photosToDelete.count) fotoğraf kalıcı olarak silinecek. Emin misiniz?")
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Similar Group Row
struct SimilarGroupRow: View {
    let group: SimilarPhotoGroup

    var body: some View {
        HStack(spacing: 12) {
            // Sol kısım - Thumbnails ve Bilgiler
            VStack(alignment: .leading, spacing: 8) {
                // Bilgiler - İki satırda
                VStack(alignment: .leading, spacing: 4) {
                    // İlk satır: Fotoğraf sayısı ve benzerlik
                    HStack(spacing: 4) {
                        Text("\(group.count) benzer fotoğraf")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(getSimilarityDescription(group.similarityScore))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // İkinci satır: Tarih
                    if let date = group.representativePhoto?.creationDate {
                        Text(date.formatted(date: .numeric, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Önizleme resimleri
                HStack(spacing: -20) {
                    ForEach(Array(group.photos.prefix(3)), id: \.id) { photo in
                        if let thumbnail = photo.thumbnail,
                            let uiImage = thumbnail.toUIImage()
                        {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            // Sağ kısım - Benzerlik skoru
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(group.similarityScore * 100))%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(getScoreColor(group.similarityScore))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text("benzer")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 55, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }

    private func getSimilarityDescription(_ score: Double) -> String {
        if score >= 0.95 {
            return "Neredeyse aynı"
        } else if score >= 0.85 {
            return "Çok benzer"
        } else if score >= 0.75 {
            return "Benzer"
        } else if score >= 0.65 {
            return "Biraz benzer"
        } else {
            return "Az benzer"
        }
    }

    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 0.9...1.0: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Similar Photo Detail View
struct SimilarPhotoDetailView: View {
    let group: SimilarPhotoGroup
    @ObservedObject var photoManager: PhotoLibraryManager
    let onDelete: ([PhotoItem]) -> Void

    @State private var selectedPhotos = Set<String>()
    @State private var showingFullImage: PhotoItem?
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack {
            // Üst bilgi
            VStack(spacing: 8) {
                Text("\(group.count) benzer fotoğraf")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Silmek istediğiniz fotoğrafları seçin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            // Fotoğraf grid'i
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(group.photos) { photo in
                        PhotoGridItem(
                            photo: photo,
                            isSelected: selectedPhotos.contains(photo.id),
                            onTap: {
                                if selectedPhotos.contains(photo.id) {
                                    selectedPhotos.remove(photo.id)
                                } else {
                                    selectedPhotos.insert(photo.id)
                                }
                            },
                            onLongPress: {
                                showingFullImage = photo
                            }
                        )
                    }
                }
                .padding()
            }

            // Alt butonlar
            HStack(spacing: 15) {
                // Tümünü seç/kaldır
                Button(action: {
                    if selectedPhotos.count == group.photos.count {
                        selectedPhotos.removeAll()
                    } else {
                        selectedPhotos = Set(group.photos.map { $0.id })
                    }
                }) {
                    HStack {
                        Image(
                            systemName: selectedPhotos.count == group.photos.count
                                ? "checkmark.circle" : "circle")
                        Text(
                            selectedPhotos.count == group.photos.count
                                ? "Tümünü Kaldır" : "Tümünü Seç")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }

                // En eskilerini seç
                Button(action: {
                    selectOldestPhotos()
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("En Eskileri")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            // Sil butonu
            Button(action: {
                let photosToDelete = group.photos.filter { selectedPhotos.contains($0.id) }
                onDelete(photosToDelete)
                // Seçimleri temizle ve geri dön
                selectedPhotos.removeAll()
                dismiss()
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Seçilenleri Sil (\(selectedPhotos.count))")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedPhotos.isEmpty ? Color.gray : Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(selectedPhotos.isEmpty)
            .padding()
        }
        .navigationTitle("Grup Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $showingFullImage) { photo in
            FullImageView(photo: photo)
        }
    }

    private func selectOldestPhotos() {
        let sorted = group.photos.sorted { photo1, photo2 in
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

// MARK: - Photo Grid Item
struct PhotoGridItem: View {
    let photo: PhotoItem
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                if let thumbnail = photo.thumbnail,
                    let uiImage = thumbnail.toUIImage()
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 160)
                        .cornerRadius(12)
                        .overlay(
                            ProgressView()
                        )
                }

                // Seçim işareti
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .padding(8)
                }
            }

            // Tarih bilgisi
            if let date = photo.creationDate {
                Text(date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Boyut bilgisi
            Text("\(photo.pixelWidth) × \(photo.pixelHeight)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

// MARK: - Full Image View
struct FullImageView: View {
    let photo: PhotoItem
    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image = fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if let thumbnail = photo.thumbnail,
                let uiImage = thumbnail.toUIImage()
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }

            // Kapat butonu
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onAppear {
            loadFullImage()
        }
    }

    private func loadFullImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: photo.asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            if let image = image {
                fullImage = image
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SimilarPhotosListView(
            similarityManager: SimilarityManager(),
            photoManager: PhotoLibraryManager()
        )
    }
}
