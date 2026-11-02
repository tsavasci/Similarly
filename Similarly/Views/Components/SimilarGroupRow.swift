//
//  SimilarGroupRow.swift
//  Similarly
//
//  Created by AI Agent (Arch Swift)
//

import Photos
import SwiftUI

/// Benzer grup özet satır görünümü
struct SimilarGroupRow: View {
    let group: SimilarPhotoGroup

    var body: some View {
        HStack(spacing: 12) {
            // Sol kısım - Thumbnails ve Bilgiler
            VStack(alignment: .leading, spacing: 8) {
                // Bilgiler - İki satırda
                VStack(alignment: .leading, spacing: 4) {
                    // İlk satır: Fotoğraf sayısı ve benzerlik
                    HStack(spacing: 4) {
                        Text(rowCountText)
                            .font(.caption)
                            .fontWeight(.semibold)

                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(getSimilarityDescription(group.similarityScore))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Favori badge
                        if group.hasFavorite {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.yellow)
                                Text(L10n.k("common.favorite"))
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    // Uzun çevirilerde ("Neredeyse aynı" vb.) satır bölünmesin; gerekirse hafifçe küçülsün.
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    // İkinci satır: Tarih
                    if let date = group.representativePhoto?.creationDate {
                        Text(L10n.date(date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Önizleme resimleri
                HStack(spacing: 8) {
                    ForEach(Array(group.photos.prefix(3)), id: \.id) { photo in
                        GroupRowThumbnail(photo: photo)
                    }
                }
            }

            Spacer(minLength: 8)

            // Sağ kısım - Benzerlik skoru
            VStack(alignment: .trailing, spacing: 2) {
                Text(L10n.percent(group.similarityScore))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(getScoreColor(group.similarityScore))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(L10n.k("common.similar"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 55, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }

    /// Kopya gruplarında "benzer" yerine "kopya" de; bölüm başlığıyla çelişmesin.
    private var rowCountText: String {
        if group.isDuplicate {
            return L10n.f("similar.row.duplicate_count", group.count)
        } else if group.allScreenshots {
            return L10n.f("similar.row.screenshot_count", group.count)
        }
        return L10n.f("similar.row.similar_photo_count", group.count)
    }

    private func getSimilarityDescription(_ score: Double) -> String {
        if score >= 0.99 {
            return L10n.t("similarity.exact_match")
        } else if score >= 0.95 {
            return L10n.t("similarity.almost_identical")
        } else if score >= 0.85 {
            return L10n.t("similarity.very_similar")
        } else if score >= 0.75 {
            return L10n.t("similarity.similar")
        } else if score >= 0.65 {
            return L10n.t("similarity.slightly_similar")
        } else {
            return L10n.t("similarity.less_similar")
        }
    }

    private func getScoreColor(_ score: Double) -> Color {
        switch score {
        case 0.9...1.0: return .green
        case 0.8..<0.9: return .blue
        case 0.7..<0.8: return .orange
        default: return .red
        }
    }
}
