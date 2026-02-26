# Secret Wallet (日本語)

> macOS 開発者向けのゼロ設定 API キー保護ツール -- CLI + GUI

Languages: [English](README.md) | [한국어](README.ko.md) | **日本語** | [简体中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

> Last synced with `README.md` commit: `abebbb3`

Secret Wallet は平文 `.env` ファイルを macOS Keychain ベースの保護に置き換えます。アカウント不要、サブスク不要、インストール後すぐ利用できます。

```bash
brew install baekho-lim/tap/secret-wallet
secret-wallet add OPENAI_KEY
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

## Why Not `.env` Files?

`.env` はディスクに平文で残るため、漏えいリスクが高くなります。Secret Wallet は Keychain とプロセス分離でリスクを下げます。

| 項目 | `.env` | Secret Wallet |
|------|--------|---------------|
| 保存 | 平文ファイル | macOS Keychain (AES-256-GCM) |
| Git リスク | 誤コミットで漏えい | コミット対象の秘密ファイルなし |
| 制御 | ファイル権限 | OS Keychain ACL |
| 分離 | dotenv でグローバル読込 | 子プロセス限定 |
| HW 保護 | なし | Secure Enclave(生体キー) |

## Installation

Homebrew / ソースビルド / GUI ビルドのいずれかを選択します。

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

| Shortcut | Full Command | 説明 |
|----------|-------------|------|
| `sw` | `secret-wallet` | 基本コマンド |
| `swa KEY` | `secret-wallet add KEY` | 追加 |
| `swg KEY` | `secret-wallet get KEY` | 取得 |
| `swl` | `secret-wallet list` | 一覧 |
| `swr KEY` | `secret-wallet remove KEY` | 削除 |
| `swi cmd` | `secret-wallet inject --only OPENAI_KEY -- cmd` | 注入して実行 |

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

既存 `.env` は `scripts/migrate-env.sh` で移行できます。

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

| コマンド | 説明 | JSON |
|----------|------|------|
| `init` | Keychain 接続確認 | -- |
| `add <name>` | 保存 | -- |
| `get <name>` | 取得 | `--json` |
| `list` | 一覧 | `--json` |
| `remove <name>` | 削除 | -- |
| `inject [filters] -- <cmd>` | 選択注入して実行 | -- |
| `status` | 状態(JSON) | Always JSON |
| `setup` | エイリアス設定 | -- |

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

選択された秘密のみ子プロセスに注入され、親シェルは汚染されません。

### Why repeated password prompts happen

主な原因:
1. フィルタなし inject が保存済みキー全体を読み込む
2. 自動化/テストで inject を連続呼び出し
3. エージェントが get/inject を繰り返す

対策:
1. `--only` / `--only-env` を優先
2. 実行前に `--dry-run`
3. 全件注入は必要時のみ

### Legacy compatibility mode (inject all)

`secret-wallet inject -- <cmd>` と `secret-wallet inject --all -- <cmd>` は後方互換のため維持されています。意図的に全件注入する場合のみ使用してください。

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

SwiftUI ベースの GUI で端末なしでも秘密を管理できます。

### Features

- ダッシュボード一覧/検索
- Add Key の段階入力
- OpenAI/Anthropic/Google AI/OpenRouter プリセット
- コピー + 30秒後クリップボード消去
- GUI/CLI で同一ストレージ共有

## Security Model

### Defense in Depth (7 layers)

1. 物理保護(FileVault)
2. Secure Enclave
3. Keychain ACL
4. 暗号化保存(AES-256-GCM)
5. 生体認証(任意)
6. ランタイム注入
7. 子プロセス分離

### Threat Mitigations

| 脅威 | 対応 |
|------|------|
| 平文漏えい | Keychain 暗号化 |
| Git 誤コミット | 秘密ファイルなし |
| 悪性依存 | ACL で遮断 |
| メモリダンプ | 子プロセス限定 |
| 不正利用 | 生体認証(任意) |

## Comparison

| 項目 | `.env` | 1Password CLI | Secret Wallet |
|------|--------|---------------|---------------|
| 価格 | 無料 | 有料 | 無料 |
| アカウント | 不要 | 必要 | 不要 |
| セットアップ | 低 | 中 | 低 |
| HW セキュリティ | なし | 限定 | Secure Enclave |
| プロセス分離 | 低 | 中 | 高 |

## Architecture

CLI と GUI は `SecretWalletCore` を共有します。

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
- [x] v0.2.0 シェル統合
- [x] v0.3.0-alpha GUI + JSON + status
- [ ] v0.3.0 GUI 改善 + DMG
- [ ] v0.4.0 `.env` import コマンド
- [ ] v1.0.0 Stable

## FAQ

**Q: 毎回 TouchID は必要ですか？**  
A: `--biometric` で保存したキーにのみ認証が必要です。

**Q: パスワードプロンプトが多すぎます。**  
A: `--only` / `--only-env` / `--dry-run` で注入範囲を絞ってください。

**Q: GUI と CLI は同じキーを使いますか？**  
A: はい。同じ Keychain service と metadata を使用します。

**Q: package.json では?**
```json
{ "scripts": { "dev": "secret-wallet inject --only OPENAI_KEY -- next dev" } }
```

**Q: CI/CD でも使うべきですか？**  
A: Secret Wallet はローカル開発向けです。CI/CD は各プラットフォームの Secret 管理を推奨します。

## Contributing

貢献方法は [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build
cd App && swift build
```

## License

MIT License. 詳細は [LICENSE](LICENSE) を参照してください。
