//
//  SimilarPhotosListView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI
import ImageIO

/// Benzer fotoğraf gruplarını liste halinde gösteren görünüm
struct SimilarPhotosListView: View {
    @ObservedObject var similarityManager: SimilarityManager
    @ObservedObject var photoManager: PhotoLibraryManager
    @State private var showingDeleteConfirmation = false
    @State private var photosToDelete: [PhotoItem] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if similarityManager.similarGroups.isEmpty && similarityManager.duplicateGroups.isEmpty
                && similarityManager.screenshotGroups.isEmpty
            {
                // Benzer fotoğraf bulunamadı
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text(L10n.k("similar.empty.title"))
                        .font(.title)
                        .fontWeight(.bold)

                    Text(L10n.k("similar.empty.message"))
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
                            // Duplikatlar
                            if !similarityManager.duplicateGroups.isEmpty {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.red)
                                    Text(L10n.f("similar.summary.duplicate_groups", similarityManager.duplicateGroups.count))
                                        .font(.headline)
                                }
                            }

                            // Screenshots
                            if !similarityManager.screenshotGroups.isEmpty {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                        .foregroundColor(.orange)
                                    Text(
                                        L10n.f("similar.summary.screenshot_groups", similarityManager.screenshotGroups.count)
                                    )
                                    .font(.headline)
                                }
                            }

                            // Benzer fotoğraflar
                            if !similarityManager.similarGroups.isEmpty {
                                HStack {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .foregroundColor(.blue)
                                    Text(L10n.f("similar.summary.similar_groups", similarityManager.similarGroups.count))
                                        .font(.headline)
                                }
                            }

                            Divider()

                            // Toplam istatistikler
                            let totalPhotos =
                                similarityManager.getTotalDuplicatesCount()
                                + similarityManager.getTotalScreenshotsCount()
                                + similarityManager.getTotalSimilarPhotosCount()

                            HStack {
                                Image(systemName: "photo.stack")
                                    .foregroundColor(.purple)
                                Text(L10n.f("similar.summary.total_photos", totalPhotos))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if similarityManager.getPotentialSpaceSavings() > 0 {
                                HStack {
                                    Image(systemName: "internaldrive")
                                        .foregroundColor(.green)
                                    Text(
                                        L10n.f("similar.summary.savings", formatBytes(similarityManager.getPotentialSpaceSavings()))
                                    )
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Video ve Live Photos
                    if similarityManager.getTotalVideosCount() > 0
                        || similarityManager.getTotalLivePhotosCount() > 0
                    {
                        Section(
                            header: HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(.blue)
                                Text(L10n.k("media.header.title"))
                                    .foregroundColor(.blue)
                            }
                        ) {
                            NavigationLink {
                                MediaLibraryView(
                                    similarityManager: similarityManager,
                                    photoManager: photoManager
                                )
                            } label: {
                                VStack(spacing: 12) {
                                    if similarityManager.getTotalVideosCount() > 0 {
                                        HStack {
                                            Image(systemName: "video.fill")
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(
                                                    L10n.f("media.videos_count", similarityManager.getTotalVideosCount())
                                                )
                                                .font(.headline)
                                                Text(L10n.k("similar.media.videos_cta"))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }

                                    if similarityManager.getTotalLivePhotosCount() > 0 {
                                        HStack {
                                            Image(systemName: "livephoto")
                                                .foregroundColor(.purple)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(
                                                    L10n.f("media.live_photos_count", similarityManager.getTotalLivePhotosCount())
                                                )
                                                .font(.headline)
                                                Text(L10n.k("similar.media.live_cta"))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }

                    // Kalite Sorunları
                    if similarityManager.getTotalQualityIssuesCount() > 0 {
                        Section(
                            header: HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(L10n.k("quality.nav_title"))
                                    .foregroundColor(.orange)
                            }
                        ) {
                            NavigationLink {
                                QualityIssuesView(
                                    similarityManager: similarityManager,
                                    photoManager: photoManager
                                )
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            if !similarityManager.blurryPhotos.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "eye.slash.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.orange)
                                                    Text("\(similarityManager.blurryPhotos.count)")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                }
                                            }

                                            if !similarityManager.darkPhotos.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "moon.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.purple)
                                                    Text("\(similarityManager.darkPhotos.count)")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                }
                                            }

                                            if !similarityManager.brightPhotos.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "sun.max.fill")
                                                        .font(.caption)
                                                        .foregroundColor(.yellow)
                                                    Text("\(similarityManager.brightPhotos.count)")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                }
                                            }
                                        }

                                        Text(L10n.k("similar.quality.desc"))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    // Duplikat Grupları
                    if !similarityManager.duplicateGroups.isEmpty {
                        Section(
                            header: HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .foregroundColor(.red)
                                Text(L10n.k("similar.section.duplicates"))
                                    .foregroundColor(.red)
                            }
                        ) {
                            ForEach(similarityManager.duplicateGroups) { group in
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
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                            }
                        }
                    }

                    // Screenshot Grupları
                    if !similarityManager.screenshotGroups.isEmpty {
                        Section(
                            header: HStack {
                                Image(systemName: "camera.viewfinder")
                                    .foregroundColor(.orange)
                                Text(L10n.k("similar.section.screenshots"))
                                    .foregroundColor(.orange)
                            }
                        ) {
                            ForEach(similarityManager.screenshotGroups) { group in
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
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                            }
                        }
                    }

                    // Benzer Gruplar
                    if !similarityManager.similarGroups.isEmpty {
                        Section(
                            header: HStack {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .foregroundColor(.blue)
                                Text(L10n.k("similar.section.similar_groups"))
                                    .foregroundColor(.blue)
                            }
                        ) {
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
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.k("similar.nav_title"))
        .navigationBarTitleDisplayMode(.large)
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

                        // Grupları güncelle
                        await similarityManager.findSimilarPhotos(from: photoManager.photos)
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
                        Text(
                            group.allScreenshots
                                ? L10n.f("similar.row.screenshot_count", group.count)
                                : L10n.f("similar.row.similar_photo_count", group.count)
                        )
                        .font(.caption)
                        .fontWeight(.semibold)

                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(getSimilarityDescription(group.similarityScore))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Favori badge
                        if group.hasFavorite {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                                Text(L10n.k("common.favorite"))
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }

                    // İkinci satır: Tarih
                    if let date = group.representativePhoto?.creationDate {
                        Text(date.formatted(date: .numeric, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Önizleme resimleri
                HStack(spacing: 8) {
                    ForEach(Array(group.photos.prefix(3)), id: \.id) { photo in
                        if let thumbnail = photo.thumbnail,
                            let uiImage = thumbnail.toUIImage()
                        {
                            ZStack(alignment: .topLeading) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                photo.isFavorite ? Color.yellow : Color.white,
                                                lineWidth: photo.isFavorite ? 4 : 3
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                                // Favori badge
                                if photo.isFavorite {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                        .padding(4)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                        .offset(x: 4, y: 4)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
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

                Text(L10n.k("common.similar"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 55, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }

    private func getSimilarityDescription(_ score: Double) -> String {
        if score >= 0.99 {
            return L10n.t("similarity.exact_match")
        } else if score >= 0.95 {
            return L10n.t("similarity.almost_identical")
        } else if score >= 0.85 {
            return L10n.t("similarity.very_similar")
        } else if score >= 0.75 {
            return L10n.t("similarity.similar")
        } else if score >= 0.65 {
            return L10n.t("similarity.slightly_similar")
        } else {
            return L10n.t("similarity.less_similar")
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
    @State private var showingComparison = false
    @State private var comparisonStartIndex = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {

            // Üst bilgi
            VStack(spacing: 8) {
                Text(L10n.f("similar.detail.count", group.count))
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
                let availableWidth = max(0, geometry.size.width - totalHorizontalPadding - spacing)
                let cellWidth = floor(availableWidth / 2)
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
                    Text(L10n.f("common.delete_selected_count", selectedPhotos.count))
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
        .navigationTitle(L10n.k("similar.detail.nav_title"))
        .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Photo Grid Item
struct PhotoGridItem: View {
    let photo: PhotoItem
    let cellSize: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @StateObject private var loader = AssetImageLoader()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Background to maintain bounds
                Color.gray.opacity(0.05)
                
                if let image = loader.image {
                    // Loader'dan gelen full-res image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let thumbnail = photo.thumbnail,
                    let uiImage = thumbnail.toUIImage()
                {
                    // Memory'de cache'lenmiş thumbnail
                    Image(uiImage: uiImage)
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
            .frame(width: cellSize, height: cellSize)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        photo.isFavorite ? Color.yellow : (isSelected ? Color.blue : Color.clear),
                        lineWidth: photo.isFavorite ? 3 : (isSelected ? 3 : 0)
                    )
            )
            .onAppear {
                // Thumbnail cache'de yoksa, loader ile yükle
                // DispatchQueue kullanarak daha reliable delay sağla
                guard photo.thumbnail == nil else { return }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak loader] in
                    guard let loader = loader else { return }
                    let scale = UIScreen.main.scale
                    let side = max(1, cellSize * scale)
                    let size = CGSize(width: side, height: side)
                    loader.load(asset: photo.asset, targetSize: size)
                }
            }

            // Tarih bilgisi
            HStack {
                if let date = photo.creationDate {
                    Text(date, style: .date)
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
        options.resizeMode = .none
        options.isNetworkAccessAllowed = true
        options.version = .current

        guard photo.asset.pixelWidth > 0, photo.asset.pixelHeight > 0 else {
            return
        }

        let scale = UIScreen.main.scale
        let bounds = UIScreen.main.bounds
        let maxPixelSize = max(bounds.width, bounds.height) * scale

        PHImageManager.default().requestImageDataAndOrientation(
            for: photo.asset,
            options: options
        ) { data, _, _, info in
            let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
            if cancelled { return }
            guard let data = data else { return }

            if let image = downsampleImage(from: data, maxPixelSize: maxPixelSize) {
                DispatchQueue.main.async {
                    fullImage = image
                }
            }
        }
    }

    private func downsampleImage(from data: Data, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard
            let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary)
        else {
            return UIImage(data: data)
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: max(1, Int(maxPixelSize.rounded(.up)))
        ]

        guard
            let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                thumbnailOptions as CFDictionary
            )
        else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
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
