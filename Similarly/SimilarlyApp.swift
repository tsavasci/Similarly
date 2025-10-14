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
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: ProcessedPhoto.self)
    }
}
