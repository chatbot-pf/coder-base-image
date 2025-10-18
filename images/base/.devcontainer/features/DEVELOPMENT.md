# Development Guide

## Key Learnings and Best Practices

### Package Management Pattern

All features should follow the official devcontainer pattern for cross-platform package installation:

```bash
# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release

# Get an adjusted ID independent of distro variants
ADJUSTED_ID="${ID}"
if [ "${ID}" = "debian" ] || [ "${ID_LIKE#*debian*}" != "${ID_LIKE}" ]; then
    ADJUSTED_ID="debian"
elif [ "${ID}" = "rhel" ] || [ "${ID}" = "fedora" ] || [ "${ID}" = "mariner" ]; then
    ADJUSTED_ID="rhel"
fi

# Setup INSTALL_CMD & PKG_MGR_CMD
if type apt-get > /dev/null 2>&1; then
    PKG_MGR_CMD=apt-get
    INSTALL_CMD="${PKG_MGR_CMD} -y install --no-install-recommends"
elif type microdnf > /dev/null 2>&1; then
    PKG_MGR_CMD=microdnf
    INSTALL_CMD="${PKG_MGR_CMD} -y install --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0"
elif type dnf > /dev/null 2>&1; then
    PKG_MGR_CMD=dnf
    INSTALL_CMD="${PKG_MGR_CMD} -y install"
elif type yum > /dev/null 2>&1; then
    PKG_MGR_CMD=yum
    INSTALL_CMD="${PKG_MGR_CMD} -y install"
fi

# Smart package manager update (only if needed)
pkg_mgr_update() {
    case ${ADJUSTED_ID} in
        debian)
            if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
                ${PKG_MGR_CMD} update -y
            fi
            ;;
        rhel)
            if [ ${PKG_MGR_CMD} = "microdnf" ]; then
                if [ "$(ls /var/cache/yum/* 2>/dev/null | wc -l)" = 0 ]; then
                    ${PKG_MGR_CMD} makecache
                fi
            else
                if [ "$(ls /var/cache/${PKG_MGR_CMD}/* 2>/dev/null | wc -l)" = 0 ]; then
                    ${PKG_MGR_CMD} -q check-update || true
                fi
            fi
            ;;
    esac
}

# Check and install packages
check_packages() {
    case ${ADJUSTED_ID} in
        debian)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                pkg_mgr_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
        rhel)
            if ! rpm -q "$@" > /dev/null 2>&1; then
                pkg_mgr_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
    esac
}

# Clean up package manager caches
clean_up() {
    case ${ADJUSTED_ID} in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        rhel)
            rm -rf /var/cache/dnf/* /var/cache/yum/*
            ;;
    esac
}
```

### Common Package Dependencies

Each feature requires certain packages. Always use `check_packages` before installation:

- **All features**: `curl ca-certificates`
- **Archive extraction**: Add `unzip` (bun, deno, fvm) or `zip unzip` (sdkman)
- **Shell features**: Add `zsh`

Example:
```bash
check_packages curl ca-certificates unzip
```

### User Context Pattern

Features must work correctly whether they run as root or install for a non-root user.

#### User Detection (from official features)

```bash
USERNAME=${USERNAME:-"automatic"}

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "coder" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

USER_HOME="/home/${USERNAME}"
if [ "${USERNAME}" = "root" ]; then
    USER_HOME="/root"
fi
```

#### Critical: Copy Configs to Root

**Problem**: Features install for `ubuntu` user but tests run as `root` user.

**Solution**: After installation, copy user configs to root (following official common-utils pattern):

```bash
# Copy shell configurations to root user if installing for non-root
if [ "${USERNAME}" != "root" ]; then
    copy_files=()
    [ -f "${USER_HOME}/.zshrc" ] && copy_files+=("${USER_HOME}/.zshrc")
    [ -d "${USER_HOME}/.zim" ] && copy_files+=("${USER_HOME}/.zim")
    [ -d "${USER_HOME}/.oh-my-zsh" ] && copy_files+=("${USER_HOME}/.oh-my-zsh")
    if [ ${#copy_files[@]} -gt 0 ]; then
        cp -rf "${copy_files[@]}" /root/
    fi
fi
```

This ensures:
- Tests pass when run as root
- Root user can use the same tools
- Compatible with official devcontainer patterns

### Shell Config Files Pattern

When creating shell config files (like .zshrc):

1. **Check /etc/skel first** (official pattern):
```bash
if [ -f "/etc/skel/.zshrc" ]; then
    if [ ! -e "${USER_HOME}/.zshrc" ] || [ ! -s "${USER_HOME}/.zshrc" ]; then
        cp "/etc/skel/.zshrc" "${USER_HOME}/.zshrc"
        chown ${USERNAME}:$(id -gn ${USERNAME}) "${USER_HOME}/.zshrc"
    fi
fi
```

