# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Docker base image for Coder workspaces, built on top of `codercom/enterprise-base:ubuntu`. It provides a development environment with:
- Zsh shell with Zimfw framework and Powerlevel10k theme
- Node.js (via NVM) with LTS and version 22
- SDKMAN for Java/JVM ecosystem tools
- Bun JavaScript runtime
- Custom fonts for terminal display

## Common Commands

### Build and Deploy
```bash
# Build Docker image locally
docker build -t coder-base-image .

# GitHub Actions automatically builds and publishes to ghcr.io on push to main
# Manual trigger is not needed for deployment
```

### Shell Scripts
```bash
# Install development SDKs (runs inside container during build)
./install-sdk.sh

# Install fonts (runs as root during container build)
./install-fonts.sh

# Configure Zsh environment (for manual setup)
./install.sh
```

## Architecture

The repository consists of:

1. **Dockerfile**: Multi-stage build that:
   - Installs system packages (zip, zsh, screen, fonts)
   - Changes default shell to zsh for coder user
   - Copies and executes installation scripts
   - Sets up development environment

2. **Installation Scripts**:
   - `install-sdk.sh`: Installs Zimfw, NVM, Node.js, SDKMAN, and Bun
   - `install-fonts.sh`: Installs system fonts for terminal UI
   - `install.sh`: Helper script for Zsh configuration management

3. **Configuration Files**:
   - `.zimrc`: Zimfw configuration with modules and theme settings
   - `.p10k.zsh`: Powerlevel10k prompt configuration
   - `.zshenv`: Environment variable for skipping global compinit

4. **CI/CD**:
   - GitHub Actions workflow (`.github/workflows/docker-publish.yml`) automatically builds and publishes Docker images to GitHub Container Registry on push to main branch