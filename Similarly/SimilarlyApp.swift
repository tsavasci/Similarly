//
//  SimilarlyApp.swift
//  Similarly
//
//  Created by Tamer Savaşçı on 13.10.2025.
//

import SwiftData
import SwiftUI

@main
struct SimilarlyApp: App {
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    let modelContainer: ModelContainer

    private var screenshotScreen: Int? {
        guard let idx = CommandLine.arguments.firstIndex(of: "--screenshot"),
              idx + 1 < CommandLine.arguments.count,
              let screen = Int(CommandLine.arguments[idx + 1]) else {
            return nil
        }
        return screen
    }

    init() {
        // Ensure Application Support directory exists before creating ModelContainer
        let fileManager = FileManager.default
        if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        // Configure ModelContainer with proper error handling and fallback
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
                // Disk kurtarılamazsa bellek içi (in-memory) kapsayıcıya düşerek uygulamanın çökmesini engelle
                let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
                if let memoryContainer = try? ModelContainer(for: ProcessedPhoto.self, configurations: memoryConfig) {
                    self.modelContainer = memoryContainer
                } else {
                    fatalError("Critical: Could not initialize ModelContainer: \(error)")
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            if let screen = screenshotScreen {
                ScreenshotHostView(screenNumber: screen)
                    .environment(\.locale, L10n.locale(forLanguage: L10n.resolvedLanguageCode(for: appLanguage)))
            } else {
                MainView()
                    .environment(\.locale, L10n.locale(forLanguage: L10n.resolvedLanguageCode(for: appLanguage)))
            }
        }
        .modelContainer(modelContainer)
    }
}
