import Foundation

struct SecretMetadata: Codable, Identifiable {
    let name: String
    let envName: String
    let biometric: Bool
    var serviceName: String?
    var createdAt: Date?

    var id: String { name }

    var displayName: String {
        if let svc = serviceName,
           let service = AIService.all.first(where: { $0.id == svc }) {
            return service.name
        }
        return name
    }
}
