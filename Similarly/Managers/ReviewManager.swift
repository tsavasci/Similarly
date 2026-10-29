//
//  ReviewManager.swift
//  Similarly
//
//  Akıllı App Store puanlama isteği yöneticisi.
//  Yalnızca kullanıcının uygulamadan gerçek değer aldığı başarılı temizleme işlemlerinden sonra,
//  sürüm başına en fazla 1 kez ve cooldown süresiyle tetiklenir.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
final class ReviewManager {
    static let shared = ReviewManager()

    private let userDefaults: UserDefaults

    // Anahtarlar
    private let keyLastReviewDate = "review_last_prompt_date"
    private let keyLastPromptedVersion = "review_last_prompted_version"
    private let keyLifetimePhotosDeleted = "review_lifetime_photos_deleted"
    private let keyLifetimeBytesSaved = "review_lifetime_bytes_saved"
    private let keySuccessfulCleanCount = "review_successful_clean_count"

    // Kurallar
    private let cooldownDays: Double = 30
    private let minPhotosForSingleCleanPrompt: Int = 3
    private let minBytesForSingleCleanPrompt: Int64 = 15 * 1024 * 1024 // 15 MB
    private let minTotalCleansRequired: Int = 2

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Başarılı bir temizlik işleminden sonra çağrılır.
    /// - Parameters:
    ///   - deletedPhotosCount: Bu işlemde silinen fotoğraf adedi
    ///   - savedBytes: Bu işlemde kazanılan tahmini/gerçek bayt miktarı
    func recordSuccessfulClean(deletedPhotosCount: Int, savedBytes: Int64) {
        guard deletedPhotosCount > 0 else { return }

        let currentLifetimePhotos = userDefaults.integer(forKey: keyLifetimePhotosDeleted) + deletedPhotosCount
        let currentLifetimeBytes = (userDefaults.object(forKey: keyLifetimeBytesSaved) as? Int64 ?? 0) + savedBytes
        let currentCleans = userDefaults.integer(forKey: keySuccessfulCleanCount) + 1

        userDefaults.set(currentLifetimePhotos, forKey: keyLifetimePhotosDeleted)
        userDefaults.set(currentLifetimeBytes, forKey: keyLifetimeBytesSaved)
        userDefaults.set(currentCleans, forKey: keySuccessfulCleanCount)

        checkAndRequestReview(recentDeletedCount: deletedPhotosCount, recentSavedBytes: savedBytes)
    }

    /// İnceleme isteminin gösterilip gösterilmeyeceğini kontrol eder ve uygunsa StoreKit'i tetikler.
    func checkAndRequestReview(recentDeletedCount: Int, recentSavedBytes: Int64) {
        guard shouldRequestReview(recentDeletedCount: recentDeletedCount, recentSavedBytes: recentSavedBytes) else {
            return
        }

        // Güncel sürümü ve tarihi kaydet
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        userDefaults.set(Date().timeIntervalSince1970, forKey: keyLastReviewDate)
        userDefaults.set(currentVersion, forKey: keyLastPromptedVersion)

        // Kullanıcı deneyimini bölmemek için kısa bir gecikmeyle çağır
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: {
                $0.activationState == .foregroundActive
            }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: windowScene)
            }
        }
    }

    /// Kural tabanlı uygunluk değerlendirmesi (Test edilebilir mantık).
    func shouldRequestReview(recentDeletedCount: Int, recentSavedBytes: Int64, currentDate: Date = Date()) -> Bool {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let lastPromptedVersion = userDefaults.string(forKey: keyLastPromptedVersion)

        // 1. Kural: Bu sürümde zaten gösterilmiş mi?
        if lastPromptedVersion == currentVersion {
            return false
        }

        // 2. Kural: Cooldown kontrolü (Son gösterimden en az 30 gün geçmiş olmalı)
        if let lastTimestamp = userDefaults.object(forKey: keyLastReviewDate) as? Double {
            let lastDate = Date(timeIntervalSince1970: lastTimestamp)
            let daysSinceLast = currentDate.timeIntervalSince(lastDate) / (60 * 60 * 24)
            if daysSinceLast < cooldownDays {
                return false
            }
        }

        // 3. Kural: Anlamlı değer alma kriteri
        // Ya tek seferde yüksek etki (örn: >= 5 fotoğraf veya >= 25MB)
        // Ya da en az 2 farklı başarılı temizlik ve toplamda >= 5 fotoğraf
        let isHighImpactClean = recentDeletedCount >= minPhotosForSingleCleanPrompt || recentSavedBytes >= minBytesForSingleCleanPrompt
        let totalCleans = userDefaults.integer(forKey: keySuccessfulCleanCount)
        let totalPhotos = userDefaults.integer(forKey: keyLifetimePhotosDeleted)
        let isExperiencedUser = totalCleans >= minTotalCleansRequired && totalPhotos >= 5

        return isHighImpactClean || isExperiencedUser
    }

    /// App Store'da uygulamaya yorum yapma sayfasına doğrudan yönlendirir.
    static func openAppStoreReview() {
        let appID = "6753979293"
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // İstatistik Okuyucuları
    var lifetimePhotosDeleted: Int {
        userDefaults.integer(forKey: keyLifetimePhotosDeleted)
    }

    var lifetimeBytesSaved: Int64 {
        userDefaults.object(forKey: keyLifetimeBytesSaved) as? Int64 ?? 0
    }
}
