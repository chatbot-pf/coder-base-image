# Coder Base Image

A comprehensive Docker base image for [Coder](https://coder.com/) workspaces, built on `codercom/enterprise-base:ubuntu`.

## Features

### Shell Environment
- **Zsh** with [Zimfw](https://github.com/zimfw/zimfw) framework
- **Oh My Posh** for customizable prompt themes
- Vim mode, syntax highlighting, autosuggestions, and history search
- Custom Nerd Fonts (MesloLGS NF, JetBrainsMono, D2Coding)

### Development Tools
- **Node.js**: Managed via [fnm](https://github.com/Schniz/fnm) (LTS and v22 installed)
- **SDKMAN**: For Java/JVM ecosystem tools
- **Bun**: Fast JavaScript runtime and toolkit
- **Deno**: Secure TypeScript/JavaScript runtime
- **FVM**: Flutter Version Management
- **Claude Code CLI**: AI-powered coding assistant

### DevOps & Tools
- **Docker**: Containerization with coder user in docker group
- **Homebrew**: Package manager for Linux
- **Graphite CLI**: Stacked pull request workflow
- **GitHub CLI (gh)**: GitHub operations from terminal
- **AWS CLI**: Amazon Web Services command line interface
- **Qodana CLI**: JetBrains code quality platform

## Quick Start

### Using with VS Code Dev Containers

1. **Install Prerequisites:**
   - [VS Code](https://code.visualstudio.com/)
   - [Dev Containers Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
   - [Docker Desktop](https://www.docker.com/products/docker-desktop)

2. **Open in Dev Container:**
   ```bash
   # Clone this repository
   git clone https://github.com/rebooter-dev/coder-base-image.git
   cd coder-base-image

   # Open in VS Code
   code .

   # Press F1 and select "Dev Containers: Reopen in Container"
   ```

3. **Or use with GitHub Codespaces:**
   - Click "Code" → "Create codespace on main" in GitHub
   - The environment will be automatically configured

### Using with Coder

1. **Reference the published image:**
   ```bash
   docker pull ghcr.io/rebooter-dev/coder-base-image:main
   ```

2. **Use Dev Container in Coder (recommended):**

   Coder supports Dev Containers natively. See [Coder Dev Container docs](https://coder.com/docs/admin/templates/managing-templates/devcontainers) for details.

   For Coder workspace templates using this image, see the separate [coder-templates](https://github.com/rebooter-dev/coder-templates) repository.

### Building Locally

```bash
# Build Coder image
docker build -t coder-base-image .

# Build Dev Container image
docker build -f .devcontainer/Dockerfile -t coder-base-devcontainer .
```

## Architecture

### Build Process

The Dockerfile uses a two-phase build:

1. **Root Phase**: System-level installations
   - Ubuntu mirror configured to Kakao (Korea)
   - System packages and fonts
   - GitHub CLI, AWS CLI, Qodana CLI
   - Docker Engine

2. **User Phase**: Development environment for `coder` user
   - Shell framework and tools
   - Programming language runtimes
   - Package managers
   - CLI utilities

### Installation Scripts

All installation scripts are located in the `scripts/` directory:

| Script | Description | User |
|--------|-------------|------|
| `install-fonts.sh` | System fonts installation | root |
| `install-root-sdk.sh` | Qodana CLI, AWS CLI | root |
| `install-docker.sh` | Docker Engine | root |
| `install-sdk.sh` | fnm, SDKMAN, Bun, Deno, Claude Code, FVM | coder |
| `install-ohmyposh.sh` | Oh My Posh prompt | coder |
| `install-brew.sh` | Homebrew package manager | coder |
| `install-graphite.sh` | Graphite CLI | coder |

## Customization

### Adding New Tools

1. Create a new installation script in `scripts/`:
   ```bash
   scripts/install-mytool.sh
   ```

2. Add the script to Dockerfile:
   ```dockerfile
   COPY --chown=coder:coder scripts/install-mytool.sh /tmp/install-mytool.sh
   RUN chmod +x /tmp/install-mytool.sh && \
       /usr/bin/zsh /tmp/install-mytool.sh && \
       rm /tmp/install-mytool.sh
   ```

### Modifying Shell Configuration

- **Zimfw modules**: Edit `.zimrc`
- **Oh My Posh theme**: Modify initialization in `scripts/install-ohmyposh.sh`
- **Environment variables**: Update `.zshenv`

## CI/CD

Images are automatically built and published to GitHub Container Registry via GitHub Actions:

- **Triggers**:
  - Push to `main` branch
  - Pull requests (build only, no push)
  - Daily at 20:27 UTC
  - Semver tags (`v*.*.*`)

- **Registry**: `ghcr.io/rebooter-dev/coder-base-image`
- **Security**: Images are signed with cosign

## Important Notes

- **fnm vs nvm**: This image uses fnm instead of nvm. An alias `nvm="fnm"` is provided for compatibility
- **Homebrew location**: Installed at `/home/linuxbrew/.linuxbrew/`
- **Oh My Posh**: Installed via official script to `~/.local/bin`
- **Docker daemon**: Must be started separately in Coder workspaces
- **Timezone**: Configured to `Asia/Seoul`

## License

This project is open source and available under the [MIT License](LICENSE).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request
