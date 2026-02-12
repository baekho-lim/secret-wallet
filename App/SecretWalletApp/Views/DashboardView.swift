import SwiftUI
import AppKit

struct DashboardView: View {
    @State private var secrets: [SecretMetadata] = []
    @State private var showAddSheet = false
    @State private var searchText = ""
    @State private var alertMessage: String?
    @State private var showAlert = false

    private var filteredSecrets: [SecretMetadata] {
        if searchText.isEmpty { return secrets }
        return secrets.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.envName.localizedCaseInsensitiveContains(searchText) ||
            ($0.serviceName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            Divider()

            // Content
            if secrets.isEmpty {
                emptyStateView
            } else {
                keyListView
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { loadSecrets() }
        .sheet(isPresented: $showAddSheet) {
            AddKeyView { loadSecrets() }
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "Something went wrong")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Secret Wallet")
                    .font(.title.bold())
                Text("\(secrets.count) key\(secrets.count == 1 ? "" : "s") secured")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showAddSheet = true
            } label: {
                Label("Add Key", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: 8) {
                Text("No API keys yet")
                    .font(.title3.bold())
                Text("Add your first API key to keep it safe.\nNo more plaintext config files.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddSheet = true
            } label: {
                Label("Add Your First Key", systemImage: "plus.circle.fill")
                    .frame(width: 200, height: 40)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Key List

    private var keyListView: some View {
        VStack(spacing: 0) {
            // Search bar
            if secrets.count > 3 {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search keys...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredSecrets) { secret in
                        KeyCardView(
                            metadata: secret,
                            onCopy: { copyKey(secret) },
                            onDelete: { deleteKey(secret) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Actions

    private func loadSecrets() {
        secrets = MetadataStore.list()
    }

    private func copyKey(_ secret: SecretMetadata) {
        do {
            let value = try KeychainManager.get(
                key: secret.name,
                prompt: "Copy '\(secret.displayName)' to clipboard"
            )
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(value, forType: .string)

            // Auto-clear clipboard after 30 seconds using changeCount (avoids holding secret in closure)
            let changeCount = NSPasteboard.general.changeCount
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                if NSPasteboard.general.changeCount == changeCount {
                    NSPasteboard.general.clearContents()
                }
            }
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func deleteKey(_ secret: SecretMetadata) {
        do {
            try KeychainManager.delete(
                key: secret.name,
                prompt: "Delete '\(secret.displayName)'"
            )
            try MetadataStore.delete(name: secret.name)
            loadSecrets()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
}
