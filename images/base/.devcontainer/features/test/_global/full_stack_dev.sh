#!/bin/bash

# This test verifies a full-stack development environment setup
# with shell utilities, Node.js ecosystem, and modern runtimes

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Setup environment
export PATH="$HOME/.local/share/fnm:$HOME/.local/bin:$HOME/.bun/bin:$HOME/.deno/bin:$PATH"
if command -v fnm &> /dev/null; then
    eval "$(fnm env 2>/dev/null)" || true
fi

# Test shell utilities
check "zsh installed" bash -c "zsh --version"
check "oh-my-posh installed" bash -c "command -v oh-my-posh"

# Test Node.js ecosystem
check "fnm installed" bash -c "command -v fnm"
check "node installed" bash -c "command -v node"
check "npm installed" bash -c "command -v npm"
check "yarn installed" bash -c "command -v yarn"
check "pnpm installed" bash -c "command -v pnpm"

# Test Graphite
check "gt installed" bash -c "command -v gt"

# Test modern runtimes
check "bun installed" bash -c "command -v bun"
check "deno installed" bash -c "command -v deno"

# Verify integrations work
check "node execution" bash -c "node -e \"console.log('Node.js works')\""
check "bun execution" bash -c "bun --version"
check "deno execution" bash -c "deno eval \"console.log('Deno works')\""

# Report result
reportResults
