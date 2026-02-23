//
//  MainView.swift
//  Similarly
//
//  Created by AI Agent
//

import Photos
import SwiftData
import SwiftUI

/// Ana uygulama görünümü - fotoğraf kütüphanesine erişim ve benzer fotoğraf bulma
struct MainView: View {
    @StateObject private var photoManager = PhotoLibraryManager()
    @StateObject private var similarityManager = SimilarityManager()
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showingOnboarding = false
    @State private var showingSimilarPhotos = false
    @State private var showingSettings = false
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Ana içerik
                VStack(spacing: 30) {
                    // Logo ve başlık
                    VStack(spacing: 10) {
                        Image(systemName: "photo.stack.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Similarly")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Benzer fotoğrafları bul ve temizle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)

                    Spacer()

                    // İstatistikler
                    if !photoManager.photos.isEmpty {
                        VStack(spacing: 15) {
                            StatCard(
                                icon: "photo.on.rectangle.angled",
                                title: "Toplam Fotoğraf",
                                value: "\(photoManager.photos.count)",
                                color: .blue
                            )

                            if !similarityManager.similarGroups.isEmpty {
                                StatCard(
                                    icon: "square.on.square",
                                    title: "Benzer Grup",
                                    value: "\(similarityManager.similarGroups.count)",
                                    color: .purple
                                )

                                StatCard(
                                    icon: "trash.circle.fill",
                                    title: "Temizlenebilir",
                                    value:
                                        "\(similarityManager.getTotalSimilarPhotosCount()) fotoğraf",
                                    color: .orange
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Ana butonlar
                    VStack(spacing: 15) {
                        if photoManager.photos.isEmpty {
                            // İlk yükleme butonu
                            Button(action: {
                                Task {
                                    await photoManager.requestAccessAndFetch()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Fotoğrafları Yükle")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .disabled(photoManager.isProcessing)
                        } else {
                            // Analiz butonu
                            Button(action: {
                                Task {
                                    await similarityManager.findSimilarPhotos(
                                        from: photoManager.photos)
                                    showingSimilarPhotos = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Benzer Fotoğrafları Bul")
                                        .fontWeight(.semibold)
                                }
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
                                .cornerRadius(15)
                            }
                            .disabled(similarityManager.isAnalyzing)

                            // Yeniden yükle butonu
                            Button(action: {
                                Task {
                                    await photoManager.fetchAssets()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Yeniden Yükle")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .cornerRadius(15)
                            }
                            .disabled(photoManager.isProcessing)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                }

                // İşleniyor göstergesi
                if photoManager.isProcessing {
                    ProcessingOverlay(
                        title: "Fotoğraflar İşleniyor",
                        progress: photoManager.processingProgress
                    )
                }

                if similarityManager.isAnalyzing {
                    ProcessingOverlay(
                        title: "Benzerlik Analizi Yapılıyor",
                        progress: similarityManager.analysisProgress
                    )
                }
            }
            .navigationDestination(isPresented: $showingSimilarPhotos) {
                SimilarPhotosListView(
                    similarityManager: similarityManager,
                    photoManager: photoManager
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert("Hata", isPresented: $showingError) {
                Button("Tamam", role: .cancel) {
                    photoManager.errorMessage = nil
                }
            } message: {
                Text(photoManager.errorMessage ?? "Bir hata oluştu")
            }
            .fullScreenCover(isPresented: $showingOnboarding) {
                OnboardingView(isPresented: $showingOnboarding)
            }
            }
            .onAppear {
                if !hasSeenOnboarding {
                    showingOnboarding = true
                }
                // ModelContext'i PhotoLibraryManager'a set et
                photoManager.modelContext = modelContext
            }
            .onChange(of: photoManager.errorMessage) { _, newMessage in
                showingError = (newMessage != nil)
            }
        }
    }


// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Processing Overlay
struct ProcessingOverlay: View {
    let title: String
    let progress: Double

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(.white)
                    .frame(width: 200)

                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
}

// MARK: - Preview
#Preview {
    MainView()
}
