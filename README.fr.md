# Secret Wallet (Français)

> Sécurité API key zéro configuration pour développeurs macOS -- CLI + GUI

Languages: [English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | **Français** | [Deutsch](README.de.md)

> Last synced with `README.md` commit: `abebbb3`

Secret Wallet remplace les fichiers `.env` en clair par le trousseau macOS (Keychain). Aucun compte, aucun abonnement, installation immédiate.

```bash
brew install baekho-lim/tap/secret-wallet
secret-wallet add OPENAI_KEY
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

## Why Not `.env` Files?

Les `.env` restent en clair sur disque. Secret Wallet réduit ce risque avec Keychain + isolation de processus.

| Aspect | `.env` | Secret Wallet |
|--------|--------|---------------|
| Stockage | Fichier en clair | macOS Keychain (AES-256-GCM) |
| Risque Git | Fuite via commit accidentel | Aucun fichier secret à commit |
| Contrôle d'accès | Permissions fichier | ACL Keychain |
| Isolation | Chargement global dotenv | Processus enfant uniquement |
| Matériel sécurisé | Non | Secure Enclave |

## Installation

Installez via Homebrew, build source ou build GUI.

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

| Shortcut | Full Command | Description |
|----------|-------------|-------------|
| `sw` | `secret-wallet` | Commande de base |
| `swa KEY` | `secret-wallet add KEY` | Ajouter |
| `swg KEY` | `secret-wallet get KEY` | Lire |
| `swl` | `secret-wallet list` | Lister |
| `swr KEY` | `secret-wallet remove KEY` | Supprimer |
| `swi cmd` | `secret-wallet inject --only OPENAI_KEY -- cmd` | Injecter + exécuter |

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

Utilisez `scripts/migrate-env.sh` pour scanner/prévisualiser/importer.

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

| Commande | Description | JSON |
|----------|-------------|------|
| `init` | Vérifier l'accès Keychain | -- |
| `add <name>` | Stocker un secret | -- |
| `get <name>` | Récupérer un secret | `--json` |
| `list` | Lister les secrets | `--json` |
| `remove <name>` | Supprimer un secret | -- |
| `inject [filters] -- <cmd>` | Injecter les secrets sélectionnés | -- |
| `status` | État système (JSON) | Always JSON |
| `setup` | Installer les alias shell | -- |

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

Seuls les secrets sélectionnés sont injectés dans le processus enfant; le shell parent reste intact.

### Why repeated password prompts happen

Causes fréquentes:
1. inject sans filtre charge tous les secrets
2. tests/automatisation appellent inject en boucle
3. l'agent répète get/inject

Réduction des prompts:
1. privilégier `--only` / `--only-env`
2. vérifier la portée via `--dry-run`
3. réserver l'injection complète aux workflows de confiance

### Legacy compatibility mode (inject all)

`secret-wallet inject -- <cmd>` et `secret-wallet inject --all -- <cmd>` restent disponibles pour compatibilité. À utiliser uniquement si l'injection complète est intentionnelle.

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

Application SwiftUI native pour gérer les secrets sans terminal.

### Features

- Dashboard avec recherche
- Flux Add Key en étapes
- Préréglages OpenAI/Anthropic/Google AI/OpenRouter
- Copie + purge presse-papiers après 30s
- Stockage partagé GUI/CLI

## Security Model

### Defense in Depth (7 layers)

1. Sécurité physique (FileVault)
2. Secure Enclave
3. ACL Keychain
4. Stockage chiffré (AES-256-GCM)
5. Biométrie (optionnelle)
6. Injection runtime
7. Isolation processus enfant

### Threat Mitigations

| Menace | Mitigation |
|--------|------------|
| Vol en clair | Chiffrement Keychain |
| Commit Git accidentel | Aucun fichier secret |
| Dépendance malveillante | ACL Keychain |
| Dump mémoire | Isolation enfant |
| Accès non autorisé | Biométrie optionnelle |

## Comparison

| Aspect | `.env` | 1Password CLI | Secret Wallet |
|--------|--------|---------------|---------------|
| Prix | Gratuit | Payant | Gratuit |
| Compte requis | Non | Oui | Non |
| Setup | Faible | Moyen | Faible |
| Sécurité matérielle | Non | Partielle | Secure Enclave |
| Isolation processus | Faible | Moyenne | Forte |

## Architecture

CLI et GUI partagent `SecretWalletCore`.

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
- [x] v0.2.0 intégration shell
- [x] v0.3.0-alpha GUI + JSON + status
- [ ] v0.3.0 stabilisation GUI + DMG
- [ ] v0.4.0 commande import `.env`
- [ ] v1.0.0 Stable

## FAQ

**Q: TouchID est-il requis à chaque fois ?**  
A: Non. Seulement pour les secrets ajoutés avec `--biometric`.

**Q: Pourquoi autant de prompts mot de passe ?**  
A: Réduisez la portée avec `--only`, `--only-env`, `--dry-run`.

**Q: GUI et CLI partagent-ils les mêmes secrets ?**  
A: Oui, même service Keychain et même metadata.

**Q: Exemple package.json ?**
```json
{ "scripts": { "dev": "secret-wallet inject --only OPENAI_KEY -- next dev" } }
```

**Q: Et pour CI/CD ?**  
A: Secret Wallet cible le dev local. En CI/CD, utilisez le secret manager natif de la plateforme.

## Contributing

Voir [CONTRIBUTING.md](CONTRIBUTING.md).

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build
cd App && swift build
```

## License

Licence MIT. Voir [LICENSE](LICENSE).
