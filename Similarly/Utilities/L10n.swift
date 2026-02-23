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
        return String(format: format, locale: Locale(identifier: selectedLanguageCode), arguments: args)
    }

    #if canImport(SwiftUI)
    static func k(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }
    #endif
}
