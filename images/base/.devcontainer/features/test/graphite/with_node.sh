#!/bin/bash

# Test for graphite with node

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Setup PATH for npm global packages
export PATH="$HOME/.local/share/fnm:$PATH:/usr/local/bin"

# Feature-specific tests
check "graphite installed" bash -c "command -v gt"
check "graphite version" bash -c "gt --version"

# Report result
reportResults
