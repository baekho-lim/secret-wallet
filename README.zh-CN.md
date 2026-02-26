# Secret Wallet (简体中文)

> 面向 macOS 开发者的零配置 API Key 安全方案 -- CLI + GUI

Languages: [English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | **简体中文** | [Français](README.fr.md) | [Deutsch](README.de.md)

> Last synced with `README.md` commit: `abebbb3`

Secret Wallet 用 macOS Keychain 替代明文 `.env`。无需账号、无需订阅，安装后即可使用。

```bash
brew install baekho-lim/tap/secret-wallet
secret-wallet add OPENAI_KEY
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

## Why Not `.env` Files?

`.env` 默认明文落盘，泄露风险高。Secret Wallet 通过 Keychain 和进程隔离降低暴露面。

| 维度 | `.env` | Secret Wallet |
|------|--------|---------------|
| 存储 | 磁盘明文 | macOS Keychain (AES-256-GCM) |
| Git 风险 | 一次误提交即泄露 | 无可提交的密钥文件 |
| 访问控制 | 文件权限 | OS Keychain ACL |
| 进程隔离 | dotenv 全局注入 | 仅子进程可见 |
| 硬件安全 | 无 | Secure Enclave（生物密钥） |

## Installation

支持 Homebrew、源码编译、GUI 编译三种方式。

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

| Shortcut | Full Command | 说明 |
|----------|-------------|------|
| `sw` | `secret-wallet` | 基础命令 |
| `swa KEY` | `secret-wallet add KEY` | 新增密钥 |
| `swg KEY` | `secret-wallet get KEY` | 读取密钥 |
| `swl` | `secret-wallet list` | 查看列表 |
| `swr KEY` | `secret-wallet remove KEY` | 删除密钥 |
| `swi cmd` | `secret-wallet inject --only OPENAI_KEY -- cmd` | 注入并执行 |

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

可使用 `scripts/migrate-env.sh` 扫描并导入现有 `.env`。

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

| 命令 | 说明 | JSON |
|------|------|------|
| `init` | 验证 Keychain 可用性 | -- |
| `add <name>` | 存储密钥 | -- |
| `get <name>` | 读取密钥 | `--json` |
| `list` | 列出密钥 | `--json` |
| `remove <name>` | 删除密钥 | -- |
| `inject [filters] -- <cmd>` | 按过滤注入后执行 | -- |
| `status` | 输出系统状态(JSON) | Always JSON |
| `setup` | 安装 shell 别名 | -- |

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

仅所选密钥会注入到子进程环境变量，父 shell 不会被污染。

### Why repeated password prompts happen

常见原因：
1. 不加过滤时会加载全部已存储密钥
2. 自动化/测试连续调用 `inject`
3. Agent 连续调用 `get` / `inject`

缓解方式：
1. 优先使用 `--only` / `--only-env`
2. 先用 `--dry-run` 确认加载范围
3. 全量注入只在可信场景使用

### Legacy compatibility mode (inject all)

`secret-wallet inject -- <cmd>` 和 `secret-wallet inject --all -- <cmd>` 为兼容旧用法仍保留。仅在明确需要全量注入时使用。

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

提供基于 SwiftUI 的图形界面，便于非终端操作。

### Features

- 仪表盘列表/搜索
- 分步 Add Key 流程
- OpenAI/Anthropic/Google AI/OpenRouter 预设
- 一键复制 + 30 秒自动清空剪贴板
- GUI/CLI 共享存储

## Security Model

### Defense in Depth (7 layers)

1. 物理安全（FileVault）
2. Secure Enclave
3. Keychain ACL
4. 加密存储（AES-256-GCM）
5. 生物认证（可选）
6. 运行时注入
7. 子进程隔离

### Threat Mitigations

| 威胁 | 缓解 |
|------|------|
| 明文泄露 | Keychain 加密 |
| Git 误提交 | 无密钥文件可提交 |
| 恶意依赖读取 | ACL 阻断 |
| 内存转储 | 子进程隔离 |
| 非授权访问 | 生物认证（可选） |

## Comparison

| 维度 | `.env` | 1Password CLI | Secret Wallet |
|------|--------|---------------|---------------|
| 价格 | 免费 | 付费 | 免费 |
| 账号要求 | 否 | 是 | 否 |
| 配置成本 | 低 | 中 | 低 |
| 硬件级保护 | 无 | 有限 | Secure Enclave |
| 进程隔离 | 低 | 中 | 高 |

## Architecture

CLI 与 GUI 共用 `SecretWalletCore`。

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
- [x] v0.2.0 Shell 集成
- [x] v0.3.0-alpha GUI + JSON + status
- [ ] v0.3.0 GUI 打磨 + DMG
- [ ] v0.4.0 `.env` import 子命令
- [ ] v1.0.0 Stable

## FAQ

**Q: 每次都需要 TouchID 吗？**  
A: 不需要。只有用 `--biometric` 保存的密钥会触发认证。

**Q: 为什么密码提示弹窗很多？**  
A: 用 `--only` / `--only-env` / `--dry-run` 缩小注入范围。

**Q: GUI 和 CLI 是否共享密钥？**  
A: 是，二者共享同一 Keychain service 和 metadata。

**Q: package.json 如何配置？**
```json
{ "scripts": { "dev": "secret-wallet inject --only OPENAI_KEY -- next dev" } }
```

**Q: CI/CD 也适合用吗？**  
A: Secret Wallet 主要面向本地开发。CI/CD 建议使用平台原生密钥管理。

## Contributing

贡献方式见 [CONTRIBUTING.md](CONTRIBUTING.md)。

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build
cd App && swift build
```

## License

MIT License。详见 [LICENSE](LICENSE)。
