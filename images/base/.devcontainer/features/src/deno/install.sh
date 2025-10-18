#!/usr/bin/env bash
set -e

# Save VERSION option before sourcing os-release
DENO_VERSION=${VERSION:-"latest"}

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

# Determine the appropriate non-root user
if [ "${_REMOTE_USER}" != "root" ]; then
    USERNAME="${_REMOTE_USER}"
else
    USERNAME="${USERNAME:-"automatic"}"
fi

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
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" > /dev/null 2>&1; then
    USERNAME=root
fi

USER_HOME="/root"
if [ "${USERNAME}" != "root" ]; then
    USER_HOME="/home/${USERNAME}"
fi

echo "Installing Deno..."
echo "Installing for user: ${USERNAME}"
echo "Home directory: ${USER_HOME}"

# Install required packages
check_packages curl ca-certificates unzip

# Install Deno as the target user
if [ "${DENO_VERSION}" = "latest" ]; then
    su - ${USERNAME} << 'EOF'
curl -fsSL https://deno.land/install.sh | sh
EOF
else
    su - ${USERNAME} bash -c "curl -fsSL https://deno.land/install.sh | sh -s v${DENO_VERSION}"
fi

# Add to shell configs for the target user
if [ -f "${USER_HOME}/.zshrc" ]; then
    if ! grep -qF 'export DENO_INSTALL="$HOME/.deno"' "${USER_HOME}/.zshrc"; then
        echo 'export DENO_INSTALL="$HOME/.deno"' >> "${USER_HOME}/.zshrc"
        echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> "${USER_HOME}/.zshrc"
    fi
fi

if [ -f "${USER_HOME}/.bashrc" ]; then
    if ! grep -qF 'export DENO_INSTALL="$HOME/.deno"' "${USER_HOME}/.bashrc"; then
        echo 'export DENO_INSTALL="$HOME/.deno"' >> "${USER_HOME}/.bashrc"
        echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> "${USER_HOME}/.bashrc"
    fi
fi

# Copy deno installation to root user if installing for non-root
if [ "${USERNAME}" != "root" ]; then
    if [ -d "${USER_HOME}/.deno" ]; then
        cp -rf "${USER_HOME}/.deno" /root/
    fi

    # Also add to root's shell configs
    if [ -f "/root/.bashrc" ]; then
        if ! grep -qF 'export DENO_INSTALL="$HOME/.deno"' "/root/.bashrc"; then
            echo 'export DENO_INSTALL="$HOME/.deno"' >> /root/.bashrc
            echo 'export PATH="$DENO_INSTALL/bin:$PATH"' >> /root/.bashrc
        fi
    fi
fi

echo "✅ Deno installed successfully!"
su - ${USERNAME} << 'EOF'
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
deno --version
EOF

# Clean up
clean_up

echo "Done!"
