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
    @AppStorage("blurThreshold") private var blurThreshold: Double = 100.0
    @AppStorage("darknessThreshold") private var darknessThreshold: Double = 0.2
    @AppStorage("brightnessThreshold") private var brightnessThreshold: Double = 0.9
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    @State private var selectedPreset: PresetType? = nil

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
    }

    struct LanguageOption: Identifiable, Hashable {
        let code: String
        let flag: String
        var id: String { code }

        static let all: [LanguageOption] = [
            LanguageOption(code: "system", flag: "🌐"),
            LanguageOption(code: "en", flag: "🇺🇸"),
            LanguageOption(code: "tr", flag: "🇹🇷"),
            LanguageOption(code: "ar", flag: "🇸🇦"),
            LanguageOption(code: "zh-Hans", flag: "🇨🇳"),
            LanguageOption(code: "es", flag: "🇪🇸"),
            LanguageOption(code: "fr", flag: "🇫🇷"),
            LanguageOption(code: "de", flag: "🇩🇪"),
            LanguageOption(code: "ja", flag: "🇯🇵"),
        ]
    }

    enum PresetType: CaseIterable {
        case precise
        case balanced
        case flexible

        var title: String {
            switch self {
            case .precise:
                return L10n.t("settings.preset.precise.title")
            case .balanced:
                return L10n.t("settings.preset.balanced.title")
            case .flexible:
                return L10n.t("settings.preset.flexible.title")
            }
        }

        var description: String {
            switch self {
            case .precise:
                return L10n.t("settings.preset.precise.desc")
            case .balanced:
                return L10n.t("settings.preset.balanced.desc")
            case .flexible:
                return L10n.t("settings.preset.flexible.desc")
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
                // Dil Seçimi
                Section {
                    ForEach(LanguageOption.all) { option in
                        Button {
                            appLanguage = option.code
                        } label: {
                            HStack(spacing: 12) {
                                Text(option.flag)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(languageDisplayName(for: option))
                                        .foregroundColor(.primary)

                                    if option.code == "system" {
                                        Text(L10n.k("settings.language.follow_system"))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if selectedLanguageOption.code == option.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(L10n.k("settings.language.title"))
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("settings.language.footer"))
                        Text(L10n.f("settings.language.current", languageDisplayName(for: selectedLanguageOption)))
                    }
                }

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
                                    Text(preset.title)
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
                    Text(L10n.k("settings.quick.title"))
                } footer: {
                    Text(L10n.k("settings.quick.footer"))
                }

                // Genel Ayarlar
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.similarity.title"))
                            Spacer()
                            Text("\(Int(similarityThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $similarityThreshold, in: 0.80...1.0, step: 0.05)
                            .tint(.blue)

                        Text(L10n.k("settings.similarity.desc"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L10n.k("settings.analysis.title"))
                } footer: {
                    Text(L10n.k("settings.analysis.footer"))
                }

                // Metadata Filtreleri
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.date_proximity.title"))
                            Spacer()
                            Text(L10n.f("settings.seconds", Int(dateThreshold)))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $dateThreshold, in: 1...60, step: 1)
                            .tint(.blue)

                        Text(L10n.k("settings.date_proximity.desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.location_proximity.title"))
                            Spacer()
                            Text(L10n.f("settings.meters", Int(locationThreshold)))
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $locationThreshold, in: 10...1000, step: 10)
                            .tint(.blue)

                        Text(L10n.k("settings.location_proximity.desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L10n.k("settings.metadata.title"))
                } footer: {
                    Text(L10n.k("settings.metadata.footer"))
                }

                // Kalite Kontrol Ayarları
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.blur_threshold.title"))
                            Spacer()
                            Text("\(Int(blurThreshold))")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $blurThreshold, in: 50...200, step: 10)
                            .tint(.orange)

                        Text(L10n.k("settings.blur_threshold.desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.dark_threshold.title"))
                            Spacer()
                            Text("\(Int(darknessThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $darknessThreshold, in: 0.1...0.4, step: 0.05)
                            .tint(.purple)

                        Text(L10n.k("settings.dark_threshold.desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.brightness_threshold.title"))
                            Spacer()
                            Text("\(Int(brightnessThreshold * 100))%")
                                .foregroundColor(.secondary)
                        }

                        Slider(value: $brightnessThreshold, in: 0.7...1.0, step: 0.05)
                            .tint(.yellow)

                        Text(L10n.k("settings.brightness_threshold.desc"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L10n.k("settings.quality.title"))
                } footer: {
                    Text(L10n.k("settings.quality.footer"))
                }

                // Hakkında
                Section {
                    HStack {
                        Text(L10n.k("settings.about.version"))
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text(L10n.k("settings.about.build"))
                        Spacer()
                        Text(appBuild)
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text(L10n.k("settings.about.github"))
                            Spacer()
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundColor(.blue)
                        }
                    }
                } header: {
                    Text(L10n.k("settings.about.title"))
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.k("settings.about.app_name"))
                            .font(.caption)
                        Text(L10n.k("settings.about.tagline"))
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
                            Text(L10n.k("settings.reset"))
                            Spacer()
                        }
                    }
                } footer: {
                    Text(L10n.k("settings.reset.footer"))
                }
            }
            .navigationTitle(L10n.k("settings.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(L10n.t("common.ok")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            validateLanguagePreference()
            updateSelectedPreset()
        }
    }

    private var selectedLanguageOption: LanguageOption {
        LanguageOption.all.first(where: { $0.code == appLanguage }) ?? LanguageOption.all[0]
    }

    private func validateLanguagePreference() {
        let isValid = LanguageOption.all.contains(where: { $0.code == appLanguage })
        if !isValid {
            appLanguage = "system"
        }
    }

    private func languageDisplayName(for option: LanguageOption) -> String {
        if option.code == "system" {
            return L10n.t("settings.language.system")
        }

        let localeIdentifier = option.code == "zh-Hans" ? "zh_Hans" : option.code
        let locale = Locale(identifier: localeIdentifier)
        let languageCode = locale.language.languageCode?.identifier ?? option.code

        if let name = locale.localizedString(forLanguageCode: languageCode) {
            return name.capitalized(with: locale)
        }

        return option.code
    }

    private func resetToDefaults() {
        similarityThreshold = 0.85
        dateThreshold = 5.0
        locationThreshold = 100.0
        blurThreshold = 100.0
        darknessThreshold = 0.2
        brightnessThreshold = 0.9
        selectedPreset = .balanced
        updateSelectedPreset()
    }

    private func updateSelectedPreset() {
        // Mevcut ayarlara göre hangi preset'in aktif olduğunu belirle
        if similarityThreshold >= 0.90 && dateThreshold <= 3.0 && locationThreshold <= 60.0 {
            selectedPreset = .precise
        } else if similarityThreshold <= 0.82 && dateThreshold >= 8.0 && locationThreshold >= 150.0 {
            selectedPreset = .flexible
        } else {
            selectedPreset = .balanced
        }
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
            similarityThreshold = 0.80
            dateThreshold = 10.0
            locationThreshold = 200.0
            blurThreshold = 75.0
            darknessThreshold = 0.25
            brightnessThreshold = 0.85
        }

        // Preset seçimini güncelle
        updateSelectedPreset()
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