2. **Create if missing**:
```bash
if [ ! -f "${USER_HOME}/.zshrc" ]; then
    touch "${USER_HOME}/.zshrc"
    chown ${USERNAME}:$(id -gn ${USERNAME}) "${USER_HOME}/.zshrc"
fi
```

3. **Copy to root after installation** (see User Context Pattern above)

### Testing Features

#### Test Directory Structure

```
test/
├── feature-name/
│   ├── test.sh              # Main test script
│   └── scenarios.json       # Optional test scenarios
```

#### Basic Test Pattern

```bash
#!/bin/bash
set -e
source dev-container-features-test-lib

# Feature-specific tests
check "tool installed" bash -c "command -v tool"
check "version check" bash -c "tool --version"
check "config exists" bash -c "test -f $HOME/.config"
```

#### Running Tests

```bash
# Test single feature with specific base image
devcontainer features test --skip-scenarios -f feature-name -i ubuntu:latest .

# Test all features
devcontainer features test .
```

#### Common Test Issues

1. **Missing test directories**: Test framework creates unique temp directories
2. **User context mismatch**: Tests run as root, installation may be for different user
   - **Solution**: Copy configs to root (see User Context Pattern)
3. **PATH issues**: Tools installed in user-specific paths
   - **Solution**: Add PATH exports to both user and root shell configs

### Framework Installation Patterns

#### Install with su -

Always use `su - ${USERNAME}` to run installations in the target user's environment:

```bash
su - ${USERNAME} << 'EOF'
export ZIM_HOME="${HOME}/.zim"
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh || true
EOF
```

Note:
- Use heredoc with `'EOF'` to prevent variable expansion in parent shell
- Add `|| true` to prevent installation failures from stopping the script
- Export necessary environment variables inside the heredoc

### Error Handling

```bash
set -e  # Exit on error

# For optional installations, use || true
curl -fsSL https://install.sh | bash || true

# For heredocs that might fail, don't use set -e inside
su - ${USERNAME} << 'EOF'
# Don't use 'set -e' here as it conflicts with || true pattern
curl -fsSL https://install.sh | zsh || true
EOF
```

### PATH Management

When installing tools that add executables to PATH:

```bash
# Add to shell configs
if [ -f "${USER_HOME}/.zshrc" ]; then
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "${USER_HOME}/.zshrc" || \
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${USER_HOME}/.zshrc"
fi

if [ -f "${USER_HOME}/.bashrc" ]; then
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "${USER_HOME}/.bashrc" || \
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${USER_HOME}/.bashrc"
fi
```

Use `grep -qxF` to check if line already exists before adding.

## Feature Development Checklist

When creating a new feature:

- [ ] Create `devcontainer-feature.json` with proper metadata
- [ ] Create `install.sh` with shebang `#!/usr/bin/env bash`
- [ ] Add `set -e` at the top
- [ ] Include common utility functions (check_packages, pkg_mgr_update, clean_up)
- [ ] Use `check_packages` to install dependencies
- [ ] Implement user detection (USERNAME=automatic pattern)
- [ ] Install tools for detected user using `su - ${USERNAME}`
- [ ] Copy configs to root if installing for non-root user
- [ ] Add PATH exports to shell configs
- [ ] Call `clean_up` at the end
- [ ] Create test script in `test/feature-name/test.sh`
- [ ] Test with multiple base images (ubuntu:latest, debian:latest, etc.)

## Common Mistakes to Avoid

1. **Not using check_packages**: Always use it instead of raw apt-get/dnf
2. **Forgetting to copy to root**: Tests will fail if configs only exist for target user
3. **Not checking for existing config**: Use grep or test before adding to files
4. **Hardcoding paths**: Use ${USER_HOME} and ${USERNAME} variables
5. **Not cleaning up**: Always call clean_up() at the end to reduce image size
6. **Missing dependencies**: Add all required packages (curl, ca-certificates, unzip, etc.)
7. **Not handling /etc/skel**: Check /etc/skel for default config files first
8. **Variable conflicts with /etc/os-release**: Save feature options BEFORE sourcing /etc/os-release (e.g., `NODE_VERSION=${VERSION:-"lts"}` before `. /etc/os-release`)
9. **Duplicate installations**: Check if version options overlap (e.g., VERSION="lts" + INSTALLLTS="true")

## Useful Commands

```bash
# Build and test locally
devcontainer features test --skip-scenarios -f feature-name -i ubuntu:latest .

# Test built image directly
docker run --rm <image-id> bash -c "command -v tool && test -f /root/.config"

# Check what's in /etc/skel
docker run --rm ubuntu:latest ls -la /etc/skel

# Debug user detection
docker run --rm ubuntu:latest bash -c "awk -v val=1000 -F ':' '\$3==val{print \$1}' /etc/passwd"
```

## References

- [Official devcontainer features](https://github.com/devcontainers/features)
- [common-utils feature](https://github.com/devcontainers/features/tree/main/src/common-utils) - Best reference for user handling
- [devcontainer CLI](https://github.com/devcontainers/cli)
