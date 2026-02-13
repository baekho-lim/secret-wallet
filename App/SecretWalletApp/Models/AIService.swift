import Foundation
import SwiftUI
import SecretWalletCore

enum ServiceColor: String, Sendable {
    case green, orange, blue, purple, gray

    var color: Color {
        switch self {
        case .green: return .green
        case .orange: return .orange
        case .blue: return .blue
        case .purple: return .purple
        case .gray: return .secondary
        }
    }
}

struct AIService: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let defaultEnvName: String
    let serviceColor: ServiceColor

    var swiftUIColor: Color { serviceColor.color }

    static let all: [AIService] = [
        AIService(id: "openai", name: "OpenAI", icon: "brain.head.profile", defaultEnvName: "OPENAI_API_KEY", serviceColor: .green),
        AIService(id: "anthropic", name: "Anthropic", icon: "sparkle", defaultEnvName: "ANTHROPIC_API_KEY", serviceColor: .orange),
        AIService(id: "google", name: "Google AI", icon: "globe", defaultEnvName: "GOOGLE_API_KEY", serviceColor: .blue),
        AIService(id: "openrouter", name: "OpenRouter", icon: "arrow.triangle.branch", defaultEnvName: "OPENROUTER_API_KEY", serviceColor: .purple),
        AIService(id: "other", name: "Other", icon: "key.fill", defaultEnvName: "API_KEY", serviceColor: .gray),
    ]
}

// GUI-only extension: displayName requires AIService (SwiftUI dependency)
extension SecretMetadata {
    var displayName: String {
        if let svc = serviceName,
           let service = AIService.all.first(where: { $0.id == svc }) {
            return service.name
        }
        return name
    }
}
