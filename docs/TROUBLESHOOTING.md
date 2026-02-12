# Troubleshooting

> Secret Wallet 개발 중 발견한 문제와 해결 방법

---

## macOS Keychain `errSecMissingEntitlement` (-34018)

**증상**: GUI 앱에서 Save Securely 클릭 시 `Storage error (code: -34018)` 발생. CLI는 정상 동작.

**원인**: `swift build`로 빌드한 앱은 코드 서명이 없음. `SecAccessControlCreateWithFlags(.biometryCurrentSet)`로 생성한 biometric ACL은 **생성 자체는 성공**하지만, `SecItemAdd` 시점에 entitlement 검증이 실패함.

**핵심**: ACL 객체 생성 성공 != Keychain 저장 성공. 두 단계 모두에서 fallback이 필요.

**해결**:
```swift
var status = SecItemAdd(query as CFDictionary, nil)

// -34018: unsigned app can't use biometric ACL -- retry without
if status == errSecMissingEntitlement && biometricApplied {
    query.removeValue(forKey: kSecAttrAccessControl as String)
    query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    biometricApplied = false
    status = SecItemAdd(query as CFDictionary, nil)
}
```

**적용 범위**: CLI + GUI 양쪽 KeychainManager에 동일 패턴 적용.

**장기 해결**: Xcode 프로젝트로 전환 + 코드 서명 + Keychain Access Group entitlement 추가.

---

## SwiftUI 앱에서 print() 출력 안 보임

**증상**: `print()` 디버그 로그가 터미널에 출력되지 않음.

**원인**: GUI 앱은 stdout이 터미널에 연결되지 않음. `swift build`로 빌드 후 `open`으로 실행하면 stdout이 `/dev/null`로 리다이렉트됨.

**해결**: `os.log`의 `Logger` 사용.
```swift
import os.log
private let logger = Logger(subsystem: "com.secret-wallet", category: "MyView")
logger.warning("debug message")
```

**로그 확인**:
```bash
log show --predicate 'subsystem == "com.secret-wallet"' --last 2m --style compact
```

---

## SwiftUI 앱 창이 안 보임 (백그라운드 실행)

**증상**: `open .build/release/SecretWalletApp` 실행 후 앱이 Dock에만 나타나고 창이 보이지 않음.

**원인**: `swift build`로 빌드한 앱은 `.app` 번들이 아님. `open` 명령으로 실행 시 포커스를 받지 못함.

**해결**: `AppDelegate`에서 강제 활성화.
```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }
}
```

---

## delete-before-save에서 biometric 항목 삭제 실패

**증상**: 이미 biometric ACL로 저장된 항목을 덮어쓰기 할 때, `delete(key:)`에서 TouchID 프롬프트가 뜨거나 실패.

**원인**: `delete()` 함수가 `LAContext`를 query에 포함. biometric 보호된 항목 삭제 시 인증 필요.

**해결**: save 전 delete에서 `LAContext` 없이 `SecItemDelete` 직접 호출.
```swift
let deleteQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: key,
]
SecItemDelete(deleteQuery as CFDictionary)
```

---

## `symbolEffect(.bounce)` 컴파일 에러

**증상**: `symbolEffect(.bounce)` 사용 시 `'symbolEffect' is only available in macOS 14 or newer` 에러.

**원인**: 프로젝트 타겟이 macOS 13+. `symbolEffect`는 macOS 14+ API.

**해결**: `scaleEffect` 애니메이션으로 대체.
```swift
.scaleEffect(showSuccess ? 1.0 : 0.5)
```

---

## SwiftUI 에러 메시지가 사용자에게 안 보임

**증상**: 저장 실패 시 에러 메시지가 설정되지만 사용자가 볼 수 없음.

**원인**: 에러 텍스트가 `ScrollView` 내부에 위치. 스크롤하지 않으면 보이지 않음.

**해결**: 에러 메시지를 ScrollView 밖, Save 버튼 바로 위에 고정 배치.

---

## 개발 키워드

`Swift`, `SwiftUI`, `macOS`, `Keychain Services`, `Security.framework`,
`LocalAuthentication`, `LAContext`, `SecItemAdd`, `SecAccessControlCreateWithFlags`,
`errSecMissingEntitlement`, `biometryCurrentSet`, `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`,
`os.log`, `Logger`, `NSApplicationDelegateAdaptor`, `SPM (Swift Package Manager)`,
`swift-argument-parser`, `code signing`, `entitlements`
