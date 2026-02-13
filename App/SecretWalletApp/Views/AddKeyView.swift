import SwiftUI
import SecretWalletCore

struct AddKeyView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedService: AIService?
    @State private var keyName = ""
    @State private var keyValue = ""
    @State private var useBiometric = BiometricService.isAvailable
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var showDuplicateWarning = false
    @State private var pendingSaveName = ""
    @State private var pendingSaveValue = ""
    @State private var pendingSaveEnvName = ""

    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add API Key")
                    .font(.title2.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Step 1: Select service
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Select Service", systemImage: "1.circle.fill")
                            .font(.headline)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 10) {
                            ForEach(AIService.all) { service in
                                ServiceButton(
                                    service: service,
                                    isSelected: selectedService?.id == service.id
                                ) {
                                    selectedService = service
                                    if keyName.isEmpty {
                                        keyName = service.name
                                    }
                                }
                            }
                        }
                    }

                    // Step 2: Key name
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Name", systemImage: "2.circle.fill")
                            .font(.headline)

                        TextField("e.g. My OpenAI Key", text: $keyName)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Step 3: Paste key
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Paste Your API Key", systemImage: "3.circle.fill")
                            .font(.headline)

                        SecureField("sk-...", text: $keyValue)
                            .textFieldStyle(.roundedBorder)
                            .monospaced()

                        Text("Your key is encrypted and never leaves this device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Biometric toggle
                    if BiometricService.isAvailable {
                        Toggle(isOn: $useBiometric) {
                            HStack(spacing: 8) {
                                Image(systemName: "touchid")
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Require \(BiometricService.biometricTypeName)")
                                        .font(.body)
                                    Text("Extra protection for this key")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.switch)
                    }

                }
                .padding(24)
            }

            Divider()

            // Error (always visible above save button)
            if let errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
                .font(.callout)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            // Save button
            HStack {
                Spacer()
                Button {
                    saveKey()
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text("Save Securely")
                    }
                    .frame(width: 160, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyName.isEmpty || keyValue.isEmpty || isSaving)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding(16)
        }
        .frame(width: 460, height: 560)
        .overlay {
            if showSuccess {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.green)
                        .scaleEffect(showSuccess ? 1.0 : 0.5)
                    Text("Saved!")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccess)
        .alert("Key Already Exists", isPresented: $showDuplicateWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Replace", role: .destructive) { performSave() }
        } message: {
            Text("'\(pendingSaveName)' already exists. Replace with the new value?")
        }
    }

    private func saveKey() {
        errorMessage = nil

        let trimmedValue = keyValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            errorMessage = "Please enter a valid API key"
            return
        }

        let sanitizedName = keyName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }

        let envName = selectedService?.defaultEnvName
            ?? sanitizedName.uppercased().replacingOccurrences(of: "-", with: "_")

        // Store pending values for use after confirmation
        pendingSaveName = sanitizedName
        pendingSaveValue = trimmedValue
        pendingSaveEnvName = envName

        // Check for duplicate
        if MetadataStore.list().contains(where: { $0.name == sanitizedName }) {
            showDuplicateWarning = true
            return
        }

        performSave()
    }

    private func performSave() {
        isSaving = true

        Task {
            do {
                let biometricApplied = try KeychainManager.save(key: pendingSaveName, value: pendingSaveValue, biometric: useBiometric)

                let metadata = SecretMetadata(
                    name: pendingSaveName,
                    envName: pendingSaveEnvName,
                    biometric: biometricApplied,
                    serviceName: selectedService?.id,
                    createdAt: Date()
                )
                try MetadataStore.save(metadata)

                await MainActor.run {
                    keyValue = ""
                    isSaving = false
                    showSuccess = true
                    onSave()
                }

                try? await Task.sleep(nanoseconds: 1_000_000_000)

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ServiceButton: View {
    let service: AIService
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: service.icon)
                    .font(.title3)
                Text(service.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(isSelected ? service.swiftUIColor.opacity(0.15) : Color.secondary.opacity(0.06))
            .foregroundStyle(isSelected ? service.swiftUIColor : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? service.swiftUIColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
