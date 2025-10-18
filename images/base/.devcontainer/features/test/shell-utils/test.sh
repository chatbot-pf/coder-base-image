#!/bin/bash

# This test file will be executed against an auto-generated devcontainer.json that
# includes the 'shell-utils' feature with no options.

set -e

# Optional: Import test library bundled with the devcontainer CLI
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "zsh installed" bash -c "zsh --version"
check "zshrc exists" bash -c "test -f $HOME/.zshrc"

# Check for Zimfw or Oh My Zsh (at least one should exist)
zimfw_exists=false
ohmyzsh_exists=false

if [ -d "$HOME/.zim" ]; then
    check "zimfw directory" bash -c "test -d $HOME/.zim"
    check "zimfw init" bash -c "test -f $HOME/.zim/init.zsh"
    zimfw_exists=true
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    check "ohmyzsh directory" bash -c "test -d $HOME/.oh-my-zsh"
    ohmyzsh_exists=true
fi

# At least one framework should be installed
if [ "$zimfw_exists" = false ] && [ "$ohmyzsh_exists" = false ]; then
    echo "ERROR: Neither Zimfw nor Oh My Zsh found"
    exit 1
fi

# Check Oh My Posh (should be installed by default)
# Note: oh-my-posh is in ~/.local/bin which may not be in non-login shell PATH
check "oh-my-posh installed" bash -c "test -f $HOME/.local/bin/oh-my-posh"

# Check version with explicit path since test runs in non-login shell
if [ -f "$HOME/.local/bin/oh-my-posh" ]; then
    check "oh-my-posh version" bash -c "$HOME/.local/bin/oh-my-posh --version"
fi

# Report result
reportResults
