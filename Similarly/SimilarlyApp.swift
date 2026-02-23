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

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.locale, Locale(identifier: L10n.resolvedLanguageCode(for: appLanguage)))
        }
        .modelContainer(for: ProcessedPhoto.self)
    }
}
