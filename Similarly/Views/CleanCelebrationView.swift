//
//  CleanCelebrationView.swift
//  Similarly
//
//  Kullanıcı fotoğraf sildikten sonra ne kadar depolama alanı kazandığını ve
//  başarısını gösteren tatmin edici kutlama ve paylaşım görünümü.
//  Emil Kowalski akıcı mikro animasyonlar ve fiziksel yay geçişleri ile modernize edilmiştir.
//

import SwiftUI

struct CleanCelebrationView: View {
    let deletedCount: Int
    let savedBytes: Int64
    let onDismiss: () -> Void

    @State private var showIcon = false
    @State private var showText = false
    @State private var showStats = false
    @State private var showButtons = false
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

            // İkon & Efekt (Emil Kowalski: Doğal yaylı giriş ve mikroskobik ölçek)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.18), Color.blue.opacity(0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(showIcon ? 1.0 : 0.92)
                    .opacity(showIcon ? 1.0 : 0.0)

                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(showIcon ? 1.0 : 0.88)
                    .rotationEffect(.degrees(showIcon ? 0 : -8))
                    .opacity(showIcon ? 1.0 : 0.0)
            }
            .padding(.bottom, 8)

            // Başlık & Açıklama (Kademeli yumuşak yükseliş)
            VStack(spacing: 8) {
                Text(L10n.k("celebration.title"))
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(L10n.f("celebration.subtitle", deletedCount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .offset(y: showText ? 0 : 12)
            .opacity(showText ? 1.0 : 0.0)

            // Tasarruf Kartı (Kademeli fiziksel yay geçişi)
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("celebration.storage_freed"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(formattedSavedSpace)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(DesignSystem.Colors.success)
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    Divider()
                        .frame(height: 40)

                    Spacer()

                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("celebration.photos_cleaned"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(deletedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                            .contentTransition(.numericText())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.card, style: .continuous))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal)
            .offset(y: showStats ? 0 : 16)
            .opacity(showStats ? 1.0 : 0.0)

            Spacer()

            // Butonlar (Dokunsal yay tepkili butonlar)
            VStack(spacing: 12) {
                // Paylaş Butonu (Organik Growth)
                Button {
                    DesignSystem.Haptics.impact(.light)
                    showingShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10n.k("celebration.share_button"))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous))
                }
                .buttonStyle(.bouncy(scale: 0.97))

                // Tamam Butonu
                Button {
                    DesignSystem.Haptics.impact(.medium)
                    onDismiss()
                } label: {
                    Text(L10n.k("common.done"))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.bouncy(scale: 0.97))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .offset(y: showButtons ? 0 : 20)
            .opacity(showButtons ? 1.0 : 0.0)
        }
        .padding()
        .presentationDetents([.fraction(0.70), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DesignSystem.CornerRadius.celebration)
        .onAppear {
            // Başarılı işlem haptik geribildirimi
            DesignSystem.Haptics.notification(.success)

            // Emil Kowalski kademeli mikro animasyon orkestrasyonu
            withAnimation(DesignSystem.Springs.bouncy) {
                showIcon = true
            }

            withAnimation(DesignSystem.Springs.settle.delay(0.08)) {
                showText = true
            }

            withAnimation(DesignSystem.Springs.settle.delay(0.16)) {
                showStats = true
            }

            withAnimation(DesignSystem.Springs.interactive.delay(0.24)) {
                showButtons = true
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
