#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'bun' feature with no options.

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Setup environment
export PATH="$HOME/.bun/bin:$PATH"

# Feature-specific tests
check "bun installed" bash -c "command -v bun"
check "bun version" bash -c "bun --version"

# Report result
reportResults
