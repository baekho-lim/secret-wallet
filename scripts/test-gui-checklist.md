# Secret Wallet GUI -- Manual Test Checklist

> 하나씩 따라하면서 PASS/FAIL 체크하세요.
> 테스트 전 GUI 앱 빌드: `cd App && swift build -c release`

---

## 사전 준비

```bash
# CLI 바이너리 경로
BINARY="./.build/release/secret-wallet"

# GUI 앱 실행
open App/.build/release/SecretWalletApp
```

---

## P0: GUI 기능 테스트

### GUI-01: 앱 실행 -- 크래시 없음
- [ ] PASS / FAIL

1. `open App/.build/release/SecretWalletApp` 실행
2. 3초 기다림

**기대 결과**: "Secret Wallet" 윈도우가 나타남. 크래시 다이얼로그 없음.

---

### GUI-02: 빈 상태 표시
- [ ] PASS / FAIL

1. 저장된 키가 없는 상태에서 앱을 열거나, 모든 키를 삭제한 후 확인

**기대 결과**: 방패 아이콘 + "No API keys yet" 텍스트 + "Add Your First Key" 버튼 표시

---

### GUI-03: 키 추가 -- 전체 플로우
- [ ] PASS / FAIL

1. "Add Key" 버튼 클릭 (우상단 또는 빈 상태 버튼)
2. "Add API Key" 시트 등장
3. **OpenAI** 클릭 -> 초록색 하이라이트
4. 이름 필드에 "OpenAI" 자동 입력 확인
5. "Paste Your API Key" 필드에 `sk-test-1234567890` 입력
6. TouchID 토글 설정 (선택)
7. "Save Securely" 클릭
8. 시트 닫힘
9. 대시보드에 키 카드 등장

**기대 결과**: OpenAI 아이콘(초록) + 이름 + `OPENAI_API_KEY` env var 표시

---

### GUI-04: Save 버튼 비활성화
- [ ] PASS / FAIL

1. "Add Key" 클릭
2. 아무 서비스도 선택하지 않고 "Save Securely" 확인 -> 비활성화?
3. 서비스 선택 + 이름만 입력 (키 값 비움) -> 비활성화?
4. 서비스 선택 + 키 값만 입력 (이름 비움) -> 비활성화?

**기대 결과**: 이름과 키 값 모두 입력해야 Save 버튼 활성화

---

### GUI-05: 키 복사 -> 클립보드
- [ ] PASS / FAIL

1. 키 카드의 복사 아이콘 (사각형 2개) 클릭
2. TouchID 인증 (설정된 경우)
3. 텍스트에디터에서 Cmd+V

**기대 결과**: 복사 아이콘이 잠시 체크마크로 변함. 붙여넣기하면 저장한 키 값이 나옴.

---

### GUI-06: 클립보드 30초 후 자동 삭제
- [ ] PASS / FAIL

1. 키 복사 (GUI-05 수행)
2. 텍스트에디터에서 Cmd+V -> 값 확인
3. **35초 기다림** (타이머 사용)
4. 다시 Cmd+V

**기대 결과**: 35초 후에는 붙여넣기해도 아무것도 안 나옴 (클립보드 비워짐)

---

### GUI-07: 30초 내 다른 복사 시 유지
- [ ] PASS / FAIL

1. Secret Wallet에서 키 복사
2. **10초 이내에** 텍스트에디터에서 아무 텍스트 선택 후 Cmd+C
3. 35초 후 Cmd+V

**기대 결과**: 2번에서 복사한 텍스트가 그대로 유지됨 (삭제되지 않음)

---

### GUI-08: 키 삭제 확인 다이얼로그
- [ ] PASS / FAIL

1. 키 카드의 휴지통 아이콘 클릭
2. "Delete this key?" 다이얼로그 등장
3. **Cancel** 클릭 -> 키 유지 확인
4. 다시 휴지통 클릭
5. **Delete** (빨간 버튼) 클릭

**기대 결과**: Cancel 시 키 유지. Delete 시 키 사라짐.

---

### GUI-09: SecureField 마스킹
- [ ] PASS / FAIL

1. "Add Key" 클릭
2. "Paste Your API Key" 필드에 값 입력

**기대 결과**: 입력한 문자가 점(dots)으로 가려짐 (비밀번호 필드처럼)

---

## P0: 통합 테스트 (CLI <-> GUI)

### INT-01: CLI에서 추가 -> GUI에서 보임
- [ ] PASS / FAIL

1. 터미널: `echo "int-test-val" | ./.build/release/secret-wallet add int-test-key --env-name INT_VAR`
2. GUI 앱에서 대시보드 확인 (앱 재시작 필요할 수 있음)

**기대 결과**: `int-test-key` 가 GUI 대시보드에 나타남

**정리**: `./. build/release/secret-wallet remove int-test-key`

---

### INT-02: GUI에서 추가 -> CLI에서 조회
- [ ] PASS / FAIL

1. GUI에서 "Add Key" -> Other -> 이름: `gui-to-cli` -> 값: `gui-test-123`
2. 터미널: `./.build/release/secret-wallet list`
3. 터미널: `./.build/release/secret-wallet get gui-to-cli`

**기대 결과**: list에 `gui-to-cli` 표시. get 결과가 `gui-test-123`.

**정리**: `./.build/release/secret-wallet remove gui-to-cli`

---

### INT-03: CLI에서 삭제 -> GUI에서 사라짐
- [ ] PASS / FAIL

1. CLI로 키 추가: `echo "del-test" | ./.build/release/secret-wallet add del-test-key --env-name DEL_VAR`
2. GUI에서 확인 (보이는지)
3. CLI로 삭제: `./.build/release/secret-wallet remove del-test-key`
4. GUI 앱 재시작 또는 새로고침

**기대 결과**: 삭제 후 GUI에서 사라짐

---

## P1: 생체 인증 테스트 (TouchID 있는 Mac만)

### BIO-01: CLI에서 생체 키 추가
- [ ] PASS / FAIL

```bash
echo "bio-val" | ./.build/release/secret-wallet add bio-test --biometric --env-name BIO_VAR
./.build/release/secret-wallet list | grep bio-test
```

**기대 결과**: 추가 성공. list에서 잠금 아이콘 표시.

---

### BIO-02: 생체 키 조회 시 TouchID 프롬프트
- [ ] PASS / FAIL

```bash
./.build/release/secret-wallet get bio-test
```

**기대 결과**: 시스템 TouchID 다이얼로그 등장. 지문 인증 후 값 반환.

---

### BIO-03: TouchID 취소 시 에러
- [ ] PASS / FAIL

```bash
./.build/release/secret-wallet get bio-test
# TouchID 프롬프트에서 Cancel 또는 ESC
```

**기대 결과**: 에러 메시지 출력 (시크릿 값 아님). 비정상 종료 코드.

---

### BIO-04: 생체 키 삭제
- [ ] PASS / FAIL

```bash
./.build/release/secret-wallet remove bio-test
```

**기대 결과**: TouchID 인증 후 삭제 성공.

---

## 결과 요약

| 카테고리 | 총 | PASS | FAIL |
|----------|-----|------|------|
| GUI 기능 (P0) | 9 | | |
| 통합 (P0) | 3 | | |
| 생체 인증 (P1) | 4 | | |
| **합계** | **16** | | |

**릴리스 기준**: P0 전체 PASS 필수.

---

*테스트 완료 후 결과를 공유해주세요.*
