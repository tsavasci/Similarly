//
//  CleanCelebrationView.swift
//  Similarly
//
//  Kullanıcı fotoğraf sildikten sonra ne kadar depolama alanı kazandığını ve
//  başarısını gösteren tatmin edici kutlama ve paylaşım görünümü.
//

import SwiftUI

struct CleanCelebrationView: View {
    let deletedCount: Int
    let savedBytes: Int64
    let onDismiss: () -> Void

    @State private var animateContent = false
    @State private var showingShareSheet = false

    private var formattedSavedSpace: String {
        L10n.bytes(savedBytes)
    }

    private var shareMessage: String {
        L10n.f("celebration.share_message", deletedCount, formattedSavedSpace)
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // İkon & Efekt
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .blue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateContent ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateContent)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateContent ? 1.0 : 0.8)
            }
            .padding(.bottom, 8)

            // Başlık & Açıklama
            VStack(spacing: 8) {
                Text(L10n.k("celebration.title"))
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(L10n.f("celebration.subtitle", deletedCount))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Tasarruf Kartı
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("celebration.storage_freed"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedSavedSpace)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    Divider()
                        .frame(height: 40)

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("celebration.photos_cleaned"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(deletedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(16)
            }
            .padding(.horizontal)

            Spacer()

            // Butonlar
            VStack(spacing: 12) {
                // Paylaş Butonu (Organik Growth)
                Button(action: {
                    showingShareSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.k("celebration.share_button"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .cornerRadius(14)
                }

                // Tamam Butonu
                Button(action: {
                    onDismiss()
                }) {
                    Text(L10n.k("common.done"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareMessage])
        }
    }
}

// MARK: - Share Sheet Helper
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
