import Foundation
import SwiftUI

struct AIService: Identifiable {
    let id: String
    let name: String
    let icon: String
    let defaultEnvName: String
    let color: String

    var swiftUIColor: Color {
        switch color {
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        case "purple": return .purple
        default: return .secondary
        }
    }

    static let all: [AIService] = [
        AIService(id: "openai", name: "OpenAI", icon: "brain.head.profile", defaultEnvName: "OPENAI_API_KEY", color: "green"),
        AIService(id: "anthropic", name: "Anthropic", icon: "sparkle", defaultEnvName: "ANTHROPIC_API_KEY", color: "orange"),
        AIService(id: "google", name: "Google AI", icon: "globe", defaultEnvName: "GOOGLE_API_KEY", color: "blue"),
        AIService(id: "openrouter", name: "OpenRouter", icon: "arrow.triangle.branch", defaultEnvName: "OPENROUTER_API_KEY", color: "purple"),
        AIService(id: "other", name: "Other", icon: "key.fill", defaultEnvName: "API_KEY", color: "gray"),
    ]
}
