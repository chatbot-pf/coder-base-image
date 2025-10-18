#!/bin/bash

# Test for node with version 22, LTS, yarn, and pnpm

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
# Check node version starts with v22
check "node version 22" bash -c "fnm exec --using=default node --version | grep -q '^v22\.'"

check "npm installed" bash -c "fnm exec --using=default npm --version"

# Check yarn (enabled in scenario)
check "yarn installed" bash -c "fnm exec --using=default yarn --version"

# Check pnpm (enabled in scenario)
check "pnpm installed" bash -c "fnm exec --using=default pnpm --version"

# Check that LTS is also installed (installLts: true)
check "lts version installed" bash -c "fnm list | grep -q 'lts-latest'"

# Check nvm alias
check "nvm alias configuration" bash -c "grep -q 'alias nvm' $HOME/.zshrc || grep -q 'alias nvm' $HOME/.bashrc"

# Test node execution
check "node execution" bash -c "fnm exec --using=default node -e \"console.log('test')\""

# Report result
reportResults
