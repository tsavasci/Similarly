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

    var body: some View {
        NavigationStack {
            Form {
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
