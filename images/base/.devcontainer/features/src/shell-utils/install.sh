#!/usr/bin/env bash
set -e

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

# Import options
INSTALLZSH=${INSTALLZSH:-"true"}
CONFIGUREZSH_AS_DEFAULTSHELL=${CONFIGUREZSH_AS_DEFAULTSHELL:-"true"}
SHELLFRAMEWORK=${SHELLFRAMEWORK:-"zimfw"}
INSTALLOHMYPOSH=${INSTALLOHMYPOSH:-"true"}
OHMYPOSHTHEME=${OHMYPOSHTHEME:-"default"}
USERNAME=${USERNAME:-"automatic"}
UPGRADEPACKAGES=${UPGRADEPACKAGES:-"true"}

echo "=========================================="
echo "Installing Shell Utilities..."
echo "=========================================="

# Detect the user to install for (same logic as official features)
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

echo "Configuring for user: ${USERNAME}"
echo "Home directory: ${USER_HOME}"

# Install required packages
echo "Installing required packages..."
check_packages curl ca-certificates unzip zsh

# Set Zsh as default shell if requested
if [ "${INSTALLZSH}" = "true" ] && [ "${CONFIGUREZSH_AS_DEFAULTSHELL}" = "true" ]; then
    echo "Setting Zsh as default shell for ${USERNAME}..."
    chsh -s $(which zsh) ${USERNAME}
fi

# Restore .zshrc from /etc/skel if available
if [ -f "/etc/skel/.zshrc" ]; then
    if [ ! -e "${USER_HOME}/.zshrc" ] || [ ! -s "${USER_HOME}/.zshrc" ]; then
        cp "/etc/skel/.zshrc" "${USER_HOME}/.zshrc"
        chown ${USERNAME}:$(id -gn ${USERNAME}) "${USER_HOME}/.zshrc"
    fi
fi

# Ensure .zshrc exists for target user (if /etc/skel didn't have one)
if [ ! -f "${USER_HOME}/.zshrc" ]; then
    touch "${USER_HOME}/.zshrc"
    chown ${USERNAME}:$(id -gn ${USERNAME}) "${USER_HOME}/.zshrc"
fi

# Install shell framework
if [ "${SHELLFRAMEWORK}" = "zimfw" ]; then
    echo "Installing Zimfw..."
    su - ${USERNAME} << 'EOF'
export ZIM_HOME="${HOME}/.zim"
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh || true
EOF
    echo "✅ Zimfw installed"

elif [ "${SHELLFRAMEWORK}" = "ohmyzsh" ]; then
    echo "Installing Oh My Zsh..."
    su - ${USERNAME} << 'EOF'
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
EOF
    echo "✅ Oh My Zsh installed"
fi

# Install Oh My Posh if requested
if [ "${INSTALLOHMYPOSH}" = "true" ]; then
    echo "Installing Oh My Posh..."
    su - ${USERNAME} << 'EOF'
curl -s https://ohmyposh.dev/install.sh | bash -s || true
EOF

    # Add Oh My Posh to shell configs
    if [ -f "${USER_HOME}/.zshrc" ]; then
        cat >> "${USER_HOME}/.zshrc" << 'ZSHRC_EOF'

# Oh My Posh initialization
export PATH="$HOME/.local/bin:$PATH"
eval "$(oh-my-posh init zsh)"
ZSHRC_EOF
    fi

    # Ensure .bashrc exists
    if [ ! -f "${USER_HOME}/.bashrc" ]; then
        touch "${USER_HOME}/.bashrc"
        chown ${USERNAME}:$(id -gn ${USERNAME}) "${USER_HOME}/.bashrc"
    fi

    if [ -f "${USER_HOME}/.bashrc" ]; then
        cat >> "${USER_HOME}/.bashrc" << 'BASHRC_EOF'

# Oh My Posh initialization
export PATH="$HOME/.local/bin:$PATH"
eval "$(oh-my-posh init bash)"
BASHRC_EOF
    fi

    # Apply theme if specified
    if [ "${OHMYPOSHTHEME}" != "default" ]; then
        echo "Configuring Oh My Posh theme: ${OHMYPOSHTHEME}..."
        # Note: Theme configuration can be done by users in their shell configs
    fi

    echo "✅ Oh My Posh installed"
fi

# Copy shell configurations to root user if installing for non-root
# This must be done AFTER all installations (frameworks + Oh My Posh)
if [ "${USERNAME}" != "root" ]; then
    copy_files=()
    [ -f "${USER_HOME}/.zshrc" ] && copy_files+=("${USER_HOME}/.zshrc")
    [ -f "${USER_HOME}/.bashrc" ] && copy_files+=("${USER_HOME}/.bashrc")
    [ -d "${USER_HOME}/.zim" ] && copy_files+=("${USER_HOME}/.zim")
    [ -d "${USER_HOME}/.oh-my-zsh" ] && copy_files+=("${USER_HOME}/.oh-my-zsh")
    [ -d "${USER_HOME}/.local" ] && copy_files+=("${USER_HOME}/.local")
    [ -d "${USER_HOME}/.cache" ] && copy_files+=("${USER_HOME}/.cache")
    if [ ${#copy_files[@]} -gt 0 ]; then
        cp -rf "${copy_files[@]}" /root/
    fi
fi

echo "=========================================="
echo "✅ Shell utilities installation completed!"
echo "=========================================="

# Show installed components
echo "Installed components:"
if [ "${INSTALLZSH}" = "true" ]; then
    echo "  - Zsh: $(zsh --version)"
fi
if [ "${SHELLFRAMEWORK}" != "none" ]; then
    echo "  - Shell Framework: ${SHELLFRAMEWORK}"
fi
if [ "${INSTALLOHMYPOSH}" = "true" ]; then
    su - ${USERNAME} << 'EOF'
if command -v oh-my-posh &> /dev/null; then
    echo "  - Oh My Posh: $(oh-my-posh --version)"
fi
EOF
fi

# Clean up
clean_up

echo "Done!"
