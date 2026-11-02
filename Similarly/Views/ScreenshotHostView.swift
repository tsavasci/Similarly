//
//  ScreenshotHostView.swift
//  Similarly
//

import Photos
import SwiftData
import SwiftUI

enum ScreenshotDestination: Hashable {
    case similarList
    case duplicateDetail
    case similarDetail
    case quality(Int)
}

struct ScreenshotHostView: View {
    let screenNumber: Int
    @StateObject private var photoManager = PhotoLibraryManager()
    @StateObject private var similarityManager = SimilarityManager()
    @Environment(\.modelContext) private var modelContext
    @State private var isReady = false
    @State private var navPath: [ScreenshotDestination] = []

    var body: some View {
        Group {
            if isReady {
                content
            } else {
                Color(uiColor: .systemBackground)
            }
        }
        .task {
            photoManager.modelContext = modelContext
            photoManager.onPhotosRemoved = { ids in
                similarityManager.removePhotos(ids: ids)
            }

            if screenNumber == 1 || screenNumber == 2 || screenNumber == 10 {
                isReady = true
                return
            }

            // Fetch library assets
            await photoManager.requestAccessAndFetch()

            if screenNumber == 3 {
                isReady = true
                return
            }

            // Analyze photos for screens 4..9
            await similarityManager.findSimilarPhotos(
                from: photoManager.photos,
                featurePrints: photoManager.featurePrints
            )

            // Ensure rich sample groups exist for screenshot fidelity
            ensureSampleGroups()

            // Setup navigation paths for screens that are pushed
            switch screenNumber {
            case 4:
                navPath = [.similarList]
            case 5:
                navPath = [.similarList, .duplicateDetail]
            case 6:
                navPath = [.similarList, .similarDetail]
            case 8:
                navPath = [.similarList, .quality(0)]
            case 9:
                navPath = [.similarList, .quality(1)]
            default:
                break
            }

            isReady = true
        }
    }

    private func ensureSampleGroups() {
        if similarityManager.similarGroups.isEmpty && photoManager.photos.count >= 4 {
            let simGroup = SimilarPhotoGroup(
                photos: [photoManager.photos[2], photoManager.photos[3]],
                similarityScore: 0.85,
                isDuplicate: false
            )
            similarityManager.similarGroups = [simGroup]
        }

        if similarityManager.blurryPhotos.isEmpty && photoManager.photos.count >= 2 {
            var p1 = photoManager.photos[0]
            p1.blurScore = 30.0
            var p2 = photoManager.photos[1]
            p2.blurScore = 45.0
            similarityManager.blurryPhotos = [p1, p2]
        }

        if similarityManager.darkPhotos.isEmpty && photoManager.photos.count >= 1 {
            var p = photoManager.photos[0]
            p.brightnessScore = 0.08
            similarityManager.darkPhotos = [p]
        }
    }

    @ViewBuilder
    private var content: some View {
        switch screenNumber {
        case 1:
            OnboardingView(isPresented: .constant(true), initialPage: 0)
        case 2:
            OnboardingView(isPresented: .constant(true), initialPage: 1)
        case 3:
            MainView(photoManager: photoManager, similarityManager: similarityManager)
        case 7:
            let group = similarityManager.duplicateGroups.first ?? similarityManager.similarGroups.first
            if let group {
                PhotoComparisonView(photos: group.photos, initialIndex: 0, onSelect: { _ in })
            } else {
                Text("No photos to compare")
            }
        case 10:
            SettingsView()
        case 4, 5, 6, 8, 9:
            NavigationStack(path: $navPath) {
                Color(uiColor: .systemBackground)
                    .navigationDestination(for: ScreenshotDestination.self) { destination in
                        switch destination {
                        case .similarList:
                            SimilarPhotosListView(
                                similarityManager: similarityManager,
                                photoManager: photoManager
                            )
                        case .duplicateDetail:
                            if let group = similarityManager.duplicateGroups.first ?? similarityManager.similarGroups.first {
                                SimilarPhotoDetailView(
                                    group: group,
                                    photoManager: photoManager
                                )
                            }
                        case .similarDetail:
                            let group = similarityManager.similarGroups.first ?? similarityManager.duplicateGroups.first
                            if let group {
                                SimilarPhotoDetailView(
                                    group: group,
                                    photoManager: photoManager
                                )
                            }
                        case .quality(let tab):
                            QualityIssuesView(
                                similarityManager: similarityManager,
                                photoManager: photoManager,
                                initialTab: tab
                            )
                        }
                    }
            }
        default:
            Text("Unknown screen: \(screenNumber)")
        }
    }
}
