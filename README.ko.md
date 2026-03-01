# Secret Wallet (한국어)

> macOS 개발자를 위한 제로-설정 API 키 보안 도구 -- CLI + GUI

Languages: [English](README.md) | **한국어** | [日本語](README.ja.md) | [简体中文](README.zh-CN.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

> Last synced with `README.md` commit: `abebbb3`

Secret Wallet은 평문 `.env` 파일을 macOS Keychain 기반 보안 저장소로 대체합니다. 계정/구독 없이 설치 즉시 사용할 수 있습니다.

```bash
brew install baekho-lim/tap/secret-wallet
secret-wallet add OPENAI_KEY
secret-wallet inject --only OPENAI_KEY -- npm run dev
```

## Why Not `.env` Files?

`.env`는 디스크 평문 저장이 기본이라 유출 위험이 높습니다. Secret Wallet은 Keychain + 프로세스 격리로 노출면을 줄입니다.

| 항목 | `.env` 파일 | Secret Wallet |
|------|-------------|---------------|
| 저장 | 디스크 평문 | macOS Keychain (AES-256-GCM) |
| Git 유출 | 실수 한 번으로 노출 | 커밋할 비밀 파일 없음 |
| 접근 통제 | 파일 권한 중심 | OS Keychain ACL |
| 프로세스 격리 | dotenv 전역 로딩 | 자식 프로세스 한정 |
| 하드웨어 보안 | 없음 | Secure Enclave(생체키) |

## Installation

설치 방법은 Homebrew, 소스 빌드, GUI 빌드 중 하나를 선택합니다.

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

| Shortcut | Full Command | 설명 |
|----------|-------------|------|
| `sw` | `secret-wallet` | 기본 명령 |
| `swa KEY` | `secret-wallet add KEY` | 시크릿 추가 |
| `swg KEY` | `secret-wallet get KEY` | 시크릿 조회 |
| `swl` | `secret-wallet list` | 목록 조회 |
| `swr KEY` | `secret-wallet remove KEY` | 시크릿 삭제 |
| `swi cmd` | `secret-wallet inject --only OPENAI_KEY -- cmd` | 주입 후 실행 |

## Quick Start

기본 사용 흐름은 추가 -> 검증 -> 실행입니다.

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

기존 `.env`는 `scripts/migrate-env.sh`로 스캔/미리보기/가져오기를 수행합니다.

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

핵심 명령과 옵션은 아래를 기준으로 사용합니다.

### Commands

| 명령 | 설명 | JSON |
|------|------|------|
| `init` | Keychain 접근 확인 | -- |
| `add <name>` | 시크릿 저장 | -- |
| `get <name>` | 시크릿 조회 | `--json` |
| `list` | 시크릿 목록 | `--json` |
| `remove <name>` | 시크릿 삭제 | -- |
| `inject [filters] -- <cmd>` | 선택 시크릿 주입 실행 | -- |
| `status` | 상태 출력(JSON) | Always JSON |
| `setup` | 셸 별칭 설치 | -- |

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

선택된 시크릿만 자식 프로세스 환경변수에 주입되며, 부모 셸은 오염되지 않습니다.

### Why repeated password prompts happen

반복 프롬프트 주요 원인:
1. 기본 주입(필터 미사용) 시 저장된 키 전부 로드
2. 자동화/테스트의 연속 `inject` 호출
3. 에이전트의 반복 `get`/`inject` 호출

완화 방법:
1. `--only`, `--only-env` 우선 사용
2. 실행 전 `--dry-run`으로 범위 확인
3. 전체 주입은 신뢰 워크플로에서만 사용

### Legacy compatibility mode (inject all)

`secret-wallet inject -- <cmd>` 및 `secret-wallet inject --all -- <cmd>`는 호환성 때문에 유지됩니다. 필요한 경우에만 사용하세요.

### Use in package.json

```json
{
  "scripts": {
    "dev": "secret-wallet inject --only OPENAI_KEY -- next dev",
    "build": "secret-wallet inject --only OPENAI_KEY -- next build"
  }
}
```

## Testing

빠른 CLI 검증(대부분의 변경 기본 경로):

```bash
./scripts/test-cli-fast.sh
```

Swift 스모크 검증(core + GUI build):

```bash
./scripts/test-swift-smoke.sh
```

전체 통합 검증:

```bash
./scripts/test-full.sh --full
```

상세 테스트 매트릭스/릴리스 게이트:
- `docs/TESTING_STRATEGY.md`

### Release tracks

- 전체 릴리스(`v*` 태그): CLI + GUI 아티팩트
- CLI 전용 릴리스(`cli-v*` 태그): CLI 아티팩트만 배포

## GUI App

터미널 없이 키를 관리할 수 있는 SwiftUI 기반 GUI 앱을 제공합니다.

### Features

- 대시보드 카드 목록/검색
- Add Key 단계형 입력
- 서비스 프리셋(OpenAI/Anthropic/Google AI/OpenRouter)
- 복사 + 30초 클립보드 자동 정리
- GUI/CLI 공유 저장소

## Security Model

보안 설계는 다중 방어(Defense in Depth)를 기본 원칙으로 둡니다.

### Defense in Depth (7 layers)

1. 물리 보안(FileVault)
2. Secure Enclave
3. Keychain ACL
4. 암호화 저장(AES-256-GCM)
5. 생체 인증(선택)
6. 런타임 주입
7. 자식 프로세스 격리

### Threat Mitigations

| 위협 | 대응 |
|------|------|
| 평문 탈취 | Keychain 암호화 저장 |
| Git 실수 커밋 | 비밀 파일 없음 |
| 악성 패키지 접근 | Keychain ACL 차단 |
| 메모리 덤프 | 자식 프로세스 한정 |
| 무단 사용 | 생체 인증(옵션) |

## Comparison

| 항목 | `.env` | 1Password CLI | Secret Wallet |
|------|--------|---------------|---------------|
| 가격 | 무료 | 유료 | 무료 |
| 계정 필요 | 아니오 | 예 | 아니오 |
| 설정 난이도 | 낮음 | 중간 | 낮음 |
| 하드웨어 보안 | 없음 | 제한적 | Secure Enclave |
| 프로세스 격리 | 낮음 | 중간 | 높음 |

## Architecture

CLI와 GUI는 공용 코어(`SecretWalletCore`)를 공유합니다.

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
- [x] v0.2.0 셸 통합
- [x] v0.3.0-alpha GUI + JSON + status
- [ ] v0.3.0 GUI 안정화 + DMG
- [ ] v0.4.0 `.env` import 커맨드
- [ ] v1.0.0 Stable

## FAQ

**Q: 매번 TouchID가 필요한가요?**  
A: 아닙니다. `--biometric`로 저장된 키에만 인증이 요구됩니다.

**Q: 비밀번호 프롬프트가 너무 자주 뜹니다.**  
A: `--only`, `--only-env`, `--dry-run`으로 주입 범위를 축소하세요.

**Q: GUI와 CLI가 키를 공유하나요?**  
A: 예. 동일한 Keychain service와 metadata를 사용합니다.

**Q: package.json에서 어떻게 쓰나요?**
```json
{ "scripts": { "dev": "secret-wallet inject --only OPENAI_KEY -- next dev" } }
```

**Q: CI/CD에서도 써야 하나요?**  
A: Secret Wallet은 로컬 개발 중심입니다. CI/CD는 플랫폼 비밀관리 사용을 권장합니다.

## Contributing

기여 가이드는 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요.

```bash
git clone https://github.com/baekho-lim/secret-wallet.git
cd secret-wallet && swift build
cd App && swift build
```

## License

MIT License. 자세한 내용은 [LICENSE](LICENSE)를 참고하세요.
