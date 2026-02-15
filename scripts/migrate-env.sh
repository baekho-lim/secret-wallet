#!/bin/bash
# Secret Wallet .env Migration Tool
# Reads .env files and imports secrets into macOS Keychain via Secret Wallet
#
# Usage:
#   ./scripts/migrate-env.sh <.env file>           # Interactive (confirm each key)
#   ./scripts/migrate-env.sh <.env file> --all      # Import all keys
#   ./scripts/migrate-env.sh <.env file> --dry-run  # Preview only, no changes
#   ./scripts/migrate-env.sh --scan <directory>     # Scan for .env files recursively

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Counters ---
IMPORTED=0
SKIPPED=0
DUPLICATE=0
FAILED=0
PUBLIC_SKIPPED=0

# --- Check prerequisites ---
check_secret_wallet() {
    if ! command -v secret-wallet &>/dev/null; then
        echo -e "${RED}secret-wallet not found.${NC}"
        echo "Install: brew install baekho-lim/tap/secret-wallet"
        exit 1
    fi
}

# --- Parse .env file into key=value pairs ---
# Handles: KEY=VALUE, KEY="VALUE", KEY='VALUE', export KEY=VALUE
# Skips: comments (#), empty lines, NEXT_PUBLIC_* (public keys)
parse_env_file() {
    local file="$1"
    local include_public="${2:-false}"

    if [ ! -f "$file" ]; then
        echo -e "${RED}File not found: $file${NC}"
        exit 1
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Remove 'export ' prefix if present
        line="${line#export }"

        # Extract key and value
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Remove surrounding quotes from value
            if [[ "$value" =~ ^\"(.*)\"$ ]]; then
                value="${BASH_REMATCH[1]}"
            elif [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi

            # Skip empty values
            [[ -z "$value" ]] && continue

            # Skip public keys (not secrets) unless --include-public
            if [[ "$include_public" == "false" && "$key" =~ ^NEXT_PUBLIC_ ]]; then
                echo "@@PUBLIC_SKIP@@"
                continue
            fi

            # Skip non-secret config values
            if is_config_value "$key" "$value"; then
                echo "@@CONFIG_SKIP@@"
                continue
            fi

            echo "${key}=${value}"
        fi
    done < "$file"
}

# --- Detect non-secret config values ---
is_config_value() {
    local key="$1"
    local value="$2"

    # URLs that are public endpoints (not secrets)
    case "$key" in
        *_URL|*_HOST|*_PORT|*_BASE_URL|*_APP_URL)
            # Database URLs ARE secrets (contain passwords)
            if [[ "$key" == "DATABASE_URL" || "$key" == "DIRECT_URL" ]]; then
                return 1  # IS a secret
            fi
            return 0  # NOT a secret
            ;;
        *_LEVEL|*_MODE|DRY_RUN|NODE_ENV|LOG_LEVEL)
            return 0  # NOT a secret
            ;;
    esac

    # Boolean/numeric config values
    if [[ "$value" == "true" || "$value" == "false" || "$value" =~ ^[0-9]+$ ]]; then
        # Small numbers are config, but long numbers could be IDs/secrets
        if [[ ${#value} -lt 10 ]]; then
            return 0  # NOT a secret
        fi
    fi

    return 1  # IS a secret (default: treat as secret)
}

# --- Check if key already exists in Secret Wallet ---
key_exists() {
    local key="$1"
    secret-wallet get "$key" &>/dev/null
    return $?
}

# --- Import a single key ---
import_key() {
    local key="$1"
    local value="$2"
    local dry_run="$3"
    local biometric="${4:-false}"

    if [ "$dry_run" == "true" ]; then
        echo -e "  ${CYAN}[DRY-RUN]${NC} Would import: ${BLUE}$key${NC}"
        IMPORTED=$((IMPORTED + 1))
        return 0
    fi

    if key_exists "$key"; then
        echo -e "  ${YELLOW}[SKIP]${NC} Already exists: ${BLUE}$key${NC}"
        DUPLICATE=$((DUPLICATE + 1))
        return 0
    fi

    local add_args=("add" "$key" "--env-name" "$key")
    if [ "$biometric" == "true" ]; then
        add_args+=("--biometric")
    fi

    if echo "$value" | secret-wallet "${add_args[@]}" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC} Imported: ${BLUE}$key${NC}"
        IMPORTED=$((IMPORTED + 1))
    else
        echo -e "  ${RED}[FAIL]${NC} Failed: ${BLUE}$key${NC}"
        FAILED=$((FAILED + 1))
    fi
}

# --- Scan directory for .env files ---
scan_directory() {
    local dir="$1"
    echo -e "${CYAN}Scanning for .env files in: ${dir}${NC}"
    echo ""

    local count=0
    while IFS= read -r -d '' env_file; do
        count=$((count + 1))
        local key_count
        key_count=$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=' "$env_file" 2>/dev/null || echo 0)
        echo -e "  ${BLUE}$env_file${NC} (${key_count} keys)"
    done < <(find "$dir" -name ".env*" \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -name ".env.example" \
        -not -name ".env.sample" \
        -not -name ".env.template" \
        -print0 2>/dev/null | sort -z)

    echo ""
    echo -e "${GREEN}Found ${count} .env file(s)${NC}"
    echo ""
    echo "To import a specific file:"
    echo "  ./scripts/migrate-env.sh <path-to-.env>"
    echo ""
    echo "To preview without importing:"
    echo "  ./scripts/migrate-env.sh <path-to-.env> --dry-run"
}

# --- Print summary ---
print_summary() {
    echo ""
    echo -e "${CYAN}━━━ Migration Summary ━━━${NC}"
    [ "$IMPORTED" -gt 0 ]       && echo -e "  ${GREEN}Imported:${NC}        $IMPORTED"
    [ "$DUPLICATE" -gt 0 ]      && echo -e "  ${YELLOW}Already existed:${NC} $DUPLICATE"
    [ "$PUBLIC_SKIPPED" -gt 0 ] && echo -e "  ${BLUE}Public (skipped):${NC} $PUBLIC_SKIPPED"
    [ "$SKIPPED" -gt 0 ]        && echo -e "  ${BLUE}Config (skipped):${NC} $SKIPPED"
    [ "$FAILED" -gt 0 ]         && echo -e "  ${RED}Failed:${NC}          $FAILED"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ "$IMPORTED" -gt 0 ] && [ "$1" != "true" ]; then
        echo ""
        echo -e "${GREEN}Verify with:${NC} secret-wallet list"
        echo ""
        echo -e "${YELLOW}Next steps:${NC}"
        echo "  1. Verify: secret-wallet list --json"
        echo "  2. Test:   secret-wallet get <KEY_NAME>"
        echo "  3. Use:    secret-wallet inject -- <your-command>"
        echo "  4. After confirming, consider removing the .env file"
    fi
}

# --- Main ---
main() {
    check_secret_wallet

    # Handle --scan mode
    if [ "$1" == "--scan" ]; then
        local scan_dir="${2:-.}"
        scan_directory "$scan_dir"
        exit 0
    fi

    # Require file argument
    if [ -z "$1" ]; then
        echo "Secret Wallet .env Migration Tool"
        echo ""
        echo "Usage:"
        echo "  $(basename "$0") <.env file>            Import secrets interactively"
        echo "  $(basename "$0") <.env file> --all       Import all secrets"
        echo "  $(basename "$0") <.env file> --dry-run   Preview only"
        echo "  $(basename "$0") --scan [directory]      Find .env files"
        echo ""
        echo "Options:"
        echo "  --all              Skip confirmation for each key"
        echo "  --dry-run          Preview what would be imported"
        echo "  --include-public   Include NEXT_PUBLIC_* keys too"
        echo "  --biometric        Protect all imported keys with TouchID"
        exit 0
    fi

    local env_file="$1"
    shift

    # Parse flags
    local mode="interactive"
    local dry_run="false"
    local include_public="false"
    local biometric="false"

    while [ $# -gt 0 ]; do
        case "$1" in
            --all)            mode="all" ;;
            --dry-run)        dry_run="true" ;;
            --include-public) include_public="true" ;;
            --biometric)      biometric="true" ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
        shift
    done

    echo -e "${CYAN}Secret Wallet .env Migration${NC}"
    echo -e "Source: ${BLUE}$env_file${NC}"
    [ "$dry_run" == "true" ] && echo -e "${YELLOW}Mode: DRY RUN (no changes will be made)${NC}"
    echo ""

    # Parse and process each key
    local entries
    entries=$(parse_env_file "$env_file" "$include_public")

    # Count skipped entries from subshell markers
    PUBLIC_SKIPPED=$(echo "$entries" | grep -c '@@PUBLIC_SKIP@@' || true)
    SKIPPED=$(echo "$entries" | grep -c '@@CONFIG_SKIP@@' || true)

    # Filter out markers, keep only real entries
    entries=$(echo "$entries" | grep -v '^@@.*@@$')

    if [ -z "$entries" ]; then
        echo -e "${YELLOW}No importable secrets found in $env_file${NC}"
        [ "$PUBLIC_SKIPPED" -gt 0 ] && echo -e "  (${PUBLIC_SKIPPED} NEXT_PUBLIC_* keys skipped, use --include-public to include)"
        [ "$SKIPPED" -gt 0 ] && echo -e "  (${SKIPPED} config values skipped)"
        exit 0
    fi

    local total
    total=$(echo "$entries" | wc -l | tr -d ' ')
    echo -e "Found ${GREEN}${total}${NC} secret(s) to import:"
    echo ""

    while IFS= read -r entry; do
        [ -z "$entry" ] && continue

        # Split on first '=' only (values may contain '=')
        local key="${entry%%=*}"
        local value="${entry#*=}"
        [ -z "$key" ] && continue

        if [ "$mode" == "interactive" ]; then
            echo -en "  Import ${BLUE}${key}${NC}? [Y/n/q] "
            read -r answer </dev/tty
            case "$answer" in
                [nN])
                    echo -e "  ${YELLOW}[SKIP]${NC} $key"
                    SKIPPED=$((SKIPPED + 1))
                    continue
                    ;;
                [qQ])
                    echo -e "\n${YELLOW}Aborted by user.${NC}"
                    print_summary "$dry_run"
                    exit 0
                    ;;
            esac
        fi

        import_key "$key" "$value" "$dry_run" "$biometric"
    done <<< "$entries"

    print_summary "$dry_run"
}

main "$@"
