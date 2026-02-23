//
//  QualityIssuesView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI

/// Kalite sorunlu fotoğrafları gösteren görünüm
struct QualityIssuesView: View {
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
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("quality.header.title"))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(L10n.f("quality.total_found", similarityManager.getTotalQualityIssuesCount()))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)

                // Kategori seçimi
                Picker(L10n.t("common.category"), selection: $selectedTab) {
                    Text(L10n.f("quality.tab.blurry", similarityManager.blurryPhotos.count))
                        .tag(0)
                    Text(L10n.f("quality.tab.dark", similarityManager.darkPhotos.count))
                        .tag(1)
                    Text(L10n.f("quality.tab.bright", similarityManager.brightPhotos.count))
                        .tag(2)
                }
                .pickerStyle(.segmented)
            }
            .padding()

            // Fotoğraf listesi
            TabView(selection: $selectedTab) {
                // Bulanık fotoğraflar
                QualityPhotoGrid(
                    photos: similarityManager.blurryPhotos,
                    issueType: .blurry,
                    onDelete: { photos in
                        photosToDelete = photos
                        showingDeleteConfirmation = true
                    },
                    similarityManager: similarityManager
                )
                .tag(0)

                // Karanlık fotoğraflar
                QualityPhotoGrid(
                    photos: similarityManager.darkPhotos,
                    issueType: .dark,
                    onDelete: { photos in
                        photosToDelete = photos
                        showingDeleteConfirmation = true
                    },
                    similarityManager: similarityManager
                )
                .tag(1)

                // Parlak fotoğraflar
                QualityPhotoGrid(
                    photos: similarityManager.brightPhotos,
                    issueType: .bright,
                    onDelete: { photos in
                        photosToDelete = photos
                        showingDeleteConfirmation = true
                    },
                    similarityManager: similarityManager
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(L10n.k("quality.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(L10n.t("photos.alert.delete_title"), isPresented: $showingDeleteConfirmation) {
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

                        // Eğer kalite sorunu kalmadıysa geri dön
                        if similarityManager.getTotalQualityIssuesCount() == 0 {
                            dismiss()
                        }
                    } catch {
                        photoManager.setError(
                            L10n.f(
                                "errors.delete_photos_failed",
                                error.localizedDescription
                            )
                        )
                    }
                }
            }
        } message: {
            Text(L10n.f("photos.alert.delete_message", photosToDelete.count))
        }
    }
}

// MARK: - Quality Photo Grid
struct QualityPhotoGrid: View {
    let photos: [PhotoItem]
    let issueType: QualityIssueType
    let onDelete: ([PhotoItem]) -> Void
    @ObservedObject var similarityManager: SimilarityManager

    @State private var selectedPhotos = Set<String>()
    @State private var showingFullImage: PhotoItem?

    private func markAsNotIssue(_ photos: [PhotoItem]) {
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)

        // Kalite sorunları listesinden kaldır
        switch issueType {
        case .blurry:
            similarityManager.removeFromBlurryPhotos(photos)
        case .dark:
            similarityManager.removeFromDarkPhotos(photos)
        case .bright:
            similarityManager.removeFromBrightPhotos(photos)
        }

        // Seçimi temizle
        selectedPhotos.removeAll()
    }

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
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)

                    Text(L10n.k("quality.empty.title"))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(issueType.emptyMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                // Açıklama
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: issueType.icon)
                            .foregroundColor(issueType.color)
                        Text(issueType.title)
                            .font(.headline)
                            .foregroundColor(issueType.color)
                    }

                    Text(issueType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(issueType.color.opacity(0.1))

                // Fotoğraf grid'i
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(photos) { photo in
                            QualityPhotoItem(
                                photo: photo,
                                issueType: issueType,
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
                    }
                    .padding(.horizontal)

                    // Aksiyon butonları
                    HStack(spacing: 12) {
                        // Kalite Sorunu Yok butonu
                        Button(action: {
                            let photosToMark = photos.filter { selectedPhotos.contains($0.id) }
                            markAsNotIssue(photosToMark)
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(issueType.notIssueButtonText)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPhotos.isEmpty ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(selectedPhotos.isEmpty)

                        // Sil butonu
                        Button(action: {
                            let photosToDelete = photos.filter { selectedPhotos.contains($0.id) }
                            onDelete(photosToDelete)
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text(L10n.k("common.delete"))
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

// MARK: - Quality Photo Item
struct QualityPhotoItem: View {
    let photo: PhotoItem
    let issueType: QualityIssueType
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                if let thumbnail = photo.thumbnail,
                    let uiImage = thumbnail.toUIImage()
                {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 110, height: 110)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 110, height: 110)
                        .cornerRadius(12)
                }

                // Favori badge
                if photo.isFavorite {
                    VStack {
                        HStack {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                                .padding(4)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(6)
                }

                // Seçim işareti
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white))
                        .padding(6)
                }
            }

            // Kalite skoru
            HStack(spacing: 4) {
                Image(systemName: issueType.icon)
                    .font(.system(size: 8))
                    .foregroundColor(issueType.color)

                Text(issueType.scoreText(for: photo))
                    .font(.caption2)
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
}

// MARK: - Quality Issue Type
enum QualityIssueType {
    case blurry
    case dark
    case bright

    var icon: String {
        switch self {
        case .blurry: return "eye.slash.fill"
        case .dark: return "moon.fill"
        case .bright: return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .blurry: return .orange
        case .dark: return .purple
        case .bright: return .yellow
        }
    }

    var title: String {
        switch self {
        case .blurry: return L10n.t("quality.type.blurry.title")
        case .dark: return L10n.t("quality.type.dark.title")
        case .bright: return L10n.t("quality.type.bright.title")
        }
    }

    var description: String {
        switch self {
        case .blurry:
            return L10n.t("quality.type.blurry.desc")
        case .dark:
            return L10n.t("quality.type.dark.desc")
        case .bright:
            return L10n.t("quality.type.bright.desc")
        }
    }

    var emptyMessage: String {
        switch self {
        case .blurry:
            return L10n.t("quality.type.blurry.empty")
        case .dark:
            return L10n.t("quality.type.dark.empty")
        case .bright:
            return L10n.t("quality.type.bright.empty")
        }
    }

    var notIssueButtonText: String {
        switch self {
        case .blurry:
            return L10n.t("quality.mark.sharp")
        case .dark:
            return L10n.t("quality.mark.good")
        case .bright:
            return L10n.t("quality.mark.good")
        }
    }

    func scoreText(for photo: PhotoItem) -> String {
        switch self {
        case .blurry:
            if let score = photo.blurScore {
                return String(format: "%.0f", score)
            }
            return "-"
        case .dark, .bright:
            if let score = photo.brightnessScore {
                return String(format: "%.1f%%", score * 100)
            }
            return "-"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        QualityIssuesView(
            similarityManager: SimilarityManager(),
            photoManager: PhotoLibraryManager()
        )
    }
}
