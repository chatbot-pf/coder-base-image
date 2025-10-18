#!/bin/bash

# Test for minimal node installation with version 20 only (no LTS, no yarn, no pnpm)

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Setup PATH for fnm
export PATH="$HOME/.local/share/fnm:$PATH"

# Feature-specific tests
check "fnm installed" bash -c "command -v fnm"
check "fnm version" bash -c "fnm --version"

# Use fnm exec to run node commands since fnm env doesn't work in test context
# Check node version starts with v20
check "node version 20" bash -c "fnm exec --using=default node --version | grep -q '^v20\.'"

check "npm installed" bash -c "fnm exec --using=default npm --version"

# Check yarn NOT installed (disabled in scenario)
check "yarn not installed" bash -c "! fnm exec --using=default yarn --version 2>/dev/null"

# Check pnpm NOT installed (disabled in scenario)
check "pnpm not installed" bash -c "! fnm exec --using=default pnpm --version 2>/dev/null"

# Check that ONLY version 20 is installed (installLts: false)
check "only v20 installed" bash -c "fnm list | grep -q '^[* ]*v20\.' && ! fnm list | grep -q 'lts-latest'"

# Check nvm alias
check "nvm alias configuration" bash -c "grep -q 'alias nvm' $HOME/.zshrc || grep -q 'alias nvm' $HOME/.bashrc"

# Test node execution
check "node execution" bash -c "fnm exec --using=default node -e \"console.log('test')\""

# Report result
reportResults
