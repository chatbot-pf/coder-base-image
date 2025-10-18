#!/usr/bin/env bash
set -e

# Save feature VERSION option before sourcing /etc/os-release
NODE_VERSION=${VERSION:-"lts"}

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
ADJUSTED_ID="${ID}"
if [ "${ID}" = "debian" ] || [ "${ID_LIKE#*debian*}" != "${ID_LIKE}" ]; then
    ADJUSTED_ID="debian"
elif [ "${ID}" = "rhel" ] || [ "${ID}" = "fedora" ] || [ "${ID}" = "mariner" ] || [ "${ID_LIKE#*rhel*}" != "${ID_LIKE}" ] || [ "${ID_LIKE#*fedora*}" != "${ID_LIKE}" ] || [ "${ID_LIKE#*mariner*}" != "${ID_LIKE}" ]; then
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
else
    echo "(Error) Unable to find a supported package manager."
    exit 1
fi

pkg_mgr_update() {
    case ${ADJUSTED_ID} in
        debian)
            if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
                echo "Running apt-get update..."
                ${PKG_MGR_CMD} update -y
            fi
            ;;
        rhel)
            if [ ${PKG_MGR_CMD} = "microdnf" ]; then
                if [ "$(ls /var/cache/yum/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} makecache..."
                    ${PKG_MGR_CMD} makecache
                fi
            else
                if [ "$(ls /var/cache/${PKG_MGR_CMD}/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} check-update..."
                    set +e
                    stderr_messages=$(${PKG_MGR_CMD} -q check-update 2>&1)
                    rc=$?
                    if [ $rc != 0 ] && [ $rc != 100 ]; then
                        echo "(Error) ${PKG_MGR_CMD} check-update produced the following error message(s):"
                        echo "${stderr_messages}"
                        exit 1
                    fi
                    set -e
                fi
            fi
            ;;
    esac
}

# Checks if packages are installed and installs them if not
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

# Clean up
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

# Import options (NODE_VERSION already set before sourcing /etc/os-release)
INSTALLLTS=${INSTALLLTS:-"true"}
INSTALLYARN=${INSTALLYARN:-"true"}
INSTALLPNPM=${INSTALLPNPM:-"true"}
PNPMVERSION=${PNPMVERSION:-"latest"}
NVMALIAS=${NVMALIAS:-"true"}

echo "=========================================="
echo "Installing Node.js via fnm..."
echo "=========================================="

# Install required packages
echo "Installing required packages..."
check_packages curl ca-certificates unzip

# Detect the user to install for (same logic as official features)
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
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

echo "Installing for user: ${USERNAME}"
echo "Home directory: ${USER_HOME}"

# Install fnm as the target user
su - ${USERNAME} << 'EOF'
set -e

echo "Installing fnm..."
curl -fsSL https://fnm.vercel.app/install | bash

# Setup fnm environment
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"

EOF

# Add fnm to shell configs
cat >> "${USER_HOME}/.bashrc" << 'BASHRC_EOF'

# fnm (Fast Node Manager)
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
BASHRC_EOF

if [ -f "${USER_HOME}/.zshrc" ]; then
    cat >> "${USER_HOME}/.zshrc" << 'ZSHRC_EOF'

# fnm (Fast Node Manager)
export PATH="$HOME/.local/share/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
ZSHRC_EOF
fi

# Install Node.js versions as the target user
su - ${USERNAME} << EOF
set -e

# Setup fnm environment
export PATH="\$HOME/.local/share/fnm:\$PATH"
eval "\$(fnm env --use-on-cd)"

# Install Node.js versions
if [ "${NODE_VERSION}" = "lts" ] || [ "${NODE_VERSION}" = "none" ]; then
    # If version is lts or none, just install LTS if requested
    if [ "${INSTALLLTS}" = "true" ]; then
        echo "Installing Node.js LTS..."
        fnm install --lts
        # Get the actual LTS version that was installed
        INSTALLED_LTS=\$(fnm list | grep -oP 'v\d+\.\d+\.\d+' | head -n1 | sed 's/^v//')
        if [ -n "\$INSTALLED_LTS" ]; then
            fnm default "\$INSTALLED_LTS"
        fi
    fi
else
    # Install specified version first
    echo "Installing Node.js ${NODE_VERSION}..."
    fnm install "${NODE_VERSION}"
    fnm default "${NODE_VERSION}"

    # Also install LTS if requested (different from specified version)
    if [ "${INSTALLLTS}" = "true" ]; then
        echo "Installing Node.js LTS..."
        fnm install --lts
    fi
fi

# Show installed versions
echo "Installed Node.js versions:"
fnm list

# Verify installation by running node through fnm
echo "Node.js version:"
fnm exec --using=default node --version
echo "npm version:"
fnm exec --using=default npm --version

EOF

# Install Yarn if requested
if [ "${INSTALLYARN}" = "true" ]; then
    echo "Installing Yarn..."
    su - ${USERNAME} << 'EOF'
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
    fnm exec --using=default npm install -g yarn
    fnm exec --using=default yarn --version
EOF
fi

# Install pnpm if requested
if [ "${INSTALLPNPM}" = "true" ]; then
    echo "Installing pnpm ${PNPMVERSION}..."
    su - ${USERNAME} << EOF
    export PATH="\$HOME/.local/share/fnm:\$PATH"
    eval "\$(fnm env --use-on-cd)"
    if [ "${PNPMVERSION}" = "latest" ]; then
        fnm exec --using=default npm install -g pnpm
    else
        fnm exec --using=default npm install -g pnpm@${PNPMVERSION}
    fi
    fnm exec --using=default pnpm --version
EOF
fi

# Add nvm alias for compatibility if requested
if [ "${NVMALIAS}" = "true" ]; then
    echo "Adding nvm alias for compatibility..."
    echo 'alias nvm="fnm"' >> "${USER_HOME}/.bashrc"
    if [ -f "${USER_HOME}/.zshrc" ]; then
        echo 'alias nvm="fnm"' >> "${USER_HOME}/.zshrc"
    fi
fi

echo "=========================================="
echo "✅ Node.js installation completed!"
echo "=========================================="
su - ${USERNAME} << 'EOF'
export PATH="$HOME/.local/share/fnm:$PATH"
echo "Node.js: $(fnm exec --using=default node --version)"
echo "npm: $(fnm exec --using=default npm --version)"
if fnm exec --using=default yarn --version &> /dev/null; then
    echo "Yarn: $(fnm exec --using=default yarn --version)"
fi
if fnm exec --using=default pnpm --version &> /dev/null; then
    echo "pnpm: $(fnm exec --using=default pnpm --version)"
fi
EOF

# Clean up
clean_up

echo "Done!"
