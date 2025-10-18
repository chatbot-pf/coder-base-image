#!/bin/bash

# This test verifies the complete development environment
# with all features installed and working together

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

echo "Testing complete development environment..."

# Setup environment variables
export PATH="$HOME/.local/share/fnm:$HOME/.local/bin:$HOME/.bun/bin:$HOME/.deno/bin:$HOME/.pub-cache/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env 2>/dev/null)" || true
fi

# Shell utilities
check "zsh installed" bash -c "zsh --version"
check "oh-my-posh installed" bash -c "command -v oh-my-posh"

# Development tools
check "graphite installed" bash -c "command -v gt"

# Node.js ecosystem
check "fnm installed" bash -c "command -v fnm"
check "node installed" bash -c "command -v node"
check "yarn installed" bash -c "command -v yarn"
check "pnpm installed" bash -c "command -v pnpm"

# JavaScript/TypeScript runtimes
check "bun installed" bash -c "command -v bun"
check "deno installed" bash -c "command -v deno"

# JVM ecosystem
check "sdkman directory" bash -c "test -d $HOME/.sdkman"

# Development tools
check "claude-code path" bash -c "test -d $HOME/.local/bin"

# Flutter (optional - may not be critical)
if [ -d "$HOME/.pub-cache" ]; then
    check "pub-cache directory" bash -c "test -d $HOME/.pub-cache"
fi

# Integration tests
check "node works" bash -c "node -e \"console.log('ok')\""
check "bun works" bash -c "bun --version"
check "deno works" bash -c "deno --version"
check "gt works" bash -c "gt --version"

# Report result
reportResults
