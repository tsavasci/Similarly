//
//  L10n.swift
//  Similarly
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

enum L10n {
    private static let languagePreferenceKey = "appLanguage"

    private static let supportedLanguages: [String] = [
        "en", "tr", "ar", "zh-Hans", "es", "fr", "de", "ja",
    ]

    static func resolvedLanguageCode(for preference: String) -> String {
        if preference == "system" {
            return resolveSupportedLanguage(from: Locale.preferredLanguages.first ?? "en")
        }
        return resolveSupportedLanguage(from: preference)
    }

    private static var selectedLanguageCode: String {
        let preference = UserDefaults.standard.string(forKey: languagePreferenceKey) ?? "system"
        return resolvedLanguageCode(for: preference)
    }

    private static var localizedBundle: Bundle {
        bundle(for: selectedLanguageCode)
    }

    private static func bundle(for languageCode: String) -> Bundle {
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        {
            return bundle
        }
        if languageCode.contains("-"),
            let baseCode = languageCode.split(separator: "-").first,
            let path = Bundle.main.path(forResource: String(baseCode), ofType: "lproj"),
            let bundle = Bundle(path: path)
        {
            return bundle
        }
        return Bundle.main
    }

    private static func resolveSupportedLanguage(from identifier: String) -> String {
        let normalized = identifier.lowercased().replacingOccurrences(of: "_", with: "-")

        if normalized.hasPrefix("tr") { return "tr" }
        if normalized.hasPrefix("ar") { return "ar" }
        if normalized.hasPrefix("zh") { return "zh-Hans" }
        if normalized.hasPrefix("es") { return "es" }
        if normalized.hasPrefix("fr") { return "fr" }
        if normalized.hasPrefix("de") { return "de" }
        if normalized.hasPrefix("ja") { return "ja" }
        if normalized.hasPrefix("en") { return "en" }

        return supportedLanguages.contains(identifier) ? identifier : "en"
    }

    static func t(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func f(_ key: String, _ args: CVarArg...) -> String {
        let format = t(key)
        return String(format: format, locale: appLocale, arguments: args)
    }

    /// Uygulama dili + cihaz bölgesi (örn. "ar" + SA → ar_SA). Metin, sayı, yüzde ve tarihler hep bu
    /// yerel ayarla biçimlenir; aksi halde aynı ekranda farklı rakam stilleri (٢ ve 2) karışıyordu.
    static func locale(forLanguage code: String) -> Locale {
        guard let region = Locale.current.region?.identifier else { return Locale(identifier: code) }
        return Locale(identifier: "\(code)_\(region)")
    }

    static var appLocale: Locale {
        locale(forLanguage: selectedLanguageCode)
    }

    static func number(_ value: Int) -> String {
        value.formatted(.number.locale(appLocale))
    }

    static func bytes(_ value: Int64) -> String {
        value.formatted(.byteCount(style: .file).locale(appLocale))
    }

    static func date(_ date: Date, time: Date.FormatStyle.TimeStyle = .omitted) -> String {
        date.formatted(Date.FormatStyle(date: .numeric, time: time).locale(appLocale))
    }

    /// Oranı (0-1) seçili uygulama dilinin kurallarına göre yüzde olarak yazar: "%98", "98 %", "٩٨٪"...
    static func percent(_ fraction: Double) -> String {
        fraction.formatted(
            .percent.precision(.fractionLength(0)).locale(appLocale)
        )
    }

    #if canImport(SwiftUI)
    static func k(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }
    #endif
}
