//
//  PhotoLibraryManager.swift
//  Similarly
//
//  Created by AI Agent
//

import Combine
import Foundation
import Photos
import SwiftData
import os

private let logger = Logger(subsystem: "com.similarly.app", category: "library")

/// Veritabanından okunan analiz verisinin hafif kopyası
private struct ProcessedPhotoData {
    let featurePrint: [Float]?
    let blurScore: Double?
    let brightnessScore: Double?
    let cachedFileSize: Int64?
    let modificationDate: Date?
    let analysisVersion: Int
    let qualityDismissed: Bool

    init(from photo: ProcessedPhoto) {
        self.featurePrint = photo.featurePrint.map(FeaturePrintCoding.decode)
        self.blurScore = photo.blurScore
        self.brightnessScore = photo.brightnessScore
        self.cachedFileSize = photo.cachedFileSize
        self.modificationDate = photo.modificationDate
        self.analysisVersion = photo.analysisVersion
        self.qualityDismissed = photo.qualityDismissed
    }
}

/// Fotoğraf kütüphanesine erişim ve işlemleri yöneten sınıf
@MainActor
final class PhotoLibraryManager: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published private(set) var photos: [PhotoItem] = []
    @Published private(set) var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published private(set) var isProcessing = false
    @Published private(set) var processingProgress: Double = 0.0
    @Published var errorMessage: String?

    /// Asset kimliğine göre Vision feature print vektörleri. `PhotoItem`'ı hafif tutmak için ayrı saklanır.
    private(set) var featurePrints: [String: [Float]] = [:]

    /// Fotoğraflar kütüphaneden kaldırıldığında (uygulama içi silme veya dış değişiklik) çağrılır.
    var onPhotosRemoved: ((Set<String>) -> Void)?

    var modelContext: ModelContext?

    private let analyzer = PhotoAnalyzer()
    private var fetchResult: PHFetchResult<PHAsset>?
    private var indexByID: [String: Int] = [:]
    private var isObservingLibrary = false
    private var pendingAnalysisTask: Task<Void, Never>?
    private var needsAnotherAnalysisPass = false

    /// Tek seferde analiz edilip kaydedilen fotoğraf sayısı
    private static let analysisBatchSize = 32

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        super.init()
        checkAuthorizationStatus()
    }

    deinit {
        // PhotoKit gözlemcileri zayıf tutar; yine de kaydı temizle.
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestAccessAndFetch() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        authorizationStatus = status

        if status == .authorized || status == .limited {
            await fetchAssets()
        } else {
            setError(L10n.t("errors.photo_access_denied"))
        }
    }

    // MARK: - Fetching Assets

    private static func makeFetchOptions() -> PHFetchOptions {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.includeAssetSourceTypes = [.typeUserLibrary, .typeiTunesSynced, .typeCloudShared]
        fetchOptions.predicate = NSPredicate(
            format: "mediaType = %d OR mediaType = %d",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaType.video.rawValue
        )
        return fetchOptions
    }

    /// Kütüphaneyi yükler, önceki analizleri veritabanından eşler ve eksik analizleri tamamlar.
    func fetchAssets() async {
        guard !isProcessing else { return }
        isProcessing = true
        processingProgress = 0.0
        pendingAnalysisTask?.cancel()
        pendingAnalysisTask = nil
        needsAnotherAnalysisPass = false

        let cached = loadProcessedPhotosFromDatabase()
        let result = PHAsset.fetchAssets(with: Self.makeFetchOptions())
        fetchResult = result
        registerChangeObserverIfNeeded()

        var items: [PhotoItem] = []
        items.reserveCapacity(result.count)
        var vectors: [String: [Float]] = [:]
        result.enumerateObjects { asset, _, _ in
            items.append(self.makeItem(for: asset, cached: cached, vectors: &vectors))
        }

        // Tek seferde yayınla (her batch'te tüm diziyi yeniden yayınlamak O(n²) idi).
        featurePrints = vectors
        setPhotos(items)

        let imageCount = items.filter { $0.mediaType == .image }.count
        let analyzedCount = items.filter { $0.hasAnalysis }.count
        logger.info("Loaded \(items.count) assets (\(imageCount) images, \(analyzedCount) already analyzed)")

        // Analizi aynı akışta bekle; böylece benzerlik analizi eksik verilerle başlamaz.
        await processPendingPhotos()

        if authorizationStatus != .limited {
            cleanupOrphanedProcessedPhotos()
        }

        isProcessing = false
        processingProgress = 1.0
    }

    private func makeItem(
        for asset: PHAsset,
        cached: [String: ProcessedPhotoData],
        vectors: inout [String: [Float]]
    ) -> PhotoItem {
        guard let data = cached[asset.localIdentifier],
            data.modificationDate == asset.modificationDate
        else {
            return PhotoItem(asset: asset)
        }

        let isCurrent = data.analysisVersion >= AnalysisVersion.current && data.featurePrint != nil
        if isCurrent, let vector = data.featurePrint {
            vectors[asset.localIdentifier] = vector
        }
        return PhotoItem(
            asset: asset,
            blurScore: isCurrent ? data.blurScore : nil,
            brightnessScore: isCurrent ? data.brightnessScore : nil,
            cachedFileSize: data.cachedFileSize,
            hasAnalysis: isCurrent,
            qualityDismissed: data.qualityDismissed
        )
    }

    private func setPhotos(_ newPhotos: [PhotoItem]) {
        photos = newPhotos
        rebuildIndex()
    }

    private func rebuildIndex() {
        indexByID = Dictionary(
            photos.enumerated().map { ($1.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    // MARK: - Processing Photos

    /// Analizi eksik veya eski sürümlü fotoğrafları arka planda analiz eder.
    private func processPendingPhotos() async {
        let pendingIDs = photos
            .filter { $0.mediaType == .image && !$0.hasAnalysis }
            .map(\.id)
        guard !pendingIDs.isEmpty else { return }

        logger.info("Analyzing \(pendingIDs.count) photos")
        let total = Double(pendingIDs.count)
        var completed = 0
        var succeeded = 0

        for start in stride(from: 0, to: pendingIDs.count, by: Self.analysisBatchSize) {
            if Task.isCancelled { break }
            let batch = Array(pendingIDs[start..<min(start + Self.analysisBatchSize, pendingIDs.count)])
            let results = await analyzer.analyze(localIdentifiers: batch)
            apply(results)
            succeeded += results.count

            completed += batch.count
            processingProgress = Double(completed) / total
        }

        logger.info("Photo analysis finished: \(succeeded)/\(pendingIDs.count) succeeded")
    }

    /// Analiz sonuçlarını kimliğe göre uygular ve tek bir kayıtla veritabanına yazar.
    private func apply(_ results: [PhotoAnalysisResult]) {
        guard !results.isEmpty else { return }

        var updated = photos
        var persisted: [PhotoItem] = []
        for result in results {
            // Kütüphane bu arada değişmiş olabilir: yalnızca kimliği eşleşen öğeyi güncelle.
            guard let index = indexByID[result.id], index < updated.count, updated[index].id == result.id else {
                continue
            }
            updated[index].blurScore = result.blurScore
            updated[index].brightnessScore = result.brightnessScore
            updated[index].hasAnalysis = true
            featurePrints[result.id] = result.featurePrint
            persisted.append(updated[index])
        }
        photos = updated

        saveProcessedPhotos(persisted)
    }

    // MARK: - Database Operations

    private func loadProcessedPhotosFromDatabase() -> [String: ProcessedPhotoData] {
        guard let context = modelContext else { return [:] }

        do {
            let results = try context.fetch(FetchDescriptor<ProcessedPhoto>())
            var dict: [String: ProcessedPhotoData] = [:]
            dict.reserveCapacity(results.count)
            for photo in results {
                dict[photo.id] = ProcessedPhotoData(from: photo)
            }
            return dict
        } catch {
            setError(L10n.f("errors.load_previous_analysis_failed", error.localizedDescription))
            return [:]
        }
    }

    private func fetchRecords(ids: [String], in context: ModelContext) throws -> [String: ProcessedPhoto] {
        let descriptor = FetchDescriptor<ProcessedPhoto>(
            predicate: #Predicate { ids.contains($0.id) }
        )
        let records = try context.fetch(descriptor)
        return Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Bir grup fotoğrafı tek fetch ve tek `save()` ile kaydeder.
    private func saveProcessedPhotos(_ items: [PhotoItem]) {
        guard let context = modelContext, !items.isEmpty else { return }

        do {
            let existing = try fetchRecords(ids: items.map(\.id), in: context)
            for item in items {
                let vector = featurePrints[item.id].map(FeaturePrintCoding.encode)
                if let record = existing[item.id] {
                    record.featurePrint = vector
                    record.blurScore = item.blurScore
                    record.brightnessScore = item.brightnessScore
                    record.cachedFileSize = item.cachedFileSize
                    record.creationDate = item.creationDate
                    record.modificationDate = item.modificationDate
                    record.lastProcessedDate = Date()
                    record.analysisVersion = AnalysisVersion.current
                    record.qualityDismissed = item.qualityDismissed
                } else {
                    context.insert(
                        ProcessedPhoto(
                            id: item.id,
                            featurePrint: vector,
                            blurScore: item.blurScore,
                            brightnessScore: item.brightnessScore,
                            cachedFileSize: item.cachedFileSize,
                            creationDate: item.creationDate,
                            modificationDate: item.modificationDate,
                            qualityDismissed: item.qualityDismissed
                        )
                    )
                }
            }
            try context.save()
        } catch {
            setError(L10n.f("errors.save_analysis_failed", error.localizedDescription))
        }
    }

    private func deleteRecords(ids: Set<String>) {
        guard let context = modelContext, !ids.isEmpty else { return }
        do {
            let records = try fetchRecords(ids: Array(ids), in: context)
            records.values.forEach { context.delete($0) }
            if !records.isEmpty {
                try context.save()
            }
        } catch {
            logger.error("Failed to delete records: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Kütüphanede artık bulunmayan fotoğrafların kayıtlarını siler.
    /// Sınırlı erişimde çağrılmamalıdır; aksi halde seçilmeyen fotoğrafların analizi kaybolur.
    private func cleanupOrphanedProcessedPhotos() {
        guard let context = modelContext else { return }

        let currentPhotoIds = Set(photos.map(\.id))
        do {
            var descriptor = FetchDescriptor<ProcessedPhoto>()
            descriptor.propertiesToFetch = [\.id]
            let orphaned = try context.fetch(descriptor).filter { !currentPhotoIds.contains($0.id) }
            guard !orphaned.isEmpty else { return }

            orphaned.forEach { context.delete($0) }
            try context.save()
            logger.info("Deleted \(orphaned.count) orphaned analysis records")
        } catch {
            logger.error("Orphan cleanup failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Quality Dismissal

    /// Fotoğrafları "kalite sorunu yok" olarak işaretler ve bunu kalıcı hale getirir.
    func setQualityDismissed(ids: Set<String>) {
        guard !ids.isEmpty else { return }

        var updated = photos
        for id in ids {
            if let index = indexByID[id], index < updated.count, updated[index].id == id {
                updated[index].qualityDismissed = true
            }
        }
        photos = updated

        guard let context = modelContext else { return }
        do {
            let records = try fetchRecords(ids: Array(ids), in: context)
            records.values.forEach { $0.qualityDismissed = true }
            try context.save()
        } catch {
            setError(L10n.f("errors.save_analysis_failed", error.localizedDescription))
        }
    }

    // MARK: - Delete Photos

    /// Fotoğrafları kütüphaneden siler. Kullanıcı sistem onayını iptal ederse `false` döner.
    @discardableResult
    func deletePhotos(_ items: [PhotoItem]) async throws -> Bool {
        let ids = items.map(\.id)
        guard !ids.isEmpty else { return false }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
                PHAssetChangeRequest.deleteAssets(assets)
            }
        } catch let error as PHPhotosError where error.code == .userCancelled {
            return false
        }

        removeLocally(ids: Set(ids))
        logger.info("Deleted \(ids.count) photos")
        return true
    }

    /// Fotoğrafları yerel listelerden, vektör deposundan ve veritabanından çıkarır.
    private func removeLocally(ids: Set<String>) {
        let present = ids.filter { indexByID[$0] != nil }
        guard !present.isEmpty else { return }

        setPhotos(photos.filter { !present.contains($0.id) })
        present.forEach { featurePrints[$0] = nil }
        deleteRecords(ids: present)
        onPhotosRemoved?(present)
    }

    // MARK: - Library Changes

    private func registerChangeObserverIfNeeded() {
        guard !isObservingLibrary else { return }
        PHPhotoLibrary.shared().register(self)
        isObservingLibrary = true
    }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        Task { @MainActor in
            self.handleLibraryChange(changeInstance)
        }
    }

    /// Uygulama dışında yapılan ekleme/silme/düzenlemeleri listeye yansıtır ve yeni fotoğrafları analiz eder.
    private func handleLibraryChange(_ change: PHChange) {
        guard let currentResult = fetchResult,
            let details = change.changeDetails(for: currentResult)
        else { return }
        fetchResult = details.fetchResultAfterChanges

        let removedIDs = Set(details.removedObjects.map(\.localIdentifier))
        let changedAssets = details.changedObjects
        let insertedAssets = details.insertedObjects
        guard !removedIDs.isEmpty || !changedAssets.isEmpty || !insertedAssets.isEmpty else { return }

        if !removedIDs.isEmpty {
            removeLocally(ids: removedIDs)
        }

        var updated = photos
        var needsSort = false
        var metadataOnlyChanges: [PhotoItem] = []
        for asset in changedAssets {
            guard let index = indexByID[asset.localIdentifier], index < updated.count else { continue }
            let old = updated[index]
            // Fotoğraflar uygulaması favori, yüz tanıma vb. için asset'lere sık dokunur;
            // yalnızca görüntü içeriği değiştiyse (düzenleme) analizi sıfırla.
            let contentChanged = change.changeDetails(for: asset)?.assetContentChanged ?? false
            updated[index] = PhotoItem(
                asset: asset,
                blurScore: contentChanged ? nil : old.blurScore,
                brightnessScore: contentChanged ? nil : old.brightnessScore,
                cachedFileSize: old.cachedFileSize,
                hasAnalysis: contentChanged ? false : old.hasAnalysis,
                qualityDismissed: contentChanged ? false : old.qualityDismissed
            )
            if contentChanged {
                featurePrints[asset.localIdentifier] = nil
            } else if old.hasAnalysis, old.modificationDate != asset.modificationDate {
                metadataOnlyChanges.append(updated[index])
            }
        }
        for asset in insertedAssets where indexByID[asset.localIdentifier] == nil {
            updated.append(PhotoItem(asset: asset))
            needsSort = true
        }
        if needsSort {
            updated.sort { ($0.creationDate ?? .distantPast) > ($1.creationDate ?? .distantPast) }
        }
        setPhotos(updated)

        // Kayıtlı değişiklik tarihini güncelle; aksi halde sonraki açılışta gereksiz yeniden analiz yapılır.
        updateStoredModificationDates(metadataOnlyChanges)

        // İşlem sürmüyorsa yeni/değişen fotoğrafları analiz et.
        guard !isProcessing else { return }
        scheduleBackgroundAnalysis()
    }

    /// Art arda gelen değişiklikleri birleştirir: çalışan analizi iptal etmek yerine
    /// bitince bir tur daha çalıştırır (iptal, yarım kalan batch'in sonuçlarını kaybettiriyordu).
    private func scheduleBackgroundAnalysis() {
        guard pendingAnalysisTask == nil else {
            needsAnotherAnalysisPass = true
            return
        }
        pendingAnalysisTask = Task {
            // Kısa bir bekleme ile peş peşe gelen değişiklik bildirimlerini topla.
            try? await Task.sleep(for: .seconds(1))
            repeat {
                needsAnotherAnalysisPass = false
                if Task.isCancelled { break }
                await processPendingPhotos()
            } while needsAnotherAnalysisPass
            pendingAnalysisTask = nil
        }
    }

    private func updateStoredModificationDates(_ items: [PhotoItem]) {
        guard let context = modelContext, !items.isEmpty else { return }
        do {
            let records = try fetchRecords(ids: items.map(\.id), in: context)
            for item in items {
                records[item.id]?.modificationDate = item.modificationDate
            }
            try context.save()
        } catch {
            logger.error("Failed to update modification dates: \(error.localizedDescription, privacy: .public)")
        }
    }

    func setError(_ message: String) {
        errorMessage = message
    }
}
