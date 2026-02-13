import ArgumentParser
import Foundation

struct Setup: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Install shell completions and aliases"
    )

    func run() throws {
        let shellName = ProcessInfo.processInfo.environment["SHELL"].flatMap { URL(fileURLWithPath: $0).lastPathComponent } ?? "zsh"

        guard shellName == "zsh" || shellName == "bash" else {
            print("❌ Unsupported shell: \(shellName) (zsh/bash only)")
            throw ExitCode.failure
        }

        let rcFile = shellName == "zsh" ? "\(NSHomeDirectory())/.zshrc" : "\(NSHomeDirectory())/.bashrc"
        let marker = "# >>> secret-wallet shell integration >>>"
        let endMarker = "# <<< secret-wallet shell integration <<<"

        let existing = (try? String(contentsOfFile: rcFile, encoding: .utf8)) ?? ""

        if existing.contains(marker) {
            print("✅ Shell integration already installed in \(rcFile)")
            print("   To reinstall, remove the secret-wallet block first.")
            return
        }

        let snippet = """

\(marker)
alias sw='secret-wallet'
alias swa='secret-wallet add'
alias swg='secret-wallet get'
alias swl='secret-wallet list'
alias swr='secret-wallet remove'
swi() { secret-wallet inject -- "$@"; }
\(endMarker)
"""

        let newContent = existing + snippet
        do {
            try newContent.write(to: URL(fileURLWithPath: rcFile), atomically: true, encoding: .utf8)
        } catch {
            print("❌ Failed to write to \(rcFile): \(error.localizedDescription)")
            throw ExitCode.failure
        }

        print("✅ Shell integration installed in \(rcFile)")
        print("")
        print("Available shortcuts:")
        print("  sw   → secret-wallet")
        print("  swa  → secret-wallet add")
        print("  swg  → secret-wallet get")
        print("  swl  → secret-wallet list")
        print("  swr  → secret-wallet remove")
        print("  swi  → secret-wallet inject --")
        print("")
        print("Run 'source \(rcFile)' or open a new terminal to activate.")
    }
}
