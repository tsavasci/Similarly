//
//  SimilarPhotosListView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftUI
import ImageIO

/// Benzer fotoğraf gruplarını liste halinde gösteren görünüm
struct SimilarPhotosListView: View {
    @ObservedObject var similarityManager: SimilarityManager
    @ObservedObject var photoManager: PhotoLibraryManager
    @State private var visibleDuplicateCount = 50  // Initial visible count for pagination
    @State private var visibleScreenshotCount = 50
    @State private var visibleSimilarCount = 50
    @ScaledMetric(relativeTo: .largeTitle) private var emptyIconSize: CGFloat = 80

    var body: some View {
        ZStack {
            if similarityManager.similarGroups.isEmpty && similarityManager.duplicateGroups.isEmpty
                && similarityManager.screenshotGroups.isEmpty
            {
                // Benzer fotoğraf bulunamadı (veya analiz hiç yapılamadı)
                let analysisUnavailable = similarityManager.isAnalysisUnavailable
                VStack(spacing: 20) {
                    Image(systemName: analysisUnavailable ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: emptyIconSize, height: emptyIconSize)
                        .foregroundStyle(analysisUnavailable ? .orange : .green)
                        .accessibilityHidden(true)

                    Text(L10n.k(analysisUnavailable ? "similar.analysis_failed.title" : "similar.empty.title"))
                        .font(.title)
                        .fontWeight(.bold)

                    Text(L10n.k(analysisUnavailable ? "similar.analysis_failed.message" : "similar.empty.message"))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                // Benzer fotoğraf grupları listesi
                List {
                    // Özet bilgi
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            // Duplikatlar
                            if !similarityManager.duplicateGroups.isEmpty {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .accessibilityHidden(true)
                                        .foregroundStyle(.red)
                                    Text(L10n.f("similar.summary.duplicate_groups", similarityManager.duplicateGroups.count))
                                        .font(.headline)
                                }
                            }

                            // Screenshots
                            if !similarityManager.screenshotGroups.isEmpty {
                                HStack {
                                    Image(systemName: "camera.viewfinder")
                                        .accessibilityHidden(true)
                                        .foregroundStyle(.orange)
                                    Text(
                                        L10n.f("similar.summary.screenshot_groups", similarityManager.screenshotGroups.count)
                                    )
                                    .font(.headline)
                                }
                            }

                            // Benzer fotoğraflar
                            if !similarityManager.similarGroups.isEmpty {
                                HStack {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .accessibilityHidden(true)
                                        .foregroundStyle(.blue)
                                    Text(L10n.f("similar.summary.similar_groups", similarityManager.similarGroups.count))
                                        .font(.headline)
                                }
                            }

                            Divider()

                            // Toplam istatistikler
                            let totalPhotos =
                                similarityManager.getTotalDuplicatesCount()
                                + similarityManager.getTotalScreenshotsCount()
                                + similarityManager.getTotalSimilarPhotosCount()

                            HStack {
                                Image(systemName: "photo.stack")
                                    .accessibilityHidden(true)
                                    .foregroundStyle(.purple)
                                Text(L10n.f("similar.summary.total_photos", totalPhotos))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if similarityManager.potentialSavings > 0 {
                                HStack {
                                    Image(systemName: "internaldrive")
                                        .accessibilityHidden(true)
                                        .foregroundStyle(.green)
                                    Text(
                                        L10n.f("similar.summary.savings", formatBytes(similarityManager.potentialSavings))
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Video ve Live Photos
                    if similarityManager.getTotalVideosCount() > 0
                        || similarityManager.getTotalLivePhotosCount() > 0
                    {
                        Section(
                            header: HStack {
                                Image(systemName: "video.fill")
                                    .accessibilityHidden(true)
                                    .foregroundStyle(.blue)
                                Text(L10n.k("media.header.title"))
                                    .foregroundStyle(.blue)
                            }
                        ) {
                            NavigationLink {
                                MediaLibraryView(
                                    similarityManager: similarityManager,
                                    photoManager: photoManager
                                )
                            } label: {
                                VStack(spacing: 12) {
                                    if similarityManager.getTotalVideosCount() > 0 {
                                        HStack {
                                            Image(systemName: "video.fill")
                                                .accessibilityHidden(true)
                                                .foregroundStyle(.blue)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(
                                                    L10n.f("media.videos_count", similarityManager.getTotalVideosCount())
                                                )
                                                .font(.headline)
                                                Text(L10n.k("similar.media.videos_cta"))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }

                                    if similarityManager.getTotalLivePhotosCount() > 0 {
                                        HStack {
                                            Image(systemName: "livephoto")
                                                .accessibilityHidden(true)
                                                .foregroundStyle(.purple)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(
                                                    L10n.f("media.live_photos_count", similarityManager.getTotalLivePhotosCount())
                                                )
                                                .font(.headline)
                                                Text(L10n.k("similar.media.live_cta"))
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                            }
                        }
                    }

                    // Kalite Sorunları
                    if similarityManager.getTotalQualityIssuesCount() > 0 {
                        Section(
                            header: HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .accessibilityHidden(true)
                                    .foregroundStyle(.orange)
                                Text(L10n.k("quality.nav_title"))
                                    .foregroundStyle(.orange)
                            }
                        ) {
                            NavigationLink {
                                QualityIssuesView(
                                    similarityManager: similarityManager,
                                    photoManager: photoManager
                                )
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            if !similarityManager.blurryPhotos.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "eye.slash.fill")
                                                        .accessibilityLabel(L10n.t("quality.type.blurry.title"))
                                                        .font(.caption)
                                                        .foregroundStyle(.orange)
                                                    Text("\(similarityManager.blurryPhotos.count)")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                }
                                            }

                                            if !similarityManager.darkPhotos.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "moon.fill")
                                                        .accessibilityLabel(L10n.t("quality.type.dark.title"))
                                                        .font(.caption)
                                                        .foregroundStyle(.purple)
                                                    Text("\(similarityManager.darkPhotos.count)")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                }
                                            }

                                            if !similarityManager.brightPhotos.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "sun.max.fill")
                                                        .accessibilityLabel(L10n.t("quality.type.bright.title"))
                                                        .font(.caption)
                                                        .foregroundStyle(.yellow)
                                                    Text("\(similarityManager.brightPhotos.count)")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                }
                                            }
                                        }

                                        Text(L10n.k("similar.quality.desc"))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }

                    // Duplikat Grupları
                    if !similarityManager.duplicateGroups.isEmpty {
                        Section(
                            header: HStack {
                                Image(systemName: "doc.on.doc.fill")
                                    .accessibilityHidden(true)
                                    .foregroundStyle(.red)
                                Text(L10n.k("similar.section.duplicates"))
                                    .foregroundStyle(.red)
                            }
                        ) {
                            ForEach(Array(similarityManager.duplicateGroups.prefix(visibleDuplicateCount))) { group in
                                NavigationLink {
                                    SimilarPhotoDetailView(
                                        group: group,
                                        photoManager: photoManager
                                    )
                                } label: {
                                    SimilarGroupRow(group: group)
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                                .onAppear {
                                    if group.id == similarityManager.duplicateGroups.prefix(visibleDuplicateCount).last?.id {
                                        visibleDuplicateCount += 25
                                    }
                                }
                            }
                            
                            // Show "Load More" indicator if there are more groups
                            if visibleDuplicateCount < similarityManager.duplicateGroups.count {
                                HStack {
                                    Spacer()
                                    Text(L10n.f("common.loading_count", similarityManager.duplicateGroups.count - visibleDuplicateCount))
                                        .foregroundStyle(.secondary)
                                        .onAppear {
                                            visibleDuplicateCount = min(visibleDuplicateCount + 25, similarityManager.duplicateGroups.count)
                                        }
                                    Spacer()
                                }
                            }
                        }
                    }

                    // Screenshot Grupları
                    if !similarityManager.screenshotGroups.isEmpty {
                        Section(
                            header: HStack {
                                Image(systemName: "camera.viewfinder")
                                    .accessibilityHidden(true)
                                    .foregroundStyle(.orange)
                                Text(L10n.k("similar.section.screenshots"))
                                    .foregroundStyle(.orange)
                            }
                        ) {
                            ForEach(Array(similarityManager.screenshotGroups.prefix(visibleScreenshotCount))) { group in
                                NavigationLink {
                                    SimilarPhotoDetailView(
                                        group: group,
                                        photoManager: photoManager
                                    )
                                } label: {
                                    SimilarGroupRow(group: group)
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                                .onAppear {
                                    if group.id == similarityManager.screenshotGroups.prefix(visibleScreenshotCount).last?.id {
                                        visibleScreenshotCount += 25
                                    }
                                }
                            }
                            
                            if visibleScreenshotCount < similarityManager.screenshotGroups.count {
                                HStack {
                                    Spacer()
                                    Text(L10n.f("common.loading_count", similarityManager.screenshotGroups.count - visibleScreenshotCount))
                                        .foregroundStyle(.secondary)
                                        .onAppear {
                                            visibleScreenshotCount = min(visibleScreenshotCount + 25, similarityManager.screenshotGroups.count)
                                        }
                                    Spacer()
                                }
                            }
                        }
                    }

                    // Benzer Gruplar
                    if !similarityManager.similarGroups.isEmpty {
                        Section(
                            header: HStack {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .accessibilityHidden(true)
                                    .foregroundStyle(.blue)
                                Text(L10n.k("similar.section.similar_groups"))
                                    .foregroundStyle(.blue)
                            }
                        ) {
                            ForEach(Array(similarityManager.similarGroups.prefix(visibleSimilarCount))) { group in
                                NavigationLink {
                                    SimilarPhotoDetailView(
                                        group: group,
                                        photoManager: photoManager
                                    )
                                } label: {
                                    SimilarGroupRow(group: group)
                                }
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 16))
                                .onAppear {
                                    if group.id == similarityManager.similarGroups.prefix(visibleSimilarCount).last?.id {
                                        visibleSimilarCount += 25
                                    }
                                }
                            }
                            
                            if visibleSimilarCount < similarityManager.similarGroups.count {
                                HStack {
                                    Spacer()
                                    Text(L10n.f("common.loading_count", similarityManager.similarGroups.count - visibleSimilarCount))
                                        .foregroundStyle(.secondary)
                                        .onAppear {
                                            visibleSimilarCount = min(visibleSimilarCount + 25, similarityManager.similarGroups.count)
                                        }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(L10n.k("similar.nav_title"))
        .navigationBarTitleDisplayMode(.large)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        L10n.bytes(bytes)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SimilarPhotosListView(
            similarityManager: SimilarityManager(),
            photoManager: PhotoLibraryManager()
        )
    }
}
