#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'claude-code' feature with no options.

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "claude installed" bash -c "test -f $HOME/.local/bin/claude"

# Report result
reportResults
