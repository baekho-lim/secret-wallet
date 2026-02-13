import Foundation

public struct SecretMetadata: Codable, Identifiable, Sendable {
    public let name: String
    public let envName: String
    public let biometric: Bool
    public var serviceName: String?
    public var createdAt: Date?

    public var id: String { name }

    public init(name: String, envName: String, biometric: Bool, serviceName: String? = nil, createdAt: Date? = nil) {
        self.name = name
        self.envName = envName
        self.biometric = biometric
        self.serviceName = serviceName
        self.createdAt = createdAt
    }
}
