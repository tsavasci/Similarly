//
//  SettingsView.swift
//  Similarly
//
//  Created by AI Agent
//

import SwiftUI

/// Uygulama ayarları görünümü - Emil Kowalski fiziksel yay geçişleri ve modern HIG form yapısı
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
            LanguageOption(code: "de", flag: "🇩🇪"),
            LanguageOption(code: "fr", flag: "🇫🇷"),
            LanguageOption(code: "es", flag: "🇪🇸"),
            LanguageOption(code: "it", flag: "🇮🇹"),
            LanguageOption(code: "pt-BR", flag: "🇧🇷"),
            LanguageOption(code: "ja", flag: "🇯🇵"),
            LanguageOption(code: "ko", flag: "🇰🇷"),
            LanguageOption(code: "zh-Hans", flag: "🇨🇳"),
            LanguageOption(code: "ru", flag: "🇷🇺"),
            LanguageOption(code: "ar", flag: "🇸🇦"),
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
                            DesignSystem.Haptics.selection()
                            withAnimation(DesignSystem.Springs.interactive) {
                                appLanguage = option.code
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(option.flag)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(languageDisplayName(for: option))
                                        .foregroundStyle(.primary)

                                    if option.code == "system" {
                                        Text(L10n.k("settings.language.follow_system"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if selectedLanguageOption.code == option.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.bouncy(scale: 0.98))
                    }
                } header: {
                    Text(L10n.k("settings.language.title"))
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.k("settings.language.footer"))
                        Text(L10n.f("settings.language.current", languageDisplayName(for: selectedLanguageOption)))
                    }
                }

                // Hazır Ayarlar (Emil Kowalski dokunsal kart seçimi)
                Section {
                    ForEach(PresetType.allCases, id: \.self) { preset in
                        Button {
                            DesignSystem.Haptics.selection()
                            withAnimation(DesignSystem.Springs.settle) {
                                applyPreset(preset)
                                selectedPreset = preset
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(selectedPreset == preset ? Color.blue.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                                        .frame(width: 38, height: 38)

                                    Image(systemName: preset.icon)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(selectedPreset == preset ? Color.blue : Color.secondary)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(preset.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(preset.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                if selectedPreset == preset {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(.blue)
                                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.bouncy(scale: 0.98))
                    }
                } header: {
                    Text(L10n.k("settings.quick.title"))
                } footer: {
                    Text(L10n.k("settings.quick.footer"))
                }

                // Genel Ayarlar (Benzerlik)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.similarity.title"))
                            Spacer()
                            Text(L10n.percent(similarityThreshold))
                                .font(.subheadline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill), in: Capsule())
                                .contentTransition(.numericText())
                                .animation(DesignSystem.Springs.interactive, value: similarityThreshold)
                        }

                        Slider(value: $similarityThreshold, in: 0.80...1.0, step: 0.05)
                            .tint(.blue)
                            .onChange(of: similarityThreshold) { _, _ in
                                updateSelectedPreset()
                            }

                        Text(L10n.k("settings.similarity.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                                .font(.subheadline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill), in: Capsule())
                                .contentTransition(.numericText())
                                .animation(DesignSystem.Springs.interactive, value: dateThreshold)
                        }

                        Slider(value: $dateThreshold, in: 1...60, step: 1)
                            .tint(.blue)
                            .onChange(of: dateThreshold) { _, _ in
                                updateSelectedPreset()
                            }

                        Text(L10n.k("settings.date_proximity.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.location_proximity.title"))
                            Spacer()
                            Text(L10n.f("settings.meters", Int(locationThreshold)))
                                .font(.subheadline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill), in: Capsule())
                                .contentTransition(.numericText())
                                .animation(DesignSystem.Springs.interactive, value: locationThreshold)
                        }

                        Slider(value: $locationThreshold, in: 10...1000, step: 10)
                            .tint(.blue)
                            .onChange(of: locationThreshold) { _, _ in
                                updateSelectedPreset()
                            }

                        Text(L10n.k("settings.location_proximity.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                                .font(.subheadline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill), in: Capsule())
                                .contentTransition(.numericText())
                                .animation(DesignSystem.Springs.interactive, value: blurThreshold)
                        }

                        Slider(value: $blurThreshold, in: 50...200, step: 10)
                            .tint(DesignSystem.Colors.warning)
                            .onChange(of: blurThreshold) { _, _ in
                                updateSelectedPreset()
                            }

                        Text(L10n.k("settings.blur_threshold.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.dark_threshold.title"))
                            Spacer()
                            Text(L10n.percent(darknessThreshold))
                                .font(.subheadline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill), in: Capsule())
                                .contentTransition(.numericText())
                                .animation(DesignSystem.Springs.interactive, value: darknessThreshold)
                        }

                        Slider(value: $darknessThreshold, in: 0.1...0.4, step: 0.05)
                            .tint(.purple)
                            .onChange(of: darknessThreshold) { _, _ in
                                updateSelectedPreset()
                            }

                        Text(L10n.k("settings.dark_threshold.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.k("settings.brightness_threshold.title"))
                            Spacer()
                            Text(L10n.percent(brightnessThreshold))
                                .font(.subheadline.monospacedDigit())
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill), in: Capsule())
                                .contentTransition(.numericText())
                                .animation(DesignSystem.Springs.interactive, value: brightnessThreshold)
                        }

                        Slider(value: $brightnessThreshold, in: 0.7...1.0, step: 0.05)
                            .tint(DesignSystem.Colors.favorite)
                            .onChange(of: brightnessThreshold) { _, _ in
                                updateSelectedPreset()
                            }

                        Text(L10n.k("settings.brightness_threshold.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text(L10n.k("settings.quality.title"))
                } footer: {
                    Text(L10n.k("settings.quality.footer"))
                }

                // Hakkında
                Section {
                    Button {
                        DesignSystem.Haptics.impact(.light)
                        ReviewManager.openAppStoreReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(DesignSystem.Colors.favorite)
                            Text(L10n.k("settings.about.rate_app"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.bouncy(scale: 0.98))

                    Button {
                        DesignSystem.Haptics.impact(.light)
                        ReviewManager.sendFeedbackEmail()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(.blue)
                            Text(L10n.k("settings.about.send_feedback"))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.bouncy(scale: 0.98))

                    if let privacyURL = URL(string: "https://tsavasci.github.io/Similarly/privacy.html") {
                        Link(destination: privacyURL) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .foregroundStyle(.green)
                                Text(L10n.k("settings.about.privacy_policy"))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    HStack {
                        Text(L10n.k("settings.about.version"))
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(L10n.k("settings.about.build"))
                        Spacer()
                        Text(appBuild)
                            .foregroundStyle(.secondary)
                    }

                    if let gitHubURL = URL(string: "https://github.com/tsavasci/Similarly") {
                        Link(destination: gitHubURL) {
                            HStack {
                                Text(L10n.k("settings.about.github"))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.forward.square")
                                    .font(.footnote)
                                    .foregroundStyle(.blue)
                            }
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
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }

                // Varsayılan Ayarlar
                Section {
                    Button(role: .destructive) {
                        DesignSystem.Haptics.notification(.warning)
                        withAnimation(DesignSystem.Springs.settle) {
                            resetToDefaults()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(L10n.k("settings.reset"))
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.bouncy(scale: 0.98))
                } footer: {
                    Text(L10n.k("settings.reset.footer"))
                }
            }
            .navigationTitle(L10n.k("settings.nav_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.ok")) {
                        DesignSystem.Haptics.impact(.light)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.fraction(0.92), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(DesignSystem.CornerRadius.sheet)
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

        let localeIdentifier: String
        if option.code == "zh-Hans" {
            localeIdentifier = "zh_Hans"
        } else if option.code == "pt-BR" {
            localeIdentifier = "pt_BR"
        } else {
            localeIdentifier = option.code
        }
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
