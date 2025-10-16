# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker base image for Coder workspaces, built on top of `codercom/enterprise-base:ubuntu`. It provides a comprehensive development environment with:
- Zsh shell with Zimfw framework and Oh My Posh prompt
- Node.js (via fnm) with LTS and version 22
- SDKMAN for Java/JVM ecosystem tools
- Bun, Deno, and Claude Code CLI
- Docker with coder user in docker group
- Homebrew package manager
- Graphite CLI for stacked PRs
- AWS CLI, Google Cloud CLI, and Qodana CLI
- Custom Nerd Fonts for terminal display

## Common Commands

### Build and Deploy
```bash
# Build Docker image locally
docker build -t coder-base-image .

# GitHub Actions automatically builds and publishes to ghcr.io on push to main
# Images are published to ghcr.io on:
#   - Push to main branch
#   - Daily at 20:27 UTC (scheduled)
#   - Semver tags (v*.*.*)
```

## Architecture

The repository uses a two-phase Docker build with clear separation between root and user installations:

### Build Phases

**Phase 1 - Root User Setup:**
1. Ubuntu mirror changed to Kakao for faster downloads (Korea region)
2. System packages installed (zip, zsh, screen, lsof, amazon-ecr-credential-helper)
3. GitHub CLI installed via apt repository
4. Google Cloud CLI installed via apt repository
5. Default shell changed to zsh for coder user
6. Fonts installed system-wide
7. Root-level tools installed (Qodana CLI, AWS CLI)
8. Docker installed and coder user added to docker group

**Phase 2 - Coder User Setup:**
1. Development SDKs installed (Zimfw, fnm, Node.js, SDKMAN, Bun, Deno, Claude Code, FVM)
2. Oh My Posh installed for shell prompt theming
3. Homebrew installed
4. Graphite CLI installed via Homebrew

### Script Organization

All installation scripts are in `scripts/` directory:
- `install-fonts.sh` - System fonts (MesloLGS NF, JetBrainsMono Nerd Font, D2Coding)
- `install-root-sdk.sh` - Root-level tools (Qodana, AWS CLI)
- `install-docker.sh` - Docker Engine installation
- `install-sdk.sh` - User development tools (fnm, SDKMAN, Bun, Deno, Claude Code, FVM)
- `install-ohmyposh.sh` - Oh My Posh prompt (uses official installer)
- `install-brew.sh` - Homebrew package manager
- `install-graphite.sh` - Graphite CLI for stacked PRs

### Key Configuration Files

- `.zimrc` - Zimfw modules (git, input, completion, syntax-highlighting, autosuggestions, vim-mode)
- `.zshenv` - Environment variable to skip global compinit
- `.p10k.zsh` - Powerlevel10k configuration (legacy, being replaced by Oh My Posh)

### CI/CD

GitHub Actions workflow at `.github/workflows/docker-publish.yml`:
- Builds on push to main, PRs, daily schedule, and semver tags
- Publishes to GitHub Container Registry (ghcr.io)
- Uses Docker Buildx for caching
- Signs images with cosign for security

## Important Notes

- Node.js is managed via fnm (not nvm) with alias `nvm="fnm"` for compatibility
- Homebrew is installed for coder user at `/home/linuxbrew/.linuxbrew/`
- Oh My Posh is installed via official script (not Homebrew) to `~/.local/bin`
- Docker daemon must be started separately in Coder workspaces
- All user scripts run as coder user, root scripts run as root
- Scripts are copied to `/tmp/` and deleted after execution to minimize image size