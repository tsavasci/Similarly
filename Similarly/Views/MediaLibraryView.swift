//
//  MediaLibraryView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI

/// Video ve Live Photos görünümü
struct MediaLibraryView: View {
    @ObservedObject var similarityManager: SimilarityManager
    @ObservedObject var photoManager: PhotoLibraryManager
    @State private var showingDeleteConfirmation = false
    @State private var photosToDelete: [PhotoItem] = []
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Özet bilgi
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "film.stack")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("media.header.title"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(L10n.f("common.media_files_count", getTotalMediaCount()))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                // Kategori seçimi
                Picker(L10n.t("common.category"), selection: $selectedTab) {
                    Text(L10n.f("media.videos_count", similarityManager.videos.count))
                        .tag(0)
                    Text(L10n.f("media.live_photos_count", similarityManager.livePhotos.count))
                        .tag(1)
                }
                .pickerStyle(.segmented)
            }
            .padding()

            // Medya listesi
            TabView(selection: $selectedTab) {
                // Videolar
                MediaPhotoGrid(
                    photos: similarityManager.videos,
                    mediaType: .video,
                    onDelete: { photos in
                        photosToDelete = photos
                        showingDeleteConfirmation = true
                    }
                )
                .tag(0)

                // Live Photos
                MediaPhotoGrid(
                    photos: similarityManager.livePhotos,
                    mediaType: .livePhoto,
                    onDelete: { photos in
                        photosToDelete = photos
                        showingDeleteConfirmation = true
                    }
                )
                .tag(1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(L10n.k("media.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.t("media.alert.delete_title"), isPresented: $showingDeleteConfirmation) {
            Button(L10n.t("common.cancel"), role: .cancel) {
                photosToDelete = []
            }
            Button(L10n.t("common.delete"), role: .destructive) {
                Task {
                    do {
                        try await photoManager.deletePhotos(photosToDelete)
                        photosToDelete = []

                        // Fotoğraf kütüphanesini yeniden yükle
                        await photoManager.fetchAssets()

                        // Analizi güncelle
                        await similarityManager.findSimilarPhotos(from: photoManager.photos)

                        // Eğer medya kalmadıysa geri dön
                        if getTotalMediaCount() == 0 {
                            dismiss()
                        }
                    } catch {
                        photoManager.setError(
                            L10n.f(
                                "errors.delete_media_failed",
                                error.localizedDescription
                            )
                        )
                    }
                }
            }
        } message: {
            Text(L10n.f("media.alert.delete_message", photosToDelete.count))
        }
    }

    private func getTotalMediaCount() -> Int {
        return similarityManager.videos.count + similarityManager.livePhotos.count
    }
}

// MARK: - Media Photo Grid
struct MediaPhotoGrid: View {
    let photos: [PhotoItem]
    let mediaType: MediaType
    let onDelete: ([PhotoItem]) -> Void

    @State private var selectedPhotos = Set<String>()
    @State private var showingFullImage: PhotoItem?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if photos.isEmpty {
                // Boş durum
                VStack(spacing: 20) {
                    Image(systemName: mediaType == .video ? "video.slash" : "livephoto.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text(L10n.k("media.empty.title"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(mediaType.emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // Açıklama
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: mediaType.icon)
                            .foregroundColor(mediaType.color)
                        Text(mediaType.title)
                            .font(.headline)
                            .foregroundColor(mediaType.color)
                    }

                    Text(mediaType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(mediaType.color.opacity(0.1))

                // Medya grid'i
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(photos) { photo in
                            MediaPhotoItem(
                                photo: photo,
                                mediaType: mediaType,
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

                // Alt kontroller
                VStack(spacing: 12) {
                    // Seçim özeti
                    if !selectedPhotos.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text(L10n.f("media.selected_count", selectedPhotos.count))
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
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }

                        // Sil butonu
                        Button(action: {
                            let photosToDelete = photos.filter { selectedPhotos.contains($0.id) }
                            onDelete(photosToDelete)
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(L10n.f("common.delete_with_count", selectedPhotos.count))
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
        }
        .fullScreenCover(item: $showingFullImage) { photo in
            FullImageView(photo: photo)
        }
    }
}

// MARK: - Media Photo Item
struct MediaPhotoItem: View {
    let photo: PhotoItem
    let mediaType: MediaType
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    if let thumbnail = photo.thumbnail,
                        let uiImage = thumbnail.toUIImage()
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .cornerRadius(12)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .cornerRadius(12)
                    }

                    // Video/Live Photo badge
                    VStack {
                        HStack {
                            Image(systemName: mediaType.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Circle().fill(mediaType.color))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(6)

                    // Favori badge
                    if photo.isFavorite {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                                    .padding(4)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                                Spacer()
                            }
                        }
                        .padding(6)
                    }

                    // Seçim işareti
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(Color.white))
                                    .padding(6)
                            }
                            Spacer()
                        }
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)

            // Medya bilgileri
            VStack(spacing: 2) {
                // Tarih
                if let date = photo.creationDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // Video için süre
                if mediaType == .video {
                    if photo.duration > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                            Text(formatDuration(photo.duration))
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Dosya boyutu
                if let size = photo.fileSize {
                    HStack(spacing: 4) {
                        Image(systemName: "doc")
                            .font(.system(size: 8))
                        Text(formatFileSize(size))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
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

    private func formatDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, remainingSeconds)
        } else {
            return String(format: "0:%02d", remainingSeconds)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Media Type
enum MediaType {
    case video
    case livePhoto

    var icon: String {
        switch self {
        case .video: return "video.fill"
        case .livePhoto: return "livephoto"
        }
    }

    var color: Color {
        switch self {
        case .video: return .blue
        case .livePhoto: return .purple
        }
    }

    var title: String {
        switch self {
        case .video: return L10n.t("media.type.videos")
        case .livePhoto: return L10n.t("media.type.live_photos")
        }
    }

    var description: String {
        switch self {
        case .video:
            return L10n.t("media.type.videos.desc")
        case .livePhoto:
            return L10n.t("media.type.live_photos.desc")
        }
    }

    var emptyMessage: String {
        switch self {
        case .video:
            return L10n.t("media.type.videos.empty")
        case .livePhoto:
            return L10n.t("media.type.live_photos.empty")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MediaLibraryView(
            similarityManager: SimilarityManager(),
            photoManager: PhotoLibraryManager()
        )
    }
}
