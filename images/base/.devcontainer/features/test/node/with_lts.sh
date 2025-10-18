#!/bin/bash

# Test for node with LTS, yarn, and pnpm

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
check "node installed" bash -c "fnm exec --using=default node --version"
check "npm installed" bash -c "fnm exec --using=default npm --version"

# Check yarn (enabled in scenario)
check "yarn installed" bash -c "fnm exec --using=default yarn --version"

# Check pnpm (enabled in scenario)
check "pnpm installed" bash -c "fnm exec --using=default pnpm --version"

# Check nvm alias
check "nvm alias configuration" bash -c "grep -q 'alias nvm' $HOME/.zshrc || grep -q 'alias nvm' $HOME/.bashrc"

# Test node execution
check "node execution" bash -c "fnm exec --using=default node -e \"console.log('test')\""

# Report result
reportResults
