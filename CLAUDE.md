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

## Repository Structure

```
.
├── images/                 # Docker images directory
│   ├── base/              # Base development image
│   └── CLAUDE.md          # Detailed images documentation
├── .devcontainer/         # VS Code Dev Container configuration
├── .github/workflows/     # CI/CD workflows
├── docs/                  # Documentation
└── CLAUDE.md             # This file - repository guidance
```

**For detailed information:**
- **Docker images, build process, and scripts:** See [images/CLAUDE.md](images/CLAUDE.md)

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

The repository uses a two-phase Docker build with clear separation between root and user installations.

**Build Phases:**
- **Phase 1 (Root)**: System packages, CLI tools (gh, gcloud), fonts, Docker, root-level tools
- **Phase 2 (Coder User)**: Development SDKs, Oh My Posh, Homebrew, Graphite CLI

**For detailed build phases, script organization, and configuration files, see [images/CLAUDE.md](images/CLAUDE.md)**

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