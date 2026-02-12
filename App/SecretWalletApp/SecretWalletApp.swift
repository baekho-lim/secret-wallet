import SwiftUI

@main
struct SecretWalletApp: App {
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .frame(minWidth: 480, minHeight: 520)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 520, height: 600)
    }
}
