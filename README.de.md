# Secret Wallet (Deutsch)

> Zero-Config API-Key-Sicherheit für macOS-Entwickler -- CLI + GUI

Languages: [English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [Français](README.fr.md) | **Deutsch**

> Last synced with `README.md` commit: `abebbb3`

Secret Wallet ersetzt Klartext-`.env`-Dateien durch macOS Keychain-Speicherung. Kein Konto, kein Abo, sofort nutzbar.

```bash
brew install baekho-lim/tap/secret-wallet
secret-wallet add OPENAI_KEY
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

## Why Not `.env` Files?

`.env` liegt typischerweise im Klartext auf der Festplatte. Secret Wallet reduziert Risiken durch Keychain + Prozessisolation.

| Aspekt | `.env` | Secret Wallet |
|--------|--------|---------------|
| Speicherung | Klartextdatei | macOS Keychain (AES-256-GCM) |
| Git-Risiko | Leck durch Fehl-Commit | Keine Secret-Dateien zum Committen |
| Zugriffskontrolle | Dateirechte | OS Keychain ACL |
| Isolation | Global via dotenv | Nur Kindprozess |
| Hardware-Schutz | Nein | Secure Enclave |

## Installation

Installation per Homebrew, Source-Build oder GUI-Build.

### Homebrew (recommended)

```bash
brew install baekho-lim/tap/secret-wallet
```

### Build from source

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet
swift build -c release
cp .build/release/secret-wallet /usr/local/bin/
```

### GUI App

```bash
cd secret-wallet/App
swift build -c release
open .build/release/SecretWalletApp
```

### Shell Aliases (optional)

```bash
secret-wallet setup
source ~/.zshrc
```

| Shortcut | Full Command | Beschreibung |
|----------|-------------|--------------|
| `sw` | `secret-wallet` | Basisbefehl |
| `swa KEY` | `secret-wallet add KEY` | Secret hinzufügen |
| `swg KEY` | `secret-wallet get KEY` | Secret lesen |
| `swl` | `secret-wallet list` | Liste anzeigen |
| `swr KEY` | `secret-wallet remove KEY` | Secret löschen |
| `swi cmd` | `secret-wallet inject --only OPENAI_KEY -- cmd` | Inject + ausführen |

## Quick Start

### 1. Add your first key

```bash
secret-wallet add OPENAI_KEY
# Enter value (hidden input): sk-proj-xxxxxxxx
```

### 2. Verify

```bash
secret-wallet list
secret-wallet status
```

### 3. Use in your project

```bash
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

## Migrating from `.env` Files

Mit `scripts/migrate-env.sh` kannst du `.env`-Dateien scannen/vorprüfen/importieren.

### Scan your projects

```bash
./scripts/migrate-env.sh --scan ~/projects
```

### Preview (no changes)

```bash
./scripts/migrate-env.sh .env.local --dry-run --all
```

### Import

```bash
./scripts/migrate-env.sh .env.local
./scripts/migrate-env.sh .env.local --all
```

## CLI Reference

### Commands

| Befehl | Beschreibung | JSON |
|--------|--------------|------|
| `init` | Keychain-Zugriff prüfen | -- |
| `add <name>` | Secret speichern | -- |
| `get <name>` | Secret abrufen | `--json` |
| `list` | Secrets listen | `--json` |
| `remove <name>` | Secret löschen | -- |
| `inject [filters] -- <cmd>` | Ausgewählte Secrets injizieren | -- |
| `status` | Systemstatus (JSON) | Always JSON |
| `setup` | Shell-Aliase installieren | -- |

### Options

```bash
secret-wallet add my-key --env-name CUSTOM_ENV_VAR
secret-wallet add production-db --biometric
secret-wallet get OPENAI_KEY --json
secret-wallet list --json
secret-wallet status
secret-wallet inject --only OPENAI_KEY -- npm run dev
secret-wallet inject --only-env OPENAI_API_KEY -- npm run dev
secret-wallet inject --all -- npm run dev
secret-wallet inject --dry-run --only OPENAI_KEY -- npm run dev
```

### Process Isolation

```bash
secret-wallet inject --only OPENAI_KEY -- node server.js
```

Nur ausgewählte Secrets werden in den Kindprozess gesetzt; die Eltern-Shell bleibt unverändert.

### Why repeated password prompts happen

Häufige Ursachen:
1. Inject ohne Filter lädt alle gespeicherten Secrets
2. Automatisierung/Tests rufen inject mehrfach auf
3. Agent ruft get/inject wiederholt auf

Reduzierung:
1. `--only` / `--only-env` bevorzugen
2. Vorher `--dry-run` nutzen
3. Vollinjektion nur in vertrauenswürdigen Workflows

### Legacy compatibility mode (inject all)

`secret-wallet inject -- <cmd>` und `secret-wallet inject --all -- <cmd>` bleiben aus Kompatibilitätsgründen erhalten. Nur gezielt verwenden.

### Use in package.json

```json
{
  "scripts": {
    "dev": "secret-wallet inject --only OPENAI_KEY -- next dev",
    "build": "secret-wallet inject --only OPENAI_KEY -- next build"
  }
}
```

## GUI App

Native SwiftUI-App für Secret-Management ohne Terminal.

### Features

- Dashboard mit Suche
- Add-Key Schritt-für-Schritt
- Presets für OpenAI/Anthropic/Google AI/OpenRouter
- Copy + Clipboard-Reset nach 30 Sekunden
- Gemeinsamer Speicher für GUI/CLI

## Security Model

### Defense in Depth (7 layers)

1. Physische Sicherheit (FileVault)
2. Secure Enclave
3. Keychain ACL
4. Verschlüsselte Speicherung (AES-256-GCM)
5. Biometrie (optional)
6. Runtime-Injection
7. Kindprozess-Isolation

### Threat Mitigations

| Bedrohung | Schutz |
|-----------|--------|
| Klartext-Leak | Keychain-Verschlüsselung |
| Git-Fehl-Commit | Keine Secret-Dateien |
| Bösartige Pakete | ACL blockiert Zugriff |
| Memory-Dump | Kindprozess-Isolation |
| Unbefugter Zugriff | Optionale Biometrie |

## Comparison

| Aspekt | `.env` | 1Password CLI | Secret Wallet |
|--------|--------|---------------|---------------|
| Preis | Kostenlos | Kostenpflichtig | Kostenlos |
| Konto nötig | Nein | Ja | Nein |
| Setup-Aufwand | Niedrig | Mittel | Niedrig |
| Hardware-Sicherheit | Nein | Teilweise | Secure Enclave |
| Prozessisolation | Niedrig | Mittel | Hoch |

## Architecture

CLI und GUI teilen sich `SecretWalletCore`.

### Project Structure

```text
secret-wallet/
├── Sources/SecretWalletCore/
├── Sources/secret-wallet/Commands/
├── App/SecretWalletApp/
├── scripts/
└── docs/
```

### Shared Storage

- Keychain service: `com.secret-wallet`
- Metadata: `~/Library/Application Support/secret-wallet/metadata.json`

## Use Cases

### Next.js / Node.js Project

```bash
./scripts/migrate-env.sh .env.local --all
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

### OpenClaw / AI Agents

```bash
secret-wallet add anthropic --env-name ANTHROPIC_API_KEY
secret-wallet inject --only anthropic -- moltbot chat "Hello"
```

### Multi-Key Workflows

```bash
secret-wallet add openai --env-name OPENAI_API_KEY
secret-wallet add anthropic --env-name ANTHROPIC_API_KEY
secret-wallet add supabase --env-name SUPABASE_SERVICE_ROLE_KEY
secret-wallet inject --only openai --only anthropic --only supabase -- ./multi-agent-orchestrator.sh
```

### Vercel / CI Deployment

```bash
secret-wallet add vercel-token --env-name VERCEL_TOKEN
secret-wallet inject --only vercel-token -- vercel deploy --prod
```

## Roadmap

- [x] v0.1.0 CLI MVP
- [x] v0.2.0 Shell-Integration
- [x] v0.3.0-alpha GUI + JSON + status
- [ ] v0.3.0 GUI-Polish + DMG
- [ ] v0.4.0 `.env` import command
- [ ] v1.0.0 Stable

## FAQ

**Q: Brauche ich immer TouchID?**  
A: Nein. Nur für Keys mit `--biometric`.

**Q: Warum so viele Passwort-Prompts?**  
A: Mit `--only`, `--only-env`, `--dry-run` den Umfang verkleinern.

**Q: Teilen GUI und CLI dieselben Keys?**  
A: Ja, gleicher Keychain-Service und gleiche Metadata-Datei.

**Q: package.json Beispiel?**
```json
{ "scripts": { "dev": "secret-wallet inject --only OPENAI_KEY -- next dev" } }
```

**Q: Für CI/CD geeignet?**  
A: Secret Wallet ist primär für lokale Entwicklung. Für CI/CD bitte Plattform-Secret-Manager nutzen.

## Contributing

Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build
cd App && swift build
```

## License

MIT License. Siehe [LICENSE](LICENSE).
