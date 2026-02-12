#!/bin/bash
# Secret Wallet Shell Integration Setup
# Adds aliases and completions to your shell

set -e

SHELL_NAME=$(basename "$SHELL")
RC_FILE=""

case "$SHELL_NAME" in
    zsh)  RC_FILE="$HOME/.zshrc" ;;
    bash) RC_FILE="$HOME/.bashrc" ;;
    *)
        echo "❌ Unsupported shell: $SHELL_NAME (zsh/bash only)"
        exit 1
        ;;
esac

MARKER="# >>> secret-wallet shell integration >>>"
END_MARKER="# <<< secret-wallet shell integration <<<"

# Check if already installed
if grep -q "$MARKER" "$RC_FILE" 2>/dev/null; then
    echo "✅ Shell integration already installed in $RC_FILE"
    echo "   To reinstall, remove the secret-wallet block from $RC_FILE first."
    exit 0
fi

SNIPPET="
$MARKER
alias sw='secret-wallet'
alias swa='secret-wallet add'
alias swg='secret-wallet get'
alias swl='secret-wallet list'
alias swr='secret-wallet remove'
swi() { secret-wallet inject -- \"\$@\"; }
$END_MARKER"

echo "$SNIPPET" >> "$RC_FILE"

echo "✅ Shell integration installed in $RC_FILE"
echo ""
echo "Available shortcuts:"
echo "  sw   → secret-wallet"
echo "  swa  → secret-wallet add"
echo "  swg  → secret-wallet get"
echo "  swl  → secret-wallet list"
echo "  swr  → secret-wallet remove"
echo "  swi  → secret-wallet inject --"
echo ""
echo "Run 'source $RC_FILE' or open a new terminal to activate."
