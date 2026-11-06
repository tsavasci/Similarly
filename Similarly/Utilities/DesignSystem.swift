//
//  DesignSystem.swift
//  Similarly
//
//  Design System tokens, Emil Kowalski tactile physics, and HIG-compliant styling.
//

import SwiftUI
import UIKit

public enum DesignSystem {
    public enum Colors {
        public static let accent = Color.accentColor
        public static let primaryGradient = LinearGradient(
            colors: [.blue, .purple],
            startPoint: .leading,
            endPoint: .trailing
        )
        public static let logoGradient = LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        public static let celebrationGradient = LinearGradient(
            colors: [.green, .blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        public static let success = Color.green
        public static let warning = Color.orange
        public static let destructive = Color.red
        public static let favorite = Color.yellow
        public static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
        public static let subtleBackground = Color(UIColor.tertiarySystemGroupedBackground)
    }

    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 20
        public static let xxl: CGFloat = 24
        public static let xxxl: CGFloat = 32
    }

    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 12
        public static let button: CGFloat = 14
        public static let cta: CGFloat = 15
        public static let card: CGFloat = 16
        public static let sheet: CGFloat = 28
        public static let celebration: CGFloat = 32
    }

    public enum Springs {
        /// Emil Kowalski tactile spring: snappy, interactive for button presses and quick toggles
        public static let interactive = Animation.spring(response: 0.28, dampingFraction: 0.72)
        /// Fluid settling spring for sheet cards, selection indicators, and morphs
        public static let settle = Animation.spring(response: 0.42, dampingFraction: 0.82)
        /// Bouncy spring for playful celebrations and badge appearances
        public static let bouncy = Animation.spring(response: 0.46, dampingFraction: 0.65)
        /// Smooth entrance spring for staggered sheet elements
        public static let entrance = Animation.spring(response: 0.50, dampingFraction: 0.78)
    }

    @MainActor
    public enum Haptics {
        public static func selection() {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }

        public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        }

        public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }
    }
}

/// Emil Kowalski responsive button style: scales down subtly on press with spring physics
public struct BouncyButtonStyle: ButtonStyle {
    var scale: CGFloat
    var pressedOpacity: Double

    public init(scale: CGFloat = 0.97, pressedOpacity: Double = 0.90) {
        self.scale = scale
        self.pressedOpacity = pressedOpacity
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .opacity(configuration.isPressed ? pressedOpacity : 1.0)
            .animation(DesignSystem.Springs.interactive, value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == BouncyButtonStyle {
    static var bouncy: BouncyButtonStyle { BouncyButtonStyle() }
    static func bouncy(scale: CGFloat = 0.97, pressedOpacity: Double = 0.90) -> BouncyButtonStyle {
        BouncyButtonStyle(scale: scale, pressedOpacity: pressedOpacity)
    }
}
