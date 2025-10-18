#!/bin/bash

# Test for shell-utils with zimfw but without oh-my-posh

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "zsh installed" bash -c "zsh --version"
check "zshrc exists" bash -c "test -f $HOME/.zshrc"

# Check for Zimfw (should exist with this scenario)
check "zimfw directory" bash -c "test -d $HOME/.zim"
check "zimfw init" bash -c "test -f $HOME/.zim/init.zsh"

# Check Oh My Posh NOT installed (disabled in scenario)
check "oh-my-posh not installed" bash -c "! test -f $HOME/.local/bin/oh-my-posh"

# Report result
reportResults
