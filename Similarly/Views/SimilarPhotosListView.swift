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
                            // Duplikatlar
                            if !similarityManager.duplicateGroups.isEmpty {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.red)
                                    Text("\(similarityManager.duplicateGroups.count) duplikat grup")
                                        .font(.headline)
                                }
                            }

                            // Screenshots
                            if !similarityManager.screenshotGroups.isEmpty {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                        .foregroundColor(.orange)
                                    Text(
                                        "\(similarityManager.screenshotGroups.count) screenshot grup"
                                    )
                                    .font(.headline)
                                }
                            }

                            // Benzer fotoğraflar
                            if !similarityManager.similarGroups.isEmpty {
                                HStack {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .foregroundColor(.blue)
                                    Text("\(similarityManager.similarGroups.count) benzer grup")
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
                                Text("\(totalPhotos) toplam fotoğraf")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            if similarityManager.getPotentialSpaceSavings() > 0 {
                                HStack {
                                    Image(systemName: "internaldrive")
                                        .foregroundColor(.green)
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

                    // Video ve Live Photos
                    if similarityManager.getTotalVideosCount() > 0
                        || similarityManager.getTotalLivePhotosCount() > 0
                    {
                        Section(
                            header: HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(.blue)
                                Text("Video ve Live Photos")
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
                                                    "\(similarityManager.getTotalVideosCount()) video"
                                                )
                                                .font(.headline)
                                                Text("Videoları görüntüle ve yönet")
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
                                                    "\(similarityManager.getTotalLivePhotosCount()) Live Photo"
                                                )
                                                .font(.headline)
                                                Text("Live Photos'ları görüntüle ve yönet")
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
                                Text("Kalite Sorunları")
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

                                        Text("Bulanık, karanlık veya aşırı parlak fotoğraflar")
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
                                Text("Duplikat Fotoğraflar (%100 Aynı)")
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
                                        .padding(.leading, -20)
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
                                Text("Ekran Görüntüleri")
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
                                        .padding(.leading, -20)
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
                                Text("Benzer Fotoğraf Grupları")
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
                                        .padding(.leading, -20)
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                            }
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
                    do {
                        try await photoManager.deletePhotos(photosToDelete)
                        photosToDelete = []

                        // Fotoğraf kütüphanesini yeniden yükle
                        await photoManager.fetchAssets()

                        // Grupları güncelle
                        await similarityManager.findSimilarPhotos(from: photoManager.photos)
                    } catch {
                        photoManager.setError("Fotoğraflar silinemedi: \(error.localizedDescription)")
                    }
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
                        Text(
                            "\(group.count) \(group.allScreenshots ? "screenshot" : "benzer fotoğraf")"
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
                                Text("Favori")
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
                HStack(spacing: -20) {
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
        if score >= 0.99 {
            return "%100 Aynı"
        } else if score >= 0.95 {
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
    @State private var showingComparison = false
    @State private var comparisonStartIndex = 0
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

                // Favori uyarısı
                if group.hasFavorite {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Favori işaretli fotoğraflar otomatik olarak korunur")
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
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(Array(group.photos.enumerated()), id: \.element.id) { index, photo in
                        PhotoGridItem(
                            photo: photo,
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
                    }
                }
                .padding()
            }

            // Karşılaştırma butonu
            Button(action: {
                comparisonStartIndex = 0
                showingComparison = true
            }) {
                HStack {
                    Image(systemName: "arrow.left.and.right.square")
                    Text("Fotoğrafları Karşılaştır")
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
                                ? "Tümünü Kaldır" : "Tümünü Seç")
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
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
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
                            .overlay(
                                ProgressView()
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
            }
            .aspectRatio(1, contentMode: .fit)

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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    photo.isFavorite ? Color.yellow : (isSelected ? Color.blue : Color.clear),
                    lineWidth: photo.isFavorite ? 3 : (isSelected ? 3 : 0)
                )
        )
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
