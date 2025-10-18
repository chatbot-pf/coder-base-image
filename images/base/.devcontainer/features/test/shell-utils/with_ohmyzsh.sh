#!/bin/bash

# Test for shell-utils with ohmyzsh and oh-my-posh

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "zsh installed" bash -c "zsh --version"
check "zshrc exists" bash -c "test -f $HOME/.zshrc"

# Check for Oh My Zsh (should exist with this scenario)
check "ohmyzsh directory" bash -c "test -d $HOME/.oh-my-zsh"

# Check Oh My Posh (enabled in scenario)
check "oh-my-posh installed" bash -c "test -f $HOME/.local/bin/oh-my-posh"
check "oh-my-posh version" bash -c "$HOME/.local/bin/oh-my-posh --version"

# Report result
reportResults
