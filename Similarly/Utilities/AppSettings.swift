//
//  AppSettings.swift
//  Similarly
//
//  Created by AI Agent
//

import Foundation

nonisolated enum AppDefaults {
    static let similarityThreshold: Double = 0.85
    static let dateThresholdSeconds: Double = 5.0
    static let locationThresholdMeters: Double = 100.0
    static let blurThreshold: Double = 100.0
    static let darknessThreshold: Double = 0.2
    static let brightnessThreshold: Double = 0.9
}

nonisolated extension UserDefaults {
    /// Returns a default value only when the key has never been set.
    func doubleValue(forKey key: String, default defaultValue: Double) -> Double {
        guard object(forKey: key) != nil else { return defaultValue }
        return double(forKey: key)
    }
}
