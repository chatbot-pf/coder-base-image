# CLAUDE.md

This file provides guidance to Claude Code when working with devcontainer features in this repository.

## Repository Overview

This repository contains custom devcontainer features for development environments. Features are modular, reusable installation units that can be composed in `devcontainer.json`.

### Available Features

1. **shell-utils** - Zsh with Zimfw/Oh My Zsh + Oh My Posh
2. **node** - Node.js via fnm (Fast Node Manager)
3. **homebrew** - Homebrew package manager
4. **graphite** - Graphite CLI for stacked PRs
5. **bun** - Bun JavaScript runtime
6. **deno** - Deno runtime
7. **sdkman** - SDKMAN for Java/JVM tools
8. **claude-code** - Claude Code CLI
9. **fvm** - Flutter Version Management

## Architecture

Each feature follows this structure:

```
src/feature-name/
├── devcontainer-feature.json    # Metadata and options
└── install.sh                   # Installation script

test/feature-name/
├── test.sh                      # Test script
└── scenarios.json               # Optional test scenarios
```

## Key Patterns

### 1. Package Management (CRITICAL)

**Always use these utility functions** (from official devcontainer features):

```bash
check_packages curl ca-certificates unzip  # Installs only if missing
clean_up  # Removes package manager caches at end
```

These functions handle both Debian (apt) and RHEL (dnf/yum) systems automatically.

### 2. User Context (CRITICAL for Tests)

Features install for a detected user (usually `ubuntu`, `vscode`, `coder`) but tests run as `root`.

**Must copy configs to root after installation**:

```bash
# After installing for non-root user
if [ "${USERNAME}" != "root" ]; then
    copy_files=()
    [ -f "${USER_HOME}/.zshrc" ] && copy_files+=("${USER_HOME}/.zshrc")
    [ -d "${USER_HOME}/.zim" ] && copy_files+=("${USER_HOME}/.zim")
    if [ ${#copy_files[@]} -gt 0 ]; then
        cp -rf "${copy_files[@]}" /root/
    fi
fi
```

**Why**: Tests check `$HOME/.config` which is `/root/.config` when test runs as root, but installation creates `/home/ubuntu/.config`.

### 3. Shell Config Files

1. Check `/etc/skel` first (may have defaults)
2. Create if missing
3. Add PATH exports with `grep -qxF` to avoid duplicates
4. **Copy to root for non-root installs**

### 4. Installation with su

Always use `su - ${USERNAME}` to run in target user's environment:

```bash
su - ${USERNAME} << 'EOF'
curl -fsSL https://install.sh | bash || true
EOF
```

## Common Commands

### Testing

```bash
# Test specific feature
cd .devcontainer/features
devcontainer features test --skip-scenarios -f feature-name -i ubuntu:latest .

# Test all features
devcontainer features test .

# Test built image directly (useful for debugging)
docker run --rm <image-id> bash -c "test -f /root/.zshrc && echo OK"
```

### Development

```bash
# Run feature install script directly
bash src/feature-name/install.sh

# Check git submodule
cd .devcontainer/features
git status
git add -A
git commit -m "feat: ..."
git push
```

## Common Issues and Solutions

### Issue: Test fails with "config file not found"
**Cause**: Config created for ubuntu user but test runs as root
**Solution**: Copy configs to root after installation (see User Context pattern)

### Issue: "command not found" in tests
**Cause**: PATH not set for root user
**Solution**: Add PATH exports to both user and root shell configs

### Issue: Package installation fails
**Cause**: Missing dependencies or wrong package manager
**Solution**: Use `check_packages` instead of raw apt-get/dnf

### Issue: Feature works in container but test fails
**Cause**: User context mismatch
**Solution**: Always copy configs to root for non-root installs

## Important Files

- `DEVELOPMENT.md` - Detailed development guide with all patterns
- `README.md` - User-facing documentation
- `src/*/install.sh` - Installation scripts (must follow patterns)
- `test/*/test.sh` - Test scripts

## Instructions for Claude Code

### When modifying features:

1. **Always follow the official patterns** documented in DEVELOPMENT.md
2. **Use utility functions**: check_packages, pkg_mgr_update, clean_up
3. **Handle user context**: Detect user, install for user, copy to root
4. **Test thoroughly**: Run tests with ubuntu:latest base image
5. **Check /etc/skel**: Look for default config files before creating new ones

### When creating new features:

1. Copy structure from existing feature (e.g., `src/bun/`)
2. Include all utility functions in install.sh
3. Follow the Feature Development Checklist in DEVELOPMENT.md
4. Create test script in test/feature-name/test.sh
5. Test with: `devcontainer features test --skip-scenarios -f feature-name -i ubuntu:latest .`

### When debugging test failures:

1. Check if issue is user context related (root vs target user)
2. Verify configs exist in /root/ for root-run tests
3. Test the built image directly with docker run
4. Review DEVELOPMENT.md "Common Test Issues" section

### Critical Reminders:

- ⚠️ **Never skip copying configs to root** for non-root installs
- ⚠️ **Always use check_packages** instead of raw apt-get/dnf
- ⚠️ **Always call clean_up()** at the end to reduce image size
- ⚠️ **Check /etc/skel** for default configs before creating new ones
- ⚠️ **Use `grep -qxF`** to avoid duplicate PATH exports

## References

See DEVELOPMENT.md for comprehensive patterns, examples, and best practices.
