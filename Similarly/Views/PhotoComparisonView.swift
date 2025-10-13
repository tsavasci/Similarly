//
//  PhotoComparisonView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI

/// İki fotoğrafı yan yana karşılaştırma görünümü
struct PhotoComparisonView: View {
    let photos: [PhotoItem]
    let initialIndex: Int
    let onSelect: (PhotoItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var currentIndex: Int
    @State private var nextIndex: Int
    @State private var showingMetadata = false
    @State private var selectedPhoto: PhotoItem?
    @State private var fullImages: [String: UIImage] = [:]

    init(photos: [PhotoItem], initialIndex: Int = 0, onSelect: @escaping (PhotoItem) -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onSelect = onSelect
        _currentIndex = State(initialValue: initialIndex)
        _nextIndex = State(initialValue: min(initialIndex + 1, photos.count - 1))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Üst bilgi - Hangi fotoğraflar karşılaştırılıyor
                    HStack {
                        Text("Fotoğraf \(currentIndex + 1) / \(photos.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)

                        Spacer()

                        Text("Fotoğraf \(nextIndex + 1) / \(photos.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.5))

                    // Fotoğraf karşılaştırma alanı
                    if horizontalSizeClass == .regular {
                        // iPad veya landscape - Yan yana
                        HStack(spacing: 0) {
                            photoView(for: photos[currentIndex], index: currentIndex)
                            Divider().background(Color.white)
                            photoView(for: photos[nextIndex], index: nextIndex)
                        }
                    } else {
                        // iPhone portrait - Üst üste
                        VStack(spacing: 0) {
                            photoView(for: photos[currentIndex], index: currentIndex)
                            Divider().background(Color.white)
                            photoView(for: photos[nextIndex], index: nextIndex)
                        }
                    }

                    // Alt kontroller
                    VStack(spacing: 12) {
                        // Metadata toggle
                        Button(action: {
                            withAnimation {
                                showingMetadata.toggle()
                            }
                        }) {
                            HStack {
                                Image(
                                    systemName: showingMetadata ? "info.circle.fill" : "info.circle"
                                )
                                Text(showingMetadata ? "Bilgileri Gizle" : "Bilgileri Göster")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                        }

                        if showingMetadata {
                            metadataComparison
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        // Navigasyon butonları
                        HStack(spacing: 20) {
                            Button(action: previousPair) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Önceki")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(currentIndex > 0 ? Color.blue : Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(currentIndex == 0)

                            Button(action: nextPair) {
                                HStack {
                                    Text("Sonraki")
                                    Image(systemName: "chevron.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    nextIndex < photos.count - 1
                                        ? Color.blue : Color.gray.opacity(0.3)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(nextIndex >= photos.count - 1)
                        }
                        .padding(.horizontal)

                        // Seçim butonları
                        HStack(spacing: 12) {
                            Button(action: {
                                selectPhoto(photos[currentIndex])
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Sol/Üst")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    selectedPhoto?.id == photos[currentIndex].id
                                        ? Color.green
                                        : Color.white.opacity(0.2)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                selectPhoto(photos[nextIndex])
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                    Text("Sağ/Alt")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    selectedPhoto?.id == photos[nextIndex].id
                                        ? Color.green
                                        : Color.white.opacity(0.2)
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button(action: {
                                selectBothPhotos()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "square.stack.fill")
                                        .font(.title2)
                                    Text("İkisi de")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.8))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("Karşılaştır")
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .onAppear {
            loadFullImages()
        }
    }

    // MARK: - Photo View
    @ViewBuilder
    private func photoView(for photo: PhotoItem, index: Int) -> some View {
        ZStack {
            if let fullImage = fullImages[photo.id] {
                Image(uiImage: fullImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let thumbnail = photo.thumbnail,
                let uiImage = thumbnail.toUIImage()
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }

            // Seçim göstergesi
            if selectedPhoto?.id == photo.id {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .padding(4)
                            )
                            .padding()
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Metadata Comparison
    private var metadataComparison: some View {
        HStack(spacing: 0) {
            // Sol/Üst fotoğraf metadata
            VStack(alignment: .leading, spacing: 6) {
                metadataRow(
                    icon: "calendar",
                    label: "Tarih",
                    value: formatDate(photos[currentIndex].creationDate)
                )
                metadataRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    label: "Boyut",
                    value:
                        "\(photos[currentIndex].pixelWidth) × \(photos[currentIndex].pixelHeight)"
                )
                metadataRow(
                    icon: "doc",
                    label: "Dosya",
                    value: formatFileSize(photos[currentIndex])
                )
                if let location = photos[currentIndex].location {
                    metadataRow(
                        icon: "location.fill",
                        label: "Konum",
                        value: "Var"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            Spacer().frame(width: 8)

            // Sağ/Alt fotoğraf metadata
            VStack(alignment: .leading, spacing: 6) {
                metadataRow(
                    icon: "calendar",
                    label: "Tarih",
                    value: formatDate(photos[nextIndex].creationDate)
                )
                metadataRow(
                    icon: "arrow.up.left.and.arrow.down.right",
                    label: "Boyut",
                    value: "\(photos[nextIndex].pixelWidth) × \(photos[nextIndex].pixelHeight)"
                )
                metadataRow(
                    icon: "doc",
                    label: "Dosya",
                    value: formatFileSize(photos[nextIndex])
                )
                if let location = photos[nextIndex].location {
                    metadataRow(
                        icon: "location.fill",
                        label: "Konum",
                        value: "Var"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }

    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Text(value)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: - Actions
    private func previousPair() {
        guard currentIndex > 0 else { return }
        withAnimation {
            currentIndex -= 1
            nextIndex = min(currentIndex + 1, photos.count - 1)
            selectedPhoto = nil
        }
        loadFullImages()
    }

    private func nextPair() {
        guard nextIndex < photos.count - 1 else { return }
        withAnimation {
            currentIndex = nextIndex
            nextIndex = min(currentIndex + 1, photos.count - 1)
            selectedPhoto = nil
        }
        loadFullImages()
    }

    private func selectPhoto(_ photo: PhotoItem) {
        withAnimation {
            selectedPhoto = photo
        }
        onSelect(photo)
    }

    private func selectBothPhotos() {
        // İkisi de seçildiğinde hiçbirini silme
        selectedPhoto = nil
    }

    // MARK: - Helper Functions
    private func loadFullImages() {
        let photosToLoad = [photos[currentIndex], photos[nextIndex]]

        for photo in photosToLoad {
            guard fullImages[photo.id] == nil else { continue }

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
                    DispatchQueue.main.async {
                        fullImages[photo.id] = image
                    }
                }
            }
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Bilinmiyor" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatFileSize(_ photo: PhotoItem) -> String {
        if let resource = PHAssetResource.assetResources(for: photo.asset).first,
            let fileSize = resource.value(forKey: "fileSize") as? Int64
        {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: fileSize)
        }
        // Fallback tahmini
        let estimatedSize = Int64(photo.pixelWidth * photo.pixelHeight) / 5
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "~\(formatter.string(fromByteCount: estimatedSize))"
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
