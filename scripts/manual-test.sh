#!/bin/bash
# Manual Test Script for Secret Wallet
# Run on both MacBook and Mac mini to verify functionality

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔐 Secret Wallet Manual Test Suite"
echo "=================================="
echo ""

# Display environment info
echo "📋 Test Environment:"
echo "  Hostname: $(hostname)"
echo "  macOS: $(sw_vers -productVersion)"
echo "  Architecture: $(uname -m)"
echo "  Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# Build release binary
echo "🔨 Building release binary..."
swift build -c release

BINARY="./.build/release/secret-wallet"

if [ ! -f "$BINARY" ]; then
    echo -e "${RED}❌ Binary not found at $BINARY${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Binary built successfully${NC}"
echo ""

# Test counter
PASSED=0
FAILED=0
TOTAL=7

# Test 1: Version check
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1/7: Version Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
VERSION=$($BINARY --version 2>&1 || echo "")
if echo "$VERSION" | grep -q "0.1.0"; then
    echo -e "${GREEN}✅ PASS${NC} - Version: $VERSION"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - Expected '0.1.0', got: $VERSION"
    ((FAILED++))
fi
echo ""

# Test 2: Init command
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2/7: Init Command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INIT_OUTPUT=$($BINARY init 2>&1 || echo "INIT_FAILED")
if echo "$INIT_OUTPUT" | grep -q "✅ macOS Keychain 연동 완료"; then
    echo -e "${GREEN}✅ PASS${NC} - Keychain access verified"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - Init command failed"
    echo "$INIT_OUTPUT"
    ((FAILED++))
fi
echo ""

# Test 3: Add secret (non-biometric)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3/7: Add Secret (No Biometric)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEST_SECRET="test-secret-$(date +%s)"
TEST_VALUE="test-value-$(uuidgen)"
ADD_OUTPUT=$(echo "$TEST_VALUE" | $BINARY add "$TEST_SECRET" --env-name "TEST_VAR" 2>&1 || echo "ADD_FAILED")

if echo "$ADD_OUTPUT" | grep -q "✅"; then
    # Verify it appears in list
    LIST_OUTPUT=$($BINARY list 2>&1)
    if echo "$LIST_OUTPUT" | grep -q "$TEST_SECRET"; then
        echo -e "${GREEN}✅ PASS${NC} - Secret added successfully"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} - Secret not found in list"
        echo "$LIST_OUTPUT"
        ((FAILED++))
    fi
else
    echo -e "${RED}❌ FAIL${NC} - Add command failed"
    echo "$ADD_OUTPUT"
    ((FAILED++))
fi
echo ""

# Test 4: Get secret
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4/7: Get Secret"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RETRIEVED=$($BINARY get "$TEST_SECRET" 2>&1 || echo "GET_FAILED")
if [ "$RETRIEVED" = "$TEST_VALUE" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Retrieved value matches"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}"
    echo "  Expected: $TEST_VALUE"
    echo "  Got:      $RETRIEVED"
    ((FAILED++))
fi
echo ""

# Test 5: Inject command
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 5/7: Inject Command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
TEMP_FILE="/tmp/inject-test-$$.txt"
$BINARY inject -- sh -c "echo \$TEST_VAR" > "$TEMP_FILE" 2>/dev/null || echo "INJECT_FAILED" > "$TEMP_FILE"
INJECTED=$(cat "$TEMP_FILE")
rm -f "$TEMP_FILE"

if [ "$INJECTED" = "$TEST_VALUE" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Environment variable injected correctly"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}"
    echo "  Expected: $TEST_VALUE"
    echo "  Got:      $INJECTED"
    ((FAILED++))
fi
echo ""

# Test 6: List command
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 6/7: List Command"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
LIST_OUTPUT=$($BINARY list 2>&1)
if echo "$LIST_OUTPUT" | grep -q "$TEST_SECRET.*TEST_VAR"; then
    echo -e "${GREEN}✅ PASS${NC} - Secret appears in list with correct env var"
    ((PASSED++))
else
    echo -e "${RED}❌ FAIL${NC} - List format incorrect"
    echo "$LIST_OUTPUT"
    ((FAILED++))
fi
echo ""

# Test 7: Remove secret
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 7/7: Remove Secret"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
REMOVE_OUTPUT=$($BINARY remove "$TEST_SECRET" 2>&1 || echo "REMOVE_FAILED")
if echo "$REMOVE_OUTPUT" | grep -q "✅"; then
    # Verify it's gone from list
    LIST_OUTPUT=$($BINARY list 2>&1)
    if ! echo "$LIST_OUTPUT" | grep -q "$TEST_SECRET"; then
        echo -e "${GREEN}✅ PASS${NC} - Secret removed successfully"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC} - Secret still in list after removal"
        ((FAILED++))
    fi
else
    echo -e "${RED}❌ FAIL${NC} - Remove command failed"
    echo "$REMOVE_OUTPUT"
    ((FAILED++))
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Total:  ${BLUE}$TOTAL${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Save these results"
    echo "  2. Run on Mac mini: ssh mac-mini 'cd ~/Projects/secret-wallet && git pull && ./scripts/manual-test.sh'"
    echo "  3. Compare results between devices"
    echo ""
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo ""
    echo "Please review the failures above and fix before proceeding."
    echo ""
    exit 1
fi
