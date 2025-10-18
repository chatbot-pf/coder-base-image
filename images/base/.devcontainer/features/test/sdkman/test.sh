#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'sdkman' feature with no options.

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "sdkman directory" bash -c "test -d $HOME/.sdkman"
check "sdk command" bash -c "test -f $HOME/.sdkman/bin/sdkman-init.sh"

# Report result
reportResults
