//
//  SettingsView.swift
//  Similarly
//
//  Created by AI Agent
//

import SwiftUI

/// Uygulama ayarları görünümü
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("similarityThreshold") private var similarityThreshold: Double = 0.85
    @AppStorage("dateThreshold") private var dateThreshold: Double = 5.0
    @AppStorage("locationThreshold") private var locationThreshold: Double = 100.0
    @AppStorage("autoSelectOldest") private var autoSelectOldest: Bool = true
    @AppStorage("showAdvancedSettings") private var showAdvancedSettings: Bool = false
    @AppStorage("blurThreshold") private var blurThreshold: Double = 100.0
    @AppStorage("darknessThreshold") private var darknessThreshold: Double = 0.2
    @AppStorage("brightnessThreshold") private var brightnessThreshold: Double = 0.9

    @State private var selectedPreset: PresetType? = nil

    enum PresetType: String, CaseIterable {
        case precise = "Hassas"
        case balanced = "Dengeli"
        case flexible = "Esnek"

        var description: String {
            switch self {
            case .precise:
                return "Sadece çok benzer fotoğrafları bulur"
            case .balanced:
                return "İyi bir denge (önerilen)"
            case .flexible:
                return "Daha fazla benzer fotoğraf bulur"
            }
        }

        var icon: String {
            switch self {
            case .precise:
                return "scope"
            case .balanced:
                return "slider.horizontal.3"
            case .flexible:
                return "wand.and.stars"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Hazır Ayarlar
                Section {
                    ForEach(PresetType.allCases, id: \.self) { preset in
                        Button(action: {
                            applyPreset(preset)
                            selectedPreset = preset
                        }) {
                            HStack {
                                Image(systemName: preset.icon)
                                    .foregroundColor(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(preset.rawValue)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(preset.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedPreset == preset {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Hızlı Ayarlar")
                } footer: {
                    Text("Manuel ayarlara göre daha hızlı başlangıç için hazır profiller")
                }

                // Genel Ayarlar
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Benzerlik Eşiği")
                            Spacer()
                            Text("\(Int(similarityThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $similarityThreshold, in: 0.5...1.0, step: 0.05)
                            .tint(.blue)

                        Text("Fotoğrafların ne kadar benzer olması gerektiğini belirler")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Analiz Ayarları")
                } footer: {
                    Text(
                        "Daha düşük değer daha fazla benzer fotoğraf bulur, ancak yanlış eşleşme riski artar"
                    )
                }

                // Metadata Filtreleri
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tarih Yakınlığı")
                            Spacer()
                            Text("\(Int(dateThreshold)) saniye")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $dateThreshold, in: 1...60, step: 1)
                            .tint(.blue)

                        Text("Seri çekimler için tarih farkı limiti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Lokasyon Yakınlığı")
                            Spacer()
                            Text("\(Int(locationThreshold)) metre")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $locationThreshold, in: 10...1000, step: 10)
                            .tint(.blue)

                        Text("Aynı lokasyonda çekilen fotoğraflar için mesafe limiti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Metadata Filtreleri")
                } footer: {
                    Text("Bu değerler fotoğrafları gruplamadan önce ön filtreleme için kullanılır")
                }

                // Kalite Kontrol Ayarları
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Bulanıklık Eşiği")
                            Spacer()
                            Text("\(Int(blurThreshold))")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $blurThreshold, in: 50...200, step: 10)
                            .tint(.orange)

                        Text("Daha yüksek değer daha az bulanık fotoğraf bulur")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Karanlık Eşiği")
                            Spacer()
                            Text("\(Int(darknessThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $darknessThreshold, in: 0.1...0.4, step: 0.05)
                            .tint(.purple)

                        Text("Altındaki parlaklık değeri çok karanlık sayılır")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Parlaklık Eşiği")
                            Spacer()
                            Text("\(Int(brightnessThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $brightnessThreshold, in: 0.7...1.0, step: 0.05)
                            .tint(.yellow)

                        Text("Üstündeki parlaklık değeri aşırı parlak sayılır")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Kalite Kontrol")
                } footer: {
                    Text(
                        "Bu eşikler bulanık, karanlık veya aşırı parlak fotoğrafların tespiti için kullanılır"
                    )
                }

                // Kullanıcı Tercihleri
                Section {
                    Toggle("En Eski Fotoğrafları Otomatik Seç", isOn: $autoSelectOldest)

                    Text("Grup detayında otomatik olarak en eski fotoğrafları silme için işaretler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Seçim Tercihleri")
                }

                // Gelişmiş Ayarlar
                Section {
                    Toggle("Gelişmiş Ayarları Göster", isOn: $showAdvancedSettings)

                    if showAdvancedSettings {
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(
                                title: "Perceptual Hash",
                                description: "8x8 pHash algoritması kullanılır"
                            )

                            InfoRow(
                                title: "Histogram Analizi",
                                description: "64-bin renk histogramı karşılaştırması"
                            )

                            InfoRow(
                                title: "Metadata Analizi",
                                description: "EXIF, tarih, GPS ve boyut bilgileri"
                            )
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Gelişmiş")
                } footer: {
                    if showAdvancedSettings {
                        Text(
                            "Uygulama CoreImage ve PhotoKit framework'lerini kullanarak yüksek performanslı benzerlik analizi yapar"
                        )
                    }
                }

                // Hakkında
                Section {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.01")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text("Hakkında")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Similarly - Benzer Fotoğraf Temizleyici")
                            .font(.caption)
                        Text("Fotoğraf kütüphanenizi temiz tutmanın en kolay yolu")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }

                // Varsayılan Ayarlar
                Section {
                    Button(role: .destructive) {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Varsayılan Ayarlara Dön")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("Tüm ayarlar varsayılan değerlerine sıfırlanacak")
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tamam") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func resetToDefaults() {
        similarityThreshold = 0.85
        dateThreshold = 5.0
        locationThreshold = 100.0
        autoSelectOldest = true
        showAdvancedSettings = false
        blurThreshold = 100.0
        darknessThreshold = 0.2
        brightnessThreshold = 0.9
        selectedPreset = .balanced
    }

    private func applyPreset(_ preset: PresetType) {
        switch preset {
        case .precise:
            // Hassas: Sadece çok benzer olanlar
            similarityThreshold = 0.95
            dateThreshold = 3.0
            locationThreshold = 50.0
            blurThreshold = 150.0
            darknessThreshold = 0.15
            brightnessThreshold = 0.95

        case .balanced:
            // Dengeli: Varsayılan ayarlar
            similarityThreshold = 0.85
            dateThreshold = 5.0
            locationThreshold = 100.0
            blurThreshold = 100.0
            darknessThreshold = 0.2
            brightnessThreshold = 0.9

        case .flexible:
            // Esnek: Daha fazla sonuç
            similarityThreshold = 0.70
            dateThreshold = 10.0
            locationThreshold = 200.0
            blurThreshold = 75.0
            darknessThreshold = 0.25
            brightnessThreshold = 0.85
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
