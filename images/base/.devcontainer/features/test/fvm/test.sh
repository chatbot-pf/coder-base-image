#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'fvm' feature with no options.

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "fvm installed" bash -c "command -v fvm"
check "fvm version" bash -c "fvm --version"

# Report result
reportResults
