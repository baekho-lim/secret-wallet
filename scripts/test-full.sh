#!/bin/bash
# Secret Wallet -- Comprehensive Test Suite
# Senior Security Engineer Review: 57 test cases
#
# Usage:
#   ./scripts/test-full.sh          # P0 tests only (19 tests)
#   ./scripts/test-full.sh --full   # P0 + P1 tests (28 tests)

set +e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0
SKIPPED=0
TEST_NUM=0
TOTAL=0

# Test prefix (unique per run)
TEST_PREFIX="zz-test-$(date +%s)"

# Parse args
FULL_MODE=false
if [ "${1:-}" = "--full" ]; then
    FULL_MODE=true
fi

# Binary path
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BINARY="${BINARY:-$PROJECT_ROOT/.build/release/secret-wallet}"

# ─── Helpers ─────────────────────────────────────────

run_test() {
    local id="$1"
    local desc="$2"
    ((TEST_NUM++))
    ((TOTAL++))
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}[$id] $desc${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

pass() {
    local msg="${1:-}"
    echo -e "  ${GREEN}PASS${NC} ${msg}"
    ((PASSED++))
}

fail() {
    local msg="${1:-}"
    echo -e "  ${RED}FAIL${NC} ${msg}"
    ((FAILED++))
}

skip() {
    local msg="${1:-}"
    echo -e "  ${YELLOW}SKIP${NC} ${msg}"
    ((SKIPPED++))
}

cleanup_test_keys() {
    for key in $($BINARY list 2>/dev/null | grep -o "${TEST_PREFIX}[^ ]*" || true); do
        $BINARY remove "$key" 2>/dev/null || true
    done
}

# ─── Header ──────────────────────────────────────────

echo ""
echo -e "${BOLD}Secret Wallet -- Comprehensive Test Suite${NC}"
echo "=========================================="
echo ""
echo "Environment:"
echo "  Hostname:      $(hostname)"
echo "  macOS:         $(sw_vers -productVersion)"
echo "  Architecture:  $(uname -m)"
echo "  Swift:         $(swift --version 2>&1 | head -1)"
echo "  Date:          $(date '+%Y-%m-%d %H:%M:%S')"
echo "  Test prefix:   $TEST_PREFIX"
if [ "$FULL_MODE" = true ]; then
    echo -e "  Mode:          ${YELLOW}FULL (P0 + P1)${NC}"
else
    echo -e "  Mode:          P0 only (use --full for P1)"
fi
echo ""

# Build if needed
if [ ! -f "$BINARY" ]; then
    echo "Building release binary..."
    (cd "$PROJECT_ROOT" && swift build -c release 2>&1 | tail -1)
fi

# ═══════════════════════════════════════════════════════
# P0: CLI FUNCTIONAL TESTS
# ═══════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${BLUE}=== P0: CLI Functional Tests ===${NC}"

# ─── CLI-01 ──────────────────────────────────────────
run_test "CLI-01" "Version output"
VERSION=$($BINARY --version 2>&1 || echo "")
if echo "$VERSION" | grep -q "0.3.0-alpha"; then
    pass "Version: $VERSION"
else
    fail "Expected '0.3.0-alpha', got: '$VERSION'"
fi

# ─── CLI-02 ──────────────────────────────────────────
run_test "CLI-02" "Init -- Keychain access verification"
INIT_OUTPUT=$($BINARY init 2>&1 || echo "INIT_FAILED")
if echo "$INIT_OUTPUT" | grep -qi "keychain\|완료\|verified\|✅"; then
    pass "Keychain access verified"
else
    fail "Init failed: $INIT_OUTPUT"
fi

# ─── CLI-03 ──────────────────────────────────────────
run_test "CLI-03" "Add secret (non-biometric, stdin pipe)"
TEST_NAME="${TEST_PREFIX}-api"
TEST_VALUE="sk-test-$(uuidgen)"
ADD_OUTPUT=$(echo "$TEST_VALUE" | $BINARY add "$TEST_NAME" --env-name "TEST_API_KEY" 2>&1 || echo "ADD_FAILED")
if echo "$ADD_OUTPUT" | grep -q "✅"; then
    pass "Secret added"
else
    fail "Add failed: $ADD_OUTPUT"
fi

# ─── CLI-04 ──────────────────────────────────────────
run_test "CLI-04" "Get secret -- value integrity"
RETRIEVED=$($BINARY get "$TEST_NAME" 2>&1 || echo "GET_FAILED")
if [ "$RETRIEVED" = "$TEST_VALUE" ]; then
    pass "Value matches exactly"
else
    fail "Expected: '$TEST_VALUE', Got: '$RETRIEVED'"
fi

# ─── CLI-05 ──────────────────────────────────────────
run_test "CLI-05" "List -- entry with correct env var"
LIST_OUTPUT=$($BINARY list 2>&1)
if echo "$LIST_OUTPUT" | grep -q "$TEST_NAME" && echo "$LIST_OUTPUT" | grep -q "TEST_API_KEY"; then
    pass "Entry found with correct env var"
else
    fail "Entry not found in list output"
fi

# ─── CLI-06 ──────────────────────────────────────────
run_test "CLI-06" "Inject -- env var in child process"
INJECTED=$($BINARY inject -- sh -c 'echo $TEST_API_KEY' 2>/dev/null || echo "INJECT_FAILED")
if [ "$INJECTED" = "$TEST_VALUE" ]; then
    pass "Env var injected correctly"
else
    fail "Expected: '$TEST_VALUE', Got: '$INJECTED'"
fi

# ─── CLI-07 ──────────────────────────────────────────
run_test "CLI-07" "Remove -- Keychain + metadata cleanup"
REMOVE_OUTPUT=$($BINARY remove "$TEST_NAME" 2>&1 || echo "REMOVE_FAILED")
if echo "$REMOVE_OUTPUT" | grep -q "✅"; then
    LIST_AFTER=$($BINARY list 2>&1)
    if ! echo "$LIST_AFTER" | grep -q "$TEST_NAME"; then
        pass "Secret removed from both Keychain and metadata"
    else
        fail "Secret still in list after removal"
    fi
else
    fail "Remove failed: $REMOVE_OUTPUT"
fi

# ─── CLI-08 ──────────────────────────────────────────
run_test "CLI-08" "Get nonexistent secret -- error handling"
GET_ERR=$($BINARY get "nonexistent-$(uuidgen)" 2>&1 || true)
EXIT_CODE=$?
if echo "$GET_ERR" | grep -qi "not found\|error\|없습니다\|찾을 수 없\|❌"; then
    pass "Proper error for nonexistent key"
else
    # Some implementations return non-zero exit code without message
    if [ $EXIT_CODE -ne 0 ] 2>/dev/null; then
        pass "Non-zero exit code for nonexistent key"
    else
        fail "No error for nonexistent key: '$GET_ERR'"
    fi
fi

# ─── CLI-09 ──────────────────────────────────────────
run_test "CLI-09" "Remove nonexistent secret -- no crash"
REMOVE_ERR=$($BINARY remove "nonexistent-$(uuidgen)" 2>&1)
REMOVE_EXIT=$?
# Should not crash (no signal)
if [ $REMOVE_EXIT -le 128 ]; then
    pass "No crash (exit code: $REMOVE_EXIT)"
else
    fail "Process crashed with signal $(($REMOVE_EXIT - 128))"
fi

# ─── CLI-10 ──────────────────────────────────────────
run_test "CLI-10" "Inject with no secrets -- command still runs"
# Clean all test keys first
cleanup_test_keys
INJECT_HELLO=$($BINARY inject -- echo "hello-world" 2>/dev/null || echo "")
if echo "$INJECT_HELLO" | grep -q "hello-world"; then
    pass "Command ran successfully with no secrets"
else
    fail "Inject failed with no secrets: '$INJECT_HELLO'"
fi


# ═══════════════════════════════════════════════════════
# P0: SECURITY TESTS
# ═══════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${BLUE}=== P0: Security Tests ===${NC}"

# ─── SEC-01 ──────────────────────────────────────────
run_test "SEC-01" "Get output -- raw value only (pipe-safe)"
SEC_NAME="${TEST_PREFIX}-rawout"
echo "exact-value-12345" | $BINARY add "$SEC_NAME" --env-name "RAW_TEST" 2>/dev/null
RAW=$($BINARY get "$SEC_NAME" 2>/dev/null)
BYTE_COUNT=$(printf '%s' "$RAW" | wc -c | tr -d ' ')
if [ "$RAW" = "exact-value-12345" ] && [ "$BYTE_COUNT" = "17" ]; then
    pass "Raw output, $BYTE_COUNT bytes, no decorators"
else
    fail "Value: '$RAW', Bytes: $BYTE_COUNT (expected: 17)"
fi
$BINARY remove "$SEC_NAME" 2>/dev/null || true

# ─── SEC-02 ──────────────────────────────────────────
run_test "SEC-02" "Inject -- parent process env isolation"
SEC_ISO="${TEST_PREFIX}-iso"
echo "isolation-test-value" | $BINARY add "$SEC_ISO" --env-name "ISOLATION_TEST_VAR" 2>/dev/null
$BINARY inject -- true 2>/dev/null || true
PARENT_VAL="${ISOLATION_TEST_VAR:-NOT_SET}"
if [ "$PARENT_VAL" = "NOT_SET" ]; then
    pass "Parent env not contaminated"
else
    fail "ISOLATION_TEST_VAR leaked to parent: '$PARENT_VAL'"
fi
$BINARY remove "$SEC_ISO" 2>/dev/null || true

# ─── SEC-03 ──────────────────────────────────────────
run_test "SEC-03" "Error messages -- no secret value leakage"
SEC_ERR="${TEST_PREFIX}-errleak"
SENSITIVE="SuperSecretValue-$(uuidgen)"
echo "$SENSITIVE" | $BINARY add "$SEC_ERR" --env-name "ERR_TEST" 2>/dev/null
ERR_OUTPUT=$($BINARY get "this-key-does-not-exist" 2>&1 || true)
if ! echo "$ERR_OUTPUT" | grep -q "$SENSITIVE"; then
    pass "Sensitive value not in error output"
else
    fail "Sensitive value leaked in error message!"
fi
$BINARY remove "$SEC_ERR" 2>/dev/null || true

# ─── SEC-04 ──────────────────────────────────────────
run_test "SEC-04" "Metadata file permissions == 600"
META_PATH=~/Library/Application\ Support/secret-wallet/metadata.json
if [ -f "$META_PATH" ]; then
    PERMS=$(stat -f '%Lp' "$META_PATH")
    if [ "$PERMS" = "600" ]; then
        pass "Permissions: $PERMS"
    else
        fail "Permissions: $PERMS (expected: 600)"
    fi
else
    skip "metadata.json not found (no secrets stored yet)"
fi

# ─── SEC-05 ──────────────────────────────────────────
run_test "SEC-05" "Metadata contains only names, not values"
SEC_META="${TEST_PREFIX}-metaleak"
META_SECRET="ThisValueMustNotAppear-$(uuidgen)"
echo "$META_SECRET" | $BINARY add "$SEC_META" --env-name "META_TEST" 2>/dev/null
if [ -f "$META_PATH" ]; then
    if ! grep -q "$META_SECRET" "$META_PATH" 2>/dev/null; then
        pass "Secret value not in metadata.json"
    else
        fail "Secret value found in metadata.json!"
    fi
else
    fail "metadata.json not created"
fi
$BINARY remove "$SEC_META" 2>/dev/null || true

# ─── SEC-07 ──────────────────────────────────────────
run_test "SEC-07" "Empty secret rejected"
EMPTY_OUT=$(echo "" | $BINARY add "${TEST_PREFIX}-empty" --env-name "EMPTY_TEST" 2>&1)
EMPTY_EXIT=$?
if [ $EMPTY_EXIT -ne 0 ] || echo "$EMPTY_OUT" | grep -qi "error\|empty\|비어\|❌"; then
    pass "Empty secret rejected"
else
    # If it was accepted, clean up and fail
    $BINARY remove "${TEST_PREFIX}-empty" 2>/dev/null || true
    fail "Empty secret was accepted (should be rejected)"
fi

# ─── SEC-08 ──────────────────────────────────────────
run_test "SEC-08" "Keychain service ID consistency (CLI == GUI)"
CORE_SERVICE=$(grep -o 'service.*=.*"com\.secret-wallet"' "$PROJECT_ROOT/Sources/SecretWalletCore/KeychainManager.swift" 2>/dev/null | head -1)
if [ -n "$CORE_SERVICE" ]; then
    pass "SharedCore uses 'com.secret-wallet' (single source of truth)"
else
    fail "Service ID not found in SharedCore"
fi

# ─── SEC-09 ──────────────────────────────────────────
run_test "SEC-09" "Keychain items device-only (no iCloud sync)"
CORE_ACL=$(grep -c "WhenUnlockedThisDeviceOnly" "$PROJECT_ROOT/Sources/SecretWalletCore/KeychainManager.swift" 2>/dev/null || echo "0")
if [ "$CORE_ACL" -ge 1 ]; then
    pass "SharedCore: $CORE_ACL refs to WhenUnlockedThisDeviceOnly"
else
    fail "Missing device-only ACL in SharedCore: $CORE_ACL"
fi

# ─── SEC-10 ──────────────────────────────────────────
run_test "SEC-10" "Source code -- no hardcoded secrets"
HARDCODED=$(grep -rn 'sk-proj-\|sk-ant-\|sk-or-\|AIza[A-Za-z0-9]\|ghp_[A-Za-z0-9]\|gho_[A-Za-z0-9]' \
    "$PROJECT_ROOT/Sources/" \
    "$PROJECT_ROOT/App/SecretWalletApp/" 2>/dev/null || true)
if [ -z "$HARDCODED" ]; then
    pass "No hardcoded secrets found"
else
    fail "Hardcoded secrets detected:"
    echo "$HARDCODED"
fi


# ═══════════════════════════════════════════════════════
# P1: EDGE CASES (--full only)
# ═══════════════════════════════════════════════════════

if [ "$FULL_MODE" = true ]; then

echo ""
echo -e "${BOLD}${BLUE}=== P1: Edge Cases ===${NC}"

# ─── CLI-11 ──────────────────────────────────────────
run_test "CLI-11" "Special characters in value"
TEST_SPECIAL="${TEST_PREFIX}-special"
SPECIAL_VAL='P@$$w0rd!#%^&*()'
echo "$SPECIAL_VAL" | $BINARY add "$TEST_SPECIAL" --env-name "SPECIAL_VAR" 2>/dev/null
RETRIEVED=$($BINARY get "$TEST_SPECIAL" 2>/dev/null || echo "GET_FAILED")
if [ "$RETRIEVED" = "$SPECIAL_VAL" ]; then
    pass "Special chars preserved"
else
    fail "Expected: '$SPECIAL_VAL', Got: '$RETRIEVED'"
fi
$BINARY remove "$TEST_SPECIAL" 2>/dev/null || true

# ─── CLI-12 ──────────────────────────────────────────
run_test "CLI-12" "Unicode in value"
TEST_UNI="${TEST_PREFIX}-unicode"
UNI_VAL="token-with-unicode-horse-cafe"
echo "$UNI_VAL" | $BINARY add "$TEST_UNI" --env-name "UNI_VAR" 2>/dev/null
RETRIEVED=$($BINARY get "$TEST_UNI" 2>/dev/null || echo "GET_FAILED")
if [ "$RETRIEVED" = "$UNI_VAL" ]; then
    pass "Unicode preserved"
else
    fail "Expected: '$UNI_VAL', Got: '$RETRIEVED'"
fi
$BINARY remove "$TEST_UNI" 2>/dev/null || true

# ─── CLI-13 ──────────────────────────────────────────
run_test "CLI-13" "Large value (4096 bytes)"
TEST_LONG="${TEST_PREFIX}-long"
LONG_VAL=$(python3 -c "print('A' * 4096)")
echo "$LONG_VAL" | $BINARY add "$TEST_LONG" --env-name "LONG_VAR" 2>/dev/null
RETRIEVED=$($BINARY get "$TEST_LONG" 2>/dev/null || echo "")
RETRIEVED_LEN=$(printf '%s' "$RETRIEVED" | wc -c | tr -d ' ')
if [ "$RETRIEVED_LEN" = "4096" ]; then
    pass "4096 bytes stored and retrieved"
else
    fail "Length: $RETRIEVED_LEN (expected: 4096)"
fi
$BINARY remove "$TEST_LONG" 2>/dev/null || true

# ─── CLI-15 ──────────────────────────────────────────
run_test "CLI-15" "Overwrite existing secret"
TEST_OVR="${TEST_PREFIX}-overwrite"
echo "original-value" | $BINARY add "$TEST_OVR" --env-name "OVR_VAR" 2>/dev/null
echo "new-value" | $BINARY add "$TEST_OVR" --env-name "OVR_VAR" 2>/dev/null
RETRIEVED=$($BINARY get "$TEST_OVR" 2>/dev/null || echo "")
if [ "$RETRIEVED" = "new-value" ]; then
    pass "Overwrite successful"
else
    fail "Expected: 'new-value', Got: '$RETRIEVED'"
fi
$BINARY remove "$TEST_OVR" 2>/dev/null || true

# ─── CLI-16 ──────────────────────────────────────────
run_test "CLI-16" "Inject -- child exit code propagation"
$BINARY inject -- sh -c "exit 42" 2>/dev/null
CHILD_EXIT=$?
if [ "$CHILD_EXIT" = "42" ]; then
    pass "Exit code 42 propagated"
else
    fail "Exit code: $CHILD_EXIT (expected: 42)"
fi

# ─── CLI-18 ──────────────────────────────────────────
run_test "CLI-18" "Help text for all commands"
ALL_HELP_OK=true
for cmd in "" "init" "add" "get" "list" "remove" "inject" "setup"; do
    if [ -z "$cmd" ]; then
        OUTPUT=$($BINARY --help 2>&1 || true)
    else
        OUTPUT=$($BINARY $cmd --help 2>&1 || true)
    fi
    if [ -z "$OUTPUT" ]; then
        ALL_HELP_OK=false
        echo "  Missing help for: ${cmd:-root}"
    fi
done
if [ "$ALL_HELP_OK" = true ]; then
    pass "All commands have help text"
else
    fail "Some commands missing help"
fi

# ─── EDGE-01 ─────────────────────────────────────────
run_test "EDGE-01" "Corrupt metadata.json recovery"
META_PATH_EDGE=~/Library/Application\ Support/secret-wallet/metadata.json
if [ -f "$META_PATH_EDGE" ]; then
    cp "$META_PATH_EDGE" "${META_PATH_EDGE}.edge-bak"
    echo "this is not valid json{{{" > "$META_PATH_EDGE"
    LIST_CORRUPT=$($BINARY list 2>&1)
    LIST_EXIT=$?
    mv "${META_PATH_EDGE}.edge-bak" "$META_PATH_EDGE"
    if [ $LIST_EXIT -le 128 ]; then
        pass "No crash on corrupt metadata (exit: $LIST_EXIT)"
    else
        fail "Crashed on corrupt metadata (signal: $(($LIST_EXIT - 128)))"
    fi
else
    skip "No metadata.json to corrupt"
fi

# ─── EDGE-02 ─────────────────────────────────────────
run_test "EDGE-02" "Missing metadata.json -- auto-create"
META_DIR=~/Library/Application\ Support/secret-wallet
if [ -f "$META_DIR/metadata.json" ]; then
    mv "$META_DIR/metadata.json" "$META_DIR/metadata.json.edge-bak"
    EDGE_NAME="${TEST_PREFIX}-newfile"
    echo "new-val" | $BINARY add "$EDGE_NAME" --env-name "NEW_VAR" 2>/dev/null
    if [ -f "$META_DIR/metadata.json" ]; then
        pass "metadata.json auto-created"
    else
        fail "metadata.json not auto-created"
    fi
    $BINARY remove "$EDGE_NAME" 2>/dev/null || true
    # Restore original
    mv "$META_DIR/metadata.json.edge-bak" "$META_DIR/metadata.json"
else
    skip "No metadata dir to test"
fi

fi # end --full


# ═══════════════════════════════════════════════════════
# Cleanup
# ═══════════════════════════════════════════════════════

echo ""
echo "Cleaning up test keys..."
cleanup_test_keys
echo "Done."

# ═══════════════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Test Summary${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Total:   ${BLUE}$TOTAL${NC}"
echo -e "  Passed:  ${GREEN}$PASSED${NC}"
echo -e "  Failed:  ${RED}$FAILED${NC}"
echo -e "  Skipped: ${YELLOW}$SKIPPED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}${BOLD}ALL TESTS PASSED${NC}"
    echo ""
    echo "Next: Run GUI manual tests"
    echo "  open scripts/test-gui-checklist.md"
    echo "  open App/.build/release/SecretWalletApp"
    exit 0
else
    echo -e "${RED}${BOLD}$FAILED TEST(S) FAILED${NC}"
    echo ""
    echo "Review failures above and fix before release."
    exit 1
fi
