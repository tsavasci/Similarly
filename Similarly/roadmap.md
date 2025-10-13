Proje: IOS Similar Photo Cleaner
Amaç: Kullanıcı fotoğraf kütüphanesinden “benzer” fotoğrafları bulup listelemek ve kullanıcıya silme/işaretleme imkanı sunmak.
Hedef platform: IOS (öncelikli), iOS sonraki adım
Süre tahmini: 3 gün (AI agent ile prototip + test)
1️⃣ Fotoğraf Kütüphanesi Erişimi
Kütüphane: PhotoKit (IOS)
İzin: PHPhotoLibrary.requestAuthorization ile kullanıcıdan erişim
Veri: Asset metadata (EXIF, creationDate, GPS, orientation) ve thumbnail/full-size image
AI agent yapması gereken:
Tüm fotoğrafları fetch et
Metadata ve thumbnail bilgisini kaydet
Desteklenen format: JPG, PNG, HEIC, RAW
2️⃣ Benzer Fotoğraf Algoritması
a) Metadata Filtreleme (Ön filtre)
Tarih/saat yakınlığı → seri çekimler
GPS yakınlığı → aynı lokasyon fotoğrafları
Lens/ISO/exposure benzerliği → opsiyonel
b) Görüntü Bazlı Benzerlik
Histogram karşılaştırması (CoreImage/OpenCV)
Renk histogramları → %95+ eşleşme → benzer
Perceptual Hash (pHash/dHash/aHash)
Küçük değişiklikleri toleranslı hızlı kıyaslama
Opsiyonel: Feature matching (ORB, SIFT) → manzara/objeyi kontrol
AI agent yapması gereken:
Metadata ile aday grupları oluştur
Histogram ve pHash ile skor hesapla
Benzerlik eşiklerini ayarla (%95 gibi)
Opsiyonel: Batch processing / threading ile performans sağla
3️⃣ Kullanıcı Arayüzü
SwiftUI + AppKit
Benzer fotoğrafları side-by-side veya grid görünüm
Kullanıcı seçimi → sil / atla / mark et
AI agent yapması gereken:
Liste oluştur ve preview göster
Silme veya işaretleme fonksiyonlarını PhotoKit ile entegre et
4️⃣ Performans ve Optimizasyon
Thumbnail üzerinden hızlı kıyaslama
Büyük dataset’ler için background queue + batch işleme
AI agent için:
Önce metadata → sonra hash/histogram
Paralel işlem yapılabilir
5️⃣ AI Agent Görevleri Özet
Fotoğraf kütüphanesini fetch et ve metadata + thumbnail oluştur
Metadata bazlı ön filtre uygula (seri çekimler, lokasyon, tarih)
Histogram ve pHash ile benzerlik skorlarını hesapla
Benzer fotoğrafları grupla ve kullanıcıya preview olarak sun
Silme/işaretleme fonksiyonunu PhotoKit ile entegre et
Opsiyonel: CoreML/Feature matching ile detaylı kontrol
Batch processing ile 10K+ fotoğrafda performans sağla
6️⃣ Yayına Hazır MVP
Benzer fotoğrafları listeleyen IOS uygulaması
Thumbnail ve preview ile kullanıcı onayı
Metadata + histogram/pHash ile doğru eşleşmeler
3 gün içinde AI agent ile prototip tamamlanabilir

prototip Swift + PhotoKit + CoreImage/OpenCV iskeleti

//
// SimilarPhotoCleaner.swift
// MVP Prototype
//

import Foundation
import Photos
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Photo Model
struct PhotoItem: Identifiable {
    let id: String
    let asset: PHAsset
    var thumbnail: CIImage?
    var pHash: String?
    var histogram: [CGFloat]?
}

// MARK: - Photo Fetcher
class PhotoLibraryManager: ObservableObject {
    @Published var photos: [PhotoItem] = []

