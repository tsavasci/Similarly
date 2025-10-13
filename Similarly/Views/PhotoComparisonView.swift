//
//  PhotoComparisonView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI

/// Tinder tarzı swipe ile fotoğraf karşılaştırma görünümü
struct PhotoComparisonView: View {
    let photos: [PhotoItem]
    let initialIndex: Int
    let onSelect: (PhotoItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var offset: CGSize = .zero
    @State private var selectedPhotos = Set<String>()
    @State private var deletedPhotos = Set<String>()
    @State private var fullImages: [String: UIImage] = [:]
    @State private var showingMetadata = false
    @State private var rotation: Double = 0

    init(photos: [PhotoItem], initialIndex: Int = 0, onSelect: @escaping (PhotoItem) -> Void) {
        self.photos = photos
        self.initialIndex = initialIndex
        self.onSelect = onSelect
        _currentIndex = State(initialValue: initialIndex)
    }

    var remainingPhotos: [PhotoItem] {
        photos.filter { !deletedPhotos.contains($0.id) }
    }

    var currentPhoto: PhotoItem? {
        guard currentIndex < remainingPhotos.count else { return nil }
        return remainingPhotos[currentIndex]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Üst bilgi
                    VStack(spacing: 8) {
                        Text("\(remainingPhotos.count - currentIndex) fotoğraf kaldı")
                            .font(.headline)
                            .foregroundColor(.primary)

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 4)
                                    .cornerRadius(2)

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width
                                            * CGFloat(currentIndex)
                                            / CGFloat(max(remainingPhotos.count - 1, 1)),
                                        height: 4
                                    )
                                    .cornerRadius(2)
                            }
                        }
                        .frame(height: 4)
                        .padding(.horizontal)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    Spacer()

                    // Ana kart alanı
                    ZStack {
                        if currentPhoto == nil {
                            // Tüm fotoğraflar değerlendirildi
                            completionView
                        } else {
                            // Kart stack
                            ForEach(
                                Array(
                                    remainingPhotos[
                                        currentIndex..<min(currentIndex + 2, remainingPhotos.count)
                                    ]
                                    .enumerated()), id: \.element.id
                            ) { index, photo in
                                photoCard(for: photo, stackIndex: index)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Alt kontroller
                    VStack(spacing: 16) {
                        // Metadata toggle
                        if currentPhoto != nil {
                            Button(action: {
                                withAnimation {
                                    showingMetadata.toggle()
                                }
                            }) {
                                HStack {
                                    Image(
                                        systemName: showingMetadata
                                            ? "info.circle.fill" : "info.circle"
                                    )
                                    Text(showingMetadata ? "Bilgileri Gizle" : "Bilgileri Göster")
                                }
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                            }

                            if showingMetadata, let photo = currentPhoto {
                                metadataView(for: photo)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }

                        // Swipe butonları
                        if currentPhoto != nil {
                            HStack(spacing: 40) {
                                // Sil butonu
                                Button(action: {
                                    swipeLeft()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 30, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 70, height: 70)
                                            .background(
                                                Circle()
                                                    .fill(Color.red)
                                                    .shadow(color: .red.opacity(0.3), radius: 10)
                                            )

                                        Text("Sil")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }

                                // Geri al butonu
                                Button(action: {
                                    undoLastAction()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.uturn.backward")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 60, height: 60)
                                            .background(
                                                Circle()
                                                    .fill(Color.gray.opacity(0.6))
                                                    .shadow(
                                                        color: .gray.opacity(0.3), radius: 10)
                                            )

                                        Text("Geri")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .disabled(currentIndex == 0 && deletedPhotos.isEmpty)
                                .opacity(currentIndex == 0 && deletedPhotos.isEmpty ? 0.5 : 1)

                                // Tut butonu
                                Button(action: {
                                    swipeRight()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 30, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 70, height: 70)
                                            .background(
                                                Circle()
                                                    .fill(Color.green)
                                                    .shadow(color: .green.opacity(0.3), radius: 10)
                                            )

                                        Text("Tut")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        finalizeSelections()
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }

                ToolbarItem(placement: .principal) {
                    Text("Karşılaştır")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            loadImages()
        }
    }

    // MARK: - Photo Card
    @ViewBuilder
    private func photoCard(for photo: PhotoItem, stackIndex: Int) -> some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    // Fotoğraf
                    if let fullImage = fullImages[photo.id] {
                        Image(uiImage: fullImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                    } else if let thumbnail = photo.thumbnail,
                        let uiImage = thumbnail.toUIImage()
                    {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }

                    // Swipe overlay (sadece en üstteki kart için)
                    if stackIndex == 0 {
                        // Sil overlay (kırmızı)
                        if offset.width < -50 {
                            Color.red.opacity(Double(abs(offset.width) / 150))
                                .overlay(
                                    VStack {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white)
                                        Text("SİL")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                )
                        }

                        // Tut overlay (yeşil)
                        if offset.width > 50 {
                            Color.green.opacity(Double(offset.width / 150))
                                .overlay(
                                    VStack {
                                        Image(systemName: "heart.circle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.white)
                                        Text("TUT")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                )
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            .offset(stackIndex == 0 ? offset : .zero)
            .scaleEffect(stackIndex == 0 ? 1 : 0.95)
            .rotationEffect(.degrees(stackIndex == 0 ? rotation : 0))
            .opacity(stackIndex == 0 ? 1 : 0.5)
            .gesture(
                stackIndex == 0
                    ? DragGesture()
                        .onChanged { gesture in
                            offset = gesture.translation
                            rotation = Double(gesture.translation.width / 20)
                        }
                        .onEnded { gesture in
                            if abs(gesture.translation.width) > 100 {
                                // Swipe tamamlandı
                                if gesture.translation.width > 0 {
                                    swipeRight()
                                } else {
                                    swipeLeft()
                                }
                            } else {
                                // Swipe iptal, kartı geri getir
                                withAnimation(.spring()) {
                                    offset = .zero
                                    rotation = 0
                                }
                            }
                        }
                    : nil
            )
        }
        .padding(.vertical, 40)
    }

    // MARK: - Metadata View
    private func metadataView(for photo: PhotoItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(formatDate(photo.creationDate))
                    .font(.subheadline)
            }

            HStack {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text("\(photo.pixelWidth) × \(photo.pixelHeight)")
                    .font(.subheadline)
            }

            HStack {
                Image(systemName: "doc")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(formatFileSize(photo))
                    .font(.subheadline)
            }

            if photo.location != nil {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    Text("Konum var")
                        .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Tamamlandı!")
                .font(.title)
                .fontWeight(.bold)

            Text("Tüm fotoğrafları değerlendirdin")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(selectedPhotos.count) fotoğraf tutulacak")
                }

                HStack {
                    Image(systemName: "trash.circle.fill")
                        .foregroundColor(.red)
                    Text("\(deletedPhotos.count) fotoğraf silinecek")
                }
            }
            .font(.headline)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)

            Button(action: {
                finalizeSelections()
                dismiss()
            }) {
                Text("Tamam")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }

    // MARK: - Actions
    private func swipeLeft() {
        guard let photo = currentPhoto else { return }

        withAnimation(.spring()) {
            offset = CGSize(width: -500, height: 0)
            rotation = -20
        }

        // Fotoğrafı silinecekler listesine ekle
        deletedPhotos.insert(photo.id)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            offset = .zero
            rotation = 0
            currentIndex += 1
            loadImages()
        }
    }

    private func swipeRight() {
        guard let photo = currentPhoto else { return }

        withAnimation(.spring()) {
            offset = CGSize(width: 500, height: 0)
            rotation = 20
        }

        // Fotoğrafı tutulacaklar listesine ekle
        selectedPhotos.insert(photo.id)
        onSelect(photo)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            offset = .zero
            rotation = 0
            currentIndex += 1
            loadImages()
        }
    }

    private func undoLastAction() {
        guard currentIndex > 0 else { return }

        withAnimation(.spring()) {
            currentIndex -= 1
            let previousPhoto = remainingPhotos[currentIndex]
            deletedPhotos.remove(previousPhoto.id)
            selectedPhotos.remove(previousPhoto.id)
        }
    }

    private func finalizeSelections() {
        // Seçili olmayanları otomatik olarak silinecekler listesine ekle
        for photo in photos {
            if !selectedPhotos.contains(photo.id) && !deletedPhotos.contains(photo.id) {
                deletedPhotos.insert(photo.id)
            }
        }
    }

    // MARK: - Helper Functions
    private func loadImages() {
        // Mevcut ve bir sonraki fotoğrafı yükle
        let photosToLoad = remainingPhotos[
            currentIndex..<min(currentIndex + 2, remainingPhotos.count)]

        for photo in photosToLoad {
            guard fullImages[photo.id] == nil else { continue }

            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestImage(
                for: photo.asset,
                targetSize: CGSize(width: 1024, height: 1024),
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
