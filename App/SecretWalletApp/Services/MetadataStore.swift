import Foundation

enum MetadataStore {
    private static let queue = DispatchQueue(label: "com.secret-wallet.metadata")

    private static var metadataURL: URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory not available")
        }
        let dir = appSupport.appendingPathComponent("secret-wallet")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("metadata.json")
    }

    static func save(_ metadata: SecretMetadata) throws {
        try queue.sync {
            var all = readAll()
            all.removeAll { $0.name == metadata.name }
            all.append(metadata)
            try writeAll(all)
        }
    }

    static func list() -> [SecretMetadata] {
        queue.sync { readAll() }
    }

    static func delete(name: String) throws {
        try queue.sync {
            var all = readAll()
            all.removeAll { $0.name == name }
            try writeAll(all)
        }
    }

    private static func readAll() -> [SecretMetadata] {
        guard let data = try? Data(contentsOf: metadataURL) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SecretMetadata].self, from: data)) ?? []
    }

    private static func writeAll(_ items: [SecretMetadata]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(items)
        try data.write(to: metadataURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadataURL.path)
    }
}