    func requestAccessAndFetch() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.fetchAssets()
            } else {
                print("Photo library access denied")
            }
        }
    }

    private func fetchAssets() {
        let fetchResult = PHAsset.fetchAssets(with: nil)
        var tempPhotos: [PhotoItem] = []

        fetchResult.enumerateObjects { asset, _, _ in
            let photo = PhotoItem(id: asset.localIdentifier, asset: asset)
            tempPhotos.append(photo)
        }

        DispatchQueue.main.async {
            self.photos = tempPhotos
            self.processPhotos()
        }
    }

    private func processPhotos() {
        let context = CIContext()
        let queue = DispatchQueue(label: "photo.processing", attributes: .concurrent)

        for i in photos.indices {
            queue.async {
                self.loadThumbnail(for: &self.photos[i], context: context)
                self.computePHash(for: &self.photos[i])
                self.computeHistogram(for: &self.photos[i])
            }
        }
    }

    // MARK: Thumbnail
    private func loadThumbnail(for photo: inout PhotoItem, context: CIContext) {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        PHImageManager.default().requestImage(for: photo.asset,
                                              targetSize: CGSize(width: 200, height: 200),
                                              contentMode: .aspectFit,
                                              options: options) { image, _ in
            if let uiImage = image, let ciImage = CIImage(image: uiImage) {
                photo.thumbnail = ciImage
            }
        }
    }

    // MARK: pHash (simplified)
    private func computePHash(for photo: inout PhotoItem) {
        guard let ciImage = photo.thumbnail else { return }
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ciImage
        filter.radius = 1.0

        guard let output = filter.outputImage else { return }

        // Simplified pHash placeholder (use real pHash lib for production)
        photo.pHash = String(output.hashValue)
    }

    // MARK: Histogram
    private func computeHistogram(for photo: inout PhotoItem) {
        guard let ciImage = photo.thumbnail else { return }
        let filter = CIFilter.histogramDisplay()
        filter.inputImage = ciImage

        guard let output = filter.outputImage else { return }
        // Flatten histogram pixels as CGFloat array
        let bitmap = CIContext().createCGImage(output, from: output.extent)
        photo.histogram = [CGFloat(output.hashValue % 256)] // placeholder
    }
}

// MARK: - Similarity Checker
class SimilarityManager {
    static func compare(_ photo1: PhotoItem, _ photo2: PhotoItem) -> Bool {
        // Compare pHash (simplified)
        if photo1.pHash == photo2.pHash { return true }

        // Compare histogram (simplified)
        if let h1 = photo1.histogram, let h2 = photo2.histogram {
            let score = zip(h1, h2).map { abs($0-$1) }.reduce(0, +)
            return score < 0.1 // placeholder threshold
        }

        return false
    }
}

// MARK: - SwiftUI Grid Preview
struct SimilarPhotoGrid: View {
    @ObservedObject var manager = PhotoLibraryManager()
    @State var similarPairs: [(PhotoItem, PhotoItem)] = []

    var body: some View {
        VStack {
            Button("Fetch & Process Photos") {
                manager.requestAccessAndFetch()
            }
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                    ForEach(manager.photos) { photo in
                        if let ciImage = photo.thumbnail {
                            Image(nsImage: NSImage(ciImage: ciImage))
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 150)
                        }
                    }
                }
            }
        }
        .onChange(of: manager.photos) { _ in
            findSimilarPhotos()
        }
    }

    private func findSimilarPhotos() {
        var pairs: [(PhotoItem, PhotoItem)] = []
        let photos = manager.photos
        for i in 0..<photos.count {
            for j in (i+1)..<photos.count {
                if SimilarityManager.compare(photos[i], photos[j]) {
                    pairs.append((photos[i], photos[j]))
                }
            }
        }
        similarPairs = pairs
        print("Found similar pairs: \(pairs.count)")
    }
}

// MARK: - App Entry
@main
struct SimilarPhotoApp: App {
    var body: some Scene {
        WindowGroup {
            SimilarPhotoGrid()
        }
    }
}

