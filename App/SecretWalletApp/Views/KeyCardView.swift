import SwiftUI

struct KeyCardView: View {
    let metadata: SecretMetadata
    let onCopy: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false
    @State private var copied = false
    @State private var isHoveringCopy = false
    @State private var isHoveringDelete = false

    private var serviceIcon: String {
        if let service = AIService.all.first(where: { $0.id == metadata.serviceName }) {
            return service.icon
        }
        return "key.fill"
    }

    private var serviceColor: Color {
        if let service = AIService.all.first(where: { $0.id == metadata.serviceName }) {
            return service.swiftUIColor
        }
        return .secondary
    }

    var body: some View {
        HStack(spacing: 14) {
            // Service icon
            Image(systemName: serviceIcon)
                .font(.title2)
                .foregroundStyle(serviceColor)
                .frame(width: 40, height: 40)
                .background(serviceColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            // Key info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(metadata.displayName)
                        .font(.headline)
                    if metadata.biometric {
                        Image(systemName: "touchid")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(metadata.envName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button {
                    onCopy()
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.body)
                        .frame(width: 32, height: 32)
                        .background(isHoveringCopy ? Color.secondary.opacity(0.1) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(copied ? .green : isHoveringCopy ? .primary : .secondary)
                .onHover { isHoveringCopy = $0 }
                .help("Copy key to clipboard")

                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .frame(width: 32, height: 32)
                        .background(isHoveringDelete ? Color.red.opacity(0.1) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(isHoveringDelete ? .red : .secondary)
                .onHover { isHoveringDelete = $0 }
                .help("Delete key")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
        .alert("Delete this key?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("'\(metadata.displayName)' will be permanently removed from your secure storage.")
        }
    }
}
