//
//  SimilarlyApp.swift
//  Similarly
//
//  Created by Tamer Savaşcı on 13.10.2025.
//

import SwiftData
import SwiftUI

@main
struct SimilarlyApp: App {
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    
    let modelContainer: ModelContainer
    
    init() {
        // Ensure Application Support directory exists before creating ModelContainer
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }
        
        // Configure ModelContainer with proper error handling
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            self.modelContainer = try ModelContainer(for: ProcessedPhoto.self, configurations: config)
        } catch {
            // Veritabanı yalnızca analiz önbelleğidir: şema geçişi başarısız olursa silip yeniden oluştur.
            let storeURL = config.url
            for suffix in ["", "-shm", "-wal"] {
                try? fileManager.removeItem(at: URL(fileURLWithPath: storeURL.path + suffix))
            }
            do {
                self.modelContainer = try ModelContainer(for: ProcessedPhoto.self, configurations: config)
            } catch {
                fatalError("Could not initialize ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.locale, L10n.locale(forLanguage: L10n.resolvedLanguageCode(for: appLanguage)))
        }
        .modelContainer(modelContainer)
    }
}
